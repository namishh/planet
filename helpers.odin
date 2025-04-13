package planet

import rl "vendor:raylib"
import math "core:math"

distance :: proc(a, b: rl.Vector3) -> f32 {
	dx := a.x - b.x
	dy := a.y - b.y
	dz := a.z - b.z
	return math.sqrt(dx * dx + dy * dy + dz * dz)
}

normalize :: proc(v: rl.Vector3) -> rl.Vector3 {
	length := math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
	if length == 0 {
		return v
	}
	return rl.Vector3{v.x / length, v.y / length, v.z / length}
}

cross :: proc(a, b: rl.Vector3) -> rl.Vector3 {
	return rl.Vector3{a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x}
}