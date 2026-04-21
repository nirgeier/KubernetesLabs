FROM node:20-alpine

WORKDIR /usr/src/app

# Install dependencies first (layer caching)
COPY package.json package-lock.json* ./
RUN npm install

# Copy application source
COPY . .

# Expose app port and debug port
EXPOSE 3000 9229

# Production command (overridden by Raftt in dev-mode)
CMD ["node", "server.js"]
