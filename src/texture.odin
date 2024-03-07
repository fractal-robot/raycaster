package main

import "core:log"
import "core:strings"
import stbImage "vendor:stb/image"

// We need:
// - Load image to image struct 
// - Access a specific pixel of the texture

ATLAS_PATH :: "wolftextures.png"
TEXTURE_WIDTH :: 64
TEXTURE_HEIGHT :: 64
TEXTURE_ROW :: 8 // The number of textures per row in the texture altlas
TEXTURE_COL :: 1 // The number of textures per column in the texture altlas

Image :: struct {
	x:    i32,
	y:    i32,
	n:    i32,
	data: [^]u8,
}

Color :: distinct [3]u8

atlas := loadAtlas(ATLAS_PATH)

loadAtlas :: proc(imagePath: string) -> Image {
	image := Image{}
	path := strings.clone_to_cstring(imagePath)
	image.data = stbImage.load(path, &image.x, &image.y, &image.n, 0)
	assert(image.n == 3)
	if image.data == nil {
		log.errorf("[ERROR] stbImage.load failed.", stbImage.failure_reason())
	}
	return image
}

getPixel :: proc(image: Image, texRow, texCol, texX, texY: i32) -> Color {
	// sdb_image is row based 
	y: i32 = texRow * TEXTURE_WIDTH + texX
	x: i32 = texCol * TEXTURE_HEIGHT + texY

	pixelAddr: i32 = (x * image.x * image.n) + (y * image.n)

	color := Color {
		image.data[pixelAddr],
		image.data[pixelAddr + 1],
		image.data[pixelAddr + 2],
	}
	return color
}
