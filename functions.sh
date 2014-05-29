#!/bin/sh

gen_pass()
{
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
}

ini_hasoption()
{
    local file="$1"
    local section="$2"
    local option="$3"
    if [ "$section" = "#" ]; then
        line=`sed -n -e "/^$option[ \t]*=/p" "$file"`
    else
        line=`sed -n -e "/^\[$section\]/,/^\[.*\]/{/^$option[ \t]*=/p}" "$file"`
    fi
    [ -n "$line" ]
}

ini_set()
{
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
}

ini_get()
{
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
}

ini_comment()
{
    local file="$1"
    local section="$2"
    local option="$3"
    if [ "$section" = "#" ]; then
        sed -i -e "s~^\($option[ \t]*=.*$\)~#\1~" "$file"
    else
        sed -i -e "/^\[$section\]/,/^\[.*\]/{s~^\($option[ \t]*=.*$\)~#\1~}" "$file"
    fi
}

get_interfaces()
{
    ip link show | sed 's/:/ /2' | awk '/^[0-9]/{print $2}'
}

get_interface_ipaddresses()
{
    local interface="$1"
    ip addr show dev $interface | sed 's~/~ ~' | awk '/ inet /{print $2}'
}

get_ip_by_hostname()
{
    local hostname="$1"
    resolveip -s $hostname
}

get_interface_by_ip()
{
    local ip="$1"
    for interface in `get_interfaces`; do
        if get_interface_ipaddresses $interface | grep -q $ip; then
            echo $interface
            break
        fi
    done
}

# vim: ts=4 sw=4 et tw=79
