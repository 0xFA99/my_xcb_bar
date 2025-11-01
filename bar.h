#ifndef BAR_H
#define BAR_H

#include <xcb/xcb.h>

struct Bar {
    xcb_connection_t *XConnection;
    xcb_screen_t *XScreen;
    xcb_window_t XWindow;

    float x, y;
    float width, height;
    float border_width;

    uint32_t bg_color;
    uint32_t fg_color;

    int visible;
    char *title;
};

void bar_init(struct Bar *bar);
void bar_start(struct Bar *bar);
void bar_set_wm_hints(struct Bar *bar, xcb_window_t window);
void bar_destroy(struct Bar *bar);

#endif



#ifdef BAR_IMPLEMENTATION

#include <assert.h>
#include <stdlib.h>
#include <string.h>

void bar_init(struct Bar *bar) {
    assert(bar != NULL && "Bar pointer is NULL!");

    bar->XConnection = xcb_connect(NULL, NULL);
    assert(!xcb_connection_has_error(bar->XConnection) && "Display not found!");

    const xcb_setup_t *setup = xcb_get_setup(bar->XConnection);
    xcb_screen_iterator_t iter = xcb_setup_roots_iterator(setup);
    bar->XScreen = iter.data;

    // Default values
    bar->x = 0.0f;
    bar->y = 0.0f;
    bar->width  = 100.0f;
    bar->height = 30.0f;

    bar->bg_color = 0x181818;
    bar->fg_color = 0xf4f4f4;
    bar->visible = 1;
    bar->title = strdup("Title");
}


void bar_start(struct Bar *bar)
{
    assert(bar != NULL);
    assert(bar->XConnection != NULL);

    bar->XWindow = xcb_generate_id(bar->XConnection);

    uint32_t masks[] = { bar->XScreen->white_pixel, XCB_EVENT_MASK_EXPOSURE };

    xcb_create_window(bar->XConnection, XCB_COPY_FROM_PARENT,
                      bar->XWindow, bar->XScreen->root,
                      bar->x, bar->y, bar->width, bar->height, bar->border_width,
                      XCB_WINDOW_CLASS_INPUT_OUTPUT, bar->XScreen->root_visual,
                      XCB_CW_BACK_PIXEL | XCB_CW_EVENT_MASK,
                      masks);

    xcb_map_window(bar->XConnection, bar->XWindow);
    xcb_flush(bar->XConnection);
}


void bar_set_wm_hints(struct Bar *bar, xcb_window_t window)
{
    assert(bar != NULL);

    xcb_intern_atom_cookie_t cookie_wm_class =
        xcb_intern_atom(bar->XConnection, 0, strlen("WM_CLASS"), "WM_CLASS");

    xcb_intern_atom_reply_t *reply_wm_class =
        xcb_intern_atom_reply(bar->XConnection, cookie_wm_class, NULL);

    xcb_intern_atom_cookie_t cookie_net_wm_window_type =
        xcb_intern_atom(bar->XConnection, 0,
                strlen("_NET_WM_WINDOW_TYPE_DOCK"), "_NET_WM_WINDOW_TYPE_DOCK");

    xcb_intern_atom_reply_t *reply_net_wm_window_type =
        xcb_intern_atom_reply(bar->XConnection, cookie_net_wm_window_type, NULL);

    const char wm_class[] = "bar\0bar";
    xcb_change_property(bar->XConnection, XCB_PROP_MODE_REPLACE,
            window,
            reply_wm_class->atom,
            XCB_ATOM_STRING, 8,
            sizeof(wm_class), wm_class);

    xcb_intern_atom_cookie_t cookie_window_type =
        xcb_intern_atom(bar->XConnection, 0,
                strlen("_NET_WM_WINDOW_TYPE"), "_NET_WM_WINDOW_TYPE");

    xcb_intern_atom_reply_t *reply_window_type =
        xcb_intern_atom_reply(bar->XConnection, cookie_window_type, NULL);

    xcb_atom_t window_type_atoms[] = { reply_net_wm_window_type->atom };
    xcb_change_property(bar->XConnection, XCB_PROP_MODE_REPLACE,
            window, reply_window_type->atom, XCB_ATOM_ATOM, 32, 1, window_type_atoms);

    xcb_flush(bar->XConnection);

    free(reply_wm_class);
    free(reply_window_type);
    free(reply_net_wm_window_type);
}


void bar_destroy(struct Bar *bar) {
    assert(bar != NULL);
    assert(bar->XConnection != NULL);

    xcb_destroy_window(bar->XConnection, bar->XWindow);

    xcb_disconnect(bar->XConnection);
    bar->XConnection = NULL;
    bar->XScreen = NULL;
}

#endif

