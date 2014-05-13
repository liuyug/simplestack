#!/bin/sh

gen_pass()
{
    length=10
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

# vim: ts=4 sw=4 et tw=79
