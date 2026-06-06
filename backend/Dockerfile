FROM node:20-slim

WORKDIR /app

# Copy dependency configs first to cache install layer
COPY package*.json ./

RUN npm ci --only=production

# Copy the rest of the backend files
COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
