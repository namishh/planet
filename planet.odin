package planet

import "core:fmt"
import math "core:math"
import "core:slice"
import "core:time" 
import rl "vendor:raylib"

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

Point :: struct {
	position:     rl.Vector3,
	color:        rl.Color,
	index:        int,
	tectonic_plate_id: int,
	is_center:    bool,
}

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

is_valid_point :: proc(p: rl.Vector3) -> bool {
	return(
		!math.is_nan(p.x) &&
		!math.is_nan(p.y) &&
		!math.is_nan(p.z) &&
		!math.is_inf(p.x) &&
		!math.is_inf(p.y) &&
		!math.is_inf(p.z) \
	)
}

generate_random_sphere_point :: proc(radius: f32) -> rl.Vector3 {
	theta := rand_float32() * 2 * rl.PI
	phi := math.acos(2 * rand_float32() - 1)

	return rl.Vector3 {
		radius * math.sin(phi) * math.cos(theta),
		radius * math.sin(phi) * math.sin(theta),
		radius * math.cos(phi),
	}
}

generate_sphere_points :: proc(radius: f32, min_gap: f32) -> [dynamic]Point {
	points := make([dynamic]Point)
	approximate_points := int(4 * rl.PI * radius * radius / (min_gap * min_gap))

	phi := (1.0 + math.sqrt_f16(5.0)) / 2.0 

	reserve(&points, approximate_points)

	i := 0
	attempts := 0
	max_attempts := approximate_points * 10

	for attempts < max_attempts {
		y := 1.0 - (2.0 * f32(i) + 1.0) / f32(approximate_points)
		r := math.sqrt(1.0 - y * y)

		phi_angle := 2.0 * rl.PI * f32(i) / f32(phi)

		x := r * math.cos(phi_angle)
		z := r * math.sin(phi_angle)

		position := rl.Vector3{x * radius, y * radius, z * radius}

		if !is_valid_point(position) {
			position = generate_random_sphere_point(radius)
			if !is_valid_point(position) {
				i += 1
				attempts += 1
				continue 
			}
		}

		new_point := Point {
			position     = position,
			color        = rl.Color {
				u8(rand_int_max(200) + 55),
				u8(rand_int_max(200) + 55),
				u8(rand_int_max(200) + 55),
				255,
			},
			index        = i,
			tectonic_plate_id = -1,
			is_center    = false,
		}

		too_close := false
		for j in 0 ..< len(points) {
			if distance(new_point.position, points[j].position) < min_gap {
				too_close = true
				break
			}
		}

		if !too_close {
			append(&points, new_point)
		}

		i += 1
		attempts += 1

		if len(points) >= approximate_points {
			break
		}
	}

	fmt.println("Generated", len(points), "points after", attempts, "attempts")
	return points
}

assign_tectonic_plate_centers :: proc(points: ^[dynamic]Point, num_centers: int) {
	if len(points) < num_centers {
		fmt.println("Warning: Not enough points for the requested number of tectonic_plates")
		return
	}

	used_indices := make(map[int]bool)
	defer delete(used_indices)

	center_count := 0

	region_size := len(points) / num_centers

	for i in 0 ..< num_centers {
		region_start := i * region_size
		region_end := min(region_start + region_size, len(points))

		if region_start >= region_end {
			continue 
		}

		attempts := 0
		max_attempts := 10

		for attempts < max_attempts {
			idx := region_start + rand_int_max(region_end - region_start)

			if !used_indices[idx] && is_valid_point(points[idx].position) {
				points[idx].is_center = true
				points[idx].tectonic_plate_id = i

				bright_color := rl.Color {
					u8(rand_int_max(155) + 100), 
					u8(rand_int_max(155) + 100),
					u8(rand_int_max(155) + 100),
					255,
				}
				points[idx].color = bright_color

				used_indices[idx] = true
				center_count += 1
				break
			}

			attempts += 1
		}
	}

	if center_count < num_centers {
		attempts := 0
		max_attempts := len(points) * 2

		for center_count < num_centers && attempts < max_attempts {
			idx := rand_int_max(len(points))

			if !used_indices[idx] && is_valid_point(points[idx].position) {
				points[idx].is_center = true
				points[idx].tectonic_plate_id = center_count

				bright_color := rl.Color {
					u8(rand_int_max(155) + 100),
					u8(rand_int_max(155) + 100),
					u8(rand_int_max(155) + 100),
					255,
				}
				points[idx].color = bright_color

				used_indices[idx] = true
				center_count += 1
			}

			attempts += 1
		}
	}

	fmt.println("Created", center_count, "tectonic_plate centers")
}

get_center_indices :: proc(points: [dynamic]Point) -> []int {
	center_count := 0
	for point in points {
		if point.is_center {
			center_count += 1
		}
	}

	center_indices := make([]int, center_count)
	idx := 0

	for i in 0 ..< len(points) {
		if points[i].is_center {
			center_indices[idx] = i
			idx += 1
		}
	}

	return center_indices
}

assign_tectonic_plates :: proc(points: ^[dynamic]Point) {
	center_indices := get_center_indices(points^)
	defer delete(center_indices)

	for i in 0 ..< len(points) {
		if points[i].is_center {
			continue
		}

		min_dist := f32(1000000.0)
		closest_center_idx := -1

		for center_idx in center_indices {
			dist := distance(points[i].position, points[center_idx].position)
			if dist < min_dist {
				min_dist = dist
				closest_center_idx = center_idx
			}
		}

		if closest_center_idx >= 0 {
			points[i].tectonic_plate_id = points[closest_center_idx].tectonic_plate_id
			points[i].color = points[closest_center_idx].color
		}
	}
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .MSAA_4X_HINT})
	rl.InitWindow(1600, 900, "plonot")
	rl.SetTargetFPS(144)

	init_random()

	camera := rl.Camera3D {
		position   = rl.Vector3{10.0, 10.0, 10.0},
		target     = rl.Vector3{0.0, 0.0, 0.0},
		up         = rl.Vector3{0.0, 1.0, 0.0},
		fovy       = 45.0,
		projection = .PERSPECTIVE,
	}

	PLANET_RADIUS :: 3.0
	MIN_GAP :: 0.3
	points := generate_sphere_points(f32(PLANET_RADIUS), MIN_GAP)

	NUM_PLATES :: 8

	assign_tectonic_plate_centers(&points, NUM_PLATES)
	assign_tectonic_plates(&points)

	center_count := 0
	for i in 0 ..< len(points) {
		if points[i].is_center {
			fmt.println("tectonic_plate", points[i].tectonic_plate_id, "center:", points[i].position)
			center_count += 1
		}
	}
	fmt.println("Total tectonic_plate centers:", center_count)

	for !rl.WindowShouldClose() {
		rl.UpdateCamera(&camera, .ORBITAL)

		rotation_speed := 0.0002
		x := f64(camera.position.x)
		z := f64(camera.position.z)

		camera.position.x = f32(x * math.cos(rotation_speed) - z * math.sin(rotation_speed))
		camera.position.z = f32(x * math.sin(rotation_speed) + z * math.cos(rotation_speed))


		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.BeginMode3D(camera)

		for point in points {
			rl.DrawSphere(point.position, 0.05, point.color)
		}

		rl.EndMode3D()

		rl.DrawFPS(10, 10)
		rl.DrawText(fmt.ctprintf("Points: %d", len(points)), 10, 40, 20, rl.WHITE)
		rl.DrawText(fmt.ctprintf("tectonic_plates: %d", center_count), 10, 70, 20, rl.WHITE)

		rl.EndDrawing()
	}

	delete(points)
	rl.CloseWindow()
}
