#!/usr/bin/env bash

set -euxo pipefail

: "${NODES:=}"
: "${PREFER_V6:=0}"

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

files_exist "$etc/node.d"/*.yaml &&
    yq_eval_all "$etc/node.yaml" "$etc/node.d/"*.yaml >"$tmp/node.yaml"

IFS="," read -r -a node_arr <<<"$NODES"
for node in "${node_arr[@]}"; do
    yq ".ApiConfig.NodeID = $node" "$tmp/node.yaml" >"$tmp/nodes/$node.yaml"
    [ "$PREFER_V6" -gt 0 ] && yq -i '.ControllerConfig.SendIP = "::"' "$tmp/nodes/$node.yaml"
    yq -i '.Nodes += [ load("'"$tmp/nodes/$node.yaml"'") ]' "$tmp/config.yaml"
done

yq -i '... comments=""' "$tmp/config.yaml"

curl -fsSLo "$tmp/geoip.dat" "$url/geoip.dat"
curl -fsSLo "$tmp/geosite.dat" "$url/geosite.dat"

exec "$@"
