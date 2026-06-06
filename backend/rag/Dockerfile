FROM python:3.10-slim

WORKDIR /app

# Copy requirements file first to cache package installs
COPY backend/rag/requirements.txt ./backend/rag/requirements.txt

# Install pip dependencies (including faiss-cpu and sentence-transformers)
RUN pip install --no-cache-dir -r backend/rag/requirements.txt

# Copy RAG service files
COPY backend/rag ./backend/rag

# Expose port 9000
EXPOSE 9000

# Set working directory to service folder
WORKDIR /app/backend/rag

# Run FastAPI app
CMD ["uvicorn", "rag_service:app", "--host", "0.0.0.0", "--port", "9000"]
