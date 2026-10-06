ARG EX_BASE=local/astrex:1f6e4a8-ros2
FROM ${EX_BASE}
RUN python -m pip install --no-cache-dir torch==2.7.0 torchvision==0.22.0 --index-url https://download.pytorch.org/whl/cpu
RUN python -m pip install --no-cache-dir numpy==1.26.4 opencv-python-headless==4.11.0.86 scipy matplotlib pyyaml requests psutil polars ultralytics-thop==2.0.17 \
    && python -m pip install --no-cache-dir --no-deps ultralytics==8.3.203
COPY plugins/vision/yolo /opt/yolo-plugin
COPY deploy/yolo/start.sh /app/start-yolo.sh
RUN chmod +x /app/start-yolo.sh
LABEL org.opencontainers.image.source="https://github.com/Steven-Wang-120/AstrbotEX" \
      org.opencontainers.image.revision="1f6e4a8" \
      io.astrex.yolo.version="0.2.0"
ENTRYPOINT ["/app/start-yolo.sh"]
CMD ["python", "-m", "astrbot_ex.core.api_server", "--host", "0.0.0.0", "--port", "8765"]
