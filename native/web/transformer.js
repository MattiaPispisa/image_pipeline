window.image_pipeline = {
  config: {
    mode: "worker",
    basePath: "./",
    workerPath: "./transformer_worker.js",
  },
  worker: null,
  worker: null,
  callbacks: {}, // Tracks promises waiting for the worker
  msgId: 0,
  coreModule: null, // Used only in sync mode

  // mode can be 'worker' or 'sync'
  init_engine: async function (mode, basePath, workerPath) {
    this.config.mode = mode;
    this.config.basePath = basePath;
    this.config.workerPath = workerPath;

    if (mode === "worker") {
      if (!this.worker) {
        // init worker
        this.worker = new Worker(this.config.workerPath, { type: "module" });

        // return the message to the correct request
        this.worker.onmessage = (e) => {
          const { id, result, error, success } = e.data;
          if (this.callbacks[id]) {
            if (success) {
              this.callbacks[id].resolve(result);
            } else {
              this.callbacks[id].reject(new Error(error));
            }
            delete this.callbacks[id];
          }
        };
      }
      return true;
    } else {
      // sync mode, no worker
      if (!this.coreModule) {
        this.coreModule = await import(this.config.workerPath);
        await this.coreModule.ensurePhoton(this.config.basePath);
      }
      return true;
    }
  },

  execute_pipeline: async function (inputBytes, operations) {
    if (this.config.mode === "worker") {
      return new Promise((resolve, reject) => {
        const id = this.msgId++;
        this.callbacks[id] = { resolve, reject };

        this.worker.postMessage(
          { id, inputBytes, operations, basePath: this.config.basePath },
          [inputBytes.buffer],
        );
      });
    } else {
      if (!this.coreModule) {
        throw new Error("engine_not_initialized");
      }
      return await this.coreModule.processImage(
        inputBytes,
        operations,
        this.config.basePath,
      );
    }
  },
};
