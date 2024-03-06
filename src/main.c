#include "config.h"
#include "definitions.h"
#include "sdl-interface.h"
#include "structs.h"
#include "world.h"
#include <SDL2/SDL_events.h>
#include <SDL2/SDL_keyboard.h>
#include <SDL2/SDL_render.h>
#include <SDL2/SDL_scancode.h>
#include <SDL2/SDL_stdinc.h>
#include <SDL2/SDL_timer.h>
#include <SDL2/SDL_video.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

SDL_Renderer *renderer;
SDL_Event event;
SDL_Window *window;

bool quit = false;

double posX = 22, posY = 12;
double dirX = -1, dirY = 0;
double planeX = 0, planeY = 0.66;

void render() {

  // double time = 0;
  // double oldTime = 0;

  for (int x = 0; x < WINDOW_WIDTH; ++x) {
    double cameraX =
        (double)2 * x / WINDOW_WIDTH - 1; // X coordinate of the ray, in
    // the range [-1, 1], 0 being at the center
    double rayDirX = dirX + planeX * cameraX;
    double rayDirY = dirY + planeY * cameraX; // Direction of the current ray

    int mapX = (int)posX;
    int mapY = (int)posY; // The current square the ray is in, starting at the
                          // player position

    double sideDistX;
    double sideDistY; // Initially the distance the ray has to travel from its
                      // start position to the first x-side and the first y-side

    double deltaDistX = fabs(1 / rayDirX);
    double deltaDistY = fabs(1 / rayDirY); // The distance the ray has to travel
                                           // to go to the next X and Y side

    double perpWallDist; // Calculate the length of the ray from the plane
                         // current X to the wall

    int stepX, stepY; // -1 if the ray direction has negative component, else 1

    bool hit = false;
    int side; // was a NS or a EW wall hit?

    if (rayDirX < 0)
      stepX = -1, sideDistX = (posX - mapX) * deltaDistX;
    else
      stepX = 1, sideDistX = (mapX + 1 - posX) * deltaDistX;
    if (rayDirY < 0)
      stepY = -1, sideDistY = (posY - mapY) * deltaDistY;
    else
      stepY = 1, sideDistY = (mapY + 1 - posY) * deltaDistY;

    while (hit == false) {
      if (sideDistX < sideDistY) {
        sideDistX += deltaDistX;
        mapX += stepX;
        side = 0;
      } else {
        sideDistY += deltaDistY;
        mapY += stepY;
        side = 1;
      }

      if (world[mapX][mapY] > 0)
        hit = true;

      if (side == 0)
        // The new deltaDist have already been applied at this stage.
        perpWallDist = (sideDistX - deltaDistX);
      else
        perpWallDist = (sideDistY - deltaDistY);
    }

    int lineHeight = WINDOW_HEIGHT / perpWallDist;
    int drawStart = -lineHeight / 2 + WINDOW_HEIGHT / 2;
    if (drawStart < 0)
      drawStart = 0;
    int drawEnd = lineHeight / 2 + WINDOW_HEIGHT / 2;
    if (drawEnd >= WINDOW_HEIGHT)
      drawEnd = WINDOW_HEIGHT - 1;

    Color color;
    switch (world[mapX][mapY]) {
    case 1:
      color = RED;
      break;
    case 2:
      color = BLUE;
      break;
    case 3:
      color = GREEN;
      break;
    case 4:
      color = YELLOW;
      break;
    case 0:
      color = BLACK;
      break;
    }

    if (side == 0) {
      color.red *= .6;
      color.green *= .6;
      color.blue *= .6;
    }

    SDL_SetRenderDrawColor(renderer, color.red, color.green, color.blue, 1);
    SDL_RenderDrawLine(renderer, x, drawStart, x, drawEnd);
  }
}

int main() {
  SDL_Init(SDL_INIT_VIDEO);
  SDL_CreateWindowAndRenderer(WINDOW_WIDTH, WINDOW_HEIGHT, 0, &window,
                              &renderer);
  const Uint8 *kbdState = SDL_GetKeyboardState(NULL);

  unsigned long long time = 0;
  unsigned long long oldTime = 0;

  while (quit == false) {
    oldTime = time;
    time = SDL_GetTicks();
    double frameTime = (float)(time - oldTime) / 1000;
    double moveSpeed = frameTime * 5;
    double rotSpeed = frameTime * 3;

    processKeyboard();

    SDL_PumpEvents();

    if (kbdState[SDL_SCANCODE_W]) {
      if (world[(int)(posX + dirX * moveSpeed)][(int)posY] == false)
        posX += dirX * moveSpeed;
      if (world[(int)posX][(int)(posY + dirY * moveSpeed)] == false)
        posY += dirY * moveSpeed;
    }
    if (kbdState[SDL_SCANCODE_S]) {
      if (world[(int)(posX - dirX * moveSpeed)][(int)posY] == false)
        posX -= dirX * moveSpeed;
      if (world[(int)posX][(int)(posY - dirY * moveSpeed)] == false)
        posY -= dirY * moveSpeed;
    }

    // New directions derived of a rotation matrix.
    if (kbdState[SDL_SCANCODE_D]) {
      double oldDirX = dirX;
      dirX = dirX * cos(-rotSpeed) - dirY * sin(-rotSpeed);
      dirY = oldDirX * sin(-rotSpeed) + dirY * cos(-rotSpeed);
      double oldPlaneX = planeX;
      planeX = planeX * cos(-rotSpeed) - planeY * sin(-rotSpeed);
      planeY = oldPlaneX * sin(-rotSpeed) + planeY * cos(-rotSpeed);
    }
    if (kbdState[SDL_SCANCODE_A]) {
      double oldDirX = dirX;
      dirX = dirX * cos(rotSpeed) - dirY * sin(rotSpeed);
      dirY = oldDirX * sin(rotSpeed) + dirY * cos(rotSpeed);
      double oldPlaneX = planeX;
      planeX = planeX * cos(rotSpeed) - planeY * sin(rotSpeed);
      planeY = oldPlaneX * sin(rotSpeed) + planeY * cos(rotSpeed);
    }

    clearCanva();
    render();
    SDL_RenderPresent(renderer);
  }

  return EXIT_SUCCESS;
}

// Check at every side of a wall the ray will encounter.
// Each square have width 1, so each side of a wall is an integer plus the
// places in between (DDA, /digital differential analysis/).
// -> Which square a line hits.
//
// The camera plane isn't really a plane, but a line, we also need to store
// the player position and the direction he is looking at.
