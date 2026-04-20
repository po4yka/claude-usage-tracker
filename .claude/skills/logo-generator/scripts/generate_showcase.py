#!/usr/bin/env python3
"""
Generate heimdall logo showcase images using Nano Banana (Gemini Image Generation API).
Supports both the official Google API and third-party API endpoints.

Adapted from blog/.claude/skills/logo-generator/scripts/generate_showcase.py.
Prompts are re-skinned for heimdall's industrial-design palette (OLED black / warm
off-white), defaults reordered (void + clinical + swiss_flat lead), and the banned
style list stays intact — DESIGN.md forbids chromatic accents, gradients, and glow.
"""

import os
import sys
import base64
import argparse
from pathlib import Path
from typing import Optional
from dotenv import load_dotenv

try:
    from google import genai
    from google.genai import types
except ImportError:
    print("Error: google-genai package not installed.")
    print("Install with: pip install google-genai")
    sys.exit(1)

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_API_BASE_URL = os.getenv("GEMINI_API_BASE_URL", "").strip()
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-3.1-flash-image-preview")

# Background style prompts — tuned for heimdall's industrial monochrome system.
# The upstream 12-style set has been trimmed to the 6 styles compatible with DESIGN.md.
# Banned (do NOT re-add): fluid, analog_liquid, led_matrix, iridescent, morning, ui_container —
# each introduces chromatic accent, iridescence, glow, or gradients that violate DESIGN.md.
BACKGROUND_STYLES = {
    "void": """THE VOID
Absolute OLED black (#000000) background with extremely fine silver/white high-contrast
micro noise. Cold, sharp electronic film grain texture. Minimal atmosphere light - only
a faint icy white glow at one extreme corner, like distant starlight at the edge of the
universe. No chromatic tint. Pure neutral greyscale only. High-contrast editorial
framing; use for press moments rather than everyday renders.""",

    "frosted": """FROSTED HORIZON
Deep titanium gray or midnight slate gray base, not pure black. Organic film-like dust
noise texture, resembling unpolished rough metal or stone surface. Large area but
extremely low saturation neutral-gray light halo (no blue cast), edges completely
dissolved like mist. Stay strictly in neutral greys — heimdall forbids chromatic cast.""",

    "spotlight": """STUDIO SPOTLIGHT
Extremely dark warm carbon gray base. Slightly larger grain simulating low-light camera
photography, like paper print grain in weak light. Single-side softbox or spotlight
creating natural vignette, editorial magazine quality with professional photography
feel. Strictly monochrome — no chromatic cast.""",

    "editorial": """EDITORIAL PAPER
Off-white, alabaster, or pearl white base (not pure white). High-grade watercolor or
rough art paper texture suggesting physical paper tactile quality. Natural light
diffuse reflection with slight warm gray vignette in corners. Humanistic, independent
magazine aesthetic. No chromatic accent — only warm neutral paper tones.""",

    "clinical": """CLINICAL STUDIO
Pure white or extremely light cold gray base, aligned with heimdall's warm off-white
canvas (#F5F5F5). High-frequency sharp cold-toned digital micro noise with enhanced
sharpness. Pure light/shadow structure — large softbox from top/side creating smooth
gray-white gradient. Sterile space with geometric order, creating 3D depth in 2D
presentation. Heimdall's canonical "printed technical manual" framing.
Strictly greyscale — no color.""",

    "swiss_flat": """SWISS FLAT
100% pure solid color background. Choose ONE of heimdall's canvas or surface tokens
only: OLED black (#000000), card surface dark (#111111), warm off-white (#F5F5F5),
or card surface light (#FFFFFF). No vintage greens, burgundies, or navies.
Absolutely no gradients, no noise, no effects. Pure graphic design with zero tricks.
Just perfect neutral color and form. Classic Swiss International Style with absolute
flatness."""
}


def load_reference_image(image_path: str) -> Optional[str]:
    """Load and encode reference image to base64."""
    try:
        with open(image_path, 'rb') as f:
            image_data = f.read()
        return base64.b64encode(image_data).decode('utf-8')
    except Exception as e:
        print(f"Error loading reference image: {e}")
        return None


def generate_showcase_image(
    logo_name: str,
    reference_image_path: str,
    style: str,
    output_path: str,
    product_description: str = ""
) -> bool:
    """
    Generate a showcase image using Nano Banana API.

    Args:
        logo_name: Name of the logo/product (e.g. "heimdall")
        reference_image_path: Path to the reference logo image (SVG exported as PNG)
        style: Background style key (void, frosted, spotlight, editorial, clinical, swiss_flat)
        output_path: Path to save the generated image
        product_description: Optional product description for context

    Returns:
        True if successful, False otherwise
    """
    if not GEMINI_API_KEY:
        print("Error: GEMINI_API_KEY not set in environment")
        return False

    if style not in BACKGROUND_STYLES:
        print(f"Error: Unknown style '{style}'. Available: {list(BACKGROUND_STYLES.keys())}")
        return False

    reference_image_b64 = load_reference_image(reference_image_path)
    if not reference_image_b64:
        return False

    style_description = BACKGROUND_STYLES[style]

    # Dark backgrounds use white mark (heimdall --text-display #FFFFFF);
    # light backgrounds use black mark (heimdall --text-display #000000).
    # swiss_flat defaults to dark treatment; override if the user targets a light token.
    dark_styles = ["void", "frosted", "spotlight", "swiss_flat"]
    is_dark_bg = style in dark_styles
    logo_color = "pure white (#FFFFFF)" if is_dark_bg else "pure black (#000000)"

    prompt = f"""Extract the core graphic from the reference image as a pure flat single-color
vector structure, removing all decorations. Use high-contrast atmosphere background, delicate
film grain noise, and rigorous micro-typography to create a cutting-edge, restrained, and
highly digital order showcase effect.

LOGO PROCESSING:
- Strip background and outer frames
- Extract core graphic only, preserve graphic details
- Extremely flat: 100% solid color flat vector in {logo_color}
- Sharp, clear edges
- The logo MUST be rendered in {logo_color} to ensure maximum contrast with the background
- No gradients, no glow, no drop shadow, no halo, no phosphor — these are banned by the
  heimdall design system

BACKGROUND CONSTRUCTION:
{style_description}

TYPOGRAPHY AND LAYOUT:
Use classic Swiss-style typography logic with extreme proportion contrast.

- Main subject centered: Place the pure flat logo graphic at the absolute visual center
  with huge breathing space
- Micro-typography: Remove any large, obtrusive titles. Use extremely small font size
  (6pt to 9pt) and clean sans-serif fonts (Inter, Geist Mono, Helvetica)
  in corners or bottom center
- Text content suggestions (strictly aligned):
  Left corner: {logo_name.upper()}
  Right corner: v. 1.0.0 // 2026
  Bottom center: {product_description.upper() if product_description else 'LOCAL AI SESSION OBSERVABILITY'}

CRITICAL: The logo graphic MUST be {logo_color}, perfectly centered, extracted from the
reference image, rendered as pure flat vector with sharp edges. No chromatic cast anywhere
in the output — heimdall is strictly monochrome."""

    try:
        client_config = {"api_key": GEMINI_API_KEY}
        if GEMINI_API_BASE_URL:
            client_config["http_options"] = {"api_endpoint": GEMINI_API_BASE_URL}

        client = genai.Client(**client_config)

        contents = [
            types.Part.from_bytes(
                data=base64.b64decode(reference_image_b64),
                mime_type="image/png"
            ),
            types.Part.from_text(text=prompt)
        ]

        print(f"Generating showcase image with style: {style}")
        print(f"Using model: {GEMINI_MODEL}")
        if GEMINI_API_BASE_URL:
            print(f"Using custom API endpoint: {GEMINI_API_BASE_URL}")

        response = client.models.generate_content(
            model=GEMINI_MODEL,
            contents=contents,
            config=types.GenerateContentConfig(
                response_modalities=["IMAGE"],
                image_config=types.ImageConfig(
                    aspect_ratio="16:9",
                    image_size="2K"
                )
            )
        )

        for part in response.parts:
            if part.inline_data is not None:
                image = part.as_image()
                image.save(output_path)
                print(f"[OK] Showcase image saved: {output_path}")
                return True
            elif part.text is not None:
                print(f"Model response: {part.text}")

        print("Error: No image generated in response")
        return False

    except Exception as e:
        print(f"Error generating showcase image: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Generate heimdall logo showcase images using Nano Banana API"
    )
    parser.add_argument("logo_name", help="Name of the logo/product (e.g. heimdall)")
    parser.add_argument("reference_image", help="Path to reference logo image (PNG)")
    parser.add_argument("--style",
                       choices=list(BACKGROUND_STYLES.keys()),
                       default="void",
                       help="Background style (default: void — heimdall's canonical dark framing)")
    parser.add_argument("--output", "-o",
                       help="Output path (default: output/{logo_name}_{style}.png)")
    parser.add_argument("--description", "-d",
                       default="",
                       help="Product description for context")
    parser.add_argument("--all-styles",
                       action="store_true",
                       help="Generate all 6 on-brand styles")

    args = parser.parse_args()

    output_dir = Path("output")
    output_dir.mkdir(exist_ok=True)

    if args.all_styles:
        success_count = 0
        for style in BACKGROUND_STYLES.keys():
            output_path = output_dir / f"{args.logo_name}_{style}.png"
            if generate_showcase_image(
                args.logo_name,
                args.reference_image,
                style,
                str(output_path),
                args.description
            ):
                success_count += 1

        print(f"\n[OK] Generated {success_count}/{len(BACKGROUND_STYLES)} showcase images")
    else:
        if args.output:
            output_path = args.output
        else:
            output_path = output_dir / f"{args.logo_name}_{args.style}.png"

        success = generate_showcase_image(
            args.logo_name,
            args.reference_image,
            args.style,
            str(output_path),
            args.description
        )

        sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
