package main

import (
	"fmt"
)

const (
	HiddenAppsConf      string = "launcher/apps.ini"
	HiddenAppsGroupName string = "HiddenApps"
	HiddenAppsKeyName   string = "app_ids"
)

func unique(l []string) []string {
	s := make(map[string]bool, 0)
	for _, k := range l {
		s[k] = true
	}

	u := make([]string, 0)
	for k, _ := range s {
		u = append(u, k)
	}
	return u
}

func getHiddenApps() []ItemId {
	file, err := configFile(HiddenAppsConf)
	if err != nil {
		fmt.Println(err)
	}
	defer file.Free()

	ids := make([]ItemId, 0)
	_, list, err := file.GetStringList(HiddenAppsGroupName,
		HiddenAppsKeyName)
	if err != nil {
		return ids
	}
	for _, id := range unique(list) {
		ids = append(ids, ItemId(id))
	}
	return ids
}

func saveHiddenApps(ids []string) bool {
	file, err := configFile(HiddenAppsConf)
	if err != nil {
		fmt.Println(err)
	}
	defer file.Free()
	file.SetStringList(HiddenAppsGroupName, HiddenAppsKeyName, unique(ids))
	saveKeyFile(file, configFilePath(HiddenAppsConf))
	return true
}
