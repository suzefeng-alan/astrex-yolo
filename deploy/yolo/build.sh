#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
docker build --build-arg ROS_BASE_IMAGE=ros:jazzy-ros-base \
  -f "$root/integrations/AstrbotEX/Dockerfile.ros2" -t local/astrex:1f6e4a8-ros2 "$root/integrations/AstrbotEX"
docker build -f "$root/deploy/yolo/Dockerfile" -t local/astrex-yolo:0.2.0 "$root"
