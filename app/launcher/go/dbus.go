package main

import (
	// "fmt"
	"os"
	"path"
	"time"

	"github.com/howeyc/fsnotify"

	"dlib/dbus"
	"dlib/gio-2.0"
	"dlib/glib-2.0"
)

const (
	launcherObject            string = "com.deepin.dde.daemon.Launcher"
	launcherPath              string = "/com/deepin/dde/daemon/Launcher"
	launcherInterface         string = launcherObject
	launcherCategoryInterface string = launcherObject + ".category"
	launcherConfigInterface   string = launcherObject + ".config"

	AppDirName     string      = "applications"
	DirDefaultPerm os.FileMode = 775
)

type ItemChangedStatus struct {
	renamed, created, notRenamed, notCreated chan bool
}

type LauncherDBus struct {
	ItemChanged func(
		status string,
		itemInfo ItemInfo,
		categoryIds []CategoryId,
	)
}

func (d *LauncherDBus) GetDBusInfo() dbus.DBusInfo {
	return dbus.DBusInfo{
		launcherObject,
		launcherPath,
		launcherInterface,
	}
}

func (d *LauncherDBus) CategoryInfos() CategoryInfosResult {
	return getCategoryInfos()
}

func (d *LauncherDBus) ItemInfos(id int32) []ItemInfo {
	return getItemInfos(CategoryId(id))
}

func (d *LauncherDBus) emitItemChanged(name, status string, info map[string]ItemChangedStatus) {
	id := genId(name)

	if status != "delete" {
		itemTable[id] = &ItemInfo{}
		app := gio.NewDesktopAppInfoFromFilename(name)
		itemTable[id].init(app)
		app.Unref()
	}
	d.ItemChanged(status, *itemTable[id], itemTable[id].getCategoryIds())

	if status == "delete" {
		delete(itemTable, id)
	}
	delete(info, name)
}

func (d *LauncherDBus) itemChangedHandler(ev *fsnotify.FileEvent, name string, info map[string]ItemChangedStatus) {
	// fmt.Println(ev)
	if ev.IsRename() {
		select {
		case <-info[name].renamed:
		default:
		}
		info[name].renamed <- true
		go func() {
			select {
			case <-info[name].notRenamed:
				return
			case <-time.After(time.Second):
				<-info[name].renamed
				d.emitItemChanged(name, "deleted", info)
				// fmt.Println("deleted")
			}
		}()
	} else if ev.IsCreate() {
		info[name].created <- true
		go func() {
			select {
			case <-info[name].renamed:
				info[name].notRenamed <- true
				info[name].renamed <- true
			default:
			}
			select {
			case <-info[name].notCreated:
				return
			case <-time.After(time.Second):
				<-info[name].created
				d.emitItemChanged(name, "added", info)
				// fmt.Println("create added")
			}
		}()
	} else if ev.IsModify() && !ev.IsAttrib() {
		go func() {
			select {
			case <-info[name].created:
				info[name].notCreated <- true
			}
			select {
			case <-info[name].renamed:
				// fmt.Println("modified")
				d.emitItemChanged(name, "modified", info)
			default:
				d.emitItemChanged(name, "added", info)
				// fmt.Println("modify added")
			}
		}()
	} else if ev.IsAttrib() {
		go func() {
			select {
			case <-info[name].renamed:
				<-info[name].created
				info[name].notCreated <- true
			default:
			}
		}()
	} else if ev.IsDelete() {
		d.emitItemChanged(name, "deleted", info)
		// fmt.Println("deleted")
	}
}

func (d *LauncherDBus) eventHandler(watcher *fsnotify.Watcher) {
	var info = map[string]ItemChangedStatus{}
	for {
		select {
		case ev := <-watcher.Event:
			name := path.Clean(ev.Name)
			basename := path.Base(name)
			matched, _ := path.Match(`[^#.]*.desktop`, basename)
			if matched {
				d.itemChangedHandler(ev, name, info)
			}
		case <-watcher.Error:
		}
	}
}

func getApplicationsDirs() []string {
	dirs := make([]string, 0)
	dataDirs := glib.GetSystemDataDirs()
	for _, dir := range dataDirs {
		applicationsDir := path.Join(dir, AppDirName)
		if exist(applicationsDir) {
			dirs = append(dirs, applicationsDir)
		}
	}

	userDataDir := path.Join(glib.GetUserDataDir(), AppDirName)
	dirs = append(dirs, userDataDir)
	if !exist(userDataDir) {
		os.MkdirAll(userDataDir, DirDefaultPerm)
	}
	return dirs
}

func (d *LauncherDBus) listenItemChanged() {
	dirs := getApplicationsDirs()
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		return
	}
	// FIXME: close watcher.
	for _, dir := range dirs {
		watcher.Watch(dir)
	}

	go d.eventHandler(watcher)
}

func (d *LauncherDBus) Search(key string) []ItemId {
	return search(key)
}

func (d *LauncherDBus) IsOnDesktop(name string) bool {
	return isOnDesktop(name)
}

func (d *LauncherDBus) SendToDesktop(name string) {
	sendToDesktop(name)
}

func (d *LauncherDBus) LoadHiddenApps() []ItemId {
	return getHiddenApps()
}

func (d *LauncherDBus) SaveHiddenApps(ids []string) bool {
	return saveHiddenApps(ids)
}

func (d *LauncherDBus) GetFavors() FavorItemList {
	return getFavors()
}

func (d *LauncherDBus) SaveFavors(items FavorItemList) bool {
	return saveFavors(items)
}

func initDBus() {
	launcherDbus := LauncherDBus{}
	dbus.InstallOnSession(&launcherDbus)
	launcherDbus.listenItemChanged()
}
