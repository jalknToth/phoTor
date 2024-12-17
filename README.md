# Photor

Image Editing Web App built with Flask that provides a set of image editing tools.  It allows users to upload images and perform various operations like cropping, inverting colors, creating square images, and splitting images into grids.

## Features

* **Crop to Square:** Crop images to a perfect square, either by centering the image and cropping the excess or by padding the image with a chosen background color.
* **Invert Colors:** Invert the colors of an image.
* **Create Square Image:** Generate a square image of a specified size and color.
* **Split Image into Grid:** Divide an image into a grid of smaller square images.
* **User Authentication:** Secure user accounts with login and registration. (Implementation in progress)
* **File Management:** Upload and manage image files. (Implementation in progress)

## Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/jalknToth/phoTor.git
   ```

2. **Run the setup script:**

   ```bash
   chmod +x run.sh
   ./run.sh
   ```
   This script will:
   - Create the project directory structure.
   - Generate the `.env` file.  **Important:**  Edit the `.env` file with your MySQL credentials.
   - Create a virtual environment and install the required dependencies.
   - Set appropriate file permissions.

3. **Run the application:**

   ```bash
   flask run
   ```

## Usage
1. Navigate to `http://127.0.0.1:5000/` in your web browser.
2. Upload your images and use the available editing tools.

## Project Structure

```
photor/
├── src/                  
│   ├── cropSquare.py
│   ├── invertColor.py
│   ├── makeSquare.py
│   ├── splitIMG.py
│   ├── files.py        
│   └── dashboard.py         
├── upload/              
├── download/            
├── .env                 
├── .gitignore          
├── app.py              
├── requirements.txt    
└── setup.sh             
```

## Contributing

Contributions are welcome!  Please fork the repository and submit a pull request.