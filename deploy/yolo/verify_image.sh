#!/bin/bash
# Check that the built ROS image boots AstrbotEX with the bundled YOLO plugin.
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
name="astrex-yolo-image-check-20261006"
data="$root/runtime/yolo-native/container-data"
mkdir -p "$data"
if docker container inspect "$name" >/dev/null 2>&1; then
  echo "Container $name already exists; refusing to replace it" >&2
  exit 1
fi
cleanup() { docker stop "$name" >/dev/null 2>&1 || true; }
trap cleanup EXIT
docker run -d --rm --name "$name" --network none \
  -e ASTRBOTEX_DATA_DIR=/app/data -v "$data:/app/data" \
  local/astrex-yolo:0.2.0 >/dev/null
for _ in {1..40}; do
  if docker exec "$name" python -c 'import urllib.request; urllib.request.urlopen("http://127.0.0.1:8765/healthz",timeout=1)' >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
docker exec "$name" python -c '
import json, pathlib, urllib.request
base="http://127.0.0.1:8765"
plugins=json.load(urllib.request.urlopen(base+"/api/v1/ex/plugins"))
yolo=next((p for p in plugins["plugins"] if p["id"]=="yolo"),None)
assert yolo is not None,plugins
assert pathlib.Path("/app/data/plugins/vision/yolo/models/yolov8n-seg.pt").is_file()
print(json.dumps({"image_boot":True,"plugin":yolo["id"],"weight_bundled":True,"enabled":yolo.get("enabled")},ensure_ascii=False))
'
