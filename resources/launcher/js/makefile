com_dir = ../../common/js
com_coffee = ${com_dir}/module.coffee ${com_dir}/utils.coffee \
	     ${com_dir}/selector.coffee ${com_dir}/widget.coffee \
	     ${com_dir}/animation.coffee ${com_dir}/menu.coffee
all: ${com_coffee} \
	const.coffee \
	utils.coffee \
	config.coffee \
	search_bar.coffee \
	category_bar.coffee \
	item.coffee \
	hidden_icon.coffee \
	grid.coffee \
	event.coffee \
	signal.coffee \
	main.coffee
	coffee -cj launcher.js $^
