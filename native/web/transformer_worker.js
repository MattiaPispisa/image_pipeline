let photonLoaded = false;

// load photon
export async function ensurePhoton(basePath) {
  if (photonLoaded) {
    return self.photon;
  }
  const photonModule = await import(basePath + "photon_rs.js");
  await photonModule.default();
  self.photon = photonModule;
  photonLoaded = true;
  return self.photon;
}

export async function processImage(inputBytes, operations, basePath) {
  const photon = await ensurePhoton(basePath);
  const blob = new Blob([inputBytes]);

  let bmp;
  try {
    bmp = await createImageBitmap(blob);
  } catch (err) {
    throw new Error(`unsupported_image_format ${err.message || err}`);
  }

  const isWorker = typeof importScripts === "function";
  let canvas, ctx;

  if (isWorker) {
    canvas = new OffscreenCanvas(bmp.width, bmp.height);
    ctx = canvas.getContext("2d", { willReadFrequently: true });
  } else {
    canvas = document.createElement("canvas");
    canvas.width = bmp.width;
    canvas.height = bmp.height;
    ctx = canvas.getContext("2d", { willReadFrequently: true });
  }
  ctx.drawImage(bmp, 0, 0);

  let photonImg = null;
  let format = "image/jpeg";
  let quality = 0.75;
  let currentStep = "initialization";

  const safeFree = (img) => {
    if (img) {
      try {
        img.free();
      } catch (e) {
        // already free
      }
    }
  };

  try {
    currentStep = "reading_canvas";
    photonImg = photon.open_image(canvas, ctx);

    for (let i = 0; i < operations.length; ) {
      const op = operations[i];

      if (op === 1) {
        // resize
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
          currentStep = "resizing";

          const filter = photon.SamplingFilter
            ? photon.SamplingFilter.Lanczos3
            : 1;

          const resizedImg = photon.resize(
            photonImg,
            newWidth,
            newHeight,
            filter,
          );
          safeFree(photonImg);
          photonImg = resizedImg;
        }
      } else if (op === 2) {
        // quality
        quality = operations[i + 1] / 100.0;
        quality = Math.max(0, Math.min(1, quality));
        i += 2;
      } else {
        break;
      }
    }

    if (photonImg) {
      currentStep = "adapting_canvas";
      const finalWidth = photonImg.get_width();
      const finalHeight = photonImg.get_height();
      canvas.width = finalWidth;
      canvas.height = finalHeight;

      currentStep = "extracting_pixels";
      // Fetch raw RGBA pixels from WASM.
      const rawPixels = photonImg.get_raw_pixels();

      currentStep = "drawing_to_canvas";
      const imgData = new ImageData(
        new Uint8ClampedArray(rawPixels),
        finalWidth,
        finalHeight,
      );

      ctx.putImageData(imgData, 0, 0);
    }
  } catch (err) {
    // Report internal errors to Dart.
    throw new Error(`error_at_step [${currentStep}]: ${err.message || err}`);
  } finally {
    safeFree(photonImg);
    photonImg = null;
  }

  currentStep = "extracting_blob";
  let outBuffer;
  if (isWorker) {
    const outBlob = await canvas.convertToBlob({
      type: format,
      quality: quality,
    });
    outBuffer = await outBlob.arrayBuffer();
  } else {
    const outBlob = await new Promise((res, rej) =>
      canvas.toBlob((b) => (b ? res(b) : rej("Error")), format, quality),
    );
    outBuffer = await outBlob.arrayBuffer();
  }

  return new Uint8Array(outBuffer);
}

// Worker entry point.
if (typeof importScripts === "function") {
  self.onmessage = async function (e) {
    const { id, inputBytes, operations, basePath } = e.data;
    try {
      const result = await processImage(inputBytes, operations, basePath);

      // Return memory back to the main thread without copying.
      self.postMessage({ id, result, success: true }, [result.buffer]);
    } catch (err) {
      self.postMessage({ id, error: err.message, success: false });
    }
  };
}
