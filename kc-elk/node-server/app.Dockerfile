# Use official Node.js image
FROM node:18


# Install jq (JSON parser)
RUN apt-get update && apt-get install -y jq && apt-get clean

# Create app directory
WORKDIR /usr/src/app

# Copy package files from node-server folder
COPY ./package*.json ./

# Install dependencies
RUN npm install

# Copy rest of the app
COPY . .

# Expose the app port
EXPOSE 5500

# Start the app
CMD ["npm", "start"]
