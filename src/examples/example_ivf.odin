package example

import faiss "../faiss"
import "core:c"
import "core:fmt"
import strings "core:strings"
import time "core:time"

example_ivf :: proc() {
	stopwatch := time.Stopwatch{}
	time.stopwatch_start(&stopwatch)
	fmt.println("Generating some data...")

	d := 128
	nb := 5000
	nq := 1000

	xb := make([]f32, d * nb)
	xq := make([]f32, d * nq)

	for i in 0 ..< nb {
		for j in 0 ..< d {
			xb[d * i + j] = drand01(i * d + j)
		}
		xb[d * i] += f32(i) / 1000.0
	}
	for i in 0 ..< nq {
		for j in 0 ..< d {
			xq[d * i + j] = drand01(17 + i * d + j)
		}
		xq[d * i] += f32(i) / 1000.0
	}

	{
		fmt.println("First 3 vectors in xb:")
		for i in 0 ..< 3 {
			fmt.printf("xb[%d]: [", i)
			for j in 0 ..< d {
				fmt.printf("%.3f", xb[i * d + j])
				if j < d - 1 {
					fmt.print(", ")
				}
			}
			fmt.println("]")
		}

		fmt.println("First 3 vectors in xq:")
		for i in 0 ..< 3 {
			fmt.printf("xq[%d]: [", i)
			for j in 0 ..< d {
				fmt.printf("%.3f", xq[i * d + j])
				if j < d - 1 {
					fmt.print(", ")
				}
			}
			fmt.println("]")
		}
	}

	time.stopwatch_stop(&stopwatch)
	fmt.println("Generating some data took", stopwatch._accumulation)
	time.stopwatch_reset(&stopwatch)

	fmt.println("Building an index...")

	desc: cstring = "IVF256,Flat"
	index: ^faiss.FaissIndex
	index_name: cstring = "ivx.index"

	read_index_ptr := faiss.read_index_fname(index_name, nil, &index)

	if (read_index_ptr == 0) {
		fmt.printfln("Found index file with name: %s\n", index_name)
	} else {
		fmt.println("No existing index found, creating new index...")
		if faiss.index_factory(&index, c.int(d), desc, faiss.MetricType.METRIC_L2) != 0 {
			err_string_from_faiss := faiss.get_last_error()
			err_string, err := strings.clone_from_cstring(
				err_string_from_faiss^,
				context.temp_allocator,
			)

			if err != nil {
				fmt.println("An error occured")
			}
			fmt.printf("Index_factory failed: %s\n", err_string)
			return
		}

		// Train the index before adding vectors (required for IVF indexes)
		fmt.println("Training the index...")
		time.stopwatch_start(&stopwatch)
		if faiss.Index_train(index, faiss.idx_t(nb), raw_data(xb[:1000])) != 0 {
			err_string, err := strings.clone_from_cstring(faiss.get_last_error()^)
			defer delete(err_string)
			if err != nil {
				fmt.println("An error occurred during training")
			}
			fmt.printf("Index_train failed: %s\n", err_string)
			return
		}
		time.stopwatch_stop(&stopwatch)
		fmt.printf("Training the index took: %f s\n", stopwatch._accumulation)
		time.stopwatch_reset(&stopwatch)

		fmt.println("Adding vectors to index")

		// add
		if faiss.Index_add(index, faiss.idx_t(nb), raw_data(xb[0:300])) != 0 {
			fmt.printf("Index_add failed: %s\n", cstring(faiss.get_last_error()^))
			return
		}
	}

	fmt.printf("Is Index Flat = %s\n", faiss.is_index_flat(index) == true ? "true" : "false")

	fmt.printf("is Index trained = %s\n", faiss.Index_is_trained(index) != 0 ? "true" : "false")

	// If index has not already been trained (for loaded indexes that weren't trained).
	if faiss.Index_is_trained(index) == 0 {
		fmt.println("Training the loaded index...")
		time.stopwatch_start(&stopwatch)
		if faiss.Index_train(index, faiss.idx_t(nb), raw_data(xb)) != 0 {
			err_string, err := strings.clone_from_cstring(faiss.get_last_error()^)
			defer delete(err_string)
			if err != nil {
				fmt.println("An error occurred during training")
			}
			fmt.printf("Index_train failed: %s\n", err_string)
			return
		}
		fmt.printf("is_trained = %s\n", faiss.Index_is_trained(index) != 0 ? "true" : "false")

		time.stopwatch_stop(&stopwatch)
		fmt.println(
			"Training the index took:",
			time.duration_seconds(stopwatch._accumulation),
			's',
		)
		time.stopwatch_reset(&stopwatch)
	}


	fmt.printf("ntotal = %d\n", faiss.Index_ntotal(index))

	fmt.println("Searching...")
	k := 5

	// sanity check: search 5 first vectors of xb
	{
		I := make([]faiss.idx_t, k * 5)
		D := make([]f32, k * 5)
		if faiss.Index_search(
			   index,
			   faiss.idx_t(5),
			   raw_data(xb),
			   faiss.idx_t(k),
			   raw_data(D),
			   raw_data(I),
		   ) !=
		   0 {
			fmt.printf("Index_search (sanity) failed: %s\n", faiss.get_last_error())
			return
		}
		fmt.println("I=")
		for i in 0 ..< 5 {
			for j in 0 ..< k {
				fmt.printf("%d (d=%2.3f)  ", I[i * k + j], D[i * k + j])
			}
			fmt.println(">")
		}
		delete(I)
		delete(D)
	}

	// search xq
	{
		time.stopwatch_start(&stopwatch)
		fmt.println("\n-----\nSearching on XQ \n---- \n")
		I := make([]faiss.idx_t, k * nq)
		D := make([]f32, k * nq)
		if faiss.Index_search(
			   index,
			   faiss.idx_t(nq),
			   raw_data(xq),
			   faiss.idx_t(k),
			   raw_data(D),
			   raw_data(I),
		   ) !=
		   0 {
			fmt.printf("Index_search (xq) failed: %s\n", faiss.get_last_error())
			return
		}
		fmt.println("I=")
		for i in 0 ..< 5 {
			for j in 0 ..< k {
				fmt.printf("%d (d=%2.3f)  ", I[i * (k + j)], D[i * (k + j)])
			}
			fmt.println("")
		}

		time.stopwatch_stop(&stopwatch)
		fmt.println("Searching XQ took:", stopwatch._accumulation)
		time.stopwatch_reset(&stopwatch)
		delete(I)
		delete(D)
	}

	fmt.println("Saving index to disk...")

	_ = faiss.write_index_fname(index, index_name)

	fmt.println("Freeing index...")
	faiss.Index_free(index)

	delete(xb)
	delete(xq)

	fmt.println("Done.")
}
