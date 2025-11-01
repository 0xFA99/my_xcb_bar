#include <stdio.h>

#define BAR_IMPLEMENTATION
#include "bar.h"

int main(void) {
    struct Bar mybar;

    bar_init(&mybar);
    bar_start(&mybar);
    bar_set_wm_hints(&mybar, mybar.XWindow);

    xcb_generic_event_t *event;
    while (event = xcb_wait_for_event(mybar.XConnection))
    {
        free(event);
    }

    bar_destroy(&mybar);

    return 0;
}

