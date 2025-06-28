#include <stdint.h>
#include "core/parser.h"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
    ParserContext ctx = {0};
    parse_data(&ctx, data, size);  // Auto-crash on error
    parser_cleanup(&ctx);
    return 0;
}
