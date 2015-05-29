include ../../common/js/Makefile

desktop_item_coffee = \
		      operations.coffee \
		      dentry.coffee \
		      item.coffee \
		      desktopentry.coffee \
		      floder.coffee \
		      richdir.coffee \
		      invalidlink.coffee \
		      application.coffee \
		      specialitem.coffee
grid_coffee = grid.coffee
all: ${com_coffee} common.coffee ${grid_coffee} signals.coffee ${desktop_item_coffee} dispatch.coffee plugin.coffee main.coffee
	cat $^ | ${coffee} -c --stdio > desktop.js
