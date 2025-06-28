#include <string.h>
#include <stdlib.h>

// เปลี่ยนจาก: strcpy ที่อันตราย
// char* unsafe_copy(char* dest, const char* src) {
//   return strcpy(dest, src);
// }

// เป็น: ฟังก์ชันปลอดภัย
char* safe_copy(const char* src) {
    if (!src) return NULL;
    
    size_t len = strlen(src) + 1;
    char* dest = malloc(len);
    if (dest) {
        strncpy(dest, src, len);
        dest[len-1] = '\0'; // รับประกัน null-terminated
    }
    return dest;
}
