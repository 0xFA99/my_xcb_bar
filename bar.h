#ifndef BAR_H
#define BAR_H

#include <xcb/xcb.h>

struct Bar
{
    xcb_connection_t    *XConnection;
    xcb_screen_t        *XScreen;
    xcb_window_t         XWindow;

    int16_t     x, y;
    uint16_t    width, height;
    uint16_t    border_width;

    uint32_t    bg_color;
    uint32_t    fg_color;

    int  visible;
    char *title;
};

void bar_init(struct Bar *bar);
void bar_create(struct Bar *bar);
void bar_destroy(struct Bar *bar);

#endif

#ifdef BAR_IMPLEMENTATION

#include <assert.h>
#include <stdlib.h>
#include <string.h>

static xcb_atom_t get_atom(xcb_connection_t *connection, const char *name)
{
    xcb_intern_atom_cookie_t cookie = xcb_intern_atom(connection, 0, strlen(name), name);
    xcb_intern_atom_reply_t *reply = xcb_intern_atom_reply(connection, cookie, NULL);
    xcb_atom_t atom = reply ? reply->atom : XCB_ATOM_NONE;
    free(reply);

    return atom;
}

static void bar_set_wm_hints(struct Bar *bar)
{
    assert(bar && bar->XConnection);

    const char wm_class[] = "bar\0bar";
    xcb_change_property(
            bar->XConnection, XCB_PROP_MODE_REPLACE, bar->XWindow,
            XCB_ATOM_WM_CLASS, XCB_ATOM_STRING, 8, sizeof(wm_class), wm_class);

    xcb_atom_t net_wm_window_type = get_atom(bar->XConnection, "_NET_WM_WINDOW_TYPE");
    xcb_atom_t net_wm_window_type_dock = get_atom(bar->XConnection, "_NET_WM_WINDOW_TYPE_DOCK");

    xcb_change_property(
            bar->XConnection, XCB_PROP_MODE_REPLACE, bar->XWindow,
            net_wm_window_type, XCB_ATOM_STRING, 32, 1, &net_wm_window_type_dock);

    xcb_flush(bar->XConnection);
}

void bar_init(struct Bar *bar)
{
    assert(bar && "Bar tidak boleh NULL");

    bar->XConnection = xcb_connect(NULL, NULL);
    assert(!xcb_connection_has_error(bar->XConnection) && "Gagal connect ke X server");

    bar->XScreen = xcb_setup_roots_iterator(xcb_get_setup(bar->XConnection)).data;

    bar->x = 0;
    bar->y = 0;
    bar->width = 100;
    bar->height = 300;
    bar->border_width = 0;
    bar->bg_color = 0x181818;
    bar->fg_color = 0xfafafa;
    bar->visible = 1;
    bar->title = strdup("Bar");
}

void bar_create(struct Bar *bar)
{
    assert(bar && bar->XConnection);

    bar->XWindow = xcb_generate_id(bar->XConnection);

    uint32_t bar_masks[] = {
        bar->bg_color,
        XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_BUTTON_PRESS
    };

    xcb_create_window(
            bar->XConnection, XCB_COPY_FROM_PARENT, bar->XWindow, bar->XScreen->root,
            bar->x, bar->y, bar->width, bar->height, bar->border_width, XCB_WINDOW_CLASS_INPUT_OUTPUT,
            bar->XScreen->root_visual, XCB_CW_BACK_PIXEL | XCB_CW_EVENT_MASK,
            bar_masks);

    bar_set_wm_hints(bar);

    xcb_map_window(bar->XConnection, bar->XWindow);
    xcb_flush(bar->XConnection);
}

void bar_destroy(struct Bar *bar)
{
    if (!bar) return;

    if (bar->title) {
        free(bar->title);
        bar->title = NULL;
    }

    if (bar->XConnection) {
        if (bar->XWindow) xcb_destroy_window(bar->XConnection, bar->XWindow);
        xcb_disconnect(bar->XConnection);
        bar->XConnection = NULL;
    }

    bar->XScreen = NULL;
}

#endif

