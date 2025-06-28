// ใช้ Google's EXPECT macros สำหรับ precondition
#define EXPECT_NOT_NULL(ptr) if (!(ptr)) { \
    log_error("Null check failed: %s", #ptr); \
    return GACP_ERROR_INVALID_ARGS; \
}

GacpResult process_data(GacpContext* ctx) {
    EXPECT_NOT_NULL(ctx);
    // ... core logic
}
