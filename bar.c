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
        XCB_EVENT_MASK_EXPOSURE     | XCB_EVENT_MASK_POINTER_MOTION |
        XCB_EVENT_MASK_BUTTON_PRESS | XCB_EVENT_MASK_BUTTON_RELEASE |
        XCB_EVENT_MASK_ENTER_WINDOW | XCB_EVENT_MASK_LEAVE_WINDOW   |
        XCB_EVENT_MASK_KEY_PRESS    | XCB_EVENT_MASK_KEY_RELEASE
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

            case XCB_KEY_PRESS:
            case XCB_KEY_RELEASE:
            {
                xcb_key_press_event_t *key = (xcb_key_press_event_t *)event;
                const char *action = (type == XCB_KEY_PRESS) ? "Pressed" : "Release";

                printf("Key %d %s\n", key->detail, action);
            } break;

            case XCB_BUTTON_PRESS:
            case XCB_BUTTON_RELEASE:
            {
                xcb_button_press_event_t *btn = (xcb_button_press_event_t *)event;
                const char *action = (type == XCB_BUTTON_PRESS) ? "Pressed" : "Released";

                switch (btn->detail)
                {
                    case 1:
                        printf("Left Click %s at (%d, %d)\n", action, btn->event_x, btn->event_y);
                    break;

                    case 2:
                        printf("Middle Click %s at (%d, %d)\n", action, btn->event_x, btn->event_y);
                    break;

                    case 3:
                        printf("Right Click %s at (%d, %d)\n", action, btn->event_x, btn->event_y);
                    break;

                    case 4:
                        printf("Scroll Up %s at (%d, %d)\n", action, btn->event_x, btn->event_y);
                    break;

                    case 5:
                        printf("Scroll Down %s at (%d, %d)\n", action, btn->event_x, btn->event_y);
                    break;
                }
            } break;

            case XCB_ENTER_NOTIFY:
            case XCB_LEAVE_NOTIFY:
            {
                xcb_enter_notify_event_t *enter = (xcb_enter_notify_event_t *)event;
                const char *action = (type == XCB_ENTER_NOTIFY) ? "entered" : "leave";

                printf("Mouse %s window at (%d, %d)\n", action, enter->event_x, enter->event_y);
            } break;

            case XCB_MOTION_NOTIFY:
            {
                xcb_motion_notify_event_t *motion = (xcb_motion_notify_event_t *)event;

                printf("Mouse moved at (%d, %d)\n", motion->event_x, motion->event_y);
            } break;
        }

        free(event);
    }

    xcb_destroy_window(conn, win);
    xcb_disconnect(conn);
    return 0;
}

