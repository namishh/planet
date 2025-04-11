package planet

import "core:time"
import rl "vendor:raylib"
import "core:math"

rand_state: u64

init_random :: proc() {
	now := time.now()
	nano := time.duration_nanoseconds(time.diff(time.Time{}, now))
	rand_state = u64(nano) | 1
}

rand_next :: proc() -> u64 {
	x := rand_state
	x ~= x << 13
	x ~= x >> 7
	x ~= x << 17
	rand_state = x
	return x
}

rand_u32 :: proc() -> u32 {
	return u32(rand_next())
}

rand_float32 :: proc() -> f32 {
	return f32(rand_u32()) / 4294967296.0 // 2^32
}

rand_float32_range :: proc(min, max: f32) -> f32 {
	return min + (max - min) * rand_float32()
}

rand_int_max :: proc(max: int) -> int {
	if max <= 0 {
		return 0
	}
	return int(rand_u32() % u32(max))
}

rand_unit_vector :: proc() -> rl.Vector3 {
    for {
        x := rand_float32_range(-1, 1)
        y := rand_float32_range(-1, 1)
        z := rand_float32_range(-1, 1)
        length_sq := x*x + y*y + z*z
        if length_sq > 0 && length_sq <= 1 {
            length := math.sqrt(length_sq)
            return rl.Vector3{x / length, y / length, z / length}
        }
    }
}