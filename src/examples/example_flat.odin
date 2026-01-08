package example

import faiss "../faiss"
import "core:c"
import "core:fmt"
import strings "core:strings"
import time "core:time"

example_flat :: proc() {
	stopwatch := time.Stopwatch{}
	time.stopwatch_start(&stopwatch)
	fmt.println("Generating some data...")

	d := 128
	nb := 5000
	nq := 100

	xb := make([]f32, d * nb)
	xq := make([]f32, d * nq)

	defer {
		delete(xb)
		delete(xq)
	}

	gen_embeddings(&xb, d, nb)
	gen_embeddings(&xq, d, nq)

	time.stopwatch_stop(&stopwatch)
	time.stopwatch_reset(&stopwatch)
	fmt.println("Generating some data took", stopwatch._accumulation)

	// Build index
	fmt.println("Building an index...")
	desc: cstring = "Flat"
	index: ^faiss.FaissIndex
	if faiss.index_factory(&index, c.int(d), desc, faiss.MetricType.METRIC_INNER_PRODUCT) != 0 {
		err_string_from_faiss := faiss.get_error()
		fmt.printf("An error occured: %s\n", err_string_from_faiss)
		return
	}

	fmt.printf("is Index Flat LP = %s\n", faiss.is_index_flat(index) == true ? "true" : "false")

	fmt.printf("is_trained = %s\n", faiss.Index_is_trained(index) != 0 ? "true" : "false")

	faiss.Index_train(index, faiss.idx_t(nb), raw_data(xb[0:1000]))

	// add
	if faiss.Index_add(index, faiss.idx_t(nb), raw_data(xb)) != 0 {
		fmt.printf("Index_add failed: %s\n", string(faiss.get_last_error()))
		return
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
			fmt.printf("Index_search (xq) failed: %s\n", faiss.get_error())
			return
		}
		fmt.println("I=")
		for i in 0 ..< 5 {
			for j in 0 ..< k {
				fmt.printf("%d (d=%2.3f)  ", I[i * k + j], D[i * k + j])
			}
			fmt.println("")
		}
		delete(I)
		delete(D)
	}

	{ 	// search with IDSelectorRange [50,100]
		I := make([]faiss.idx_t, k * nq)
		D := make([]f32, k * nq)
		range_sel: ^faiss.FaissIDSelectorRange
		if faiss.IDSelectorRange_new(&range_sel, faiss.idx_t(50), faiss.idx_t(100)) != 0 {

			fmt.printf("IDSelectorRange_new failed: %s\n", faiss.get_error())
			return
		}
		params: ^faiss.FaissSearchParameters
		if faiss.SearchParameters_new(&params, (^faiss.FaissIDSelector)(range_sel)) != 0 {
			fmt.printf("SearchParameters_new failed: %s\n", faiss.get_error())
			faiss.IDSelectorRange_free(range_sel)
			return
		}
		if faiss.Index_search_with_params(
			   index,
			   faiss.idx_t(nq),
			   raw_data(xq),
			   faiss.idx_t(k),
			   params,
			   raw_data(D),
			   raw_data(I),
		   ) !=
		   0 {
			fmt.printf("Index_search_with_params (range) failed: %s\n", faiss.get_error())
			faiss.SearchParameters_free(params)
			faiss.IDSelectorRange_free(range_sel)
			return
		}
		fmt.println("Searching w/ IDSelectorRange [50,100]")
		fmt.println("I=")
		for i in 0 ..< 5 {
			for j in 0 ..< k {
				fmt.printf("%d (d=%2.3f)  ", I[i * k + j], D[i * k + j])
			}
			fmt.println("")
		}
		delete(I)
		delete(D)
		faiss.SearchParameters_free(params)
		faiss.IDSelectorRange_free(range_sel)
	}

	// search with ( [20,40] OR [45,60] )
	{
		I := make([]faiss.idx_t, k * nq)
		D := make([]f32, k * nq)
		lhs_sel: ^faiss.FaissIDSelectorRange
		rhs_sel: ^faiss.FaissIDSelectorRange
		if faiss.IDSelectorRange_new(&lhs_sel, faiss.idx_t(20), faiss.idx_t(40)) != 0 {
			delete(I)
			delete(D)
			return
		}
		if faiss.IDSelectorRange_new(&rhs_sel, faiss.idx_t(45), faiss.idx_t(60)) != 0 {
			faiss.IDSelectorRange_free(lhs_sel)
			delete(I)
			delete(D)
			return
		}
		sel_or: ^faiss.FaissIDSelectorOr
		if faiss.IDSelectorOr_new(
			   &sel_or,
			   (^faiss.FaissIDSelector)(lhs_sel),
			   (^faiss.FaissIDSelector)(rhs_sel),
		   ) !=
		   0 {
			faiss.IDSelectorRange_free(lhs_sel)
			faiss.IDSelectorRange_free(rhs_sel)
			delete(I)
			delete(D)
			return
		}
		params: ^faiss.FaissSearchParameters
		if faiss.SearchParameters_new(&params, (^faiss.FaissIDSelector)(sel_or)) != 0 {
			faiss.IDSelectorRange_free(lhs_sel)
			faiss.IDSelectorRange_free(rhs_sel)
			faiss.IDSelector_free((^faiss.FaissIDSelector)(sel_or))
			delete(I)
			delete(D)
			return
		}
		_ = faiss.Index_search_with_params(
			index,
			faiss.idx_t(nq),
			raw_data(xq),
			faiss.idx_t(k),
			params,
			raw_data(D),
			raw_data(I),
		)
		fmt.println("Searching w/ IDSelectorRange [20,40] OR [45,60]")
		fmt.println("I=")
		for i in 0 ..< 5 {
			for j in 0 ..< k {
				fmt.printf("%d (d=%2.3f)  ", I[i * k + j], D[i * k + j])
			}
			fmt.println("")
		}

		faiss.SearchParameters_free(params)
		faiss.IDSelectorRange_free(lhs_sel)
		faiss.IDSelectorRange_free(rhs_sel)
		faiss.IDSelector_free((^faiss.FaissIDSelector)(sel_or))
	}


	{ 	// search with ( [20,40] AND [15,35] )
		I := make([]faiss.idx_t, k * nq)
		D := make([]f32, k * nq)

		lhs_sel: ^faiss.FaissIDSelectorRange
		rhs_sel: ^faiss.FaissIDSelectorRange

		if faiss.IDSelectorRange_new(&lhs_sel, faiss.idx_t(20), faiss.idx_t(40)) != 0 {
			delete(I)
			delete(D)
			return
		}
		if faiss.IDSelectorRange_new(&rhs_sel, faiss.idx_t(15), faiss.idx_t(35)) != 0 {
			faiss.IDSelectorRange_free(lhs_sel)
			delete(I)
			delete(D)
			return
		}
		sel_and: ^faiss.FaissIDSelectorAnd
		if faiss.IDSelectorAnd_new(
			   &sel_and,
			   (^faiss.FaissIDSelector)(lhs_sel),
			   (^faiss.FaissIDSelector)(rhs_sel),
		   ) !=
		   0 {
			faiss.IDSelectorRange_free(lhs_sel)
			faiss.IDSelectorRange_free(rhs_sel)
			delete(I)
			delete(D)
			return
		}
		params: ^faiss.FaissSearchParameters
		if faiss.SearchParameters_new(&params, (^faiss.FaissIDSelector)(sel_and)) != 0 {
			faiss.IDSelectorRange_free(lhs_sel)
			faiss.IDSelectorRange_free(rhs_sel)
			faiss.IDSelector_free((^faiss.FaissIDSelector)(sel_and))
			delete(I)
			delete(D)
			return
		}
		_ = faiss.Index_search_with_params(
			index,
			faiss.idx_t(nq),
			raw_data(xq),
			faiss.idx_t(k),
			params,
			raw_data(D),
			raw_data(I),
		)
		fmt.println("Searching w/ IDSelectorRange [20,40] AND [15,35]")
		fmt.println("I=")
		for i in 0 ..< 5 {
			for j in 0 ..< k {
				fmt.printf("%d (d=%2.3f)  ", I[i * k + j], D[i * k + j])
			}
			fmt.println("")
		}

		// Clean up resources
		faiss.SearchParameters_free(params)
		faiss.IDSelectorRange_free(lhs_sel)
		faiss.IDSelectorRange_free(rhs_sel)
		faiss.IDSelector_free((^faiss.FaissIDSelector)(sel_and))
		delete(I)
		delete(D)
	}

	fmt.println("Saving index to disk...")
	filename: cstring = "flat.index"

	_ = faiss.write_index_fname(index, filename)

	fmt.println("Freeing index...")
	faiss.Index_free(index)
	fmt.println("Done.")
}
