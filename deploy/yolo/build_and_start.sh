#!/bin/bash
# One visible, scoped administrator session; no account/group permission changes.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
mkdir -p "$root/runtime/yolo-native"
exec > >(tee "$root/runtime/yolo-native/docker-build.log") 2>&1
docker build -f "$root/deploy/yolo/Dockerfile.aeb" -t local/aeb-yolo:0.2.0 "$root"
docker run -d --name astrex-aeb-yolo-20261006 --network host \
  -e ASTRBOTEX_ZMQ_BIND_HOST=127.0.0.1 -e ASTRBOTEX_ZMQ_TEXT_PORT=18766 \
  -e ASTRBOTEX_ZMQ_AUDIO_PORT=18767 -e ASTRBOTEX_ZMQ_VISION_PORT=18768 \
  --entrypoint python local/aeb-yolo:0.2.0 /opt/yolo-validation/aeb_host.py
bash "$root/deploy/yolo/build.sh"
docker image inspect local/astrex-yolo:0.2.0 local/aeb-yolo:0.2.0 \
  --format '{{.RepoTags}} {{.Id}}' > "$root/runtime/yolo-native/image-ids.txt"
echo 'YOLO_IMAGES_READY'
