# syntax=docker/dockerfile:1

ARG NODE_VERSION=20-alpine

# ---------- Build stage ----------

    FROM node:${NODE_VERSION} AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .

# ---------- Production stage ----------

    FROM node:${NODE_VERSION}
ARG BUILD_DATE
ARG VERSION=1.0.0
LABEL maintainer="Shamyugtha" \
      org.opencontainers.image.title="shopnest-backend" \
      org.opencontainers.image.description="ShopNest Express API" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}"
WORKDIR /app
ENV NODE_ENV=production
RUN apk add --no-cache dumb-init && \
    apk upgrade --no-cache libcrypto3 libssl3
COPY --from=build /app .
RUN rm -rf node_modules && \
    npm ci --omit=dev && \
    npm cache clean --force
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup && \
    mkdir -p /app/uploads && \
    chown -R appuser:appgroup /app
USER appuser
EXPOSE 5000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:5000/health', r => process.exit(r.statusCode === 200 ? 0 : 1))"
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]