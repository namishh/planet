package planet

import "core:fmt"
import math "core:math"
import "core:slice"
import "core:time" 
import rl "vendor:raylib"

rand_state: u64

// Random number generation utilities
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
    return rl.Vector3{
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x,
    }
}

Vertex :: struct {
	position: rl.Vector3,
	normal:   rl.Vector3,
}

Face :: struct {
	vertices:    [dynamic]int, 
	center:      rl.Vector3,
	normal:      rl.Vector3,
	color:       rl.Color,
	is_pentagon: bool,
	region_id:   int,
}

Edge :: struct {
	v1, v2:       int,
	face1, face2: int, 
}

Planet :: struct {
	faces:    [dynamic]Face,
	vertices: [dynamic]Vertex,
	edges:    [dynamic]Edge,
	radius:   f32,
}

generate_icosahedron :: proc(radius: f32) -> Planet {
	planet := Planet {
		radius = radius,
	}

	t := (1.0 + math.sqrt_f32(5.0)) / 2.0

	vertices := [?]rl.Vector3 {
		{-1, t, 0},
		{1, t, 0},
		{-1, -t, 0},
		{1, -t, 0},
		{0, -1, t},
		{0, 1, t},
		{0, -1, -t},
		{0, 1, -t},
		{t, 0, -1},
		{t, 0, 1},
		{-t, 0, -1},
		{-t, 0, 1},
	}

	for v in vertices {
		normalized := normalize(v)
		append(
			&planet.vertices,
			Vertex {
				position = rl.Vector3 {
					normalized.x * radius,
					normalized.y * radius,
					normalized.z * radius,
				},
				normal = normalized,
			},
		)
	}

	faces := [?][3]int {
		{0, 11, 5},
		{0, 5, 1},
		{0, 1, 7},
		{0, 7, 10},
		{0, 10, 11},
		{1, 5, 9},
		{5, 11, 4},
		{11, 10, 2},
		{10, 7, 6},
		{7, 1, 8},
		{3, 9, 4},
		{3, 4, 2},
		{3, 2, 6},
		{3, 6, 8},
		{3, 8, 9},
		{4, 9, 5},
		{2, 4, 11},
		{6, 2, 10},
		{8, 6, 7},
		{9, 8, 1},
	}

	for face, i in faces {
		v1 := planet.vertices[face[0]].position
		v2 := planet.vertices[face[1]].position
		v3 := planet.vertices[face[2]].position

		center := rl.Vector3 {
			(v1.x + v2.x + v3.x) / 3.0,
			(v1.y + v2.y + v3.y) / 3.0,
			(v1.z + v2.z + v3.z) / 3.0,
		}

		edge1 := rl.Vector3{v2.x - v1.x, v2.y - v1.y, v2.z - v1.z}
		edge2 := rl.Vector3{v3.x - v1.x, v3.y - v1.y, v3.z - v1.z}
		normal := normalize(cross(edge1, edge2))

		center = normalize(center)
		center.x *= radius
		center.y *= radius
		center.z *= radius

		new_face := Face {
			center      = center,
			normal      = normal,
			color       = rl.Color {
				u8(rand_int_max(155) + 100),
				u8(rand_int_max(155) + 100),
				u8(rand_int_max(155) + 100),
				255,
			},
			is_pentagon = false,
			region_id   = i % 12,
		}

		append(&new_face.vertices, face[0])
		append(&new_face.vertices, face[1])
		append(&new_face.vertices, face[2])

		append(&planet.faces, new_face)
	}

	edge_map := make(map[[2]int]int) 
	defer delete(edge_map)

	for face_idx := 0; face_idx < len(planet.faces); face_idx += 1 {
		face := &planet.faces[face_idx]

		for i := 0; i < len(face.vertices); i += 1 {
			v1 := face.vertices[i]
			v2 := face.vertices[(i + 1) % len(face.vertices)]

			min_v := min(v1, v2)
			max_v := max(v1, v2)
			edge_key := [2]int{min_v, max_v}

			edge_idx, exists := edge_map[edge_key]
			if exists {
				planet.edges[edge_idx].face2 = face_idx
			} else {
				new_edge := Edge {
					v1    = min_v,
					v2    = max_v,
					face1 = face_idx,
					face2 = -1, 
				}

				edge_map[edge_key] = len(planet.edges)
				append(&planet.edges, new_edge)
			}
		}
	}

	return planet
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
        
        
        rl.EndMode3D()
        
        rl.DrawFPS(10, 10)
        rl.EndDrawing()
    }
    
    
    rl.CloseWindow()
}