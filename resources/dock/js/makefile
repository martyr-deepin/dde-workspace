com_dir = ../../common/js
com_coffee = ${com_dir}/config.coffee ${com_dir}/utils.coffee ${com_dir}/animation.coffee ${com_dir}/module.coffee ${com_dir}/widget.coffee ${com_dir}/selector.coffee ${com_dir}/tooltip.coffee ${com_dir}/menu.coffee
# all: ${com_coffee} config.coffee panel.coffee item.coffee deepin_item.coffee clientgroup.coffee launcher.coffee preview.coffee show_desktop.coffee main.coffee
all: ${com_coffee} \
	new/const.coffee\
	config.coffee \
	new/region.coffee\
	panel.coffee\
	new/app_list.coffee \
	show_desktop.coffee\
	preview.coffee\
	new/item.coffee \
	new/activator.coffee\
	new/clientgroup.coffee\
	deepin_item.coffee\
	new/main.coffee
	coffee -cj dock.js $^
