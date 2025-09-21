package main

import faiss "../faiss"
import "core:c"
import "core:fmt"

drand01 :: proc(i: int) -> f32 {
	// Simple deterministic pseudo-random in [0,1)
	seed := u64(1469598103934665603) * u64(i * 1099511627)
	seed = seed * 1099511628211
	val := f32(seed & 0xFFFFFF) / f32(0x1000000)
	return val
}

main :: proc() {
	fmt.println("Generating some data...")

	d := 128
	nb := 100_000
	nq := 10_000

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

	fmt.println("Building an index...")

	desc: cstring = "Flat"
	index: ^faiss.FaissIndex
	if faiss.index_factory(&index, c.int(d), desc, faiss.MetricType.METRIC_L2) != 0 {
		fmt.printf("Factory failed: %s\n", faiss.get_last_error())
		return
	}

	fmt.printf("is_trained = %s\n", faiss.Index_is_trained(index) != 0 ? "true" : "false")

	// add
	if faiss.Index_add(index, faiss.idx_t(nb), raw_data(xb)) != 0 {
		fmt.printf("Index_add failed: %s\n", faiss.get_last_error())
		return
	}

	fmt.printf("ntotal = %lld\n", faiss.Index_ntotal(index))


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
			fmt.printf("Index_search (xq) failed: %s\n", faiss.get_last_error())
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
			fmt.printf("IDSelectorRange_new failed: %s\n", faiss.get_last_error())
			return
		}
		params: ^faiss.FaissSearchParameters
		if faiss.SearchParameters_new(&params, (^faiss.FaissIDSelector)(range_sel)) != 0 {
			fmt.printf("SearchParameters_new failed: %s\n", faiss.get_last_error())
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
			fmt.printf("Index_search_with_params (range) failed: %s\n", faiss.get_last_error())
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
	filename: cstring = "example.index"

	_ = faiss.write_index_fname(index, filename)

	fmt.println("Freeing index...")
	faiss.Index_free(index)

	delete(xb)
	delete(xq)

	fmt.println("Done.")
}
