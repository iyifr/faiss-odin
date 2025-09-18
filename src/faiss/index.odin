package faiss

import "core:c"

// Type aliases
component_t :: c.float
distant_t :: c.float
idx_t :: c.longlong


Index :: struct {
	d:           c.int,
	ntotal:      idx_t,
	metric_type: MetricType,
	is_trained:  bool,
}
