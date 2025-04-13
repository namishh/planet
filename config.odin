package planet

DEBUG_MODE :: false
DRAW_ROTATION_LINE :: false

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
MOUNTAIN_THRESHOLD :: 0.69
WATER_THRESHOLD :: 0.35
SNOW_CAP :: 0.95

NOISE_LAYERS :: []NoiseLayer{
    {scale = 1.0, influence = 0.3, octaves = 4, persistence = 0.7},
    {scale = 3.0, influence = 0.15, octaves = 6, persistence = 0.5},
    {scale = 8.0, influence = 0.05, octaves = 2, persistence = 0.8},
    {scale = 8.0, influence = 0.45, octaves = 12, persistence = 0.8},
}

// CLIMATE CONFIGS
EQUATOR_TEMP :: 1.5
POLE_TEMP :: 0.0
ALTITUDE_TEMP_FACTOR :: 0.2 // how much temperature decreases with altitude
COASTAL_PRECIP_BONUS :: 0.5 // bonus precipitation for coastal regions
MOUNTAIN_PRECIP_BONUS :: 0.45 // bonus precipitation for regions near mountains
LATITUDE_SCALE :: 1.0


CLIMATE_LAYERS :: []NoiseLayer{
    {scale = 1.0, influence = 0.3, octaves = 4, persistence = 0.5},
    {scale = 1.0, influence = 0.8, octaves = 4, persistence = 0.3},
    {scale = 2.0, influence = 0.5, octaves = 6, persistence = 0.5},
    {scale = 8.0, influence = 0.45, octaves = 12, persistence = 0.8},
    {scale = 8.0, influence = 0.5, octaves = 6, persistence = 0.8},
}