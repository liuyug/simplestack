#!/bin/sh

set -o xtrace

gen_pass()
{
    local oxtrace="`set +o | grep xtrace`"
    set +o xtrace
    local length=10
    if [ "x"$1 != "x" ]; then
        length=$1
    fi
    if [ -x "/usr/bin/openssl" ]; then
        openssl rand -hex $length
    else
        echo "Could not find \"openssl\"."
        exit 1
    fi
    $oxtrace
}

ini_hasoption()
{
    local oxtrace="`set +o | grep xtrace`"
    set +o xtrace
    local file="$1"
    local section="$2"
    local option="$3"
    if [ "$section" = "#" ]; then
        line=`sed -n -e "/^$option[ \t]*=/p" "$file"`
    else
        line=`sed -n -e "/^\[$section\]/,/^\[.*\]/{/^$option[ \t]*=/p}" "$file"`
    fi
    $oxtrace
    [ -n "$line" ]
}

ini_set()
{
    local oxtrace="`set +o | grep xtrace`"
    set +o xtrace
    local file="$1"
    local section="$2"
    local option="$3"
    local value="$4"
    if [ ! -f "$file" ]; then
        touch "$file"
    fi
    if [ ! "$section" = "#" ]; then
        if ! grep -q "^\[$section\]" "$file"; then
            # add section
            # dash don't support "echo -e"
            printf "\n[$section]\n" >> "$file"
        fi
    fi
    if ini_hasoption "$file" $section $option; then
        if [ "$section" = "#" ]; then
            sed -i -r "s~(^$option[ \t]*=[ \t]*).*$~\1$value~" "$file"
        else
            sed -i -r "/^\[$section\]/,/^\[.*\]/{s~(^$option[ \t]*=[ \t]*).*$~\1$value~}" "$file"
        fi
    else
        if [ "$section" = "#" ]; then
            cat <<EOF >> "$file"
$option=$value
EOF
        else
            sed -i -e "/^\[$section\]/a \\
$option=$value
" "$file"
        fi
    fi
    $oxtrace
}

ini_set_multiline()
{
    local oxtrace="`set +o | grep xtrace`"
    set +o xtrace
    local file="$1"
    local section="$2"
    local option="$3"
    local values
    if [ ! -f "$file" ]; then
        touch "$file"
    fi
    # reverse odrer
    shift 3
    for v in $@; do
        values="$v ${values}"
    done
    if ! grep -q "^\[$section\]" "$file"; then
        # add section
        # dash don't support "echo -e"
        printf "\n[$section]\n" >> "$file"
    fi
    if ini_hasoption "$file" $section $option; then
        # remove options
        sed -i -r "/^\[$section\]/,/^\[.*\]/{~^$option[ \t]*=[ \t]*.*$~d}" "$file"
    fi
    # add
    for value in $values; do
        sed -i -e "/^\[$section\]/a \\
$option=$value
" "$file"
    done
    $oxtrace
}

ini_get()
{
    local oxtrace="`set +o | grep xtrace`"
    set +o xtrace
    local file="$1"
    local section="$2"
    local option="$3"
    local line
    if [ "$section" = "#" ]; then
        line=`sed -n -e "/^$option[ \t]*=/p" "$file"`
    else
        line=`sed -n -e "/^\[$section\]/,/^\[.*\]/{/^$option[ \t]*=/p}" "$file"`
    fi
    echo ${line#*=}
    $oxtrace
}

ini_comment()
{
    local oxtrace="`set +o | grep xtrace`"
    set +o xtrace
    local file="$1"
    local section="$2"
    local option="$3"
    if [ "$section" = "#" ]; then
        sed -i -e "s~^\($option[ \t]*=.*$\)~#\1~" "$file"
    else
        sed -i -e "/^\[$section\]/,/^\[.*\]/{s~^\($option[ \t]*=.*$\)~#\1~}" "$file"
    fi
    $oxtrace
}

get_interfaces()
{
    local oxtrace="`set +o | grep xtrace`"
    set +o xtrace
    ip link show | sed 's/:/ /2' | awk '/^[0-9]/{print $2}'
    $oxtrace
}

get_ips_by_interface()
{
    local oxtrace="`set +o | grep xtrace`"
    set +o xtrace
    local interface="$1"
    # 192.168.0.1/24
    ip addr show dev $interface | awk '/ inet /{print $2}'
    $oxtrace
}

get_ip_by_hostname()
{
    local oxtrace="`set +o | grep xtrace`"
    set +o xtrace
    local hostname="$1"
    ip=`awk "/[ \t]$hostname([ \t]|\\\$)/{print \\\$1}" /etc/hosts | head -n 1`
    if [ "x$ip" = "x" ]; then
        echo "Do not find ip address by $hostname."
        #exit 1
    else
        echo $ip
    fi
    $oxtrace
}

get_interface_by_ip()
{
    local oxtrace="`set +o | grep xtrace`"
    set +o xtrace
    local ip="$1"
    for interface in `get_interfaces`; do
        if get_ips_by_interface $interface | grep -q $ip; then
            echo $interface
            break
        fi
    done
    $oxtrace
}

# vim: ts=4 sw=4 et tw=79
