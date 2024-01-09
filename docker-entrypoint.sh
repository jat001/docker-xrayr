#!/usr/bin/env bash

set -euxo pipefail
shopt -s extglob

: "${NODES:=*.yaml}"

etc=/etc/xrayr
tmp=/tmp/xrayr

url=https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download

files_exist() {
    ls "$1" >/dev/null 2>&1
}

yq_eval_all() {
    yq eval-all '. as $item ireduce ({}; . * $item )' "$@"
}

rm -rf "$tmp/nodes"
mkdir -p "$tmp/nodes"

[ -f "$etc/rulelist" ] && sed -E '/^#.*/d' "$etc/rulelist" >"$tmp/rulelist"

files_exist "$etc"/*.json &&
    for file in "$etc"/*.json; do
        sed -E '/^\/\/.*/d; /^\W+\/\/.*/d' "$file" >"/tmp/xrayr/$(basename "$file")"
    done

files_exist "$etc/conf.d"/*.yaml &&
    yq_eval_all "$etc/config.yaml" "$etc/conf.d/"*.yaml >"$tmp/config.yaml"

files_exist "$etc/node.d"/*.yaml && {
    default_file="$etc/node.d/00-default.yaml"

    for file in $(eval echo "$etc/node.d/$NODES"); do
        [ "$file" == "$default_file" ] && continue

        new_file="/tmp/xrayr/nodes/$(basename "$file")"
        if [ -f "$default_file" ]; then
            yq_eval_all "$default_file" "$file" >"$new_file"
        else
            cp "$file" "$new_file"
        fi

        yq -i '.Nodes += [ load("'"$new_file"'") ]' /tmp/xrayr/config.yaml
    done
}

yq -i '... comments=""' "$tmp/config.yaml"

curl -fsSLo "$tmp/geoip.dat" "$url/geoip.dat"
curl -fsSLo "$tmp/geosite.dat" "$url/geosite.dat"

exec "$@"
