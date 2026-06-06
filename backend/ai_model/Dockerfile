FROM python:3.10-slim

# Install system dependencies needed for OpenCV and shared libs
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements file to install dependencies
COPY backend/ai_model/requirements.txt ./backend/ai_model/requirements.txt

# Install pip dependencies (including tensorflow-cpu and opencv-python-headless)
RUN pip install --no-cache-dir -r backend/ai_model/requirements.txt
RUN pip install --no-cache-dir tensorflow-cpu opencv-python-headless

# Copy ML service files and pre-trained models preserving structure
COPY backend/ai_model ./backend/ai_model
COPY "model result" "./model result"

# Expose port 8000
EXPOSE 8000

# Set working directory to service folder
WORKDIR /app/backend/ai_model

# Run FastAPI app
CMD ["uvicorn", "yolo_service:app", "--host", "0.0.0.0", "--port", "8000"]
