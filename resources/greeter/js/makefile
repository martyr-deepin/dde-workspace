com_dir = ../../common/js
com_coffee =${com_dir}/config.coffee ${com_dir}/utils.coffee ${com_dir}/audioplay.coffee ${com_dir}/module.coffee ${com_dir}/widget.coffee ${com_dir}/selector.coffee ${com_dir}/accounts.coffee

init_coffee = config.coffee resolution.coffee animation.coffee 
power_coffee = powerdbus.coffee 
com_module_coffee = theme.coffee time.coffee version.coffee user.coffee menuchoose.coffee powermenu.coffee
common_coffee = ${com_coffee} ${init_coffee} ${power_coffee} ${com_module_coffee}


greeter_coffee = ${common_coffee} message.coffee desktopmenu.coffee usermenu.coffee greeter.coffee
lock_coffee = ${common_coffee} message.coffee switchuser.coffee mediacontrol.coffee lock.coffee 

all: ${greeter_coffee} ${lock_coffee}
	coffee -cj greeter.js ${greeter_coffee}
	coffee -cj lock.js ${lock_coffee}

