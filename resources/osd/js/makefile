com_dir = ../../common/js
com_coffee = ${com_dir}/utils.coffee ${com_dir}/module.coffee ${com_dir}/widget.coffee

util_coffee = animation.coffee utils.coffee listchoose.coffee bar.coffee 
module_coffee = option.coffee audio.coffee display.coffee fcitx.coffee keyboard.coffee

all: ${com_coffee} ${util_coffee} ${module_coffee}
	coffee -cj osd.js $^
