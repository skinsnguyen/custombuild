#!/bin/sh
if [ -x /usr/local/directadmin/custombuild/custom/unit/check_unit.sh ] && echo "$0" | grep -m1 -q '/configure/'; then
    /usr/local/directadmin/custombuild/custom/unit/check_unit.sh
    exit $?
fi

TASK_QUEUE=/usr/local/directadmin/data/task.queue.cb

run_dataskq() {
        echo "action=rewrite&value=nginx_unit" >> ${TASK_QUEUE}
        /usr/local/directadmin/dataskq --custombuild
}

if ! [ -e /var/run/unit/control.sock ]; then
        exit
fi

result="$(curl -s --unix-socket /var/run/unit/control.sock http://localhost/config/listeners -f)"

if  [ "$?" -ne "0" ] || echo ${result} | head -n1 | grep -m1 -q '{}'; then
        run_dataskq
fi