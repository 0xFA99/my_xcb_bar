#!/bin/sh

cc *.c -o bar $(pkg-config --cflags --libs xcb)

