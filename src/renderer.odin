package main

import "core:fmt"
import "core:math"
import "vendor:sdl2"

render :: proc() {
	sdl2.LockSurface(ctx.framebuffer)
	defer sdl2.UnlockSurface(ctx.framebuffer)

	ptr: [^]u32 = transmute([^]u32)ctx.framebuffer.pixels

	cameraX: f32
	rayDir: Vec2
	mapPos: [2]int
	sideDist: Vec2
	deltaDist: Vec2
	perpWallDist: f32
	step: [2]int
	hit: bool
	side: int

	//////////////////////////////////////////////////////////////////////////////
	//// Vertical lines 

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
		if drawEnd >= WINDOW_HEIGHT do drawEnd = WINDOW_HEIGHT - 1

		texID: int = world[mapPos.x][mapPos.y] - 1 // ID starting at 0

		wallX: f32
		if side == 0 {
			wallX = p.pos.y + perpWallDist * rayDir.y
		} else {
			wallX = p.pos.x + perpWallDist * rayDir.x
		}
		wallX -= math.floor(wallX)

		texX := int(wallX * TEXTURE_WIDTH)
		// Eventually rotate the texture
		if side == 0 && rayDir.x > 0 do texX = TEXTURE_WIDTH - texX - 1
		if side == 1 && rayDir.y < 0 do texX = TEXTURE_WIDTH - texX - 1

		step: f32 = TEXTURE_HEIGHT / f32(lineHeight)
		texPos: f32 =
			(f32(drawStart) - WINDOW_HEIGHT / 2 + f32(lineHeight) / 2) * step


		for y in 0 ..< drawStart do ptr[y * WINDOW_WIDTH + x] = 0
		for y in drawEnd ..< WINDOW_HEIGHT do ptr[y * WINDOW_WIDTH + x] = 0

		for y in drawStart ..< drawEnd {
			color := getPixel(atlas, i32(texID), 0, i32(texX), i32(texPos))
			//			if side == 0 do color /= 2
			// sdl2.SetRenderDrawColor(ctx.renderer, color.r, color.g, color.b, 1)
			// sdl2.RenderDrawPoint(ctx.renderer, i32(x), i32(y))

			val: u32 = sdl2.MapRGB(
				ctx.framebuffer.format,
				color.r,
				color.g,
				color.b,
			)

			texPos += step

			bufferIndex := y * WINDOW_WIDTH + x - 1
			assert(bufferIndex < WINDOW_WIDTH * WINDOW_HEIGHT)

			ptr[y * WINDOW_WIDTH + x] = val
		}
	}

	//////////////////////////////////////////////////////////////////////////////
	//// Horizontal lines 

	leftRayDir: Vec2
	rightRayDir: Vec2
	floorStep: Vec2
	floor: Vec2
	cell: [2]int
	tex: [2]int

	for y in 0 ..< WINDOW_HEIGHT {
		leftRayDir = {p.dir.x - p.plane.x, p.dir.y - p.plane.y} // p.dir - p.plane
		rightRayDir = {p.dir.x + p.plane.x, p.dir.y + p.plane.y}

		yOffset: int = y - WINDOW_HEIGHT / 2 // From the center of the screen
		cameraPosZ: int = .5 * WINDOW_HEIGHT // Current Zposition of the camera 
		rowDistance: f32 = f32(cameraPosZ) / f32(yOffset)

		floorStep = rowDistance * rightRayDir - leftRayDir / WINDOW_WIDTH
		// floorStep.y remains constant isn't it, 0
		// Starting from the left 
		floor = p.pos + rowDistance * leftRayDir

		for x in 0 ..< WINDOW_WIDTH {
			cell = {int(floor.x), int(floor.y)}


			tex =  {
				int(TEXTURE_WIDTH * (floor.x - f32(cell.x))),
				int(TEXTURE_WIDTH * (floor.x - f32(cell.x))),
			}

			floor += floorStep

			floorTex := 3
			ceilingTex := 6
			color := getPixel(atlas, i32(floorTex), 0, i32(tex.x), i32(tex.y))
			val: u32 = sdl2.MapRGB(
				ctx.framebuffer.format,
				color.r,
				color.g,
				color.b,
			)
			ptr[y * WINDOW_WIDTH + x] = val


		}
	}
}
