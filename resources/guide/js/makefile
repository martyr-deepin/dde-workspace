com_dir = ../../common/js
com_coffee = ${com_dir}/config.coffee ${com_dir}/utils.coffee ${com_dir}/animation.coffee ${com_dir}/module.coffee ${com_dir}/widget.coffee ${com_dir}/selector.coffee ${com_dir}/tooltip.coffee ${com_dir}/menu.coffee

util = config.coffee utils.coffee base.coffee pointer.coffee rect.coffee menuchoose.coffee buttonnext.coffee contextmenu.coffee
module = guide.coffee welcome.coffee start.coffee dock.coffee launcher.coffee dss.coffee desktop.coffee end.coffee
all: ${com_coffee} ${util} ${module} main.coffee
	coffee -cj guide.js $^
