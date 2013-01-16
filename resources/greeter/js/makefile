com_dir = ../../common/js
com_coffee = ${com_dir}/utils.coffee ${com_dir}/animation.coffee ${com_dir}/module.coffee ${com_dir}/widget.coffee ${com_dir}/selector.coffee
greeter_coffee = time.coffee menu.coffee session.coffee power.coffee user.coffee
lock_coffee = time.coffee lock.coffee 
all: ${com_coffee} ${greeter_coffee} ${lock_coffee}
	coffee -cj greeter.js ${com_coffee} ${greeter_coffee}
	coffee -cj lock.js ${com_coffee} ${lock_coffee}

