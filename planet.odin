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