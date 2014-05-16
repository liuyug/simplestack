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
    line=`sed -n -e "/^\[$section\]/,/^\[.*\]/{/^$option[ \t]*=/p}" "$file"`
    [ -n "$line" ]
}

ini_set()
{
    local file="$1"
    local section="$2"
    local option="$3"
    local value="$4"
    if ! grep -q "^\[$section\]" "$file"; then
        # add section
        # dash don't support "echo -e"
        printf "\n[$section]\n" >> "$file"
    fi
    if ini_hasoption "$file" $section $option; then
        sed -i -r "/^\[$section\]/,/^\[.*\]/{s~(^$option[ \t]*=[ \t]*).*$~\1$value~}" "$file"
    else
        sed -i -e "/^\[$section\]/a \\
$option=$value
        " "$file"
    fi
}

ini_get()
{
    local file="$1"
    local section="$2"
    local option="$3"
    local line
    line=`sed -n -e "/^\[$section\]/,/^\[.*\]/{/^$option[ \t]*=/p}" "$file"`
    echo ${line#*=}
}

# vim: ts=4 sw=4 et tw=79
