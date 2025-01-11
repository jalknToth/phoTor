from PIL import Image, ImageOps

def invert_png_color(input_path, output_path=None):

    # Open the image
    with Image.open(input_path) as img:
        # Ensure the image is in RGB mode
        if img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Invert the colors
        inverted_img = ImageOps.invert(img)
        
        # Determine output path
        if output_path is None:
            # Insert '_inverted' before the file extension
            parts = input_path.rsplit('.', 1)
            output_path = f"{parts[0]}_inverted.{parts[1]}"
        
        # Save the inverted image
        inverted_img.save(output_path)
        
        return output_path