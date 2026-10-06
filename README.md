# AstrEX YOLOv8-seg 插件

为 [AstrbotEX](https://github.com/Steven-Wang-120/AstrbotEX) 提供实例分割、标注 JPEG、检测 JSON 和可持久化的物体标记。插件及 `yolov8n-seg.pt` 权重都在 `plugins/vision/yolo/` 中；`patches/aeb-vision-marks.patch` 是针对 [A.E.B.](https://github.com/Steven-Wang-120/A.E.B.) `2e77eba61ad37d178f872805cbb7219104bb38fd` 的标记工具补丁。本仓库不复制这两个上游仓库的完整源码。

## 输出

| 内容 | EX TopicBus | ROS 2 | A.E.B. ZeroMQ |
|---|---|---|---|
| 检测 JSON | `yolo.json` | `/yolo/json` (`std_msgs/msg/String`) | text `vision.json.publish` |
| 标注 JPEG | `yolo.jpg` | `/yolo/jpg` (`sensor_msgs/msg/CompressedImage`) | vision `vision.jpeg.publish` |

JSON 与 JPEG 共享 `stream_id`、`frame_id`。JSON 第一字段是 Unix 秒 `timestamp`，`objects` 是以 ID 为键的字典。每个物体有 `id`、`name`、`color`、`conf`、`bbox` 和 `act`；`bbox.c`、`bbox.rt`、`bbox.lb` 分别是中心、右上、左下坐标，`bbox.px` 是整数像素框。屏幕中心为 `(0,0)`，左/上为 `+1`，右/下为 `-1`。`act=0` 默认未标记，`act=1` 为已标记。无目标时 `objects={}`，断流时发 `status=stale`。JPEG 显示轮廓、中心点、名称、颜色、置信度和已标记状态。

EX 内部 TopicBus 要求 JSON 可序列化，因此 `yolo.jpg` 的 payload 是 Base64 JPEG；ROS 与 A.E.B. 的图像通道发原始 JPEG 字节。检测 JSON 不含 JPEG 数据。插件不直接控制机器人动作。

LLM 可先用 A.E.B. 的 `get_astrbotex_vision_json_buffer` 获得准确 ID，再调用 `set_astrbotex_vision_marks`：

```json
{"stream_id":"yolo-...","ids":["id1","id2"],"marked":true,"request_id":"unique-operation-id"}
```

只有对指定 ID 显式提交 `marked=false` 才取消标记。多个 ID 可同时标记；状态写入插件的 SQLite，重启和短暂丢失后保留。相似目标或长遮挡后无法可靠重识别时，插件会分配新 ID，避免将旧标记错误继承给另一物体。A.E.B. 的两个视觉缓冲分别默认保存最近 8 条 JSON 和 8 张 JPEG，并由 LLM 按需读取。

## 安装

将 `plugins/vision/yolo/` 整个目录复制到 EX 数据目录 `plugins/vision/yolo/`。A.E.B. 一侧先检出上述固定提交，再应用补丁，并将补丁后的 `astrbot_plugin_astrbotex_interaction/` 安装到 AstrBot；请先备份原 A.E.B. 插件：

```bash
git clone https://github.com/Steven-Wang-120/A.E.B..git integrations/A.E.B.
git -C integrations/A.E.B. checkout 2e77eba61ad37d178f872805cbb7219104bb38fd
git -C integrations/A.E.B. apply ../../patches/aeb-vision-marks.patch
```

EX 插件、TopicBus 发布和 ROS2 端口默认关闭；按 `plugins/vision/yolo/README.md` 配置 Python 解释器、摄像头 Topic、输出端口及 A.E.B. 连接，再在 EX 中启用插件并选择 ROS2 环境。`plugins/vision/yolo/data/state.sqlite3` 应放在持久存储中，不应从其他机器人复制。默认 A.E.B. text/vision 端口为 8766/8768，使用 ZeroMQ，不是 HTTP。

本仓库还提供基于 AstrbotEX `1f6e4a86f46e661e9a26d522d930fb036cdf156a` 与 ROS 2 Jazzy 的本地镜像构建脚本。先将该上游提交检出到 `integrations/AstrbotEX/`，再运行 `deploy/yolo/build.sh`；`deploy/yolo/verify_image.sh` 可短暂启动镜像，检查 EX API、插件和内置权重。YOLO 镜像默认安装 CPU 版 PyTorch；需要 GPU 时应按目标设备重新构建推理环境。`deploy/yolo/Dockerfile.aeb` 可在按上方步骤准备 A.E.B. 后构建测试镜像。源码检出目录、运行数据、缓存和凭据均不应提交到 Git。

## 验证

2026-10-06 的本机验收使用真实 EX 加载器/Core Actor/ROS2 SDK、真实 YOLO 推理和真实 A.E.B. 插件工具，输入为经 ROS2 重放的官方测试图像。测试检出 6 个物体；独立 EX 插件分别订阅到 17 条 JSON 与 JPEG；两个物体的标记、单独取消、暂时消失后重现、幂等重试及 runtime 重启持久化均通过。详情见 [`evidence/report.json`](evidence/report.json)、[`evidence/marked.json`](evidence/marked.json) 和 [标注样例](evidence/marked.jpg)。该端到端测试调用了实际注册的 LLM FunctionTool，但没有运行付费 LLM 推理或现场摄像头的长时间压力测试。

运行状态测试：`python3 tests/yolo_native/test_marks.py -v`。完整本机验收入口在 `tests/yolo_native/ex_acceptance.py`，需要 ROS2、EX 源码、兼容的 YOLO Python 环境和 A.E.B. 测试接收端。

## 第三方许可与来源

本仓库按 **AGPL-3.0** 发布。随插件分发的 Ultralytics `yolov8n-seg.pt` 来自 [官方资产发布](https://github.com/ultralytics/assets/releases/download/v8.3.0/yolov8n-seg.pt)，其 SHA256 记于 `plugins/vision/yolo/models/manifest.json`；[Ultralytics 官方许可说明](https://docs.ultralytics.com/help/contributing/)说明其软件和模型的 AGPL 条款。完整协议见 [`LICENSE`](LICENSE) 及插件内的 `ULTRALYTICS_LICENSE.txt`。测试图 `bus.jpg` 与衍生标注图来自 [Ultralytics 官方测试资产](https://github.com/ultralytics/ultralytics/blob/v8.3.203/ultralytics/assets/bus.jpg)，仅用于展示验收。AstrbotEX、A.E.B.、AstrBot、ROS2 与 PyTorch 各自保留其上游版权和适用许可。
