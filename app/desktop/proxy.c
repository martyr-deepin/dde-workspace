#include <glib.h>
#include <gio/gio.h>


static void update_proxy_envs(GSettings* s)
{
#define AUTO_PROXY "auto_proxy"
#define HTTP_PROXY "http_proxy"
#define HTTPS_PROXY "https_proxy"
#define FTP_PROXY "ftp_proxy"
#define SOCKS_PROXY "socks_proxy"

#define NONE 0
#define MANUAL 1
#define AUTO 2
    switch (g_settings_get_enum(s, "proxy-method")) {
	case NONE:
	    {
		printf("SET None...\n");
		g_unsetenv(AUTO_PROXY);
		g_unsetenv(HTTP_PROXY);
		g_unsetenv(HTTPS_PROXY);
		g_unsetenv(FTP_PROXY);
		g_unsetenv(SOCKS_PROXY);
		break;
	    }
	case MANUAL:
	    {
		printf("SET MANUAL...\n");
		g_unsetenv(AUTO_PROXY);

		char* value = g_settings_get_string(s, "http-proxy");
		g_setenv(HTTP_PROXY, value, TRUE);
		g_free(value);

		value = g_settings_get_string(s, "https-proxy");
		g_setenv(HTTPS_PROXY, value, TRUE);
		g_free(value);

		value = g_settings_get_string(s, "ftp-proxy");
		g_setenv(FTP_PROXY, value, TRUE);
		g_free(value);

		value = g_settings_get_string(s, "socks-proxy");
		g_setenv(SOCKS_PROXY, value, TRUE);
		g_free(value);
		break;
	    }
	case AUTO:
	    {
		char* auto_proxy = g_settings_get_string(s, "auto-proxy");
		printf("SET Auto...%s\n", auto_proxy);
		g_setenv(AUTO_PROXY, auto_proxy, TRUE);
		g_free(auto_proxy);

		g_unsetenv(HTTP_PROXY);
		g_unsetenv(HTTPS_PROXY);
		g_unsetenv(FTP_PROXY);
		g_unsetenv(SOCKS_PROXY);
		break;
	    }
    }
}

void monitor_and_update_proxy()
{
    GSettings *s = g_settings_new("com.deepin.dde.proxy");
    g_signal_connect(s, "changed", G_CALLBACK(update_proxy_envs), NULL);
    update_proxy_envs(s);
}
