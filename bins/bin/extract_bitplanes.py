#!/usr/bin/env python3
"""
Extract bit planes from an 8-bit RGB image.

Notes
- This works on the decoded pixel values, not on JPEG's internal DCT coefficients.
- JPEG is lossy, so the extracted bit planes are from the decompressed image.
- Optional: convert to YCbCr first, then extract bit planes from Y, Cb, Cr.

Usage
-----
RGB bit planes:
    python extract_bitplanes.py input.jpg -o out_dir

YCbCr bit planes:
    python extract_bitplanes.py input.jpg -o out_dir --colorspace ycbcr

Requirements
------------
    pip install pillow numpy
"""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image


CHANNEL_NAMES = {
    "rgb": ["R", "G", "B"],
    "ycbcr": ["Y", "Cb", "Cr"],
}


def save_image(arr: np.ndarray, path: Path) -> None:
    """
    Save a 2D uint8 array as grayscale image.
    """
    img = Image.fromarray(arr.astype(np.uint8), mode="L")
    img.save(path)


def extract_bitplanes(channel: np.ndarray) -> list[np.ndarray]:
    """
    Extract 8 bit planes from one 8-bit channel.

    Returns:
        List of 8 arrays:
        index 0 = bit 0 (LSB, least significant bit)
        index 7 = bit 7 (MSB, most significant bit)

    Each output plane is scaled to 0 or 255 for visualization.
    """
    planes = []
    for bit in range(8):
        plane = ((channel >> bit) & 1) * 255
        planes.append(plane.astype(np.uint8))
    return planes


def process_image(input_path: Path, output_dir: Path, colorspace: str) -> None:
    """
    Load image, optionally convert colorspace, and save all bit planes.
    """
    if colorspace not in ("rgb", "ycbcr"):
        raise ValueError("colorspace must be 'rgb' or 'ycbcr'")

    img = Image.open(input_path)

    if colorspace == "rgb":
        img = img.convert("RGB")
    else:
        img = img.convert("YCbCr")

    arr = np.array(img, dtype=np.uint8)  # shape: (H, W, 3)
    channel_names = CHANNEL_NAMES[colorspace]

    output_dir.mkdir(parents=True, exist_ok=True)

    # Save full channels too
    for c, name in enumerate(channel_names):
        save_image(arr[:, :, c], output_dir / f"{name}_channel.png")

    # Extract and save bit planes
    for c, name in enumerate(channel_names):
        planes = extract_bitplanes(arr[:, :, c])

        for bit, plane in enumerate(planes):
            save_image(plane, output_dir / f"{name}_bit{bit}.png")

    # Optional: combined visualization strips for each channel
    for c, name in enumerate(channel_names):
        planes = extract_bitplanes(arr[:, :, c])

        # Put MSB on the left, LSB on the right
        strip = np.hstack([planes[bit] for bit in range(7, -1, -1)])
        save_image(strip, output_dir / f"{name}_bitplanes_strip_MSB_to_LSB.png")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract bit planes from an 8-bit RGB JPEG image."
    )
    parser.add_argument("input", type=Path, help="Input image path")
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("bitplanes_out"),
        help="Output directory",
    )
    parser.add_argument(
        "--colorspace",
        choices=["rgb", "ycbcr"],
        default="rgb",
        help="Extract bit planes in RGB or YCbCr space",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    process_image(args.input, args.output, args.colorspace)


if __name__ == "__main__":
    main()
