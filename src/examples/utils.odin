package example

drand01 :: proc(i: int) -> f32 {
	// Simple deterministic pseudo-random in [0,1)
	seed := u64(1469598103934665603) * u64(i * 1099511627)
	seed = seed * 1099511628211
	val := f32(seed & 0xFFFFFF) / f32(0x1000000)
	return val
}
