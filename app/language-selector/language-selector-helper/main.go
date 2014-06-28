package main

import "fmt"
import "pkg.linuxdeepin.com/lib/dbus"
import "os"
import "os/exec"

type LanguageSelector struct {
}

func (*LanguageSelector) Set(lang string) {
	l, err := os.Create("/etc/default/locale")
	if err != nil {
		print("Can't open /etc/default/locale " + err.Error())
		return
	}
	defer l.Close()
	l.WriteString(fmt.Sprintf(`
	LANG="%s.UTF-8"
	LANGUAGE="%s"
	`, lang, lang))

	go func() {
		exec.Command("/usr/bin/locale-gen", lang).Run()
		exec.Command("/usr/bin/locale-gen").Run()
	}()
}

func (*LanguageSelector) GetDBusInfo() dbus.DBusInfo {
	return dbus.DBusInfo{
		"com.deepin.helper.LanguageSelector",
		"/com/deepin/helper/LanguageSelector",
		"com.deepin.helper.LanguageSelector",
	}
}

func main() {
	err := dbus.InstallOnSystem(&LanguageSelector{})
	if err != nil {
		print("Can't Init LanguageSelector DBus Servier: " + err.Error())
		return
	}
	dbus.DealWithUnhandledMessage()
	dbus.Wait()
}
