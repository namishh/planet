package planet

// VERTICE_DISPLACEMENT :: 0.025
// SUBDIVISIONS :: 4
VERTICE_DISPLACEMENT :: 0.012
HEIGHT_DISPLACEMENT :: 0.08
SUBDIVISIONS :: 5
DRAW_BORDERS :: false
PLANET_RADIUS :: 5.0
CONTINENTS :: 64
TILT :: 23.5
CONTINENTAL_TO_OCEANIC_RATIO :: 0.3
MOUNTAIN_THRESHOLD :: 0.69
WATER_THRESHOLD :: 0.4

NOISE_LAYERS :: []NoiseLayer{
    {scale = 1.0, influence = 0.3, octaves = 4, persistence = 0.5},
    {scale = 3.0, influence = 0.15, octaves = 6, persistence = 0.5},
    {scale = 8.0, influence = 0.05, octaves = 2, persistence = 0.5},
}