// ใช้ environment variables เท่านั้น
const char* get_api_key() {
    const char* key = getenv("GACP_API_KEY");
    if (!key) {
        log_fatal("API_KEY not set. Use secrets management");
        exit(EXIT_FAILURE);
    }
    return key;
}
