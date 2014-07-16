#!/bin/sh


app_name=`basename $0`

usage()
{
    echo "$app_name <key file> <key name>"
    echo ""
    echo "Note: \"ssh-keygen\" to generate new key file."
}

if [ $# -lt 2 ]; then
    usage
    exit 1
fi

pubkey_file=$1
key_name=$2

keypair-add --pub-key $pubkey_file $key_name

# vim: ts=4 sw=4 et tw=79
