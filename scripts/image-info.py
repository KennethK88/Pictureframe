#!/usr/bin/env python3

"""
Reads image dimensions from JPEG and PNG files.

Extracts image dimensions directly from file headers without
decoding the image data.

Outputs width, height, and pixel count as semicolon-separated values.
"""

import struct
import sys
from pathlib import Path


JPEG_SOF_MARKERS = {
    0xC0, 0xC1, 0xC2, 0xC3,
    0xC5, 0xC6, 0xC7,
    0xC9, 0xCA, 0xCB,
    0xCD, 0xCE, 0xCF,
}


def get_jpeg_size(path: Path):
    """
    Reads the dimensions of a JPEG image.

    Searches the JPEG file for a Start of Frame marker containing
    the image dimensions.

    Args:
        path: Path to the JPEG file.

    Returns:
        Tuple containing width and height, or None if the
        dimensions cannot be determined.
    """
    with path.open("rb") as file:
        if file.read(2) != b"\xff\xd8":
            return None

        while True:
            byte = file.read(1)
            if not byte:
                return None

            if byte != b"\xff":
                continue

            marker_byte = file.read(1)
            if not marker_byte:
                return None

            while marker_byte == b"\xff":
                marker_byte = file.read(1)
                if not marker_byte:
                    return None

            marker = marker_byte[0]

            if marker in JPEG_SOF_MARKERS:
                segment_length = file.read(2)
                if len(segment_length) != 2:
                    return None

                file.read(1)  # precision

                size_data = file.read(4)
                if len(size_data) != 4:
                    return None

                height, width = struct.unpack(">HH", size_data)
                return width, height

            # Standalone markers without payload length
            if marker in range(0xD0, 0xD8) or marker in (0xD8, 0xD9, 0x01):
                continue

            length_data = file.read(2)
            if len(length_data) != 2:
                return None

            segment_length = struct.unpack(">H", length_data)[0]
            if segment_length < 2:
                return None

            file.seek(segment_length - 2, 1)


def get_png_size(path: Path):
    """
    Reads the dimensions of a PNG image.

    Extracts width and height directly from the PNG header.

    Args:
        path: Path to the PNG file.

    Returns:
        Tuple containing width and height, or None if the
        PNG signature is invalid.
    """
    with path.open("rb") as file:
        header = file.read(24)

        if not header.startswith(b"\x89PNG\r\n\x1a\n"):
            return None

        width, height = struct.unpack(">II", header[16:24])
        return width, height


def get_image_size(path: Path):
    """
    Determines the dimensions of a supported image file.

    Selects the appropriate reader based on the file extension.

    Args:
        path: Path to the image file.

    Returns:
        Tuple containing width and height, or None if the
        image format is unsupported or dimensions cannot be determined.
    """
    suffix = path.suffix.lower()

    if suffix in (".jpg", ".jpeg"):
        return get_jpeg_size(path)

    if suffix == ".png":
        return get_png_size(path)

    return None


def main():
    """
    Executes the image information command-line utility.

    Reads the dimensions of the specified image and prints
    width, height, and pixel count separated by semicolons.

    Returns:
        0 on success, 1 if image processing fails,
        or 2 if the command-line arguments are invalid.
    """
    if len(sys.argv) != 2:
        print("Usage: image-info.py <image-file>", file=sys.stderr)
        return 2

    path = Path(sys.argv[1])

    try:
        size = get_image_size(path)
    except OSError as error:
        print(f"Failed to read image: {error}", file=sys.stderr)
        return 1

    if size is None:
        print(f"Unsupported or unreadable image: {path}", file=sys.stderr)
        return 1

    width, height = size
    pixels = width * height

    print(f"{width};{height};{pixels}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())