"""Build installable EX and A.E.B. plugin archives with bundled model weights."""
from hashlib import sha256
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile


ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / "dist"
PACKAGES = {
    "astrex-yolo-0.2.0.zip": ROOT / "plugins/vision/yolo",
    "aeb-vision-marks-0.2.0.zip": ROOT / "integrations/A.E.B./astrbot_plugin_astrbotex_interaction",
}


def included(path: Path, base: Path) -> bool:
    relative = path.relative_to(base)
    return not any(part in {"__pycache__", "data", "tests", ".pytest_cache"} for part in relative.parts) and path.suffix != ".pyc" and path.name != "Dockerfile.test"


def build() -> None:
    DIST.mkdir(exist_ok=True)
    for name, source in PACKAGES.items():
        archive = DIST / name
        with ZipFile(archive, "w", compression=ZIP_DEFLATED) as output:
            for path in sorted(source.rglob("*")):
                if path.is_file() and included(path, source):
                    output.write(path, Path(source.name) / path.relative_to(source))
        digest = sha256(archive.read_bytes()).hexdigest()
        (DIST / f"{name}.sha256").write_text(f"{digest}  {name}\n")
        with ZipFile(archive) as check:
            assert check.testzip() is None
            if source.name == "yolo":
                assert any(item.endswith("yolov8n-seg.pt") for item in check.namelist())
        print(f"{name}: {archive.stat().st_size} bytes, sha256 {digest}")

    evidence = ROOT / "runtime/yolo-native/full-01"
    if (evidence / "report.json").is_file():
        name = "astrex-yolo-evidence-0.2.0.zip"
        archive = DIST / name
        with ZipFile(archive, "w", compression=ZIP_DEFLATED) as output:
            for item in ("report.json", "marked.json", "marked.jpg", "aeb_buffers.json"):
                output.write(evidence / item, item)
        digest = sha256(archive.read_bytes()).hexdigest()
        (DIST / f"{name}.sha256").write_text(f"{digest}  {name}\n")
        with ZipFile(archive) as check:
            assert check.testzip() is None
        print(f"{name}: {archive.stat().st_size} bytes, sha256 {digest}")


if __name__ == "__main__":
    build()
