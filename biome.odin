package planet

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
	{0.5, 0.0, rl.Color{10, 20, 80, 255}},

	// DESERT
	{0.9, 0.1, rl.Color{230, 210, 180, 255}},

	// SAVANNAH
	{0.8, 0.3, rl.Color{200, 190, 120, 255}},

	// TAIGA
	{0.3, 0.4, rl.Color{90, 120, 90, 255}},

	// RAINFOREST
	{0.8, 0.9, rl.Color{40, 160, 70, 255}},

	// TUNDRA
	{0.2, 0.2, rl.Color{180, 180, 160, 255}},

	// POLAR
	{0.1, 0.1, rl.Color{220, 220, 240, 255}},

	// TEMPERATE FOREST
	{0.5, 0.7, rl.Color{70, 140, 60, 255}},

	// MEDITERRANEAN
	{0.7, 0.4, rl.Color{170, 190, 90, 255}},

	// STEPPE
	{0.6, 0.3, rl.Color{180, 180, 120, 255}},

	// GRASSLAND
	{0.5, 0.5, rl.Color{150, 180, 90, 255}},

	// MOUNTAIN
	{0.3, 0.3, rl.Color{130, 130, 130, 255}},

	// SNOW_CAP
	{0.1, 0.1, rl.Color{240, 240, 240, 255}},
}

apply_color_noise :: proc(base: u8, range: u8) -> u8 {
	noise := rand_int_range(-int(range), int(range) + 1)
	result := int(base) + noise
	return u8(math.clamp(result, 0, 255))
}

apply_biomes :: proc(planet: ^Planet, height_map: HeightMap) {
	for face_idx := 0; face_idx < len(planet.faces); face_idx += 1 {
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

			r := math.lerp(f32(10), f32(22), depth_factor) // Deep to shallow
			g := math.lerp(f32(20), f32(44), depth_factor)
			b := math.lerp(f32(80), f32(99), depth_factor)

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
