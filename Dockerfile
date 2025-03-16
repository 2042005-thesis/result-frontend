# Stage 1: Build
FROM node:22.14.0-alpine3.21 AS builder
WORKDIR /usr/local/app
COPY package*.json ./
RUN npm ci

# Stage 2: Production
FROM node:22.14.0-alpine3.21
WORKDIR /usr/local/app
COPY --from=builder /usr/local/app/node_modules /node_modules
COPY . .
ENV PORT=80
EXPOSE 80
CMD ["node", "server.js"]