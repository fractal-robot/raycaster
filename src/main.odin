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

TEXTURE_WIDTH :: 64
TEXTURE_HEIGHT :: 64
ATLAS_PATH :: "wolftextures.png"

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
Color :: [3]u8

Player :: struct {
	pos:   [2]f32,
	dir:   [2]f32,
	plane: [2]f32,
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

	initRessources :: proc(imagePath: string) -> (ok: bool) {
		path := strings.clone_to_cstring(imagePath)
		texture := sdlImg.LoadTexture(ctx.renderer, path)
		if texture == nil {
			log.errorf("[ERROR] sdlImg.LoadTexture failed %v", imagePath)
			return false
		}
		append(&ctx.textures, texture)
		return true
	}

	initRessources(ATLAS_PATH)

	return true
}

////////////////////////////////////////////////////////////////////////////////

blit :: proc(texture: ^sdl2.Texture, x, y: i32, textureSelector: i32) {
	dest: sdl2.Rect
	dest.x = x
	dest.y = y
	dest.h = TEXTURE_HEIGHT
	dest.w = TEXTURE_WIDTH

	textureCoord: sdl2.Rect
	textureCoord.x = textureSelector * i32(TEXTURE_WIDTH)
	textureCoord.w = TEXTURE_WIDTH
	textureCoord.h = TEXTURE_HEIGHT

	// sdl2.QueryTexture(texture, nil, nil, &dest.w, &dest.h)
	sdl2.RenderCopy(ctx.renderer, texture, &textureCoord, &dest)
}

get_time :: proc() -> f64 {
	return(
		f64(sdl2.GetPerformanceCounter()) *
		1000 /
		f64(sdl2.GetPerformanceFrequency()) \
	)
}


render :: proc() {
	cameraX: f32
	rayDir: Vec2
	mapPos: [2]int
	sideDist: Vec2
	deltaDist: Vec2
	perpWallDist: f32
	step: [2]int
	hit: bool
	side: int

	for x in 0 ..< WINDOW_WIDTH {


		hit = false

		// Range [-1, 1]
		cameraX = 2 * f32(x) / WINDOW_WIDTH - 1

		// The direction of the current ray 
		rayDir.x = p.dir.x + p.plane.x * cameraX
		rayDir.y = p.dir.y + p.plane.y * cameraX

		// Current square the ray is in
		mapPos.x = int(p.pos.x)
		mapPos.y = int(p.pos.y)

		// The distance the ray has to travel to go to the next X and Y side
		deltaDist.x = abs(1 / rayDir.x)
		deltaDist.y = abs(1 / rayDir.y)

		// sideDist is the distance they ray has to travel to go to next X and Y
		if rayDir.x < 0 {
			step.x = -1
			sideDist.x = (p.pos.x - f32(mapPos.x)) * deltaDist.x
		} else {
			step.x = 1
			sideDist.x = (f32(mapPos.x) + 1 - p.pos.x) * deltaDist.x
		}
		if (rayDir.y < 0) {
			step.y = -1
			sideDist.y = (p.pos.y - f32(mapPos.y)) * deltaDist.y
		} else {
			step.y = 1
			sideDist.y = (f32(mapPos.y) + 1 - p.pos.y) * deltaDist.y
		}

		for hit == false {
			if sideDist.x < sideDist.y {
				sideDist.x += deltaDist.x
				mapPos.x += step.x
				side = 0
			} else {
				sideDist.y += deltaDist.y
				mapPos.y += step.y
				side = 1
			}

			if world[mapPos.x][mapPos.y] > 0 do hit = true

			if side == 0 {
				perpWallDist = sideDist.x - deltaDist.x
			} else {
				perpWallDist = sideDist.y - deltaDist.y
			}
		}

		lineHeight := int(WINDOW_HEIGHT / perpWallDist)

		drawStart: int = -lineHeight / 2 + WINDOW_HEIGHT / 2
		if drawStart < 0 do drawStart = 0

		drawEnd: int = lineHeight / 2 + WINDOW_HEIGHT / 2
		if drawStart >= WINDOW_HEIGHT do drawStart = WINDOW_HEIGHT - 1

		color: Color
		switch world[mapPos.x][mapPos.y] {
		case 1:
			color = {255, 0, 0}
		case 2:
			color = {0, 255, 0}
		case 3:
			color = {0, 0, 255}
		case 4:
			color = {0, 255, 255}
		case 5:
			color = {255, 255, 0}

		case:
			fmt.println(
				"[ERROR] Missing descriptor for wall type ",
				world[mapPos.x][mapPos.y],
			)
		}

		if side == 0 do color /= 2

		sdl2.SetRenderDrawColor(ctx.renderer, color.r, color.g, color.b, 1)
		sdl2.RenderDrawLine(
			ctx.renderer,
			i32(x),
			i32(drawStart),
			i32(x),
			i32(drawEnd),
		)

	}
}

////////////////////////////////////////////////////////////////////////////////

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
		blit(ctx.textures[0], WINDOW_WIDTH / 2, WINDOW_HEIGHT / 2, 3)
		sdl2.RenderPresent(ctx.renderer)
		// sdl2.UpdateWindowSurface(ctx.window)


	}
}
