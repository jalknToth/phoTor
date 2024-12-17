#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

set -e

createStructure() {
    echo -e "${YELLOW}🏗️ Creating Photor Directory Structure${NC}"

    # Create the main project directory
    mkdir -p {src,upload,download} || { echo "Error creating directories"; exit 1; }

    # Create other project files in the root
    touch .git .env .gitignore app.py

    # Create Python files in src/
    touch src/cropSquare.py
    touch src/invertColor.py
    touch src/makeSquare.py
    touch src/splitIMG.py
    touch src/files.py
    touch src/dashboard.py

    echo "Project structure created successfully."
}

gitignore() {
    echo -e "${YELLOW}♠︎ Generating .gitignore file${NC}"
    cat > .gitignore << EOL
.vscode
__pycache__
*.pyc
.venv
.env
EOL
}

creatEnv() {
    echo -e "${YELLOW}🔐 Generating .env file${NC}"
    cat > .env << EOL
# Flask Configuration
FLASK_APP=app.py
FLASK_ENV=development
SECRET_KEY=$(openssl rand -hex 32)

# Upload Configuration
UPLOAD_FOLDER=./uploads
MAX_CONTENT_LENGTH=16777216  # 16MB

# Logging
LOG_LEVEL=INFO
LOG_FILE=./logs/app.log
EOL
}

createApp() {
    echo -e "${YELLOW}🚀 Creating main application file${NC}"
    cat > app.py << EOL
import flask as fk
import waitress as wt
import werkzeug.utils as wk
import os
import dotenv as dt
import secrets as sc

#app set
dt.load_dotenv()
app = fk.Flask(__name__, static_folder='./static', template_folder='./templates')

SECRET_KEY = os.environ.get("SECRET_KEY")
app.secret_key = os.getenv("SECRET_KEY")
if "SECRET_KEY" not in os.environ:
       secret_key = sc.token_hex(32)
       os.environ["SECRET_KEY"] = secret_key
       
# Blueprints
from src.dashboard import dashboardBP
from src.files import filesBP
from src.cropSquare import cropSquareBP
from src.splitIMG import splitIMGBP
from src.makeSquare import makeSquareBP
from src.invertColor import invertColorBP

app.register_blueprint(dashboardBP, url_prefix='/dashboard')
app.register_blueprint(filesBP, url_prefix='/files')
app.register_blueprint(cropSquareBP, url_prefix='/cropSquare')
app.register_blueprint(splitIMGBP, url_prefix='/splitIMG')
app.register_blueprint(makeSquareBP, url_prefix='/makeSquare')
app.register_blueprint(invertColorBP, url_prefix='/invertColor')

@app.route('/')
def index():
    return fk.redirect(fk.url_for('dashboard.dashboard'))

if __name__ == '__main__':
    wt.serve(app, host='0.0.0.0', port=7070)
EOL
}

connectDB() {
    echo -e "${YELLOW}💾 Creating database configuration${NC}"
    cat > src/db.py << EOL
import os
import mysql.connector as sql

#DB set
def getDBconnection():
    try:
        photor = sql.connect(
            host=os.getenv("DB_HOST"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            database=os.getenv("DB_NAME")
        )
        return photor
    except sql.Error as err:
        print('Error de conexión a la base de datos', err)
        return None
EOL
}

cropSquare() {
    echo -e "${YELLOW}💾 Creating cropSquare Routes${NC}"
    cat > src/cropSquare.py << EOL
from PIL import Image

def convert_to_square(input_path, output_path=None, method='crop', background_color='white'):

    # Open the image
    try:
        with Image.open(input_path) as img:
            # Get original image width and height
            width, height = img.size
            
            # Determine the size of the square
            target_size = max(width, height)
            
            # Process image based on method
            if method == 'crop':
                # Calculate cropping box to center the image
                left = (width - target_size) // 2
                top = (height - target_size) // 2
                right = left + target_size
                bottom = top + target_size
                
                squared_img = img.crop((left, top, right, bottom))
            
            elif method == 'pad':
                # Create a new square image with background color
                squared_img = Image.new('RGBA', (target_size, target_size), background_color)
                
                # Calculate paste coordinates to center the original image
                paste_x = (target_size - width) // 2
                paste_y = (target_size - height) // 2
                
                # Paste the original image onto the new square background
                squared_img.paste(img, (paste_x, paste_y), img if img.mode == 'RGBA' else None)
            
            elif method == 'resize':
                # Resize image to a square, which may distort the image
                squared_img = img.resize((target_size, target_size), Image.LANCZOS)
            
            else:
                raise ValueError("Invalid method. Choose 'crop', 'pad', or 'resize'.")
            
            # Save the image if output path is provided
            if output_path:
                squared_img.save(output_path)
                print(f"Squared image saved to: {output_path}")
            
            return squared_img
    
    except FileNotFoundError:
        print(f"Error: File not found at {input_path}")
    except Exception as e:
        print(f"An error occurred: {e}")

# Example usage
if __name__ == "__main__":
    # Basic usage - crop method
    convert_to_square('11.png', 'output_crop.png', method='crop')
    
    # Pad method with custom background
    convert_to_square('11.png', 'output_pad.png', method='pad', background_color='lightblue')
    
    # Resize method (not recommended if you want to preserve image proportions)
    convert_to_square('11.png', 'output_resize.png', method='resize')
EOL
}

invertColor() {
    echo -e "${YELLOW}💾 Creating invertColor Routes${NC}"
    cat > src/invertColor.py << EOL
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

# Example usage
if __name__ == "__main__":
    # Simple example of inverting an image
    try:
        # Invert an image and save with default naming
        inverted_image_path = invert_png_color('fav.png')
        print(f"Inverted image saved to: {inverted_image_path}")
        
        # Invert an image and specify a custom output path
        custom_inverted_path = invert_png_color('fav.png', 'inverted.png')
        print(f"Custom inverted image saved to: {custom_inverted_path}")
    
    except FileNotFoundError:
        print("Error: Image file not found.")
    except Exception as e:
        print(f"An error occurred: {e}")
EOL
}

createDashPy() {
    echo -e "${YELLOW}💾 Creating Dashboard Routes${NC}"
    cat > src/dashboard.py << EOL
import flask as fk

dashboardBP = fk.Blueprint('dashboard', __name__)

@dashboardBP.route('/')  
def dashboard():
        return fk.render_template('dashboard.html') 

@dashboardBP.route('/files') 
def files():
       return fk.render_template('files.html')

EOL
}

makeSquare() {
    echo -e "${YELLOW}💾 Creating makeSquare Routes${NC}"
    cat > src/makeSquare.py << EOL
from PIL import Image, ImageColor

def create_square_image(size=500, color='white', output_filename='square.png'):

    # Create a new image with the specified size and color
    try:
        # Convert color to RGB
        rgb_color = ImageColor.getrgb(color)
        
        # Create the image
        image = Image.new('RGB', (size, size), rgb_color)
        
        # Save the image
        image.save(output_filename)
        
        print(f"Square PNG image created: {output_filename}")
        print(f"Size: {size}x{size} pixels")
        print(f"Color: {color}")
    
    except ValueError as e:
        print(f"Error: Invalid color. {e}")
    except Exception as e:
        print(f"An error occurred: {e}")

# Example usage
if __name__ == "__main__":
    # Create a white square
    create_square_image()
    
    # Create a red square
    create_square_image(size=300, color='red', output_filename='red_square.png')
    
    # Create a square with a hex color
    create_square_image(size=400, color='#00FF00', output_filename='green_square.png')
EOL
}

splitIMG() {
    echo -e "${YELLOW}💾 Creating splitIMG Routes${NC}"
    cat > src/splitIMG.py << EOL
from PIL import Image
import os

def split_image_into_grid(image_path, grid_size=2):

    # Open the image
    original_image = Image.open(image_path)
    
    # Get image dimensions
    width, height = original_image.size
    
    # Calculate the size of each grid square
    square_width = width // grid_size
    square_height = height // grid_size
    
    # Create output directory if it doesn't exist
    base_dir = os.path.dirname(image_path)
    output_dir = os.path.join(base_dir, f"grid_{grid_size}x{grid_size}")
    os.makedirs(output_dir, exist_ok=True)
    
    # Store paths of created image parts
    grid_parts = []
    
    # Split the image into grid parts
    for row in range(grid_size):
        for col in range(grid_size):
            # Calculate the coordinates for cropping
            left = col * square_width
            top = row * square_height
            right = left + square_width
            bottom = top + square_height
            
            # Crop the image
            grid_part = original_image.crop((left, top, right, bottom))
            
            # Generate filename
            part_filename = f"grid_part_{row}_{col}.png"
            part_path = os.path.join(output_dir, part_filename)
            
            # Save the grid part
            grid_part.save(part_path)
            grid_parts.append(part_path)
    
    print(f"Image split into {grid_size}x{grid_size} grid. Parts saved in {output_dir}")
    return grid_parts

# Example usage
def main():
    # Replace with the path to your PNG image
    image_path = "11.png"
    
    # Optional: Specify grid size (default is 4x4)
    split_image_into_grid(image_path, grid_size=2)

if __name__ == "__main__":
    main()
EOL
}

createFilesPy() {
    echo -e "${YELLOW}💾 Creating Files Routes${NC}"
    cat > src/files.py << EOL

EOL
}

createDashView() {
    echo -e "${YELLOW}💾 Creating Dashboard View${NC}"
    cat > templates/dashboard.html << EOL
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Login</title>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
        <link rel="stylesheet" href="{{ url_for('static', filename='css/dashStyle.css') }}">
        <link rel="shortcut icon" href="{{ url_for('static', filename='img/favicon.png') }}" type="image/x-icon">
        <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    </head>
<body>
    
    {% with messages = get_flashed_messages() %}
        {% if messages %}
            {% for message in messages %}
                <div class="error-message">{{ message }}</div>
            {% endfor %}
        {% endif %}
    {% endwith %}

    <div class="topnav-container">
        <div>
            <a href="{{ url_for('dashboard.dashboard') }}" class="logoIN">
                <div class="nomPag">Dashboard</div>
            </a>
        </div>
        <div class="topnav">
            <a href="{{ url_for('dashboard.dashboard') }}"><i class="fa fa-bar-chart" style="color: #0b00a2;"></i></a>
        </div>
    </div>

    <div class="row">
    

        <div class="column">
            <div class="card">
                <a href="{{ url_for('dashboard.files') }}" style="color: green;"><i class="fa fa-file-o"><span class="titles">Analizar Archivo</span></i><i class="fa fa-upload" style="color: #0b00a2;"></i></a>
            </div>
        </div>

    </div>
</body>
</html>
EOL
}

createLoginView() {
    echo -e "${YELLOW}💾 Creating Login View${NC}"
    cat > templates/login.html << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
    <link rel="shortcut icon" href="{{ url_for('static', filename='img/favicon.png') }}" type="image/x-icon">
</head>
<body>
    
    {% with messages = get_flashed_messages() %}
        {% if messages %}
            {% for message in messages %}
                <div class="error-message">{{ message }}</div>
            {% endfor %}
        {% endif %}
    {% endwith %}

    <div class="container" id="container">
        <div class="form">
            <form method="POST">
                <div class="input-group">
                    <input type="text" id="usuario" name="usuario" placeholder="Correo" required>
                </div>

                <div class="input-group">
                    <input type="password" id="contrasena" name="contrasena" placeholder="Contraseña" required>
                </div>
                
                <div class="input-group">
                    <button type="submit">
                        <i class="fa fa-sign-in"></i> Ingresar
                    </button>
                </div>
            </form>
        </div>
    </div>
</body>
</html>
EOL
}

createRegView() {
    echo -e "${YELLOW}💾 Creating Register View${NC}"
    cat > templates/register.html << EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registro</title>  <!-- Title is now fixed to Registro -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
    <link rel="shortcut icon" href="{{ url_for('static', filename='img/favicon.png') }}" type="image/x-icon">
</head>
<body>

    {% with messages = get_flashed_messages() %}
        {% if messages %}
            {% for message in messages %}
                <div class="error-message">{{ message }}</div>
            {% endfor %}
        {% endif %}
    {% endwith %}


    <div class="container" id="container">
        <div class="form">
            <form method="POST">
                <div class="input-group">
                    <input type="text" id="nombre" name="nombre" placeholder="Nombre" required autofocus>
                </div>
                <div class="input-group">
                    <input type="text" id="apellido" name="apellido" placeholder="Apellido" required>
                </div>
                <div class="input-group">
                    <input type="text" id="cedula" name="cedula" placeholder="Cédula" required>
                </div>
                <div class="input-group">
                    <input type="email" id="correo" name="correo" placeholder="Correo" required>
                </div>
                <div class="input-group">
                    <input type="text" id="cargo" name="cargo" placeholder="Cargo" required>
                </div>
                <div class="input-group">
                    <input type="password" id="contrasena" name="contrasena" placeholder="Contraseña" required>
                </div>
                <div class="input-group">
                    <input type="password" id="confTrasena" name="confTrasena" placeholder="Confirmar contraseña" required>
                </div>

                <div class="input-group">
                    <button type="submit">
                        <i class="fa fa-edit"></i> Registrarse
                    </button>
                </div>
            </form>
        </div>
    </div>
</body>
</html>
EOL
}

createFileStyle() {
    echo -e "${YELLOW}💾 Creating File style${NC}"
    cat > static/css/file.css << EOL
@import url('https://fonts.googleapis.com/css2?family=Open+Sans&display=swap');

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  background-color: rgb(255, 255, 255);
  font-family: 'Open Sans', sans-serif;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  padding: 20px;
  
}

.logoIN {
  cursor: pointer;
  margin: 1rem auto;
  width: 40px;
  height: 40px;
  background-color: #0b00a2;
  position: relative;
  display: inline-flex;
  text-decoration:none;
  border-radius: 8px;
}
.logoIN::before {
  content: "";
  width: 40px;
  height: 40px;
  border-radius: 50%;
  position: absolute;
  top: 30%;
  left: 70%;
  transform: translate(-50%, -50%);
  background-image: linear-gradient(to right, 
      #ffffff 2px, transparent 1.5px,
      transparent 1.5px, #ffffff 1.5px,
      #ffffff 2px, transparent 1.5px);
  background-size: 4px 100%; 
}

.nomPag{
  margin-left: 100px;
  padding: 20px 55px;
  text-decoration:none;
  margin-left: 2px;
  color: #0b00a2;
}

.material-icons{
  color: #0b00a2;

}

.topnav i{
  color: #0b00a2;
  font-size: 25px;
}

.topnav-container{
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px;
  top: 0;
}

.topnav a {
  display: inline-block;
  text-align: center;
  padding: 5px 5px;
  text-decoration: none;
  margin-left: 2px;
}

@media screen and (max-width: 600px) {
  .column {
    width: 100%;
    display: block;
    margin-bottom: 20px;
  }
}

@media (max-width: 480px) {
  .logo {
    margin-top: 100px;
  }
  .container {
    width: 95%;
  }
  .form {
    padding: 15px;
  }
}

@media (max-width: 768px) { /* Adjust the breakpoint as needed */
  .hidden-on-medium {
    display: none;
  }

  .header th:first-child { /* Nombre */
    width: 60%; /* Adjust widths as needed for two-column layout */
  }
  .header th:nth-child(2) { /* Compañía */
    width: 40%;
  }
}
.dashboard {
    width: 100%;
    margin: 0 auto;
}
.header {
    background: white;
    padding: 20px;
    box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2);
    border-radius: 8px;
    margin-bottom: 20px;
    border: 1px solid #c8c8c8;
}
.stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
    gap: 20px;
    margin-bottom: 20px;
    
}
/* Or display them inline within the card: */
/* .stat-item {
display: inline-block;
margin-right: 10px;
} 
*/
.stat-card {
    background: white;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2);
    border: 1px solid #c8c8c8;
}
.stat-title {
    color: #6b7280;
    font-size: 0.875rem;
    margin-bottom: 8px;
}
.stat-value {
    font-size: 1.5rem;
    font-weight: 600;
    color: #111827;
}
.chart-container {
    background: white;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    margin-bottom: 20px;
}
.data-table {
    width: 100%;
    border-collapse: collapse;
    background: white;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    border: 1px solid #c8c8c8;
}
.data-table th, .data-table td {
    padding: 12px;
    text-align: left;
    border-bottom: 1px solid #e5e7eb;
}
.data-table th {
    background: #f9fafb;
    font-weight: 500;
}
.data-table tr:last-child td {
    border-bottom: none;
}
EOL
}

createStyle() {
    echo -e "${YELLOW}💾 Creating Style${NC}"
    cat > static/css/style.css << EOL
@import url('https://fonts.googleapis.com/css2?family=Open+Sans&display=swap');

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  background-color: #f5f9fa;
  font-family: 'Open Sans', sans-serif;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  padding: 1rem; 
  align-items: center;
  justify-content: center;
  padding: 1rem;
}

.logo {
  cursor: pointer;
  margin: 1rem auto;
  width: 70px;
  height: 70px;
  background-color: #0b00a2;
  position: relative;
  overflow: hidden; 
  border-radius: 8px;
}

.logo:hover {
  background-color: #1d10d3;
}

.logo::before {
  content: "";
  width: 80px;
  height: 90px;
  position: absolute;
  border-radius: 50%;
  top: 25%;
  left: 70%;
  transform: translate(-50%, -50%);
  background-image: linear-gradient(to right, 
      #f5f9fa 3px, transparent 1px,
      transparent 1px, #f5f9fa 1px,
      #f5f9fa 3px, transparent 1px);
  background-size: 5px 100%; 
}

.container {
  width: 90%;
  max-width: 300px;
  overflow: hidden;
  transition: max-height 0.3s ease-out;
  margin: 1rem auto;
  font-family: 'Open Sans', sans-serif;
}

.form {
  padding: 1rem;
  background-color: rgb(230, 230, 230);
  border-radius: 8px;
  max-width: 100%; 
}

button {
  width: 100%;
  padding: rem;
  background-color: #0b00a2;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  margin-top: 0.8rem;
}

input, button {
  font-size: 1rem;
  padding: 0.75rem 1rem;
  margin-bottom: 0.5rem;
  border-radius: 3px;
  font-family: 'Open Sans', sans-serif;
  border: none;
  appearance: none;
  align-items: center;
  width: 100%;
}

.input-group {
  display: flex;
  justify-content: center;
  display: grid;
  grid-template-columns: 1fr; 
  gap: 0.5rem; 
}

.test a {
  color: #0b00a2;
  display: block;
  text-align: center;
  font-size: 0.8rem;
  font-family: 'Open Sans', sans-serif;
}

a {
  color: #ffffff;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
}

@media (min-width: 768px) {
  body {
    padding: 2rem; 
  }
  .logo {
    margin: 2rem auto; 
  }
  .container {
    max-width: 300px; 
  }
}

button:hover {
  background-color: #0056b3;
}
a:hover {
  text-decoration: underline;
}
EOL
}

createDashStyle() {
    echo -e "${YELLOW}💾 Creating Style IN${NC}"
    cat > static/css/dashStyle.css << EOL
@import url('https://fonts.googleapis.com/css2?family=Open+Sans&display=swap');

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  background-color: rgb(255, 255, 255);
  font-family: 'Open Sans', sans-serif;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  padding: 20px;
  
}

.logoIN {
  cursor: pointer;
  margin: 1rem auto;
  width: 40px;
  height: 40px;
  background-color: #0b00a2;
  position: relative;
  display: inline-flex;
  text-decoration:none;
  border-radius: 8px;
}
.logoIN::before {
  content: "";
  width: 40px;
  height: 40px;
  border-radius: 50%;
  position: absolute;
  top: 30%;
  left: 70%;
  transform: translate(-50%, -50%);
  background-image: linear-gradient(to right, 
      #ffffff 2px, transparent 1.5px,
      transparent 1.5px, #ffffff 1.5px,
      #ffffff 2px, transparent 1.5px);
  background-size: 4px 100%; 
}

/*
.logoIN {
  cursor: pointer;
  margin-bottom: 20px;
  width: 40px;
  height: 40px;
  background-color: #0b00a2;
  position: relative;
  display: inline-flex;
  text-decoration:none
}

.logoIN::before {
  content: "";
  display: block;
  width: 40px;
  height: 40px;
  background-color: rgb(255, 255, 255);
  border-radius: 50%;
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}
*/
.nomPag{
  margin-left: 100px;
  padding: 20px 55px;
  text-decoration:none;
  margin-left: 2px;
  color: #0b00a2;
}

.material-icons{
  color: #0b00a2;

}

.topnav i{
  color: #0b00a2;
  font-size: 25px;
}

.topnav-container{
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px;
  top: 0;
}

.topnav a {
  display: inline-block;
  text-align: center;
  padding: 5px 5px;
  text-decoration: none;
  margin-left: 2px;
}

.titles {
  font-family: 'Open Sans', sans-serif;
  font-size: 15px;
  margin: 20px;
  color: #0b00a2;
}

.column {
  float: left;
  width: 100%;
  padding: 0 10px;
  margin-bottom: 20px;
}

.search-container {
  position: relative;
}

.search-container i {
  position: absolute;
  left: 25px;
  top: 50%;
  transform: translateY(-50%);
}

.search-container input {
  padding-left: 40px;
  width: 100%;
  border: 2px solid #ccc;
  box-sizing: border-box;
  border-radius: 10px;
  padding: 20px 60px;
  font-size: 16px;
  font-family: 'Open Sans', sans-serif;
}

#tabla {
  width: 100%;
  font-size: 16px;
  font-family: 'Open Sans', sans-serif;
  padding: 0 55px;
}

#tabla th, #tabla td {
  text-align: left;
  padding: 0.8rem;
}


.row {margin: 0 -5px;}

.row:after {
  content: "";
  display: table;
  clear: both;
}

@media screen and (max-width: 600px) {
  .column {
    width: 100%;
    display: block;
    margin-bottom: 20px;
  }
}

.card {
  display: flex;
  stroke-width: 3px;
  flex-direction: column;
  align-items: center;
  box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2);
  padding: 25px;
  text-align: center;
  background-color: rgb(255, 255, 255);
  border-radius: 10px;
  position: relative;
  width: 100%;
  border: 1px solid #c8c8c8;
  
}

.card a{
  font-size: 1rem;
  color: #0b00a2;
  display: flex;
  left: 0;
  width: 100%;
  text-decoration: none;
  justify-content: space-between;
  font-family: 'Open Sans', sans-serif;
}

.card h2{
  font-family: 'Open Sans', sans-serif;
  right: 0;
  top: 0;
  position: absolute;

}

@media (max-width: 480px) {
  .logo {
    margin-top: 100px;
  }
  .container {
    width: 95%;
  }
  .form {
    padding: 15px;
  }
}

@media (max-width: 768px) { /* Adjust the breakpoint as needed */
  .hidden-on-medium {
    display: none;
  }

  .header th:first-child { /* Nombre */
    width: 60%; /* Adjust widths as needed for two-column layout */
  }
  .header th:nth-child(2) { /* Compañía */
    width: 40%;
  }


}
EOL
}

setProject() {
    gitignore
    creatEnv 
    createApp
    connectDB
    cropSquare
    invertColor
    makeSquare
    splitIMG
    createFilesPy

    echo -e "${GREEN}✨ Project created successfully!${NC}"
}

main() {
    echo -e "${YELLOW}🔧 Photor Initialization${NC}"
    
    createStructure
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install --use-pep517 python-dotenv
    pip install --upgrade pip setuptools wheel
    pip install flask mysql.connector-python waitress bcrypt pillow
    setProject

    source .env || { echo "Error sourcing .env"; exit 1; }

    chmod 600 .env

    echo -e "${GREEN}🎉 Project is ready! Run 'flask run' to start.${NC}"
}

main