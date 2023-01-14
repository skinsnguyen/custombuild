#!/usr/bin/env bash

PHP_VER=`echo $0 | grep -o '[0-9]*'`

OPTIONS=
if [ "$1" != "" ]; then
    if [ -s "$1" ]; then
            OPTIONS=" -c ${1} ${OPTIONS}"
    fi
    shift
fi

if [ "$1" = "jail=true" ]; then
    JAIL=true
    shift
fi
if [ -z "${JAIL}" ]; then
	if getent passwd $(id -u) | grep -m1 -q ':/usr/bin/jailshell$'; then
		JAIL=true
	else
		JAIL=false
	fi
fi

if [ "$#" -gt 0 ]; then
	SENDMAIL_FROM="`echo $@ | grep -o 'sendmail_from=[^ ]*' | cut -d'\"' -f2`"
	if [ "${SENDMAIL_FROM}" != "" ]; then
		SENDMAIL_ADD="-f ${SENDMAIL_FROM}"
    else
        SENDMAIL_ADD="-f admin@`hostname`"
	fi
else
    SENDMAIL_ADD="-f admin@`hostname`"
fi

# http://httpd.apache.org/mod_fcgid/mod/mod_fcgid.html
# Set desired PHP_FCGI_* environment variables.
# Example:
# PHP FastCGI processes exit after 500 requests by default.
# JE: Do not limit it to facilitate XCache (or set it really high, like 10000)
PHP_FCGI_MAX_REQUESTS=0
export PHP_FCGI_MAX_REQUESTS

# See http://www.webhostingtalk.com/archive/index.php/t-1165678.html
PHP_FCGI_CHILDREN=0
export PHP_FCGI_CHILDREN
set -euo pipefail
if [ -x /usr/bin/bwrap ] && ${JAIL}; then
    (exec -a jailphp bwrap --ro-bind /usr /usr \
    --ro-bind /lib /lib \
    --ro-bind-try /lib64 /lib64 \
    --ro-bind /bin /bin \
    --ro-bind /sbin /sbin \
    --bind $(getent passwd $(id -u) | cut -d: -f6) $(getent passwd $(id -u) | cut -d: -f6) \
    --dir /var \
    --dir /tmp \
    --proc /proc \
    --symlink ../tmp var/tmp \
    --dev /dev \
    --ro-bind-try /etc/localtime /etc/localtime \
    --ro-bind-try /etc/ld.so.cache /etc/ld.so.cache \
    --ro-bind-try /etc/resolv.conf /etc/resolv.conf \
    --ro-bind-data 13 $(getent passwd $(id -u) | cut -d: -f6)/.msmtprc \
    --ro-bind-try /etc/ssl /etc/ssl \
    --ro-bind-try /etc/pki /etc/pki \
    --ro-bind-try /etc/man_db.conf /etc/man_db.conf \
    --bind-try /var/lib/mysql/mysql.sock /var/lib/mysql/mysql.sock \
    --bind-try /home/mysql/mysql.sock /home/mysql/mysql.sock \
    --bind-try /tmp/mysql.sock /tmp/mysql.sock \
    --unshare-all \
    --share-net \
    --die-with-parent \
    --dir /run/user/$(id -u) \
    --file 11 /etc/passwd \
    --file 12 /etc/group \
    /usr/local/php${PHP_VER}/bin/php-cgi${PHP_VER} ${OPTIONS} -d sendmail_path="/usr/sbin/sendmail -t -i ${SENDMAIL_ADD}" "$@") \
    11< <(getent passwd $(id -u) 65534) \
    12< <(getent group $(id -g) 65534) \
    13< <(cat /etc/exim.jail/$(id -nu).conf 2>/dev/null)
else
    exec /usr/local/php${PHP_VER}/bin/php-cgi${PHP_VER} ${OPTIONS} -d sendmail_path="/usr/sbin/sendmail -t -i ${SENDMAIL_ADD}" $@
fi
