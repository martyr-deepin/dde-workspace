include ../../common/js/Makefile
com_coffee = ${com_dir}/utils.coffee 

all: ${com_coffee} lowpower.coffee 
	cat $^ | ${coffee} -c --stdio > lowpower.js
