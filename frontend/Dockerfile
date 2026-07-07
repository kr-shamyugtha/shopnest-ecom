# syntax=docker/dockerfile:1
ARG NODE_VERSION=20.19-alpine
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

COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q --spider http://localhost:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]