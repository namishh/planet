package planet

import math "core:math"
import rl "vendor:raylib"

NoiseLayer :: struct {
    scale: f32,       
    influence: f32,   
    octaves: int,     
    persistence: f32,
}

fade :: proc(t: f32) -> f32 {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0)
}

lerp :: proc(t, a, b: f32) -> f32 {
    return a + t * (b - a)
}

grad :: proc(hash: int, x, y, z: f32) -> f32 {
    h := hash & 15
    u := h < 8 ? x : y
    v := h < 4 ? y : (h == 12 || h == 14 ? x : z)
    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
}

generate_permutation :: proc() -> [256]int {
    perm: [256]int
    for i in 0..<256 {
        perm[i] = i
    }
    for i in 0..<256 {
        j := rand_int_max(256)
        perm[i], perm[j] = perm[j], perm[i]
    }
    return perm
}

perlin :: proc(a, b, c: f32) -> f32 {
    p := make([]int, 512)
    defer delete(p)
    
    permutation := generate_permutation()
    
    for i := 0; i < 256; i += 1 {
        p[i] = permutation[i]
        p[i + 256] = permutation[i]
    }
    
    X := int(math.floor(a)) & 255
    Y := int(math.floor(b)) & 255
    Z := int(math.floor(c)) & 255
    
    x := a - math.floor(a)
    y := b - math.floor(b)
    z := c - math.floor(c)
    
    u := fade(x)
    v := fade(y)
    w := fade(z)
    
    A := p[X] + Y
    AA := p[A] + Z
    AB := p[A + 1] + Z
    B := p[X + 1] + Y
    BA := p[B] + Z
    BB := p[B + 1] + Z
    
    result := lerp(w, lerp(v, lerp(u, grad(p[AA], x, y, z),
                                      grad(p[BA], x-1, y, z)),
                              lerp(u, grad(p[AB], x, y-1, z),
                                      grad(p[BB], x-1, y-1, z))),
                      lerp(v, lerp(u, grad(p[AA+1], x, y, z-1),
                                      grad(p[BA+1], x-1, y, z-1)),
                              lerp(u, grad(p[AB+1], x, y-1, z-1),
                                      grad(p[BB+1], x-1, y-1, z-1))))
    
    return (result + 1.0) / 2.0
}

octave_noise :: proc(x, y, z: f32, octaves: int, persistence: f32) -> f32 {
    total := f32(0)
    frequency := f32(1)
    amplitude := f32(1)
    max_value := f32(0)
    
    for i := 0; i < octaves; i += 1 {
        total += perlin(x * frequency, y * frequency, z * frequency) * amplitude
        max_value += amplitude
        amplitude *= persistence
        frequency *= 2
    }
    
    return total / max_value
}

generate_noise_layer :: proc(layer: NoiseLayer, position: rl.Vector3) -> f32 {
    dir := normalize(position)
    
    n1 := octave_noise(dir.x * layer.scale, dir.y * layer.scale, dir.z * layer.scale, 
                      layer.octaves, layer.persistence)
    n2 := octave_noise(dir.z * layer.scale, dir.x * layer.scale, dir.y * layer.scale, 
                      layer.octaves, layer.persistence)
    n3 := octave_noise(dir.y * layer.scale, dir.z * layer.scale, dir.x * layer.scale, 
                      layer.octaves, layer.persistence)
    
    noise_value := (n1 + n2 + n3) / 3.0
    
    return (noise_value * 2.0 - 1.0) * layer.influence
}