package planet

import rl "vendor:raylib"

DEBUG_MODE :: false
DRAW_ROTATION_LINE :: false
ENABLED_SHADER :: true 

// VERTICE_DISPLACEMENT :: 0.025
// SUBDIVISIONS :: 4
VERTICE_DISPLACEMENT :: 0.012
SUBDIVISIONS :: 5
HEIGHT_DISPLACEMENT :: 0.08
DRAW_BORDERS :: false
PLANET_RADIUS :: 5.0
CONTINENTS :: 64
TILT :: 23.5
CONTINENTAL_TO_OCEANIC_RATIO :: 0.4

MOUNTAIN_THRESHOLD :: 0.75
WATER_THRESHOLD :: 0.35
SNOW_CAP :: 0.95

NOISE_LAYERS :: []NoiseLayer{
    {scale = 1.0, influence = 0.3, octaves = 4, persistence = 0.7},
    {scale = 8.0, influence = 0.05, octaves = 2, persistence = 0.8},
    {scale = 8.0, influence = 0.45, octaves = 12, persistence = 0.8},
    {scale = 3.0, influence = 0.15, octaves = 6, persistence = 0.5},
    {scale = 8.0, influence = 0.05, octaves = 2, persistence = 0.8},
    {scale = 8.0, influence = 0.45, octaves = 12, persistence = 0.8},
}

// CLIMATE CONFIGS
EQUATOR_TEMP :: 1.5
POLE_TEMP :: 0.0
ALTITUDE_TEMP_FACTOR :: 0.24 // how much temperature decreases with altitude
COASTAL_PRECIP_BONUS :: 0.5 // bonus precipitation for coastal regions
MOUNTAIN_PRECIP_BONUS :: 0.38 // bonus precipitation for regions near mountains
LATITUDE_SCALE :: 1.0


CLIMATE_LAYERS :: []NoiseLayer{
    {scale = 1.0, influence = 0.3, octaves = 4, persistence = 0.5},
    {scale = 1.0, influence = 0.8, octaves = 4, persistence = 0.3},
    {scale = 2.0, influence = 0.5, octaves = 6, persistence = 0.5},
    {scale = 8.0, influence = 0.45, octaves = 12, persistence = 0.8},
    {scale = 2.0, influence = 0.5, octaves = 6, persistence = 0.5},
    {scale = 8.0, influence = 0.45, octaves = 12, persistence = 0.8},
    {scale = 1.0, influence = 0.8, octaves = 4, persistence = 0.3},
    {scale = 8.0, influence = 0.5, octaves = 6, persistence = 0.8},
}

BIOME_COLORS :: []rl.Color {
    // OCEAN
    // rgb(133, 218, 255)
    {133, 218, 255, 255},
    
    // DESERT
    // rgb(246, 218, 167)
    {246, 218, 167, 255},
    
    // SAVANNAH
    // rgb(243, 167, 136)
    {243, 167, 136, 255},
    
    // TAIGA
    // rgb(141, 216, 148)
    {141, 216, 148, 255},
    
    // RAINFOREST
    // rgb(75, 185,163)
    {75, 185, 163, 255},
    
    // TUNDRA
    // rgb(200, 200, 200)
    {200, 200, 200, 255},
    
    // POLAR
    // rgb(220, 220, 240)
    {255,255,255, 255},
    
    // TEMPERATE FOREST
    // rgb(70, 140, 60)
    {93, 193, 144, 255},
    
    // MEDITERRANEAN
    // rgb(170, 190, 90)
    {170, 190, 90, 255},
    
    // STEPPE
    // rgb(180, 180, 120)
    {180, 180, 120, 255},
    
    // GRASSLAND
    // rgb(170, 210, 110)
    {170, 210, 110, 255},
    
    // MOUNTAIN
    // rgb(71, 61, 94)
    {71, 61, 94, 255},
    
    // SNOW_CAP
    // rgb(240, 240, 240)
    {240, 240, 240, 255},
}