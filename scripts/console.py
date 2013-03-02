#!/usr/bin/python

import os
import pygame
import sys
import signal
from pygame.locals import *

return_code=0



pygame.display.init()
pygame.font.init()
pygame.mouse.set_visible(0)

size = (pygame.display.Info().current_w, pygame.display.Info().current_h)
screen = pygame.display.set_mode(size, pygame.FULLSCREEN)

# Fill background
background = pygame.Surface(screen.get_size())
background = background.convert()
background.fill((250, 250, 250))
scale = background.get_height()/float(1080)
if scale == 0:
    scale = 0.8
print "scale: ",scale


# Displsome text
fontbig = pygame.font.Font(None, int(120*scale))
textbig = fontbig.render("Relax, XBMC will resume shortly...", 1, (10, 10, 10))
textbigpos = textbig.get_rect(centerx=background.get_width()/2,centery=background.get_height()/2)
background.blit(textbig, textbigpos)
fontsmall = pygame.font.Font(None,int(50*scale))
textsmall = fontsmall.render("Press \"Esc\" key from the keyboard to access the terminal.",1,(10, 10, 10))
textsmallpos = textsmall.get_rect(centerx=background.get_width()/2,centery=background.get_height()/2+int(120*scale))


background.blit(textbig, textbigpos)
background.blit(textsmall, textsmallpos)

#screen
screen.blit(background, (0, 0))
pygame.display.flip()


class TimeoutException(Exception):
    pass

done = False

def timeout_handler(signum, frame):
    raise TimeoutException()
signal.signal(signal.SIGALRM, timeout_handler)
signal.alarm(int(sys.argv[1])) # triger alarm in 1 seconds

try:
    while not done:
        for event in pygame.event.get():
            if (event.type == KEYUP) or (event.type == KEYDOWN):
                if (event.key == K_ESCAPE):
                    return_code = 8
                    done = True
except TimeoutException:
    return_code = 9


pygame.display.quit()
sys.exit(return_code)
