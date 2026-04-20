#!/usr/bin/env python3
"""
Validate a heimdall logo SVG against the grammar contract in
`references/svg-contract.md`.

Catches the Opus 4.7 / LLM SVG failure modes identified in 2025–2026
research (LLM4SVG / Chat2SVG / SVGenius):
  - coordinate tokenization drift (out-of-viewBox values)
  - arc parameter confusion (non-0/1 flags, unflagged long arcs)
  - unclosed filled paths (missing Z)
  - disallowed element vocabulary (<text>, <use>, <linearGradient>, <filter>, ...)
  - disallowed fill colors (chromatic drift)
  - forbidden decorative effects (filter=, text-shadow, drop-shadow)

Exits non-zero if any hard rule is violated. Prints a single compact report.

Usage:
    python validate_svg.py assets/icons/master.svg
    python validate_svg.py --strict assets/icons/variants/*.svg
"""

from __future__ import annotations

import argparse
import re
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

# ---------------------------------------------------------------------------
# Contract
# ---------------------------------------------------------------------------

SVG_NS = "http://www.w3.org/2000/svg"

REQUIRED_VIEWBOX = "0 0 100 100"

FORBIDDEN_ELEMENTS = {
    "linearGradient", "radialGradient", "filter", "feGaussianBlur",
    "feDropShadow", "feOffset", "feMerge", "feColorMatrix",
    "text", "tspan", "textPath", "font", "font-face",
    "use", "image", "foreignObject", "mask", "pattern",
}

# Fill/stroke values that are always allowed.
ALLOWED_COLOR_TOKENS = {
    "none", "currentColor",
    # heimdall palette from DESIGN.md
    "#000", "#fff", "#000000", "#ffffff",
    "#e8e8e8", "#1a1a1a",
    "#d71921",  # optional accent pip (one per mark)
}

HEX_RE = re.compile(r"^#[0-9a-f]{3,8}$", re.IGNORECASE)
ARC_CMD_RE = re.compile(
    # A rx ry x-rot large-arc sweep x y  (flags must be 0 or 1)
    r"[Aa]\s*([\d.\-]+)[\s,]+([\d.\-]+)[\s,]+([\d.\-]+)[\s,]+"
    r"([01])[\s,]+([01])[\s,]+([\d.\-]+)[\s,]+([\d.\-]+)"
)
ARC_CMD_LAX_RE = re.compile(r"[Aa]\s+[^MLHVCSQTAZmlhvcsqtaz]+")
COORDINATE_RE = re.compile(r"-?\d+\.?\d*")
FILL_ATTR_RE = re.compile(r"fill\s*=\s*[\"']([^\"']+)[\"']", re.IGNORECASE)


@dataclass
class Report:
    path: Path
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)

    @property
    def ok(self) -> bool:
        return not self.errors


# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------

def _strip_ns(tag: str) -> str:
    return tag.split("}", 1)[-1] if "}" in tag else tag


def check_viewbox(root: ET.Element, r: Report) -> None:
    vb = root.attrib.get("viewBox", "").strip()
    if not vb:
        r.errors.append("viewBox attribute missing on <svg>")
    elif vb != REQUIRED_VIEWBOX:
        r.errors.append(
            f"viewBox='{vb}' (must be '{REQUIRED_VIEWBOX}')"
        )


def check_forbidden_elements(root: ET.Element, r: Report) -> None:
    for el in root.iter():
        name = _strip_ns(el.tag)
        if name in FORBIDDEN_ELEMENTS:
            r.errors.append(f"forbidden element <{name}>")


def check_forbidden_attrs(root: ET.Element, r: Report) -> None:
    for el in root.iter():
        # filter= on any element
        if "filter" in el.attrib:
            r.errors.append(f"forbidden attribute filter= on <{_strip_ns(el.tag)}>")
        # style= containing banned decorations
        style = el.attrib.get("style", "").lower()
        for banned in ("text-shadow", "drop-shadow", "box-shadow", "filter:"):
            if banned in style:
                r.errors.append(f"forbidden style fragment '{banned}' on <{_strip_ns(el.tag)}>")


def _check_color_value(value: str, attr: str, el_name: str, r: Report) -> None:
    v = value.strip()
    if v.lower() in (t.lower() for t in ALLOWED_COLOR_TOKENS):
        return
    # url() -- often means gradient/filter reference
    if v.lower().startswith("url("):
        r.errors.append(f"{attr}='{v}' on <{el_name}> references a gradient/filter (forbidden)")
        return
    # raw hex outside allowed list
    if HEX_RE.match(v):
        r.errors.append(f"disallowed {attr}='{v}' on <{el_name}> — not in heimdall palette")
        return
    # named color
    r.warnings.append(f"non-token {attr}='{v}' on <{el_name}> (prefer currentColor)")


def check_color_discipline(root: ET.Element, r: Report) -> None:
    for el in root.iter():
        name = _strip_ns(el.tag)
        for attr in ("fill", "stroke"):
            if attr in el.attrib:
                _check_color_value(el.attrib[attr], attr, name, r)


def check_accent_singleton(root: ET.Element, r: Report) -> None:
    """The #D71921 pip may appear at most once — enforces brief's 'one red pip' rule."""
    count = 0
    for el in root.iter():
        for attr in ("fill", "stroke"):
            v = el.attrib.get(attr, "").lower().strip()
            if v == "#d71921":
                count += 1
    if count > 1:
        r.errors.append(
            f"accent #D71921 appears {count} times — brief allows exactly one"
        )
    elif count == 1:
        r.notes.append("accent #D71921 present (1 instance — within rule)")


def check_filled_paths_closed(root: ET.Element, r: Report) -> None:
    for el in root.iter():
        if _strip_ns(el.tag) != "path":
            continue
        d = el.attrib.get("d", "").strip()
        fill = el.attrib.get("fill", "").strip().lower()
        if not d:
            r.errors.append("<path> has empty d= attribute")
            continue
        # A filled path (fill != none) must end with Z or z.
        has_fill = fill not in ("", "none")
        if has_fill and not d.rstrip().endswith(("Z", "z")):
            r.errors.append(
                f"filled <path fill='{fill or 'default'}'> does not end with Z "
                "(browsers auto-close but the shape is ambiguous)"
            )


def check_arc_flags(root: ET.Element, r: Report) -> None:
    """Arc-flag self-critique: flag every arc so a human verifies sweep/large-arc."""
    for el in root.iter():
        if _strip_ns(el.tag) != "path":
            continue
        d = el.attrib.get("d", "")
        # Quick presence test.
        if "A" not in d and "a" not in d:
            continue
        valid_arcs = ARC_CMD_RE.findall(d)
        lax = ARC_CMD_LAX_RE.findall(d)
        if lax and not valid_arcs:
            r.errors.append(
                "<path> contains arc (A/a) command but flags failed to parse as 0/1 — "
                "likely decimal-flag drift (known Opus 4.7 failure mode)"
            )
        elif valid_arcs:
            r.notes.append(
                f"<path> contains {len(valid_arcs)} arc command(s) — "
                "verify large-arc-flag / sweep-flag visually at 16×16 and 1024×1024"
            )


def check_coordinate_range(root: ET.Element, r: Report) -> None:
    """Values should stay within [-5, 105] to allow for stroke overflow but flag drift."""
    for el in root.iter():
        if _strip_ns(el.tag) != "path":
            continue
        d = el.attrib.get("d", "")
        for m in COORDINATE_RE.findall(d):
            try:
                v = float(m)
            except ValueError:
                continue
            if v < -10 or v > 110:
                r.warnings.append(
                    f"path coordinate {v} outside viewBox range — "
                    "possible tokenization drift (known LLM failure mode)"
                )


def check_transforms(root: ET.Element, r: Report) -> None:
    """Transforms on individual paths are forbidden — use on <g> groups only."""
    for el in root.iter():
        name = _strip_ns(el.tag)
        if name == "g" or name == "svg":
            continue
        if "transform" in el.attrib:
            r.warnings.append(
                f"<{name}> has transform= (brief: transforms belong on <g> groups only)"
            )


# ---------------------------------------------------------------------------
# Driver
# ---------------------------------------------------------------------------

def validate(path: Path, strict: bool = False) -> Report:
    r = Report(path=path)
    try:
        tree = ET.parse(path)
    except ET.ParseError as e:
        r.errors.append(f"XML parse error: {e}")
        return r
    root = tree.getroot()
    if _strip_ns(root.tag) != "svg":
        r.errors.append(f"root element is <{_strip_ns(root.tag)}>, not <svg>")
        return r

    check_viewbox(root, r)
    check_forbidden_elements(root, r)
    check_forbidden_attrs(root, r)
    check_color_discipline(root, r)
    check_accent_singleton(root, r)
    check_filled_paths_closed(root, r)
    check_arc_flags(root, r)
    check_coordinate_range(root, r)
    check_transforms(root, r)

    if strict and r.warnings:
        r.errors.extend(f"(strict mode) {w}" for w in r.warnings)
        r.warnings.clear()

    return r


def print_report(r: Report) -> None:
    badge = "[OK]  " if r.ok else "[FAIL]"
    print(f"{badge} {r.path}")
    for e in r.errors:
        print(f"    ERROR: {e}")
    for w in r.warnings:
        print(f"    warn:  {w}")
    for n in r.notes:
        print(f"    note:  {n}")


def main() -> int:
    p = argparse.ArgumentParser(description="Validate heimdall logo SVG against the grammar contract")
    p.add_argument("svg_files", nargs="+", help="one or more SVG files")
    p.add_argument("--strict", action="store_true", help="promote warnings to errors")
    args = p.parse_args()

    any_fail = False
    for f in args.svg_files:
        r = validate(Path(f), strict=args.strict)
        print_report(r)
        if not r.ok:
            any_fail = True
    if any_fail:
        print("\n[FAIL] one or more SVG files violate the heimdall grammar contract")
        return 1
    print("\n[OK] all SVG files pass the heimdall grammar contract")
    return 0


if __name__ == "__main__":
    sys.exit(main())
