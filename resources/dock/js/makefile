com_dir = ../../common/js
com_coffee = ${com_dir}/config.coffee ${com_dir}/utils.coffee ${com_dir}/animation.coffee ${com_dir}/module.coffee ${com_dir}/widget.coffee ${com_dir}/selector.coffee ${com_dir}/tooltip.coffee ${com_dir}/menu.coffee
plugin_dir=plugins
# all: ${com_coffee} config.coffee panel.coffee item.coffee deepin_item.coffee clientgroup.coffee launcher.coffee preview.coffee show_desktop.coffee main.coffee
all: ${com_coffee} \
	const.coffee\
	config.coffee \
	utils.coffee\
	region.coffee\
	settings.coffee\
	global_menu.coffee\
	docked_app_manager.coffee\
	panel.coffee\
	app_list.coffee \
	show_desktop.coffee\
	entry_proxy.coffee\
	active_window.coffee\
	preview.coffee\
	embed_window.coffee\
	item.coffee \
	deepin_item.coffee\
	${plugin_dir}/launcher.coffee\
	${plugin_dir}/trash.coffee\
	${plugin_dir}/time/time.coffee\
	system_tray.coffee\
	main.coffee
	coffee -cj dock.js $^

	# new/activator.coffee\
	# new/clientgroup.coffee\
