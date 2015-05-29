include ../../common/js/Makefile
com_coffee = ${com_dir}/utils.coffee ${com_dir}/module.coffee ${com_dir}/widget.coffee

zone_coffee = utils.coffee animation.coffee option.coffee zone.coffee
all: ${com_coffee} ${zone_coffee} main.coffee
	cat $^ | ${coffee} -c --stdio > zone.js
