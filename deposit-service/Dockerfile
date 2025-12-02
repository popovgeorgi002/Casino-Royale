FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including dev dependencies for build)
RUN npm ci

# Copy source code
COPY . .

# Build TypeScript
RUN npm run build

# Remove dev dependencies and keep only production
RUN npm prune --production

# Expose port
EXPOSE 3004

# Start the service
CMD ["node", "dist/index.js"]
