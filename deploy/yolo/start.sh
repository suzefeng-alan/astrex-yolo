#!/bin/bash
set -e
target="${ASTRBOTEX_DATA_DIR:-/app/data}/plugins/vision/yolo"
if [ ! -f "$target/plugin.json" ]; then
    mkdir -p "$target"
    cp -a /opt/yolo-plugin/. "$target/"
fi
exec /app/docker-entrypoint.ros2.sh "$@"
