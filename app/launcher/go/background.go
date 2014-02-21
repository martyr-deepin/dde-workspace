package main

import (
	"dlib/gio-2.0"
	"fmt"
)

const (
	BackgroundSchemaID      string = "com.deepin.dde.personalization"
	CurrentBackground       string = "current-picture"
	BackgroundChangedSignal string = "changed::current-picture"
)

type Background struct {
	settings *gio.Settings
}

type CallbackFunc func(setting *gio.Settings, key string, userdata string)

func (b *Background) ConnectSignal(signalName string, fn CallbackFunc) {
	b.settings.Connect(signalName, fn)
}

func (b *Background) Current() string {
	return b.settings.GetString(CurrentBackground)
}

func (b *Background) SetBackground(uri string) bool {
	if b == nil {
		fmt.Println("b wrong")
		return false
	}
	if b.settings == nil {
		fmt.Println("s wrong")
		return false
	}
	return b.settings.SetString(CurrentBackground, uri)
}

func (b *Background) Destroy() {
	b.settings.Unref()
}

func NewBackground() *Background {
	b := &Background{gio.NewSettings(BackgroundSchemaID)}
	return b
}
