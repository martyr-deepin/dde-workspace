NODE_PATH?=../../../node_modules
coffee?=${NODE_PATH}/.bin/coffee
com_dir = ../../common/js
com_coffee = ${com_dir}/config.coffee ${com_dir}/utils.coffee ${com_dir}/animation.coffee ${com_dir}/module.coffee ${com_dir}/widget.coffee ${com_dir}/selector.coffee ${com_dir}/plugin.coffee ${com_dir}/menu.coffee
desktop_item_coffee = item.coffee desktopentry.coffee floder.coffee richdir.coffee invalidlink.coffee application.coffee specialitem.coffee
grid_coffee = grid.coffee
all: ${com_coffee} common.coffee ${grid_coffee} signals.coffee ${desktop_item_coffee} dispatch.coffee plugin.coffee main.coffee
	cat $^ | ${coffee} -c --stdio > desktop.js
