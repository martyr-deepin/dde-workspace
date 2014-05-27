#include "desktop_test.h"
void test_lib_utils()
{
	setup_fixture();

	extern char* dcore_gen_id(const char* seed);
	const char* dcore_gettext(const char* c);
	const char* dcore_dgettext(char const* domain, char const* s);
	void dcore_bindtextdomain(char const* domain, char const* mo_file);

    Test({
        char* c = dcore_gen_id("1000");
        g_free(c);
    }, "dcore_gen_id");


    Test({
        const char* c G_GNUC_UNUSED = dcore_gettext("1000");
        // g_free(c);
    }, "dcore_gettext");

    tear_down_fixture();

}

