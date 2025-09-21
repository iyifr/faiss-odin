## Faiss-Odin
Odin bindings for FAISS (Facebook AI similarity search) an open-source library for efficient similarity search and clustering of dense vectors.

A handful of method are currently present in the bindings, and the code example *(example_c)* present in the `faiss` source code has been ported to odin for demonstration purposes.

The file is present at path: src/examples/example_flat.odin

To run the file, you must have faiss installed with the C API enabled;

Let's go over that again; to use faiss from odin you need

- Faiss installed
- With the C API enabled (and GPU mode soon)

In my case i built faiss from source on a 2019 Macbook Pro, compiling and installing the `libfaiss.dylib` and `libfaiss_c.dylib` files into the `/usr/local/lib` folder.

- On windows - A `faiss_c.lib` file
- On Linux - A `libfaiss_c.so` file or `libfaiss_c.a`

```zsh
➜  faiss-odin git:(main) odin run src/examples -extra-linker-flags:"-Wl,-rpath,/usr/local/lib"
```
