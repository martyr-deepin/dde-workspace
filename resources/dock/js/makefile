com_dir = ../../common/js
com_coffee = ${com_dir}/config.coffee ${com_dir}/utils.coffee \
	     ${com_dir}/animation.coffee ${com_dir}/module.coffee \
	     ${com_dir}/widget.coffee ${com_dir}/selector.coffee \
	     ${com_dir}/tooltip.coffee ${com_dir}/menu.coffee \
	     ${com_dir}/uninstaller.coffee
plugin_dir=plugins
all: ${com_coffee} \
	global.coffee\
	dragtarget.coffee\
	config.coffee \
	utils.coffee\
	region.coffee\
	hide_status.coffee\
	settings.coffee\
	global_menu.coffee\
	docked_app_manager.coffee\
	panel.coffee\
	app_list.coffee \
	entry_proxy.coffee\
	active_window.coffee\
	preview.coffee\
	embed_window.coffee\
	client_manager.coffee\
	item.coffee \
	deepin_item.coffee\
	${plugin_dir}/show_desktop.coffee\
	${plugin_dir}/launcher.coffee\
	${plugin_dir}/trash/trash.coffee\
	${plugin_dir}/time/time.coffee\
	${plugin_dir}/system_tray.coffee\
	main.coffee
	coffee -cj dock.js $^
