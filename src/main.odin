package main

import "core:fmt"
import "core:log"
import "core:math"
import "core:os"
import "core:strings"
import "vendor:sdl2"
import sdlImg "vendor:sdl2/image"

WINDOW_WIDTH :: 1024
WINDOW_HEIGHT :: 1024
WINDOW_TITLE :: "window"
WINDOW_FLAGS :: sdl2.WindowFlags{.SHOWN}

CTX :: struct {
	window:      ^sdl2.Window,
	renderer:    ^sdl2.Renderer,
	framebuffer: ^sdl2.Surface,
	event:       sdl2.Event,
	keyboard:    []u8,
	textures:    [dynamic]^sdl2.Texture,
	shouldClose: bool,
}
ctx := CTX{}

Vec2 :: distinct [2]f32

Player :: struct {
	pos:   Vec2,
	dir:   Vec2,
	plane: Vec2,
}
p := Player {
	pos   = {22, 12},
	dir   = {-1, 0},
	plane = {0, 0.66},
}

////////////////////////////////////////////////////////////////////////////////

init_sdl :: proc() -> (ok: bool) {
	if sdlRes := sdl2.Init(sdl2.INIT_VIDEO); sdlRes < 0 {
		log.errorf("[ERROR] sdl2.Init returned %v.", sdlRes)
		return false
	}

	ctx.window = sdl2.CreateWindow(
		WINDOW_TITLE,
		sdl2.WINDOWPOS_CENTERED,
		sdl2.WINDOWPOS_CENTERED,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		WINDOW_FLAGS,
	)
	if ctx.window == nil {
		log.errorf("[ERROR] sdl2.CreateWindow failed.")
		return false
	}

	ctx.renderer = sdl2.CreateRenderer(ctx.window, -1, {.ACCELERATED})
	if ctx.renderer == nil {
		log.errorf("[ERROR] sdl2.CreateRenderer failed.")
		return false
	}

	ctx.keyboard = sdl2.GetKeyboardStateAsSlice()
	if ctx.keyboard == nil {
		log.errorf("[ERROR] sdl2.GetKeyboardState failed.")
		return false
	}

	ctx.framebuffer = sdl2.GetWindowSurface(ctx.window)
	if ctx.framebuffer == nil {
		log.errorf("[ERROR] sdl2.GetWindowSurface failed.")
		return false
	}

	return true
}

////////////////////////////////////////////////////////////////////////////////

get_time :: proc() -> f64 {
	return(
		f64(sdl2.GetPerformanceCounter()) *
		1000 /
		f64(sdl2.GetPerformanceFrequency()) \
	)
}

processKeyboard :: proc() {
	for sdl2.PollEvent(&ctx.event) {
		#partial switch ctx.event.type {
		case .QUIT:
			ctx.shouldClose = true
			return
		case .KEYDOWN:
			#partial switch (ctx.event.key.keysym.sym) {
			case .ESCAPE:
				ctx.shouldClose = true
			}
		}
	}
}

processMovements :: proc(frameTime: f32) {
	moveSpeed := frameTime * 5
	rotSpeed := frameTime * 3

	sdl2.PumpEvents()

	if b8(ctx.keyboard[sdl2.SCANCODE_W]) {
		if world[int(p.pos.x + p.dir.x * moveSpeed)][int(p.pos.y)] == 0 {
			p.pos.x += p.dir.x * moveSpeed
		}
		if world[int(p.pos.x)][int(p.pos.y + p.dir.y * moveSpeed)] == 0 {
			p.pos.y += p.dir.y * moveSpeed
		}
	}
	if b8(ctx.keyboard[sdl2.SCANCODE_S]) {
		if world[int(p.pos.x - p.dir.x * moveSpeed)][int(p.pos.y)] == 0 {
			p.pos.x -= p.dir.x * moveSpeed
		}
		if world[int(p.pos.x)][int(p.pos.y - p.dir.y * moveSpeed)] == 0 {
			p.pos.y -= p.dir.y * moveSpeed
		}
	}


	if b8(ctx.keyboard[sdl2.SCANCODE_A]) {
		rotation := matrix[2, 2]f32{
			math.cos(-rotSpeed), -math.sin(-rotSpeed), 
			math.sin(-rotSpeed), math.cos(-rotSpeed), 
		}
		p.dir *= rotation
		p.plane *= rotation

	}

	if b8(ctx.keyboard[sdl2.SCANCODE_D]) {
		rotation := matrix[2, 2]f32{
			math.cos(rotSpeed), -math.sin(rotSpeed), 
			math.sin(rotSpeed), math.cos(rotSpeed), 
		}
		p.dir *= rotation
		p.plane *= rotation
	}
}

////////////////////////////////////////////////////////////////////////////////

clearCanva :: proc() {
	sdl2.SetRenderDrawColor(ctx.renderer, 0, 0, 0, 1)
	sdl2.RenderClear(ctx.renderer)
}

/*
setWindowSurfacePixel :: proc(x, y: int, color: Color) {
	pixel: ^u8 = u8^(&ctx.framebuffer.pixels)
	pixel[4] = 255

}
*/


main :: proc() {
	context.logger = log.create_console_logger()

	if res := init_sdl(); !res {
		log.errorf("[ERROR] Initialization failed.")
		os.exit(1)
	}

	time: u32
	oldTime: u32


	for ctx.shouldClose == false {
		oldTime = time
		time = sdl2.GetTicks()
		frameTime := f32(time - oldTime) / 1000

		processKeyboard()
		processMovements(frameTime)

		clearCanva()
		render()
		sdl2.UpdateWindowSurface(ctx.window)
	}
}
