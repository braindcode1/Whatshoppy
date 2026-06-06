# Stage 1: Build the Flutter Web application
FROM debian:bookworm-slim AS builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Clone the stable Flutter SDK
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Pre-download Flutter Web build dependencies
RUN flutter doctor -v

# Set up working directory
WORKDIR /app

# Copy pubspec files to cache package resolution
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy code and assets (excluding files ignored by .dockerignore)
COPY . .

# Build Flutter Web in release mode using canvaskit renderer
RUN flutter build web --release --web-renderer canvaskit

# Stage 2: Serve using Nginx
FROM nginx:alpine

# Copy built static files to Nginx web root
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
