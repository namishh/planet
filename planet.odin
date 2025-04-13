package planet

import "core:fmt"
import math "core:math"
import "core:slice"
import rl "vendor:raylib"

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
	velocity:    rl.Vector3,
}

Edge :: struct {
	v1, v2:       int,
	face1, face2: int,
}

ClimateData :: struct {
	temperature: f32,
	precipitation: f32,
	polar_factor: f32,
}

Planet :: struct {
	faces:    [dynamic]Face,
	vertices: [dynamic]Vertex,
	edges:    [dynamic]Edge,
	climate:  [dynamic]ClimateData,
	radius:   f32,
}

PlateType :: enum {
	OCEANIC,
	CONTINENTAL,
}

TectonicPlate :: struct {
	faces:            [dynamic]int,
	edges:            [dynamic]int,
	vertices:         [dynamic]int,
	plate_type:       PlateType,
	rotation_axis:    rl.Vector3,
	angular_velocity: f32,
}

HeightMap :: struct {
	values:     []f32,
	min_height: f32,
	max_height: f32,
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

		ref_vec := rl.Vector3{1, 0, 0}
		if math.abs(normalized.x) > 0.9 {
			ref_vec = rl.Vector3{0, 1, 0}
		}

		tangent1 := normalize(cross(normalized, ref_vec))
		tangent2 := normalize(cross(normalized, tangent1))

		disp1 := (rand_float32() - 0.5) * VERTICE_DISPLACEMENT
		disp2 := (rand_float32() - 0.5) * VERTICE_DISPLACEMENT

		displaced := rl.Vector3 {
			normalized.x + tangent1.x * disp1 + tangent2.x * disp2,
			normalized.y + tangent1.y * disp1 + tangent2.y * disp2,
			normalized.z + tangent1.z * disp1 + tangent2.z * disp2,
		}

		displaced = normalize(displaced)

		append(
			&planet.vertices,
			Vertex {
				position = rl.Vector3 {
					displaced.x * radius,
					displaced.y * radius,
					displaced.z * radius,
				},
				normal = displaced,
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
    
    ref_vec := rl.Vector3{1, 0, 0}
    if math.abs(normalized.x) > 0.9 {
        ref_vec = rl.Vector3{0, 1, 0}
    }
    
    tangent1 := normalize(cross(normalized, ref_vec))
    tangent2 := normalize(cross(normalized, tangent1))
    
    disp1 := (rand_float32() - 0.5) * VERTICE_DISPLACEMENT 
    disp2 := (rand_float32() - 0.5) * VERTICE_DISPLACEMENT
    
    displaced := rl.Vector3{
        normalized.x + tangent1.x * disp1 + tangent2.x * disp2,
        normalized.y + tangent1.y * disp1 + tangent2.y * disp2,
        normalized.z + tangent1.z * disp1 + tangent2.z * disp2,
    }
    
    displaced = normalize(displaced)
    
    return rl.Vector3{displaced.x * radius, displaced.y * radius, displaced.z * radius}
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
	radius: f32,
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
	center.x = center_normalized.x * radius
	center.y = center_normalized.y * radius
	center.z = center_normalized.z * radius

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

		create_face(
			&result.vertices,
			&result.faces,
			v1,
			m12,
			m31,
			face.color,
			face.region_id,
			planet.radius,
		)
		create_face(
			&result.vertices,
			&result.faces,
			m12,
			v2,
			m23,
			face.color,
			face.region_id,
			planet.radius,
		)
		create_face(
			&result.vertices,
			&result.faces,
			m31,
			m23,
			v3,
			face.color,
			face.region_id,
			planet.radius,
		)
		create_face(
			&result.vertices,
			&result.faces,
			m12,
			m23,
			m31,
			face.color,
			face.region_id,
			planet.radius,
		)
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

select_random_plate_centers :: proc(planet: ^Planet, num_plates: int) -> []int {
	plate_count := num_plates
	if plate_count > len(planet.faces) {
		plate_count = len(planet.faces)
	}

	indices := make([]int, len(planet.faces))
	for i := 0; i < len(planet.faces); i += 1 {
		indices[i] = i
	}

	for i := len(indices) - 1; i > 0; i -= 1 {
		j := rand_int_max(i + 1)
		indices[i], indices[j] = indices[j], indices[i]
	}

	plate_centers := make([]int, plate_count)
	for i := 0; i < plate_count; i += 1 {
		plate_centers[i] = indices[i]
	}

	delete(indices)
	return plate_centers
}


GrowthFrontier :: struct {
	faces:  [dynamic]int,
	scores: [dynamic]f32,
}

generate_growth_based_plates :: proc(planet: ^Planet, num_plates: int) -> []TectonicPlate {
	plate_centers := select_random_plate_centers(planet, num_plates)
	defer delete(plate_centers)

	plates := make([]TectonicPlate, num_plates)
	for i in 0 ..< num_plates {
		plates[i].faces = make([dynamic]int)
		plates[i].edges = make([dynamic]int)
		plates[i].vertices = make([dynamic]int)
		plates[i].plate_type =
			rand_float32() < CONTINENTAL_TO_OCEANIC_RATIO ? .CONTINENTAL : .OCEANIC

		plates[i].rotation_axis = rotation_axis_from_angle(TILT)
		plates[i].angular_velocity = rand_float32_range(0, 0.01)
	}

	assigned := make([]bool, len(planet.faces))
	defer delete(assigned)

	frontiers := make([]GrowthFrontier, num_plates)
	defer {
		for frontier in frontiers {
			delete(frontier.faces)
			delete(frontier.scores)
		}
		delete(frontiers)
	}

	growth_directions := make([][3]rl.Vector3, num_plates)
	defer delete(growth_directions)

	plate_colors := make([]rl.Color, num_plates)
	defer delete(plate_colors)

	for i := 0; i < num_plates; i += 1 {
		num_dirs := rand_int_range(1, 4)
		for d := 0; d < num_dirs; d += 1 {
			theta := rand_float32() * 2 * rl.PI
			phi := rand_float32() * rl.PI

			x := math.sin(phi) * math.cos(theta)
			y := math.sin(phi) * math.sin(theta)
			z := math.cos(phi)

			growth_directions[i][d] = normalize(rl.Vector3{f32(x), f32(y), f32(z)})
		}

		plate_colors[i] = rl.Color {
			u8(rand_int_max(200) + 55),
			u8(rand_int_max(200) + 55),
			u8(rand_int_max(200) + 55),
			255,
		}

		center_idx := plate_centers[i]
		append(&plates[i].faces, center_idx)
		assigned[center_idx] = true

		face := &planet.faces[center_idx]
		face.region_id = i
		face.color = plate_colors[i]

		neighbors := get_neighbor_faces(planet, center_idx)
		for neighbor in neighbors {
			if !assigned[neighbor] {
				append(&frontiers[i].faces, neighbor)
				append(&frontiers[i].scores, rand_float32())
			}
		}
		delete(neighbors)
	}

	plate_strengths := make([]f32, num_plates)
	for i := 0; i < num_plates; i += 1 {
		plate_strengths[i] = rand_float32_range(0.5, 1.0)
	}
	defer delete(plate_strengths)

	remaining_faces := len(planet.faces) - num_plates
	iterations := 0
	max_iterations := len(planet.faces) * 1000

	for remaining_faces > 0 && iterations < max_iterations {
		iterations += 1

		for plate_idx := 0; plate_idx < num_plates; plate_idx += 1 {
			if len(frontiers[plate_idx].faces) == 0 ||
			   rand_float32() > plate_strengths[plate_idx] {
				continue
			}

			center_pos := rl.Vector3{0, 0, 0}
			if len(plates[plate_idx].faces) > 0 {
				for face_idx in plates[plate_idx].faces {
					face_pos := planet.faces[face_idx].center
					center_pos.x += face_pos.x
					center_pos.y += face_pos.y
					center_pos.z += face_pos.z
				}
				center_pos.x /= f32(len(plates[plate_idx].faces))
				center_pos.y /= f32(len(plates[plate_idx].faces))
				center_pos.z /= f32(len(plates[plate_idx].faces))
				center_pos = normalize(center_pos)
			}

			for i := 0; i < len(frontiers[plate_idx].faces); i += 1 {
				face_idx := frontiers[plate_idx].faces[i]
				face_pos := planet.faces[face_idx].center

				frontiers[plate_idx].scores[i] =
					frontiers[plate_idx].scores[i] * 0.5 + rand_float32() * 0.5

				direction := normalize(
					rl.Vector3 {
						face_pos.x - center_pos.x,
						face_pos.y - center_pos.y,
						face_pos.z - center_pos.z,
					},
				)

				max_alignment := f32(0)
				for d := 0; d < 3; d += 1 {
					growth_dir := growth_directions[plate_idx][d]
					if growth_dir.x == 0 && growth_dir.y == 0 && growth_dir.z == 0 {
						continue
					}

					alignment :=
						direction.x * growth_dir.x +
						direction.y * growth_dir.y +
						direction.z * growth_dir.z

					if alignment > max_alignment {
						max_alignment = alignment
					}
				}

				alignment_factor := 1.0 + max_alignment
				frontiers[plate_idx].scores[i] *= alignment_factor
			}

			if len(frontiers[plate_idx].faces) > 0 {
				best_idx := 0
				best_score := frontiers[plate_idx].scores[0]
				for i := 1; i < len(frontiers[plate_idx].scores); i += 1 {
					if frontiers[plate_idx].scores[i] > best_score {
						best_score = frontiers[plate_idx].scores[i]
						best_idx = i
					}
				}

				face_idx := frontiers[plate_idx].faces[best_idx]

				ordered_remove(&frontiers[plate_idx].faces, best_idx)
				ordered_remove(&frontiers[plate_idx].scores, best_idx)

				if assigned[face_idx] {
					continue
				}

				append(&plates[plate_idx].faces, face_idx)
				assigned[face_idx] = true
				remaining_faces -= 1

				face := &planet.faces[face_idx]
				face.region_id = plate_idx
				face.color = plate_colors[plate_idx]

				neighbors := get_neighbor_faces(planet, face_idx)
				for neighbor in neighbors {
					if !assigned[neighbor] &&
					   !slice.contains(frontiers[plate_idx].faces[:], neighbor) {
						append(&frontiers[plate_idx].faces, neighbor)
						append(&frontiers[plate_idx].scores, rand_float32())
					}
				}
				delete(neighbors)
			}
		}

		if iterations % 1000 == 0 && remaining_faces > 0 {
			fmt.println("Forcing assignment of some faces. Remaining:", remaining_faces)

			unassigned := make([dynamic]int)
			defer delete(unassigned)

			for face_idx := 0; face_idx < len(planet.faces); face_idx += 1 {
				if !assigned[face_idx] {
					append(&unassigned, face_idx)
				}
			}

			force_count := max(1, len(unassigned) / 10)
			for i := 0; i < force_count && len(unassigned) > 0; i += 1 {
				random_idx := rand_int_max(len(unassigned))
				face_idx := unassigned[random_idx]
				ordered_remove(&unassigned, random_idx)

				plate_idx := rand_int_max(num_plates)
				append(&plates[plate_idx].faces, face_idx)
				assigned[face_idx] = true
				remaining_faces -= 1

				face := &planet.faces[face_idx]
				face.region_id = plate_idx
				face.color = plate_colors[plate_idx]

				neighbors := get_neighbor_faces(planet, face_idx)
				for neighbor in neighbors {
					if !assigned[neighbor] &&
					   !slice.contains(frontiers[plate_idx].faces[:], neighbor) {
						append(&frontiers[plate_idx].faces, neighbor)
						append(&frontiers[plate_idx].scores, rand_float32())
					}
				}
				delete(neighbors)
			}
		}
	}

	for plate_idx in 0 ..< num_plates {
		plate := &plates[plate_idx]

		face_in_plate := make([]bool, len(planet.faces))
		defer delete(face_in_plate)

		for face_idx in plate.faces {
			face_in_plate[face_idx] = true
		}

		for edge_idx in 0 ..< len(planet.edges) {
			edge := planet.edges[edge_idx]
			if (edge.face1 != -1 && edge.face2 != -1) &&
			   face_in_plate[edge.face1] &&
			   face_in_plate[edge.face2] {
				append(&plate.edges, edge_idx)
			}
		}

		vertex_set := make(map[int]bool)
		defer delete(vertex_set)

		for face_idx in plate.faces {
			face := planet.faces[face_idx]
			for v_idx in face.vertices {
				vertex_set[v_idx] = true
			}
		}

		for v_idx in vertex_set {
			append(&plate.vertices, v_idx)
		}
	}

	fmt.println("Applied growth-based tectonic plates:", num_plates)
	fmt.println("Iterations:", iterations)
	fmt.println("Unassigned faces:", remaining_faces)

	return plates
}

apply_tectonic_plates :: proc(planet: ^Planet, num_plates: int) {
	plates := generate_growth_based_plates(planet, num_plates)

	for plate_idx in 0 ..< num_plates {
		plate := plates[plate_idx]
		axis := plate.rotation_axis
		omega := plate.angular_velocity

		for face_idx in plate.faces {
			face := &planet.faces[face_idx]
			p := face.center
			face.velocity = omega * cross(axis, p)
		}
	}

	for plate in plates {
		delete(plate.faces)
		delete(plate.edges)
		delete(plate.vertices)
	}
	delete(plates)

	fmt.println("Applied tectonic plates:", num_plates)
}

get_neighbor_faces :: proc(planet: ^Planet, face_idx: int) -> [dynamic]int {
	neighbors := make([dynamic]int)

	for edge, edge_idx in planet.edges {
		if edge.face1 == face_idx && edge.face2 != -1 {
			append(&neighbors, edge.face2)
		}
		if edge.face2 == face_idx && edge.face1 != -1 {
			append(&neighbors, edge.face1)
		}
	}

	return neighbors
}

compute_face_stress :: proc(planet: ^Planet) -> []f32 {
	stress := make([]f32, len(planet.faces))

	for face_idx in 0 ..< len(planet.faces) {
		face := planet.faces[face_idx]
		my_plate := face.region_id
		neighbors := get_neighbor_faces(planet, face_idx)
		defer delete(neighbors)

		max_stress := f32(0)
		has_cross_plate_neighbor := false

		for neighbor_idx in neighbors {
			neighbor := planet.faces[neighbor_idx]
			neighbor_plate := neighbor.region_id

			if neighbor_plate != my_plate {
				has_cross_plate_neighbor = true
				dv := neighbor.velocity - face.velocity
				stress_magnitude := math.sqrt(dv.x * dv.x + dv.y * dv.y + dv.z * dv.z)
				if stress_magnitude > max_stress {
					max_stress = stress_magnitude
				}
			}
		}

		stress[face_idx] = has_cross_plate_neighbor ? max_stress : 0
	}

	return stress
}

generate_height_map :: proc(
	planet: ^Planet,
	plates: []TectonicPlate,
	stress_values: []f32,
	noise_layers: []NoiseLayer,
) -> HeightMap {
	heights := make([]f32, len(planet.faces))

	min_stress := f32(0)
	max_stress := f32(0)
	for stress in stress_values {
		if stress > max_stress {
			max_stress = stress
		}
	}

	for face_idx := 0; face_idx < len(planet.faces); face_idx += 1 {
		face := &planet.faces[face_idx]
		plate_idx := face.region_id
		plate_type := plates[plate_idx].plate_type

		base_height := plate_type == .CONTINENTAL ? 0.5 : -0.5

		stress_factor := max_stress > 0 ? stress_values[face_idx] / max_stress : 0
		stress_height := math.pow(stress_factor, 1.5) * 1.5

		noise_sum := f32(0)

		if len(noise_layers) > 0 {
			for layer in noise_layers {
				layer_noise := generate_noise_layer(layer, face.center)

				multiplier := plate_type == .CONTINENTAL ? 1.0 : 0.5
				noise_sum += layer_noise * f32(multiplier)
			}
		}

		heights[face_idx] = f32(base_height) + stress_height + noise_sum
	}

	smoothed_heights := make([]f32, len(heights))
	for face_idx := 0; face_idx < len(planet.faces); face_idx += 1 {
		neighbors := get_neighbor_faces(planet, face_idx)
		defer delete(neighbors)

		sum := heights[face_idx]
		count := 1

		for neighbor_idx in neighbors {
			sum += heights[neighbor_idx]
			count += 1
		}

		smoothed_heights[face_idx] = sum / f32(count)
	}

	min_height := f32(999)
	max_height := f32(-999)

	for height in smoothed_heights {
		if height < min_height {
			min_height = height
		}
		if height > max_height {
			max_height = height
		}
	}

	delete(heights)
	return HeightMap{values = smoothed_heights, min_height = min_height, max_height = max_height}
}


noise_for_color :: proc(value: u8, range: u8) -> u8 {
	noise := rand_int_max(int(range * 2 + 1)) - int(range)
	result := int(value) + noise
	return u8(math.clamp(result, 0, 255))
}

height_to_color :: proc(height: f32, min_height, max_height: f32, is_oceanic: bool) -> rl.Color {
	t := (height - min_height) / (max_height - min_height)
	t = math.clamp(t, 0, 1)


	if t < WATER_THRESHOLD {
		depth_factor := t / WATER_THRESHOLD

		r := u8(math.lerp(f32(10), f32(22), depth_factor))
		g := u8(math.lerp(f32(20), f32(44), depth_factor))
		b := u8(math.lerp(f32(80), f32(99), depth_factor))

		return rl.Color{noise_for_color(r, 5), noise_for_color(g, 5), noise_for_color(b, 10), 255}
	} else if t < 0.6 {
		green_t := (t - WATER_THRESHOLD) / (0.6 - WATER_THRESHOLD)

		green_t += (rand_float32() - 0.5) * 0.1
		green_t = math.clamp(green_t, 0, 1)

		if green_t < 0.2 {
			r := u8(80 + green_t * 40)
			g := u8(130 + green_t * 20)
			b := u8(30 + green_t * 20)
			return rl.Color {
				noise_for_color(r, 15),
				noise_for_color(g, 15),
				noise_for_color(b, 10),
				255,
			}
		} else if green_t < 0.4 {
			r := u8(30 + green_t * 40)
			g := u8(100 + green_t * 30)
			b := u8(30 + green_t * 20)
			return rl.Color {
				noise_for_color(r, 15),
				noise_for_color(g, 20),
				noise_for_color(b, 10),
				255,
			}
		} else if green_t < 0.6 {
			r := u8(60 + green_t * 50)
			g := u8(140 + green_t * 30)
			b := u8(30 + green_t * 30)
			return rl.Color {
				noise_for_color(r, 15),
				noise_for_color(g, 25),
				noise_for_color(b, 10),
				255,
			}
		} else if green_t < 0.8 {
			r := u8(120 + green_t * 60)
			g := u8(140 + green_t * 40)
			b := u8(40 + green_t * 20)
			return rl.Color {
				noise_for_color(r, 20),
				noise_for_color(g, 20),
				noise_for_color(b, 10),
				255,
			}
		} else {
			r := u8(150 + green_t * 50)
			g := u8(160 + green_t * 20)
			b := u8(50 + green_t * 30)
			return rl.Color {
				noise_for_color(r, 20),
				noise_for_color(g, 15),
				noise_for_color(b, 10),
				255,
			}
		}
	} else if t < MOUNTAIN_THRESHOLD {
		orange_t := (t - 0.6) / (MOUNTAIN_THRESHOLD - 0.6)

		if orange_t < 0.33 {
			r := u8(180 - orange_t * 20)
			g := u8(140 - orange_t * 40)
			b := u8(65 - orange_t * 15)
			return rl.Color {
				noise_for_color(r, 20),
				noise_for_color(g, 15),
				noise_for_color(b, 10),
				255,
			}
		} else if orange_t < 0.66 {
			r := u8(160 - orange_t * 20)
			g := u8(120 - orange_t * 30)
			b := u8(55 - orange_t * 15)
			return rl.Color {
				noise_for_color(r, 15),
				noise_for_color(g, 15),
				noise_for_color(b, 10),
				255,
			}
		} else {
			r := u8(140 - orange_t * 20)
			g := u8(100 - orange_t * 30)
			b := u8(45 - orange_t * 15)
			return rl.Color {
				noise_for_color(r, 15),
				noise_for_color(g, 10),
				noise_for_color(b, 10),
				255,
			}
		}
	} else {
		mountain_t := (t - MOUNTAIN_THRESHOLD) / (1.0 - MOUNTAIN_THRESHOLD)

		if mountain_t > 0.7 {
			snow := u8(230 + mountain_t * 25)
			return rl.Color {
				noise_for_color(snow, 10),
				noise_for_color(snow, 10),
				noise_for_color(snow, 10),
				255,
			}
		} else {
			if mountain_t < 0.35 {
				r := u8(130 - mountain_t * 20)
				g := u8(90 - mountain_t * 20)
				b := u8(80 - mountain_t * 10)
				return rl.Color {
					noise_for_color(r, 15),
					noise_for_color(g, 15),
					noise_for_color(b, 15),
					255,
				}
			} else {
				r := u8(120 - mountain_t * 20)
				g := u8(120 - mountain_t * 20)
				b := u8(120 - mountain_t * 20)
				return rl.Color {
					noise_for_color(r, 15),
					noise_for_color(g, 15),
					noise_for_color(b, 15),
					255,
				}
			}
		}
	}
}

draw_rotation_axis :: proc(axis: rl.Vector3, planet_radius: f32) {
	extended_length := planet_radius * 10

	start_point := rl.Vector3 {
		axis.x * -extended_length,
		axis.y * -extended_length,
		axis.z * -extended_length,
	}

	end_point := rl.Vector3 {
		axis.x * extended_length,
		axis.y * extended_length,
		axis.z * extended_length,
	}

	rl.DrawLine3D(start_point, end_point, rl.RED)
}

rotation_axis_from_angle :: proc(degrees: f64) -> rl.Vector3 {
	tilt_angle := degrees * rl.DEG2RAD

	x := math.sin(tilt_angle)
	y := math.cos(tilt_angle)
	z := 0.0

	return normalize(rl.Vector3{f32(x), f32(y), f32(z)})
}

apply_height_displacement :: proc(planet: ^Planet, height_map: HeightMap) {
    vertex_heights := make([]f32, len(planet.vertices))
    vertex_counts := make([]int, len(planet.vertices))
    defer delete(vertex_heights)
    defer delete(vertex_counts)
    
    for face_idx := 0; face_idx < len(planet.faces); face_idx += 1 {
        face := &planet.faces[face_idx]
        height := height_map.values[face_idx]
        
        for vertex_idx in face.vertices {
            vertex_heights[vertex_idx] += height
            vertex_counts[vertex_idx] += 1
        }
    }
    
    for vertex_idx := 0; vertex_idx < len(planet.vertices); vertex_idx += 1 {
        if vertex_counts[vertex_idx] > 0 {
            vertex_heights[vertex_idx] /= f32(vertex_counts[vertex_idx])
        }
    }
    
    height_scale := planet.radius * HEIGHT_DISPLACEMENT
    
		normalized_water_level := math.lerp(height_map.min_height, height_map.max_height, f32(WATER_THRESHOLD))
    water_displacement := normalized_water_level * height_scale
    
    for vertex_idx := 0; vertex_idx < len(planet.vertices); vertex_idx += 1 {
        if vertex_counts[vertex_idx] > 0 {
            avg_height := vertex_heights[vertex_idx]
            
            displacement: f32
            
            normalized_height := (avg_height - height_map.min_height) / (height_map.max_height - height_map.min_height)
            if normalized_height < WATER_THRESHOLD {
                displacement = water_displacement
            } else {
                displacement = avg_height * height_scale
            }
            
            vertex := &planet.vertices[vertex_idx]
            base_position := normalize(vertex.position) * planet.radius
            
            vertex.position = base_position + vertex.normal * displacement
        }
    }
    
    for face_idx := 0; face_idx < len(planet.faces); face_idx += 1 {
        face := &planet.faces[face_idx]
        
        center := rl.Vector3{0, 0, 0}
        for vertex_idx in face.vertices {
            vertex_pos := planet.vertices[vertex_idx].position
            center.x += vertex_pos.x
            center.y += vertex_pos.y
            center.z += vertex_pos.z
        }
        
        center.x /= f32(len(face.vertices))
        center.y /= f32(len(face.vertices))
        center.z /= f32(len(face.vertices))
        face.center = center
        
        if len(face.vertices) >= 3 {
            v1 := planet.vertices[face.vertices[0]].position
            v2 := planet.vertices[face.vertices[1]].position
            v3 := planet.vertices[face.vertices[2]].position
            
            edge1 := rl.Vector3{v2.x - v1.x, v2.y - v1.y, v2.z - v1.z}
            edge2 := rl.Vector3{v3.x - v1.x, v3.y - v1.y, v3.z - v1.z}
            face.normal = normalize(cross(edge1, edge2))
        }
    }
    
    recalculate_vertex_normals(planet)
}

calculate_climate :: proc(planet: ^Planet, height_map: HeightMap) {
    if planet.climate != nil {
        delete(planet.climate)
    }
    planet.climate = make([dynamic]ClimateData, len(planet.faces))
	
    high_altitude_threshold := lerp(height_map.min_height, height_map.max_height, 0.85)
    
    is_coastal := make([]bool, len(planet.faces))
    defer delete(is_coastal)

   water_threshold_normalized := lerp(height_map.min_height, height_map.max_height, WATER_THRESHOLD)
    
    for face_idx := 0; face_idx < len(planet.faces); face_idx += 1 {
        face_height := height_map.values[face_idx]
        if face_height > water_threshold_normalized {
            neighbors := get_neighbor_faces(planet, face_idx)
            for neighbor_idx in neighbors {
                if height_map.values[neighbor_idx] <= water_threshold_normalized {
                    is_coastal[face_idx] = true
                    break
                }
            }
            delete(neighbors)
        }
    }
    
    near_mountain := make([]bool, len(planet.faces))
    defer delete(near_mountain)
    
    for face_idx := 0; face_idx < len(planet.faces); face_idx += 1 {
        if height_map.values[face_idx] > high_altitude_threshold {
            neighbors := get_neighbor_faces(planet, face_idx)
            for neighbor_idx in neighbors {
                near_mountain[neighbor_idx] = true
            }
            delete(neighbors)
        }
    }
    
    rotation_axis := rotation_axis_from_angle(TILT)
    
    for face_idx := 0; face_idx < len(planet.faces); face_idx += 1 {
        face := planet.faces[face_idx]
        
        center_normalized := normalize(face.center)
        
        latitude_dot := center_normalized.x * rotation_axis.x + 
                        center_normalized.y * rotation_axis.y + 
                        center_normalized.z * rotation_axis.z
                        
        equatorial_factor := 1.0 - math.abs(latitude_dot)
        
        abs_latitude := math.abs(latitude_dot)
        
        temp := lerp(POLE_TEMP, EQUATOR_TEMP, equatorial_factor)
        
        normalized_height := (height_map.values[face_idx] - height_map.min_height) / 
                           (height_map.max_height - height_map.min_height)
        
        if normalized_height > WATER_THRESHOLD {
            altitude_factor := (normalized_height - WATER_THRESHOLD) / (1.0 - WATER_THRESHOLD)
            temp = temp - f32(altitude_factor * ALTITUDE_TEMP_FACTOR)
        }
        
        temp = math.clamp(temp, 0.0, 1.0)
        
        precip: f32
        
        scaled_latitude := abs_latitude * LATITUDE_SCALE
        
        if scaled_latitude < 0.12 {
            precip = lerp(0.8, 1.0, 1.0 - scaled_latitude/0.12)
        } else if scaled_latitude < 0.3 {
            t := (scaled_latitude - 0.12) / (0.3 - 0.12)
            precip = lerp(0.8, 0.2, t)
        } else if scaled_latitude < 0.6 {
            t := (scaled_latitude - 0.3) / (0.6 - 0.3)
            precip = lerp(0.2, 0.7, t)
        } else {
            t := (scaled_latitude - 0.6) / (1.0 - 0.6)
            precip = lerp(0.7, 0.1, t)
        }
        
        if is_coastal[face_idx] {
            precip += COASTAL_PRECIP_BONUS
        }
        
        if near_mountain[face_idx] {
            precip += MOUNTAIN_PRECIP_BONUS
        }
        
        if normalized_height <= WATER_THRESHOLD {
            precip = 0.0
        }
        
        precip = math.clamp(precip, 0.0, 1.0)
        
        planet.climate[face_idx] = ClimateData{temperature = f32(temp), precipitation = precip, polar_factor = math.abs(latitude_dot)}
    }

		smooth_climate_data(planet)
}

smooth_climate_data :: proc(planet: ^Planet) {
    temp_smoothed := make([]f32, len(planet.climate))
    precip_smoothed := make([]f32, len(planet.climate))
    defer delete(temp_smoothed)
    defer delete(precip_smoothed)
    
    for face_idx := 0; face_idx < len(planet.faces); face_idx += 1 {
        neighbors := get_neighbor_faces(planet, face_idx)
        
        temp_sum := planet.climate[face_idx].temperature
        precip_sum := planet.climate[face_idx].precipitation
        count := 1
        
        for neighbor_idx in neighbors {
            temp_sum += planet.climate[neighbor_idx].temperature
            precip_sum += planet.climate[neighbor_idx].precipitation
            count += 1
        }
        
        temp_smoothed[face_idx] = temp_sum / f32(count)
        precip_smoothed[face_idx] = precip_sum / f32(count)
        
        delete(neighbors)
    }
    
    for i := 0; i < len(planet.climate); i += 1 {
        planet.climate[i].temperature = temp_smoothed[i]
        planet.climate[i].precipitation = precip_smoothed[i]
    }
}

recalculate_vertex_normals :: proc(planet: ^Planet) {
    for i := 0; i < len(planet.vertices); i += 1 {
        planet.vertices[i].normal = rl.Vector3{0, 0, 0}
    }
    
    for face_idx := 0; face_idx < len(planet.faces); face_idx += 1 {
        face := planet.faces[face_idx]
        
        for vertex_idx in face.vertices {
            vertex := &planet.vertices[vertex_idx]
            vertex.normal.x += face.normal.x
            vertex.normal.y += face.normal.y
            vertex.normal.z += face.normal.z
        }
    }
    
    for i := 0; i < len(planet.vertices); i += 1 {
        vertex := &planet.vertices[i]
        vertex.normal = normalize(vertex.normal)
    }
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

	icosahedron := generate_icosahedron(PLANET_RADIUS)

	subdivided := subdivide(&icosahedron)

	for i := 0; i < SUBDIVISIONS; i += 1 {
		subdivided = subdivide(&subdivided)
	}

	goldberg := create_dual(&subdivided)
	apply_tectonic_plates(&goldberg, CONTINENTS)

	plates := make([]TectonicPlate, CONTINENTS)

	for i in 0 ..< CONTINENTS {
		plates[i].faces = make([dynamic]int)
		plates[i].edges = make([dynamic]int)
		plates[i].vertices = make([dynamic]int)
	}

	for face_idx in 0 ..< len(goldberg.faces) {
		face := goldberg.faces[face_idx]
		append(&plates[face.region_id].faces, face_idx)
	}

	for plate_idx in 0 ..< CONTINENTS {
		plate := &plates[plate_idx]

		face_in_plate := make([]bool, len(goldberg.faces))
		for face_idx in plate.faces {
			face_in_plate[face_idx] = true
		}

		for edge_idx in 0 ..< len(goldberg.edges) {
			edge := goldberg.edges[edge_idx]
			if (edge.face1 != -1 && edge.face2 != -1) &&
			   face_in_plate[edge.face1] &&
			   face_in_plate[edge.face2] {
				append(&plate.edges, edge_idx)
			}
		}

		vertex_set := make(map[int]bool)
		for face_idx in plate.faces {
			face := goldberg.faces[face_idx]
			for v_idx in face.vertices {
				vertex_set[v_idx] = true
			}
		}
		for v_idx in vertex_set {
			append(&plate.vertices, v_idx)
		}

		delete(face_in_plate)
		delete(vertex_set)
	}

	rotation_axis := rotation_axis_from_angle(TILT)
	max_angular_velocity := 0.01

	for i in 0 ..< CONTINENTS {
		if rand_float32() < CONTINENTAL_TO_OCEANIC_RATIO {
			plates[i].plate_type = .CONTINENTAL
		} else {
			plates[i].plate_type = .OCEANIC
		}

		plates[i].rotation_axis = rotation_axis
		plates[i].angular_velocity = rand_float32_range(0, f32(max_angular_velocity))
	}

	for plate in plates {
		axis := plate.rotation_axis
		omega := plate.angular_velocity
		for face_idx in plate.faces {
			face := &goldberg.faces[face_idx]
			p := face.center
			face.velocity = omega * cross(axis, p)
		}
	}

	stress_values := compute_face_stress(&goldberg)

	height_map := generate_height_map(&goldberg, plates, stress_values, NOISE_LAYERS)
	defer delete(height_map.values)

	apply_height_displacement(&goldberg, height_map)
	calculate_climate(&goldberg, height_map)

	apply_biomes(&goldberg, height_map)

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
			edge_color := rl.Color{30, 30, 30, 255} // Dark edges

			for i := 2; i < len(face.vertices); i += 1 {
				v1_idx := face.vertices[0]
				v2_idx := face.vertices[i - 1]
				v3_idx := face.vertices[i]

				v1 := goldberg.vertices[v1_idx].position
				v2 := goldberg.vertices[v2_idx].position
				v3 := goldberg.vertices[v3_idx].position

				rl.DrawTriangle3D(v1, v2, v3, face.color)
			}

			for i := 0; i < len(face.vertices); i += 1 {
				v1_idx := face.vertices[i]
				v2_idx := face.vertices[(i + 1) % len(face.vertices)]

				v1 := goldberg.vertices[v1_idx].position
				v2 := goldberg.vertices[v2_idx].position

				if DRAW_BORDERS {
					rl.DrawLine3D(v1, v2, edge_color)
				}
			}
		}

		if DRAW_ROTATION_LINE {
			draw_rotation_axis(rotation_axis, PLANET_RADIUS)
		}

		rl.EndMode3D()

		if DEBUG_MODE {
			rl.DrawFPS(10, 10)
			rl.DrawText(fmt.ctprintf("Vertices: %d", len(goldberg.vertices)), 10, 40, 20, rl.WHITE)
			rl.DrawText(fmt.ctprintf("Edges: %d", len(goldberg.edges)), 10, 70, 20, rl.WHITE)
			rl.DrawText(fmt.ctprintf("Faces: %d", len(goldberg.faces)), 10, 100, 20, rl.WHITE)
		}

		rl.EndDrawing()
	}

	delete(stress_values)
	cleanup(&goldberg)
	cleanup(&subdivided)
	cleanup(&icosahedron)

	for plate in plates {
		delete(plate.faces)
		delete(plate.edges)
		delete(plate.vertices)
	}
	delete(plates)

	rl.CloseWindow()
}

cleanup :: proc(planet: ^Planet) {
	for face in &planet.faces {
		delete(face.vertices)
	}
	delete(planet.faces)
	delete(planet.vertices)
	delete(planet.edges)
	if planet.climate != nil {
			delete(planet.climate)
	}
}
