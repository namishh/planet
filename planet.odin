package planet

import "core:fmt"
import math "core:math"
import "core:slice"
import rl "vendor:raylib"


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

get_midpoint :: proc(p1, p2: rl.Vector3, radius: f32) -> rl.Vector3 {
	midpoint := rl.Vector3{(p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5, (p1.z + p2.z) * 0.5}

	normalized := normalize(midpoint)
	return rl.Vector3{normalized.x * radius, normalized.y * radius, normalized.z * radius}
}

generate_edges :: proc(planet: ^Planet) {
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
				// Create new edge
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
}

get_or_create_midpoint :: proc(
	vertices: ^[dynamic]Vertex,
	midpoints: ^map[[2]int]int,
	v1, v2: int,
	radius: f32,
) -> int {
	min_v := min(v1, v2)
	max_v := max(v1, v2)
	key := [2]int{min_v, max_v}

	if idx, exists := midpoints^[key]; exists {
		return idx
	} else {
		p1 := vertices[v1].position
		p2 := vertices[v2].position
		midpoint := get_midpoint(p1, p2, radius)

		new_idx := len(vertices^)
		append(vertices, Vertex{position = midpoint, normal = normalize(midpoint)})

		midpoints^[key] = new_idx
		return new_idx
	}
}

create_face :: proc(
	vertices: ^[dynamic]Vertex,
	faces: ^[dynamic]Face,
	a, b, c: int,
	color: rl.Color,
	region_id: int,
) {
	v1 := vertices[a].position
	v2 := vertices[b].position
	v3 := vertices[c].position

	center := rl.Vector3 {
		(v1.x + v2.x + v3.x) / 3.0,
		(v1.y + v2.y + v3.y) / 3.0,
		(v1.z + v2.z + v3.z) / 3.0,
	}

	edge1 := rl.Vector3{v2.x - v1.x, v2.y - v1.y, v2.z - v1.z}
	edge2 := rl.Vector3{v3.x - v1.x, v3.y - v1.y, v3.z - v1.z}
	normal := normalize(cross(edge1, edge2))

	center_normalized := normalize(center)
	center.x = center_normalized.x * len(vertices[0].position)
	center.y = center_normalized.y * len(vertices[0].position)
	center.z = center_normalized.z * len(vertices[0].position)

	new_face := Face {
		center      = center,
		normal      = normal,
		color       = color,
		is_pentagon = false,
		region_id   = region_id,
	}

	append(&new_face.vertices, a)
	append(&new_face.vertices, b)
	append(&new_face.vertices, c)

	append(faces, new_face)
}

subdivide :: proc(planet: ^Planet) -> Planet {
	result := Planet {
		radius = planet.radius,
	}

	for v in planet.vertices {
		append(&result.vertices, v)
	}

	edge_midpoints := make(map[[2]int]int)
	defer delete(edge_midpoints)

	for face in planet.faces {
		v1 := face.vertices[0]
		v2 := face.vertices[1]
		v3 := face.vertices[2]

		m12 := get_or_create_midpoint(&result.vertices, &edge_midpoints, v1, v2, planet.radius)
		m23 := get_or_create_midpoint(&result.vertices, &edge_midpoints, v2, v3, planet.radius)
		m31 := get_or_create_midpoint(&result.vertices, &edge_midpoints, v3, v1, planet.radius)

		create_face(&result.vertices, &result.faces, v1, m12, m31, face.color, face.region_id)
		create_face(&result.vertices, &result.faces, m12, v2, m23, face.color, face.region_id)
		create_face(&result.vertices, &result.faces, m31, m23, v3, face.color, face.region_id)
		create_face(&result.vertices, &result.faces, m12, m23, m31, face.color, face.region_id)
	}

	generate_edges(&result)

	return result
}

create_dual :: proc(planet: ^Planet) -> Planet {
	dual := Planet {
		radius = planet.radius,
	}

	for face in planet.faces {
		append(&dual.vertices, Vertex{position = face.center, normal = face.normal})
	}

	vertex_to_faces := make(map[int][dynamic]int)
	defer {
		for _, faces in vertex_to_faces {
			delete(faces)
		}
		delete(vertex_to_faces)
	}

	for face_idx := 0; face_idx < len(planet.faces); face_idx += 1 {
		face := planet.faces[face_idx]
		for vertex_idx in face.vertices {
			if _, exists := vertex_to_faces[vertex_idx]; !exists {
				vertex_to_faces[vertex_idx] = make([dynamic]int)
			}
			append(&vertex_to_faces[vertex_idx], face_idx)
		}
	}

	for vertex_idx, face_indices in vertex_to_faces {
		new_face := Face {
			center      = planet.vertices[vertex_idx].position,
			normal      = planet.vertices[vertex_idx].normal,
			color       = rl.Color {
				u8(rand_int_max(155) + 100),
				u8(rand_int_max(155) + 100),
				u8(rand_int_max(155) + 100),
				255,
			},
			is_pentagon = len(face_indices) == 5,
			region_id   = vertex_idx % 12,
		}

		center := planet.vertices[vertex_idx].position
		normal := planet.vertices[vertex_idx].normal

		ref_vec := rl.Vector3{1, 0, 0}
		if math.abs(normal.x) > 0.9 {
			ref_vec = rl.Vector3{0, 1, 0}
		}

		tangent1 := normalize(cross(normal, ref_vec))
		tangent2 := normalize(cross(normal, tangent1))

		projected_points := make([]struct {
				face_idx: int,
				angle:    f32,
			}, len(face_indices))
		defer delete(projected_points)

		for i := 0; i < len(face_indices); i += 1 {
			face_idx := face_indices[i]
			face_center := planet.faces[face_idx].center

			dir := rl.Vector3 {
				face_center.x - center.x,
				face_center.y - center.y,
				face_center.z - center.z,
			}

			x := tangent1.x * dir.x + tangent1.y * dir.y + tangent1.z * dir.z
			y := tangent2.x * dir.x + tangent2.y * dir.y + tangent2.z * dir.z

			angle := math.atan2(y, x)
			if angle < 0 {
				angle += 2 * rl.PI
			}

			projected_points[i] = {face_idx, angle}
		}

		slice.sort_by(projected_points, proc(a, b: struct {
				face_idx: int,
				angle:    f32,
			}) -> bool {
			return a.angle < b.angle
		})

		for point in projected_points {
			append(&new_face.vertices, point.face_idx)
		}

		append(&dual.faces, new_face)
	}

	generate_edges(&dual)

	return dual
}

count_pentagons :: proc(planet: ^Planet) -> int {
	count := 0
	for face in planet.faces {
		if face.is_pentagon {
			count += 1
		}
	}
	return count
}

main :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .MSAA_4X_HINT})
	rl.InitWindow(1600, 900, "plonot")
	rl.SetTargetFPS(60)

	init_random()

	camera := rl.Camera3D {
		position   = rl.Vector3{10.0, 10.0, 10.0},
		target     = rl.Vector3{0.0, 0.0, 0.0},
		up         = rl.Vector3{0.0, 1.0, 0.0},
		fovy       = 45.0,
		projection = .PERSPECTIVE,
	}

	PLANET_RADIUS :: 3.0

	icosahedron := generate_icosahedron(PLANET_RADIUS)

	subdivided := subdivide(&icosahedron)
	subdivided = subdivide(&subdivided)
	subdivided = subdivide(&subdivided)
	subdivided = subdivide(&subdivided)
	subdivided = subdivide(&subdivided)

	goldberg := create_dual(&subdivided)

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

		for face in goldberg.faces {
			edge_color := rl.WHITE

			for i := 0; i < len(face.vertices); i += 1 {
				v1_idx := face.vertices[i]
				v2_idx := face.vertices[(i + 1) % len(face.vertices)]

				v1 := goldberg.vertices[v1_idx].position
				v2 := goldberg.vertices[v2_idx].position

				rl.DrawLine3D(v1, v2, edge_color)
			}
		}

		rl.EndMode3D()

		rl.DrawFPS(10, 10)
		rl.DrawText(fmt.ctprintf("Vertices: %d", len(goldberg.vertices)), 10, 40, 20, rl.WHITE)
		rl.DrawText(fmt.ctprintf("Edges: %d", len(goldberg.edges)), 10, 70, 20, rl.WHITE)
		rl.DrawText(fmt.ctprintf("Faces: %d", len(goldberg.faces)), 10, 100, 20, rl.WHITE)
		rl.DrawText(
			fmt.ctprintf("Pentagons: %d", count_pentagons(&goldberg)),
			10,
			130,
			20,
			rl.WHITE,
		)
		rl.DrawText(
			fmt.ctprintf("Hexagons: %d", len(goldberg.faces) - count_pentagons(&goldberg)),
			10,
			160,
			20,
			rl.WHITE,
		)

		rl.EndDrawing()
	}

	cleanup(&goldberg)
	cleanup(&subdivided)
	cleanup(&icosahedron)

	rl.CloseWindow()
}

cleanup :: proc(planet: ^Planet) {
	for face in &planet.faces {
		delete(face.vertices)
	}
	delete(planet.faces)
	delete(planet.vertices)
	delete(planet.edges)
}
