#ifndef RENDERER_H
#define RENDERER_H

#include "structs.h"
#include <SDL2/SDL.h>
#include <stdbool.h>

extern bool quit;
extern SDL_Renderer *renderer;
extern SDL_Event event;
extern SDL_Window *window;

void processKeyboard();
void putPixel(int x, int y, Color color);
void clearCanva();

#endif
