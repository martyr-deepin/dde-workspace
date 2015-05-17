NODE_PATH?=../../../node_modules
coffee?=${NODE_PATH}/.bin/coffee
com_dir = ../../common/js
com_coffee = ${com_dir}/utils.coffee 

all: ${com_coffee} lowpower.coffee 
	cat $^ | ${coffee} -c --stdio > lowpower.js
