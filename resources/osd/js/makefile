include ../../common/js/Makefile
com_coffee = ${com_dir}/utils.coffee ${com_dir}/module.coffee ${com_dir}/widget.coffee ${com_dir}/animation.coffee ${com_dir}/config.coffee

util_coffee = utils.coffee listchoose.coffee imglistchoose.coffee bar.coffee
module_coffee = option.coffee audio.coffee display.coffee monitor.coffee fcitx.coffee keyboard.coffee

all: ${com_coffee} ${util_coffee} ${module_coffee} main.coffee
	cat $^ | ${coffee} -c --stdio > osd.js
