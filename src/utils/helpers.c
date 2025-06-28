char* load_resource(const char* path) {
    FILE* fp = fopen(path, "r");
    if (!fp) return NULL;

    // Automatic cleanup with goto
    char* buffer = NULL;
    size_t len = 0;
    
    if (fseek(fp, 0, SEEK_END) != 0) goto cleanup;
    len = ftell(fp);
    rewind(fp);
    
    buffer = malloc(len + 1);
    if (!buffer) goto cleanup;
    
    if (fread(buffer, 1, len, fp) != len) {
        free(buffer);
        buffer = NULL;
    }

cleanup:
    fclose(fp);
    return buffer;
}
