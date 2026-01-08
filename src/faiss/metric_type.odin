package faiss

MetricType :: enum {
	METRIC_INNER_PRODUCT = 105, ///< maximum inner product search
	METRIC_L2 = 1, ///< squared L2 search
	METRIC_L1, ///< L1 (aka cityblock)
	METRIC_Linf, ///< infinity distance
	METRIC_Lp, ///< L_p distance, p is given by a faiss::Index
	/// metric_arg
	METRIC_Canberra = 20,
	METRIC_BrayCurtis,
	METRIC_JensenShannon,

	/// sum_i(min(a_i, b_i)) / sum_i(max(a_i, b_i)) where a_i, b_i > 0
	METRIC_Jaccard,
	/// Squared Eucliden distance, ignoring NaNs
	METRIC_NaNEuclidean,
	/// Gower's distance - numeric dimensions are in [0,1] and categorical
	/// dimensions are negative integers
	METRIC_GOWER,
}

is_similarity_metric :: #force_inline proc(metric_type: MetricType) -> bool {
	return(
		metric_type == MetricType.METRIC_INNER_PRODUCT ||
		metric_type == MetricType.METRIC_Jaccard \
	)
}
