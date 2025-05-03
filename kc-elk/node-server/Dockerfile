# Use official Node.js image
FROM node:18

# Install jq (optional)
RUN apt-get update && apt-get install -y jq && apt-get clean

# Set app directory
WORKDIR /usr/src/app

# Copy dependency files first (to cache install step)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy rest of the app
COPY . .

# Expose port
EXPOSE 5500

# Start the app
CMD ["node", "server.js"]
