include ../../common/js/Makefile

com_coffee += \
	${com_dir}/menu.coffee\
	${com_dir}/uninstaller.coffee \

all: ${com_coffee} \
	const.coffee \
	global.coffee \
	utils.coffee \
	sort_method.coffee\
	category_display_mode.coffee\
	settings.coffee\
	dbus.coffee \
	page.coffee \
	search_result.coffee \
	search_bar.coffee \
	category_item.coffee\
	category_bar.coffee \
	category.coffee \
	category_list.coffee \
	menu.coffee\
	switcher.coffee \
	selector.coffee \
	softwaremanager.coffee \
	delegate.coffee \
	item.coffee \
	event.coffee \
	signal.coffee \
	main.coffee
	cat $^ | ${coffee} -c --stdio > launcher.js
