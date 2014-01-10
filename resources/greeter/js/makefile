com_dir = ../../common/js

com_coffee =${com_dir}/config.coffee ${com_dir}/utils.coffee ${com_dir}/animation.coffee ${com_dir}/audioplay.coffee ${com_dir}/module.coffee ${com_dir}/widget.coffee ${com_dir}/selector.coffee ${com_dir}/tooltip.coffee

power_coffee = ../../shutdown/js/power_func.coffee 

greeter_coffee = ${power_coffee} config.coffee messagetip.coffee time.coffee version.coffee  user.coffee menu.coffee desktopmenu.coffee powermenu.coffee greeter.coffee

lock_coffee = ${power_coffee} config.coffee messagetip.coffee time.coffee switchuser.coffee user.coffee mediacontrol.coffee menu.coffee desktopmenu.coffee powermenu.coffee lock.coffee 

all: ${com_coffee} ${greeter_coffee} ${lock_coffee}
	coffee -cj greeter.js ${com_coffee} ${greeter_coffee}
	coffee -cj lock.js ${com_coffee} ${lock_coffee}

