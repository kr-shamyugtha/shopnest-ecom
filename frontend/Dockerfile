# syntax=docker/dockerfile:1
ARG NODE_VERSION=20-alpine
ARG NGINX_VERSION=1.27-alpine

# ---------- Build stage ----------
FROM node:${NODE_VERSION} AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# ---------- Production stage ----------
FROM nginx:${NGINX_VERSION}
ARG BUILD_DATE
ARG VERSION=1.0.0
LABEL maintainer="Shamyugtha" \
      org.opencontainers.image.title="shopnest-frontend" \
      org.opencontainers.image.description="ShopNest React Frontend" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.version="${VERSION}"

RUN apk upgrade --no-cache libcrypto3 libssl3

COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid

# Tell Nginx entrypoint to skip IPv6 setup which requires root
ENV NGINX_ENTRYPOINT_QUIET_LOGS=1

#USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/health || exit 1
  
CMD ["nginx", "-g", "daemon off;"]