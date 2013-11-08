com_dir = ../common/js
com_coffee = ${com_dir}/utils.coffee ${com_dir}/animation.coffee ${com_dir}/module.coffee ${com_dir}/widget.coffee

all: ${com_coffee} shutdown.coffee
	coffee -cj shutdown.js $^
