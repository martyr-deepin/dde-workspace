package main

import (
	"os"
	"testing"

	"dbus/com/deepin/api/pinyin"
	"dlib/gio-2.0"
)

func TestGetMatchers(t *testing.T) {
	for k, v := range getMatchers("chrome") {
		t.Log(k.String(), v)
	}
}

func TestSearch(t *testing.T) {
	r := search("chome")
	for _, id := range r {
		item := itemTable[id]
		t.Logf(`id: %s
		Name: %s
		Path: %s
		keywords: %v
		GenericName: %s
		Description: %s
		Exec: %s
		`, id, item.Name, item.Path, item.xinfo.keywords,
			item.xinfo.genericName, item.xinfo.description,
			item.xinfo.exec)
	}
}

func TestPinYin(t *testing.T) {
	tree, err := pinyin.NewPinyinTrie("/com/deepin/dde/api/PinyinTrie")
	if err != nil {
		return
	}
	names := make(map[string]string, 0)
	os.Setenv("LANGUAGE", "zh_CN.UTF-8")
	addName := func(m map[string]string, n string) {
		app := gio.NewDesktopAppInfo(n)
		defer app.Unref()
		name := app.GetDisplayName()
		t.Log(name)
		m[name] = name
	}
	addName(names, "deepin-software-center.desktop")
	addName(names, "firefox.desktop")
	t.Log(names)
	treeId, _ := tree.NewTrieWithString(names, "DDELauncherDaemonTest")
	var keys []string
	keys, _ = tree.SearchKeys("ruan", treeId)
	t.Log(keys)
	keys, _ = tree.SearchKeys("firefox", treeId)
	t.Log(keys)
	keys, _ = tree.SearchKeys("wang", treeId)
	t.Log(keys)
	keys, _ = tree.SearchKeys("网络", treeId)
	t.Log(keys)
	tree.DestroyTrie(treeId)
}
