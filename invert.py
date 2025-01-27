from PIL import Image
import numpy as np

def invert_image(image_path, save_path=None):
    """
    Invert colors of an image using PIL.
    
    Parameters:
    image_path (str): Path to the input image
    save_path (str): Path to save the inverted image. If None, will add '_inverted' to original name
    
    Returns:
    str: Path to the saved inverted image
    """
    # Open the image
    img = Image.open(image_path)
    
    # Convert image to RGB if it's not
    if img.mode != 'RGB':
        img = img.convert('RGB')
    
    # Convert to numpy array and invert colors
    img_array = np.array(img)
    inverted_array = 255 - img_array
    
    # Convert back to PIL Image
    inverted_image = Image.fromarray(inverted_array)
    
    # Generate save path if not provided
    if save_path is None:
        name, ext = image_path.rsplit('.', 1)
        save_path = f"{name}_inverted.{ext}"
    
    # Save the inverted image
    inverted_image.save(save_path)
    return save_path

# Example usage
original_image = "2.jpg"
inverted_image = invert_image(original_image)
print(f"Inverted image saved to: {inverted_image}")