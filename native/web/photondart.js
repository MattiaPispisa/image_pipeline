window.image_pipeline = {
  init_engine: async function (pluginName) {
    if (typeof photon === 'undefined') {
      console.warn("image_pipeline: 'photon' non disponibile. Importa '@silvia-odwyer/photon'.");
      return false;
    }
    return true;
  },

  execute_pipeline: async function (inputBytes, operations) {
    if (typeof photon === 'undefined') {
      throw new Error("image_pipeline: libreria 'photon' mancante.");
    }

    // --- Decode input ---
    const blob = new Blob([inputBytes]);
    const bmp = await createImageBitmap(blob);

    // Canvas setup
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');

    canvas.width = bmp.width;
    canvas.height = bmp.height;
    ctx.drawImage(bmp, 0, 0);

    let photonImg = null;
    let quality = null;
    let format = 'image/jpeg'; // default

    try {
      photonImg = photon.open_image(canvas, ctx);

      // --- Format detection (più robusto) ---
      if (inputBytes.length >= 8) {
        // PNG
        if (
          inputBytes[0] === 0x89 &&
          inputBytes[1] === 0x50 &&
          inputBytes[2] === 0x4E &&
          inputBytes[3] === 0x47
        ) {
          format = 'image/png';
        }
        // JPEG
        else if (
          inputBytes[0] === 0xFF &&
          inputBytes[1] === 0xD8
        ) {
          format = 'image/jpeg';
        }
        // WEBP (RIFF....WEBP)
        else if (
          inputBytes[0] === 0x52 && // R
          inputBytes[1] === 0x49 && // I
          inputBytes[2] === 0x46 && // F
          inputBytes[3] === 0x46 && // F
          inputBytes[8] === 0x57 && // W
          inputBytes[9] === 0x45 && // E
          inputBytes[10] === 0x42 && // B
          inputBytes[11] === 0x50 // P
        ) {
          format = 'image/webp';
        }
      }

      // --- Pipeline ---
      for (let i = 0; i < operations.length;) {
        const op = operations[i];

        // --- Resize ---
        if (op === 1) {
          const maxWidth = operations[i + 1];
          const maxHeight = operations[i + 2];
          i += 3;

          const width = photonImg.get_width();
          const height = photonImg.get_height();

          let newWidth = width;
          let newHeight = height;

          // Mantieni aspect ratio
          if (maxWidth > 0 && newWidth > maxWidth) {
            newHeight = Math.round(newHeight * (maxWidth / newWidth));
            newWidth = maxWidth;
          }

          if (maxHeight > 0 && newHeight > maxHeight) {
            newWidth = Math.round(newWidth * (maxHeight / newHeight));
            newHeight = maxHeight;
          }

          if (newWidth !== width || newHeight !== height) {
            const resized = photon.resize(
              photonImg,
              newWidth,
              newHeight,
              photon.SamplingFilter.Lanczos3
            );

            photonImg.free();
            photonImg = resized;
          }
        }

        // --- Quality ---
        else if (op === 2) {
          quality = operations[i + 1] / 100.0;

          // Clamp tra 0 e 1
          quality = Math.max(0, Math.min(1, quality));

          i += 2;
        }

        // --- Unknown op ---
        else {
          console.warn("image_pipeline: opcode sconosciuto:", op);
          break;
        }
      }

      // --- Render finale ---
      const finalWidth = photonImg.get_width();
      const finalHeight = photonImg.get_height();

      canvas.width = finalWidth;
      canvas.height = finalHeight;

      photon.putImageData(canvas, ctx, photonImg);

    } finally {
      if (photonImg) {
        photonImg.free();
      }
    }

    // --- Encode output ---
    const outBlob = await new Promise((resolve, reject) => {
      canvas.toBlob(
        (blobResult) => {
          if (blobResult) resolve(blobResult);
          else reject(new Error("image_pipeline: encoding fallito"));
        },
        format,
        quality // usato solo da jpeg/webp
      );
    });

    const outBuffer = await outBlob.arrayBuffer();
    return new Uint8Array(outBuffer);
  }
};