#include <check.h>
#include "core/gacp.h"

START_TEST(test_null_safety) {
    ck_assert_int_eq(process_data(NULL), GACP_ERROR_INVALID_ARGS);
}
END_TEST

TCase* create_core_tests() {
    TCase* tc = tcase_create("Core");
    tcase_add_test(tc, test_null_safety);
    return tc;
}
