include ../../common/js/Makefile

plugin_dir=plugins
all: ${com_coffee} \
	global.coffee\
	dragtarget.coffee\
	config.coffee \
	utils.coffee\
	switcher.coffee\
	region.coffee\
	hide_status.coffee\
	settings.coffee\
	global_menu.coffee\
	docked_app_manager.coffee\
	panel.coffee\
	app_list.coffee \
	entry_proxy.coffee\
	client_manager.coffee\
	active_window.coffee\
	preview.coffee\
	embed_window.coffee\
	item.coffee \
	app_item.coffee\
	deepin_item.coffee\
	${plugin_dir}/show_desktop.coffee\
	${plugin_dir}/launcher.coffee\
	${plugin_dir}/trash/trash.coffee\
	${plugin_dir}/time/now.coffee\
	${plugin_dir}/time/clock.coffee\
	${plugin_dir}/time/digit_clock.coffee\
	${plugin_dir}/time/analog_clock.coffee\
	${plugin_dir}/time/tray_clock.coffee\
	${plugin_dir}/time/time.coffee\
	${plugin_dir}/system_tray.coffee\
	signal.coffee\
	event.coffee\
	main.coffee
	cat $^ | ${coffee} -c --stdio > dock.js
