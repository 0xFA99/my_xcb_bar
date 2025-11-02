
#define BAR_IMPLEMENTATION
#include "bar.h"

#include <unistd.h>

int main(void)
{
    struct Bar bar = {0};

    bar_init(&bar);
    bar.width = 1920;
    bar.height = 24;

    bar_create(&bar);

    pause();

    bar_destroy(&bar);
    return 0;
}
