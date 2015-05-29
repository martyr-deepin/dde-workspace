include ../../common/js/Makefile

init_coffee = config.coffee resolution.coffee animation.coffee
com_module_coffee = select.coffee theme.coffee message.coffee user.coffee menuchoose.coffee powermenu.coffee
common_coffee = ${com_coffee} ${init_coffee} ${power_coffee} ${com_module_coffee}

greeter_coffee = ${common_coffee} version.coffee desktopmenu.coffee usermenu.coffee greeter.coffee
lock_coffee = ${common_coffee} keyboard.coffee time.coffee switchuser.coffee ${com_dir}/audioplay.coffee mediacontrol.coffee lock.coffee

all: ${greeter_coffee} ${lock_coffee}
	cat ${greeter_coffee} | ${coffee} -c --stdio > greeter.js
	cat ${lock_coffee} | ${coffee} -c --stdio >  lock.js

