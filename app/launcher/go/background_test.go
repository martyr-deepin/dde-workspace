package main

import (
	"testing"
	"time"

	"dlib/gio-2.0"
)

func TestBackgroundChanged(t *testing.T) {
	b := NewBackground()
	defer b.Destroy()
	b.ConnectSignal(
		BackgroundChangedSignal,
		func(setting *gio.Settings, key string, userdata string) {
			t.Log("background changed")
		},
	)
	pre := b.Current()
	b.SetBackground("file:///usr/share/backgrounds/default_background.jpg")
	select {
	case <-time.After(time.Second * 1):
		b.SetBackground(pre)
	}
	select {
	case <-time.After(time.Second * 1):
	}
}
