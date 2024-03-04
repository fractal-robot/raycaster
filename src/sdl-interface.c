#include "sdl-interface.h"
#include "config.h"
#include "structs.h"
#include <SDL2/SDL.h>
#include <assert.h>
#include <stdbool.h>

void processKeyboard() {
  while (SDL_PollEvent(&event) != 0) {
    switch (event.type) {
    case SDL_QUIT:
      quit = true;
      break;
    }
  }
}

void putPixel(int x, int y, Color color) {
  assert(x >= 0 && y >= 0 && x <= WINDOW_WIDTH && y <= WINDOW_HEIGHT);
  SDL_SetRenderDrawColor(renderer, color.red, color.green, color.blue, 1);
  SDL_RenderDrawPoint(renderer, x, y);
}

void clearCanva() {
  SDL_SetRenderDrawColor(renderer, 0, 0, 0, 1);
  SDL_RenderClear(renderer);
}
