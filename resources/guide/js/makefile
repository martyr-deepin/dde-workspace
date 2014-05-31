com_dir = ../../common/js
com_coffee = ${com_dir}/config.coffee ${com_dir}/utils.coffee ${com_dir}/animation.coffee ${com_dir}/module.coffee ${com_dir}/widget.coffee ${com_dir}/selector.coffee ${com_dir}/tooltip.coffee ${com_dir}/menu.coffee

util = utils.coffee pagecontainer.coffee pointer.coffee rect.coffee 
module = welcome.coffee start.coffee launcher.coffee desktop.coffee
all: ${com_coffee} ${util} ${module} guide.coffee
	coffee -cj guide.js $^
