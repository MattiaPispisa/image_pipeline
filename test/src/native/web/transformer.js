window.image_pipeline = {
    config: { mode: 'worker', basePath: './', workerPath: './transformer_worker.js' },
    worker: null,
    callbacks: {}, // Tiene traccia delle promesse in attesa del worker
    msgId: 0,
    coreModule: null, // Usato solo in modalità sync

    // mode può essere 'worker' o 'sync'
    init_engine: async function (mode, basePath, workerPath) {
        this.config.mode = mode;
        this.config.basePath = basePath;
        this.config.workerPath = workerPath;

        if (mode === 'worker') {
            if (!this.worker) {
                // Avvia il worker caricandolo come Modulo ES6
                this.worker = new Worker(this.config.workerPath, { type: 'module' });

                // Smista le risposte del worker alla Promise corretta in Dart
                this.worker.onmessage = (e) => {
                    const { id, result, error, success } = e.data;
                    if (this.callbacks[id]) {
                        if (success) {
                            this.callbacks[id].resolve(result);
                        }
                        else {
                            this.callbacks[id].reject(new Error(error))
                        };
                        delete this.callbacks[id];
                    }
                };
            }
            return true;
        } else {
            // Modalità SYNC: importiamo il modulo sul Main Thread per i test
            if (!this.coreModule) {
                this.coreModule = await import(this.config.workerPath);
                await this.coreModule.ensurePhoton(this.config.basePath);
            }
            return true
        }
    },

    execute_pipeline: async function (inputBytes, operations) {
        if (this.config.mode === 'worker') {
            return new Promise((resolve, reject) => {
                const id = this.msgId++;
                this.callbacks[id] = { resolve, reject };

                // Invio al Worker sfruttando i Transferable Objects (il secondo argomento array)
                // Questo rende "inaccessibile" l'inputBytes nel main thread, ma lo passa a velocità 0-copy al worker
                this.worker.postMessage(
                    { id, inputBytes, operations, basePath: this.config.basePath },
                    [inputBytes.buffer]
                );
            });
        } else {
            // Modalità SYNC
            if (!this.coreModule) { throw new Error("Motore non inizializzato"); }
            return await this.coreModule.processImage(inputBytes, operations, this.config.basePath);
        }
    }
};