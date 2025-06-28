#include <stdlib.h>

void process_data() {
    char *buffer = malloc(1024);
    if (!buffer) {
        // Error handling
        return;
    }

    // ใช้งาน buffer...

    // เปลี่ยนจาก: ไม่มี free
    // เป็น: มี cleanup แบบปลอดภัย
    free(buffer);
}
