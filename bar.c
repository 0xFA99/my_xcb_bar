#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <xcb/xcb.h>

int main(void)
{
    // Connect ke X server
    xcb_connection_t *conn = xcb_connect(NULL, NULL);
    assert(!xcb_connection_has_error(conn));

    // Setup screen
    const xcb_setup_t *setup = xcb_get_setup(conn);
    xcb_screen_iterator_t iter = xcb_setup_roots_iterator(setup);
    xcb_screen_t *screen = iter.data;

    // Create window
    xcb_window_t win = xcb_generate_id(conn);

    uint32_t values[] = {
        screen->white_pixel,
        XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_KEY_PRESS
    };

    xcb_create_window(
        conn,
        XCB_COPY_FROM_PARENT,
        win,
        screen->root,
        0, 0,
        800, 450,
        4,
        XCB_WINDOW_CLASS_INPUT_OUTPUT,
        screen->root_visual,
        XCB_CW_BACK_PIXEL | XCB_CW_EVENT_MASK,
        values
    );

    // Map window
    xcb_map_window(conn, win);
    xcb_flush(conn);

    // Event loop
    xcb_generic_event_t *event;
    while (event = xcb_wait_for_event(conn)) {
        uint8_t type = event->response_type & ~0x80;

        switch (type) {
            case XCB_EXPOSE: printf("Redraw\n"); break;
            case XCB_KEY_PRESS: printf("Key pressed\n"); break;
        }

        free(event);
    }

    xcb_destroy_window(conn, win);
    xcb_disconnect(conn);
    return 0;
}

