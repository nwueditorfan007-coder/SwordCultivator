"""Safe V15 ink rig generation entrypoint.

The first experimental version of this file projected V14 parts onto the V15
master and could drift away from the locked character template. The safe path
now regenerates V15 from the current master by direct visible-shape extraction,
then writes placeholder pose/socket libraries and offline previews.
"""
from __future__ import annotations

from pathlib import Path
import runpy


ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools"


def run_tool(filename: str) -> None:
    path = TOOLS / filename
    print(f"\n=== {filename} ===")
    runpy.run_path(str(path), run_name="__main__")


def main() -> None:
    run_tool("generate_body_v15_visible_parts_from_master.py")
    run_tool("generate_body_v15_pose_socket_libraries.py")
    run_tool("preview_body_v15_rig_poses.py")
    run_tool("verify_body_v15_rig.py")


if __name__ == "__main__":
    main()
