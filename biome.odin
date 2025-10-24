package planet

import "core:fmt"
import math "core:math"
import rl "vendor:raylib"

Biome :: enum {
	OCEAN,
	DESERT,
	SAVANNAH,
	TAIGA,
	RAINFOREST,
	TUNDRA,
	POLAR,
	TEMP_FOREST,
	MEDITERRANEAN,
	STEPPE,
	GRASSLAND,
	MOUNTAIN,
	SNOW_CAP,
}

BiomeData :: struct {
	temp:  f32,
	prec:  f32,
	color: rl.Color,
}

BIOMES := []BiomeData {
	// OCEAN
	{0.5, 0.0, BIOME_COLORS[0]},

	// DESERT
	{0.9, 0.1, BIOME_COLORS[1]},

	// SAVANNAH
	{0.8, 0.3, BIOME_COLORS[2]},

	// TAIGA
	{0.3, 0.4, BIOME_COLORS[3]},

	// RAINFOREST
	{0.8, 0.9, BIOME_COLORS[4]},

	// TUNDRA
	{0.2, 0.2, BIOME_COLORS[5]},

	// POLAR
	{0.1, 0.1, BIOME_COLORS[6]},

	// TEMPERATE FOREST
	{0.5, 0.7, BIOME_COLORS[7]},

	// MEDITERRANEAN
	{0.7, 0.4, BIOME_COLORS[8]},

	// STEPPE
	{0.6, 0.3, BIOME_COLORS[9]},

	// GRASSLAND
	{0.5, 0.5, BIOME_COLORS[10]},

	// MOUNTAIN
	{0.3, 0.3, BIOME_COLORS[11]},

	// SNOW_CAP
	{0.1, 0.1, BIOME_COLORS[12]},
}

apply_color_noise :: proc(base: u8, range: u8) -> u8 {
	noise := rand_int_range(-int(range), int(range) + 1)
	result := int(base) + noise
	return u8(math.clamp(result, 0, 255))
}

apply_biomes :: proc(planet: ^Planet, height_map: HeightMap) {
	total_faces := len(planet.faces)
	for face_idx := 0; face_idx < total_faces; face_idx += 1 {
		if face_idx % 1000 == 0 {
			fmt.printf("Processing face %d/%d\n", face_idx, total_faces)
		}
		face := &planet.faces[face_idx]
		climate := planet.climate[face_idx]
		height := height_map.values[face_idx]

		noise_sum := f32(0)

		if len(CLIMATE_LAYERS) > 0 {
			for layer in CLIMATE_LAYERS {
				layer_noise := generate_noise_layer(layer, face.center)
				if rand_int_max(100) < 25 {
					layer_noise = -layer_noise
				}
				noise_sum += layer_noise
			}
		}

		temp_adjusted := climate.temperature + noise_sum
		prec_adjusted := climate.precipitation + noise_sum

		temp_adjusted = math.clamp(temp_adjusted, 0.0, 1.0)
		prec_adjusted = math.clamp(prec_adjusted, 0.0, 1.0)

		biome := find_biome(temp_adjusted, prec_adjusted, climate.polar_factor, height, height_map)
		base_color := BIOMES[int(biome)].color

		#partial switch biome {
		case .OCEAN:
			water_level := lerp(height_map.min_height, height_map.max_height, WATER_THRESHOLD)
			depth_factor := height / water_level
			depth_factor = math.clamp(depth_factor, 0.0, 1.0)

			base_r := f32(base_color.r)
			base_g := f32(base_color.g)
			base_b := f32(base_color.b)
			
			r := math.lerp(base_r * 0.5, base_r, depth_factor)
			g := math.lerp(base_g * 0.5, base_g, depth_factor)
			b := math.lerp(base_b * 0.5, base_b, depth_factor)

			polar_factor := climate.polar_factor

      if polar_factor > 0.95 {
			r = math.lerp(r, 255.0, polar_factor * 0.65) // Lighten towards white
			g = math.lerp(g, 255.0, polar_factor * 0.65)
			b = math.lerp(b, 255.0, polar_factor * 0.65)
      }

			face.color = rl.Color {
				apply_color_noise(u8(r), 3),
				apply_color_noise(u8(g), 3),
				apply_color_noise(u8(b), 5),
				255,
			}


		case .MOUNTAIN:
			face.color = rl.Color {
				apply_color_noise(base_color.r, 10),
				apply_color_noise(base_color.g, 10),
				apply_color_noise(base_color.b, 10),
				255,
			}

		case .SNOW_CAP:
			face.color = rl.Color {
				apply_color_noise(base_color.r, 5),
				apply_color_noise(base_color.g, 5),
				apply_color_noise(base_color.b, 5),
				255,
			}

		case:
			face.color = rl.Color {
				apply_color_noise(base_color.r, 12),
				apply_color_noise(base_color.g, 12),
				apply_color_noise(base_color.b, 12),
				255,
			}
		}
	}
}

find_biome :: proc(temp: f32, prec: f32, polar_factor: f32, height: f32, height_map: HeightMap) -> Biome {
    water_level := f32(WATER_THRESHOLD)
    mountain_level := f32(MOUNTAIN_THRESHOLD)
    snow_level := f32(SNOW_CAP)

    if height <= water_level {
        return .OCEAN
    } else if height >= snow_level {
        return .SNOW_CAP
    } else if height >= mountain_level {
        return .MOUNTAIN
    } else {
        if polar_factor > 0.95 {
            return .POLAR 
        } else if polar_factor > 0.94 {
            return .TUNDRA
        } else {
            best_biome := Biome.GRASSLAND
            best_dist := f32(100.0)
            for biome_idx in 1..=10 {
                biome_data := BIOMES[biome_idx]
                temp_diff := temp - biome_data.temp
                prec_diff := prec - biome_data.prec
                dist := math.sqrt(temp_diff * temp_diff + prec_diff * prec_diff)
                if dist < best_dist {
                    best_dist = dist
                    best_biome = Biome(biome_idx)
                }
            }
            return best_biome
        }
    }
}
