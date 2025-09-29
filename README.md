## Faiss-Odin

Odin bindings for FAISS (Facebook AI similarity search) an open-source library for efficient similarity search and clustering of dense vectors.

A handful of method are currently present in the bindings, and the code example _(example_c)_ present in the `faiss` source has been ported to odin for demonstration purposes.

The file is present at path: src/examples/example_flat.odin

To run the file, you must have faiss built from source and installed with the C API enabled (and GPU mode enabled (if you want to use a GPU)

In my case i built faiss from source on a 2019 Macbook Pro, compiling and installing the `libfaiss.dylib` and `libfaiss_c.dylib` files into the `/usr/local/lib` folder.

- On windows - A `faiss_c.lib` file
- On Linux - A `libfaiss_c.so` file or `libfaiss_c.a`

### Running the example

You have to pass the rpath to the faiss library to the linker, for example:

```zsh
➜  faiss-odin git:(main) odin run src/examples -extra-linker-flags:"-Wl,-rpath,/path/to/faiss/library"
```

### TODO

- [ ] Complete bindings for remaining FAISS C API functions
  - [ ] Inverted File Index
  - [ ] Flat inverted File Index
  - [ ] Scalar Quantizers
