include ../../common/js/Makefile

util = config.coffee utils.coffee base.coffee pointer.coffee rect.coffee menuchoose.coffee buttonnext.coffee contextmenu.coffee
module = guide.coffee welcome.coffee start.coffee dock.coffee launcher.coffee dss.coffee desktop.coffee end.coffee
all: ${com_coffee} ${util} ${module} main.coffee
	cat $^ | ${coffee} -c --stdio > guide.js
