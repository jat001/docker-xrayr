#!/usr/bin/env bash

set -euo pipefail

files_exist() {
    ls "$1" >/dev/null 2>&1
}

yq_eval_all() {
    yq eval-all '. as $item ireduce ({}; . * $item )' "$@"
}

rm -rf /tmp/xrayr/nodes
mkdir -p /tmp/xrayr/nodes

files_exist /etc/xrayr/*.json &&
    for file in /etc/xrayr/*.json; do
        sed -E 's#^//.*##; s#^\W+//.*##' "$file" | yq -pj -oj >"/tmp/xrayr/$(basename "$file")"
    done

files_exist /etc/xrayr/conf.d/*.yaml &&
    yq_eval_all /etc/xrayr/config.yaml /etc/xrayr/conf.d/*.yaml >/tmp/xrayr/config.yaml

files_exist /etc/xrayr/node.d/*.yaml && {
    default_file=/etc/xrayr/node.d/00-default.yaml

    for file in /etc/xrayr/node.d/*.yaml; do
        [[ "$file" == "$default_file" ]] && continue

        new_file="/tmp/xrayr/nodes/$(basename "$file")"
        yq_eval_all "$default_file" "$file" >"$new_file"
        yq -i '.Nodes += [ load("'"$new_file"'") ]' /tmp/xrayr/config.yaml
    done
}

yq -i '... comments=""' /tmp/xrayr/config.yaml

curl -fsSLo /tmp/xrayr/geoip.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat
curl -fsSLo /tmp/xrayr/geosite.dat https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat

exec "$@"
