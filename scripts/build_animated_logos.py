#!/usr/bin/env python3
"""Generate the animated TaifaHealth logo SVGs in brand/svg/animated/.

Each output layers the brand background, the capsule mark, and the cross
mark in one self-contained SVG and alternates between the two marks with
embedded CSS keyframes (6s loop, matching the Logo Preview design file).
CSS animations run even when the SVG is loaded through an <img> tag.

The flip variant emulates the preview's rotateY() with scaleX(), because
3D transforms on SVG elements are unreliable in Safari.

Run from the repository root: python3 scripts/build_animated_logos.py
"""

from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "brand" / "svg" / "animated"

# Keyframes per variant: (name, rules for layer a, rules for layer b).
VARIANTS = {
    "crossfade": (
        "0%,40%{opacity:1}50%,90%{opacity:0}100%{opacity:1}",
        "0%,40%{opacity:0}50%,90%{opacity:1}100%{opacity:0}",
    ),
    "rotate": (
        "0%,40%{transform:rotate(0deg);opacity:1}"
        "50%,90%{transform:rotate(90deg);opacity:0}"
        "100%{transform:rotate(0deg);opacity:1}",
        "0%,40%{transform:rotate(-90deg);opacity:0}"
        "50%,90%{transform:rotate(0deg);opacity:1}"
        "100%{transform:rotate(-90deg);opacity:0}",
    ),
    # scaleX(cos t) stands in for rotateY(t); opacity hides the swap.
    "flip": (
        "0%,44%{transform:scaleX(1);opacity:1}"
        "46%,89%{opacity:0}"
        "50%,90%{transform:scaleX(-1)}"
        "100%{transform:scaleX(1);opacity:1}",
        "0%,44%{transform:scaleX(-1);opacity:0}"
        "46%,89%{opacity:1}"
        "50%,90%{transform:scaleX(1)}"
        "94%{opacity:0}"
        "100%{transform:scaleX(-1);opacity:0}",
    ),
    "pop": (
        "0%,40%{transform:scale(1);opacity:1}"
        "50%,90%{transform:scale(0);opacity:0}"
        "100%{transform:scale(1);opacity:1}",
        "0%,40%{transform:scale(0);opacity:0}"
        "52%{transform:scale(1.08);opacity:1}"
        "56%,90%{transform:scale(1);opacity:1}"
        "100%{transform:scale(0);opacity:0}",
    ),
}

CAPSULE = 'x="192" y="382" width="640" height="260" rx="130" transform="rotate(-45 512 512)"'

TEMPLATE = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
  <style>
    @keyframes {p}A {{{a}}}
    @keyframes {p}B {{{b}}}
    .{p}-a, .{p}-b {{
      transform-box: view-box;
      transform-origin: center;
      animation: 6s ease-in-out infinite;
    }}
    .{p}-a {{ animation-name: {p}A; }}
    .{p}-b {{ animation-name: {p}B; }}
    @media (prefers-reduced-motion: reduce) {{
      .{p}-a, .{p}-b {{ animation: none; }}
      .{p}-b {{ opacity: 0; }}
    }}
  </style>
  <defs>
    <clipPath id="{p}-sq"><rect x="112" y="112" width="800" height="800" rx="180"/></clipPath>
    <clipPath id="{p}-pill"><rect {capsule}/></clipPath>
    <clipPath id="{p}-pv"><rect x="422" y="212" width="180" height="600" rx="90"/></clipPath>
    <clipPath id="{p}-ph"><rect x="212" y="422" width="600" height="180" rx="90"/></clipPath>
  </defs>
  <g clip-path="url(#{p}-sq)">
    <rect x="112" y="112" width="800" height="800" fill="#E02128"/>
    <polygon points="404,912 912,404 912,912" fill="#0B8A44"/>
  </g>
  <g class="{p}-a">
    <rect {capsule} fill="none" stroke="#FFFFFF" stroke-width="40"/>
    <g clip-path="url(#{p}-pill)">
      <rect {capsule} fill="#FFFFFF"/>
      <rect x="192" y="382" width="320" height="260" transform="rotate(-45 512 512)" fill="#0B8A44"/>
      <path d="M 344 704 Q 302 662 310 606" fill="none" stroke="#FFFFFF" stroke-width="24" stroke-linecap="round"/>
    </g>
  </g>
  <g class="{p}-b">
    <rect x="212" y="422" width="600" height="180" rx="90" fill="none" stroke="#FFFFFF" stroke-width="40"/>
    <g clip-path="url(#{p}-ph)">
      <rect x="212" y="422" width="300" height="180" fill="#0B8A44"/>
      <rect x="512" y="422" width="300" height="180" fill="#FFFFFF"/>
    </g>
    <rect x="422" y="212" width="180" height="600" rx="90" fill="none" stroke="#FFFFFF" stroke-width="40"/>
    <g clip-path="url(#{p}-pv)">
      <rect x="422" y="212" width="180" height="390" fill="#FFFFFF"/>
      <rect x="422" y="622" width="180" height="190" fill="#1565C0"/>
      <path d="M 462 748 Q 442 708 446 652" fill="none" stroke="#FFFFFF" stroke-width="20" stroke-linecap="round"/>
    </g>
  </g>
</svg>
"""


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (a, b) in VARIANTS.items():
        # Short unique prefix keeps ids from colliding if files are inlined
        # into the same document.
        prefix = f"th-{name[:2]}"
        svg = TEMPLATE.format(p=prefix, a=a, b=b, capsule=CAPSULE)
        path = OUT / f"logo-{name}.svg"
        path.write_text(svg)
        print(f"wrote {path.relative_to(OUT.parent.parent.parent)}")


if __name__ == "__main__":
    main()
