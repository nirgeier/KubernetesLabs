FROM alpine

# Update
RUN apk add --update nodejs npm

# Change to the desired folder
WORKDIR /src

# Copy the desired files
COPY . .

# Install app dependencies
RUN npm i

# Start the server
CMD ["node", "proxy-server.js"]