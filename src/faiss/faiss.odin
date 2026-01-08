package faiss

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:strings"

when ODIN_OS == .Darwin {
	foreign import lib "system:/usr/local/lib/libfaiss_c.dylib"
} else when ODIN_OS == .Linux {
	foreign import lib "system:faiss_c"
} else when ODIN_OS == .Windows {
	foreign import lib "faiss_c.lib"
} else {
	foreign import lib "system:faiss_c"
}

opaque :: rawptr
FaissMetricType :: MetricType
FaissSearchParameters :: ^opaque
FaissRangeSearchResult :: ^opaque
FaissIDSelector :: ^opaque
FaissIDSelectorRange :: ^opaque
FaissIDSelectorOr :: ^opaque
FaissIDSelectorAnd :: ^opaque
FaissIndex :: ^opaque
FaissIndexFlat :: ^opaque
FaissIndexFlatIP :: ^opaque
FaissIndexFlatL2 :: ^opaque
FaissIndexRefineFlat :: ^opaque
FaissIndexFlat1D :: ^opaque


@(default_calling_convention = "c", link_prefix = "faiss_")
foreign lib {
	get_version :: proc() -> cstring ---

	// Error API (error_c.h)
	get_last_error :: proc() -> cstring ---

	// Index factory (index_factory_c.h)
	index_factory :: proc(p_index: ^^FaissIndex, d: c.int, description: cstring, metric: FaissMetricType) -> c.int ---

	// Index I/O (index_io_c.h)
	write_index_fname :: proc(index: ^FaissIndex, fname: cstring) -> c.int ---
	read_index_fname :: proc(fname: cstring, io_flags: rawptr, p_out: ^^FaissIndex) -> c.int ---

	Index_d :: proc(index: ^FaissIndex, p_d: ^c.int) -> c.int ---
	Index_is_trained :: proc(index: ^FaissIndex) -> c.int ---
	Index_ntotal :: proc(index: ^FaissIndex) -> c.int ---
	Index_metric_type :: proc(index: ^FaissIndex) -> c.int ---

	Index_verbose :: proc(index: ^FaissIndex, p_verbose: ^c.int) -> c.int ---
	Index_set_verbose :: proc(index: ^FaissIndex, verbose: c.int) -> c.int ---

	// *Train an index*
	Index_train :: proc(index: ^FaissIndex, n: idx_t, x: [^]c.float) -> c.int ---
	Index_add :: proc(index: ^FaissIndex, n: idx_t, x: [^]c.float) -> c.int ---
	Index_add_with_ids :: proc(index: ^FaissIndex, n: idx_t, x: [^]c.float, xids: [^]idx_t) -> c.int ---
	Index_search :: proc(index: ^FaissIndex, n: idx_t, x: [^]c.float, k: idx_t, distances: [^]c.float, labels: [^]idx_t) -> c.int ---
	Index_search_with_params :: proc(index: ^FaissIndex, n: idx_t, x: [^]c.float, k: idx_t, params: ^FaissSearchParameters, distances: [^]c.float, labels: [^]idx_t) -> c.int ---
	Index_range_search :: proc(index: ^FaissIndex, n: idx_t, x: [^]c.float, radius: c.float, result: ^FaissRangeSearchResult) -> c.int ---
	Index_assign :: proc(index: ^FaissIndex, n: idx_t, x: [^]c.float, labels: [^]idx_t, k: idx_t) -> c.int ---
	Index_reset :: proc(index: ^FaissIndex) -> c.int ---
	Index_remove_ids :: proc(index: ^FaissIndex, sel: ^FaissIDSelector, n_removed: ^c.size_t) -> c.int ---
	Index_reconstruct :: proc(index: ^FaissIndex, key: idx_t, recons: [^]c.float) -> c.int ---
	Index_reconstruct_n :: proc(index: ^FaissIndex, i0: idx_t, ni: idx_t, recons: [^]c.float) -> c.int ---
	Index_compute_residual :: proc(index: ^FaissIndex, x: [^]c.float, residual: [^]c.float, key: idx_t) -> c.int ---
	Index_compute_residual_n :: proc(index: ^FaissIndex, n: idx_t, x: [^]c.float, residuals: [^]c.float, keys: [^]idx_t) -> c.int ---

	Index_free :: proc(index: ^FaissIndex) ---

	// Standalone codec interface
	Index_sa_code_size :: proc(index: ^FaissIndex, size: ^c.size_t) -> c.int ---
	Index_sa_encode :: proc(index: ^FaissIndex, n: idx_t, x: [^]c.float, bytes: [^]c.uchar) -> c.int ---
	Index_sa_decode :: proc(index: ^FaissIndex, n: idx_t, bytes: [^]c.uchar, x: [^]c.float) -> c.int ---

	// IndexFlat creation
	IndexFlat_new :: proc(p_index: ^^FaissIndexFlat) -> c.int ---

	IndexFlat_new_with :: proc(p_index: ^^FaissIndexFlat, d: idx_t, metric: FaissMetricType) -> c.int ---

	IndexFlat_xb :: proc(index: ^FaissIndexFlat, p_xb: ^^c.float, p_size: ^c.size_t) ---

	IndexFlat_cast :: proc(index: ^FaissIndex) -> ^FaissIndexFlat ---

	IndexFlat_free :: proc(index: ^FaissIndexFlat) ---

	IndexFlat_compute_distance_subset :: proc(index: ^FaissIndex, n: idx_t, x: [^]c.float, k: idx_t, distances: [^]c.float, labels: [^]idx_t) -> c.int ---

	// IndexFlatIP (Inner Product)
	IndexFlatIP_new :: proc(p_index: ^^FaissIndexFlatIP) -> c.int ---

	IndexFlatIP_new_with :: proc(p_index: ^^FaissIndexFlatIP, d: idx_t) -> c.int ---

	IndexFlatIP_cast :: proc(index: ^FaissIndex) -> ^FaissIndexFlatIP ---
	IndexFlatIP_free :: proc(index: ^FaissIndexFlatIP) ---

	// IndexFlatL2 (L2 distance)
	IndexFlatL2_new :: proc(p_index: ^^FaissIndexFlatL2) -> c.int ---

	IndexFlatL2_new_with :: proc(p_index: ^^FaissIndexFlatL2, d: idx_t) -> c.int ---

	IndexFlatL2_cast :: proc(index: ^FaissIndex) -> ^FaissIndexFlatL2 ---
	IndexFlatL2_free :: proc(index: ^FaissIndexFlatL2) ---

	// IndexRefineFlat
	IndexRefineFlat_new :: proc(p_index: ^^FaissIndexRefineFlat, base_index: ^FaissIndex) -> c.int ---

	IndexRefineFlat_free :: proc(index: ^FaissIndexRefineFlat) ---
	IndexRefineFlat_cast :: proc(index: ^FaissIndex) -> ^FaissIndexRefineFlat ---

	// IndexRefineFlat getters/setters
	IndexRefineFlat_own_fields :: proc(index: ^FaissIndexRefineFlat) -> c.int ---
	IndexRefineFlat_set_own_fields :: proc(index: ^FaissIndexRefineFlat, val: c.int) ---

	IndexRefineFlat_k_factor :: proc(index: ^FaissIndexRefineFlat) -> c.float ---
	IndexRefineFlat_set_k_factor :: proc(index: ^FaissIndexRefineFlat, val: c.float) ---

	// IndexFlat1D (optimized for 1D vectors)
	IndexFlat1D_new :: proc(p_index: ^^FaissIndexFlat1D) -> c.int ---

	IndexFlat1D_new_with :: proc(p_index: ^^FaissIndexFlat1D, continuous_update: c.int) -> c.int ---

	IndexFlat1D_cast :: proc(index: ^FaissIndex) -> ^FaissIndexFlat1D ---
	IndexFlat1D_free :: proc(index: ^FaissIndexFlat1D) ---

	IndexFlat1D_update_permutation :: proc(index: ^FaissIndexFlat1D) -> c.int ---

	// ID selectors (impl/AuxIndexStructures_c.h)
	IDSelector_free :: proc(sel: ^FaissIDSelector) ---
	IDSelectorRange_new :: proc(p_sel: ^^FaissIDSelectorRange, imin: idx_t, imax: idx_t) -> c.int ---
	IDSelectorRange_free :: proc(sel: ^FaissIDSelectorRange) ---
	IDSelectorOr_new :: proc(p_sel: ^^FaissIDSelectorOr, lhs: ^FaissIDSelector, rhs: ^FaissIDSelector) -> c.int ---
	IDSelectorAnd_new :: proc(p_sel: ^^FaissIDSelectorAnd, lhs: ^FaissIDSelector, rhs: ^FaissIDSelector) -> c.int ---

	SearchParameters_new :: proc(p_sp: ^^FaissSearchParameters, sel: ^FaissIDSelector) -> c.int ---
	SearchParameters_free :: proc(sp: ^FaissSearchParameters) ---
}

is_index_flat :: proc(index: ^FaissIndex) -> bool {
	return IndexFlat_cast(index) != c.NULL
}
