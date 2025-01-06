from PIL import Image, ImageDraw, ImageFont
import os
import json

def create_anie_icon(size):
    # Create a square transparent image
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Scale inset and corner radius proportionally
    scale_factor = size / 1024
    inset = int(60 * scale_factor)
    corner_radius = int(100 * scale_factor)
    
    # Calculate rectangle dimensions
    rect_coords = [inset, inset, size-inset, size-inset]
    draw.rounded_rectangle(rect_coords, fill=(0, 0, 0), radius=corner_radius)
    
    # Scale font size proportionally
    try:
        font_size = int(400 * scale_factor)
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", font_size)
    except:
        try:
            font = ImageFont.truetype("/Library/Fonts/Arial Bold.ttf", font_size)
        except:
            font = ImageFont.load_default()
    
    colors = {
        'A': (255, 255, 255),
        'N': (0, 144, 255),
        'I': (255, 255, 255),
        'E': (0, 144, 255)
    }
    
    # Calculate positions for 2x2 grid
    spacing = int(10 * scale_factor)
    
    # First row - "AN"
    text_top = "AN"
    bbox_top = draw.textbbox((0, 0), text_top, font=font)
    width_top = bbox_top[2] - bbox_top[0]
    height_top = bbox_top[3] - bbox_top[1]
    
    # Second row - "IE"
    text_bottom = "IE"
    bbox_bottom = draw.textbbox((0, 0), text_bottom, font=font)
    width_bottom = bbox_bottom[2] - bbox_bottom[0]
    
    # Calculate vertical positions with scaled upward shift
    total_height = height_top * 2 + spacing
    start_y = (size - total_height) // 2 - int(80 * scale_factor)
    
    # Draw top row (AN)
    x = (size - width_top) // 2
    y = start_y
    
    for letter in text_top:
        letter_bbox = draw.textbbox((0, 0), letter, font=font)
        letter_width = letter_bbox[2] - letter_bbox[0]
        draw.text((x, y), letter, fill=colors[letter], font=font)
        x += letter_width + spacing
    
    # Draw bottom row (IE)
    base_x = (size - width_bottom) // 2
    y = start_y + height_top + spacing
    
    # Draw I
    letter_bbox = draw.textbbox((0, 0), "I", font=font)
    letter_width = letter_bbox[2] - letter_bbox[0]
    draw.text((base_x - int(15 * scale_factor), y), "I", fill=colors["I"], font=font)
    
    # Draw E
    letter_bbox = draw.textbbox((0, 0), "E", font=font)
    letter_width = letter_bbox[2] - letter_bbox[0]
    draw.text((base_x + letter_width + spacing - int(68 * scale_factor), y), "E", fill=colors["E"], font=font)
    
    return img

def create_icon_set():
    # Create AppIcon.appiconset directory if it doesn't exist
    icon_dir = "Assets.xcassets/AppIcon.appiconset"
    os.makedirs(icon_dir, exist_ok=True)
    
    # Define required sizes for macOS
    icon_sizes = {
        "16x16": [16, 32],     # 1x and 2x
        "32x32": [32, 64],     # 1x and 2x
        "128x128": [128, 256], # 1x and 2x
        "256x256": [256, 512], # 1x and 2x
        "512x512": [512, 1024] # 1x and 2x
    }
    
    # Create Contents.json data
    contents = {
        "images": [],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    # Generate icons for each size
    for base_size, scales in icon_sizes.items():
        width = int(base_size.split("x")[0])
        for size in scales:
            filename = f"icon_{size}x{size}.png"
            icon = create_anie_icon(size)
            icon.save(os.path.join(icon_dir, filename))
            
            # Add entry to Contents.json
            contents["images"].append({
                "size": base_size,
                "idiom": "mac",
                "filename": filename,
                "scale": f"{size//width}x"
            })
    
    # Save Contents.json
    with open(os.path.join(icon_dir, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)
    
    print("Icon set created successfully!")

if __name__ == "__main__":
    create_icon_set()