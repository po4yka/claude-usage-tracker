#!/usr/bin/env python3
"""
Convert SVG to PNG via the resvg CLI.

Migrated from cairosvg to resvg (Rust, tiny-skia-backed) because:
  - crisper 16x16 anti-aliasing (known Cairo weakness at small sizes)
  - zero native-library dependencies (no DYLD_LIBRARY_PATH gymnastics)
  - deterministic cross-platform output

Requires the `resvg` binary on PATH. Install:
    cargo install resvg
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def _find_resvg() -> str:
    path = shutil.which("resvg")
    if not path:
        print("Error: resvg binary not found on PATH.", file=sys.stderr)
        print("Install with: cargo install resvg", file=sys.stderr)
        sys.exit(1)
    return path


def svg_to_png(svg_path: str, png_path: str, width: int = 1024, height: int = 1024) -> bool:
    resvg = _find_resvg()
    try:
        subprocess.run(
            [resvg, "-w", str(width), "-h", str(height), svg_path, png_path],
            check=True, capture_output=True, text=True,
        )
        print(f"[OK] Converted: {svg_path} -> {png_path}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error converting SVG to PNG: {e.stderr or e}", file=sys.stderr)
        return False


def main():
    p = argparse.ArgumentParser(description="Convert SVG to PNG via resvg")
    p.add_argument("svg_file", help="Path to SVG file")
    p.add_argument("--output", "-o", help="Output PNG path (default: same name with .png)")
    p.add_argument("--width", "-w", type=int, default=1024, help="Output width (default: 1024)")
    p.add_argument("--height", "-H", type=int, default=1024, help="Output height (default: 1024)")

    args = p.parse_args()

    svg_path = Path(args.svg_file)
    if not svg_path.exists():
        print(f"Error: SVG file not found: {svg_path}", file=sys.stderr)
        sys.exit(1)

    png_path = Path(args.output) if args.output else svg_path.with_suffix(".png")
    ok = svg_to_png(str(svg_path), str(png_path), args.width, args.height)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
