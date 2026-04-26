// web/image_pipeline_worker.js

let photonLoaded = false;

// Esportata per l'uso Sincrono
export async function ensurePhoton(basePath) {
    if (photonLoaded) { return self.photon; }
    const photonModule = await import(basePath + 'photon_rs.js');
    await photonModule.default();
    self.photon = photonModule;
    photonLoaded = true;
    return self.photon;
}

export async function processImage(inputBytes, operations, basePath) {
    const photon = await ensurePhoton(basePath);
    const blob = new Blob([inputBytes]);
    const bmp = await createImageBitmap(blob);

    const isWorker = typeof importScripts === 'function';
    let canvas, ctx;

    // Protezione aggiuntiva: willReadFrequently evita crash di memoria in Chrome
    // quando Rust fa chiamate pesanti a getImageData()
    if (isWorker) {
        canvas = new OffscreenCanvas(bmp.width, bmp.height);
        ctx = canvas.getContext('2d', { willReadFrequently: true });
    } else {
        canvas = document.createElement('canvas');
        canvas.width = bmp.width;
        canvas.height = bmp.height;
        ctx = canvas.getContext('2d', { willReadFrequently: true });
    }
    ctx.drawImage(bmp, 0, 0);

    let photonImg = null;
    let format = 'image/jpeg';
    let quality = 0.75;
    let currentStep = "Inizializzazione completata";

    const safeFree = (img) => {
        if (img) {
            try { img.free(); } catch (e) { /* Già liberato */ }
        }
    };

    try {
        currentStep = "open_image (Lettura Canvas in Rust)";
        photonImg = photon.open_image(canvas, ctx);

        for (let i = 0; i < operations.length;) {
            const op = operations[i];

            if (op === 1) { // --- RESIZE ---
                const maxWidth = operations[i + 1];
                const maxHeight = operations[i + 2];
                i += 3;

                const width = photonImg.get_width();
                const height = photonImg.get_height();
                let newWidth = width;
                let newHeight = height;

                if (maxWidth > 0 && newWidth > maxWidth) {
                    newHeight = Math.round(newHeight * (maxWidth / newWidth));
                    newWidth = maxWidth;
                }
                if (maxHeight > 0 && newHeight > maxHeight) {
                    newWidth = Math.round(newWidth * (maxHeight / newHeight));
                    newHeight = maxHeight;
                }

                if (newWidth !== width || newHeight !== height) {
                    currentStep = `resize (da ${width}x${height} a ${newWidth}x${newHeight})`;

                    // Se photon esporta l'oggetto SamplingFilter, usiamo quello nativo. 
                    // Altrimenti proviamo con 1 (che è il filtro Triangle, molto più stabile del 5/4).
                    const filter = photon.SamplingFilter ? photon.SamplingFilter.Lanczos3 : 1;

                    const resizedImg = photon.resize(photonImg, newWidth, newHeight, filter);
                    safeFree(photonImg);
                    photonImg = resizedImg;
                }
            }
            else if (op === 2) { // --- QUALITY ---
                quality = operations[i + 1] / 100.0;
                quality = Math.max(0, Math.min(1, quality));
                i += 2;
            }
            else {
                break;
            }
        }

        if (photonImg) {
            currentStep = "Adattamento dimensioni Canvas";
            const finalWidth = photonImg.get_width();
            const finalHeight = photonImg.get_height();
            canvas.width = finalWidth;
            canvas.height = finalHeight;

            currentStep = "Estrazione array di pixel crudi (WASM -> JS)";
            // Chiediamo a Rust l'array RGBA puro, senza fargli toccare il DOM
            const rawPixels = photonImg.get_raw_pixels();

            currentStep = "Creazione oggetto ImageData nativo";
            // Convertiamo l'array Wasm in un formato digeribile dal Canvas
            const imgData = new ImageData(
                new Uint8ClampedArray(rawPixels),
                finalWidth,
                finalHeight
            );

            currentStep = "Scrittura su Canvas tramite JavaScript";
            // Disegniamo sul canvas usando JS nativo (100% immune ai crash di Rust!)
            ctx.putImageData(imgData, 0, 0);
        }

    } catch (err) {
        // CATTURIAMO IL PANIC E LO SPEDIAMO A DART!
        throw new Error(`CRASH allo step [${currentStep}]: ${err.message || err}`);
    } finally {
        safeFree(photonImg);
        photonImg = null;
    }

    currentStep = "Estrazione Blob finale";
    let outBuffer;
    if (isWorker) {
        const outBlob = await canvas.convertToBlob({ type: format, quality: quality });
        outBuffer = await outBlob.arrayBuffer();
    } else {
        const outBlob = await new Promise((res, rej) => canvas.toBlob((b) => b ? res(b) : rej("Errore"), format, quality));
        outBuffer = await outBlob.arrayBuffer();
    }

    return new Uint8Array(outBuffer);
}

// Se questo file viene lanciato come Web Worker (isolato dal DOM)
if (typeof importScripts === 'function') {
    self.onmessage = async function (e) {
        const { id, inputBytes, operations, basePath } = e.data;
        try {
            const result = await processImage(inputBytes, operations, basePath);

            // TRANSFERABLE OBJECT: Spostiamo la memoria indietro senza copiare
            self.postMessage({ id, result, success: true }, [result.buffer]);
        } catch (err) {
            self.postMessage({ id, error: err.message, success: false });
        }
    };
}