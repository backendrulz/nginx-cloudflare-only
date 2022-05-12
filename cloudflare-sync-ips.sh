#!/bin/bash

CF_ONLY=false

help() {
    echo "Get real visitor IP address and block all ips except from Cloudflare."
    echo
    echo "Syntax: $0 --[help|cf-only]"
    echo
    echo "options:"
    echo "--help     Print this Help."
    echo "--cf-only  Only Cloudflare IPs can access."
    echo
}

for arg in "$@"; do
    shift
    case "$arg" in
    '--help')
        help
        exit
        ;;
    '--cf-only')
        CF_ONLY=true
        ;;
    *)
        echo "Error: Invalid option"
        exit
        ;;
    esac
done

CLOUDFLARE_RI_FILE_PATH=${1:-/etc/nginx/cloudflare-real-ip}
CLOUDFLARE_ONLY_FILE_PATH=${1:-/etc/nginx/cloudflare-only}

echo "# Cloudflare" >$CLOUDFLARE_RI_FILE_PATH

if [ "$CF_ONLY" = "true" ]; then
    echo "# Allow only Cloudflare IPs" >$CLOUDFLARE_ONLY_FILE_PATH
fi

echo "" >>$CLOUDFLARE_RI_FILE_PATH
echo "# - IPv4" >>$CLOUDFLARE_RI_FILE_PATH

if [ "$CF_ONLY" = "true" ]; then
    echo "" >>$CLOUDFLARE_ONLY_FILE_PATH
    echo "# - IPv4" >>$CLOUDFLARE_ONLY_FILE_PATH
fi

for i in $(curl -s -L https://www.cloudflare.com/ips-v4); do
    echo "set_real_ip_from $i;" >>$CLOUDFLARE_RI_FILE_PATH

    if [ "$CF_ONLY" = "true" ]; then
        echo "allow $i;" >>$CLOUDFLARE_ONLY_FILE_PATH
    fi
done

echo "" >>$CLOUDFLARE_RI_FILE_PATH
echo "# - IPv6" >>$CLOUDFLARE_RI_FILE_PATH

if [ "$CF_ONLY" = "true" ]; then
    echo "" >>$CLOUDFLARE_ONLY_FILE_PATH
    echo "# - IPv6" >>$CLOUDFLARE_ONLY_FILE_PATH
fi

for i in $(curl -s -L https://www.cloudflare.com/ips-v6); do
    echo "set_real_ip_from $i;" >>$CLOUDFLARE_RI_FILE_PATH

    if [ "$CF_ONLY" = "true" ]; then
        echo "allow $i;" >>$CLOUDFLARE_ONLY_FILE_PATH
    fi
done

echo "" >>$CLOUDFLARE_RI_FILE_PATH
echo "real_ip_header CF-Connecting-IP;" >>$CLOUDFLARE_RI_FILE_PATH

if [ "$CF_ONLY" = "true" ]; then
    echo "" >>$CLOUDFLARE_ONLY_FILE_PATH
    echo "deny all; # deny all remaining ips" >>$CLOUDFLARE_ONLY_FILE_PATH
fi

#test configuration and reload nginx
nginx -t && systemctl reload nginx
