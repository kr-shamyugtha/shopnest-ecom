<div align="center">
  <img src="https://cdn-icons-png.flaticon.com/512/3514/3514491.png" alt="ShopNest Logo" width="80" />
  <h1>ShopNest - Full-Stack MERN E-Commerce App</h1>
  <p>A professionally engineered, full-stack E-commerce platform built strictly using modern standard React (CRA) on the frontend and Express/MongoDB on the backend.</p>
</div>

Start application:
npm run dev

**Seed Admin Access:** Email: `admin@shopnest.com` | Password: `password123`

Docker

## STEP 1 — Build both images

```bash
cd ~/shopnest-ecom

# Build backend
docker build \
  --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --build-arg VERSION=1.0.0 \
  -t shopnest-backend:v1.0.0 \
  ./backend

# Build frontend
docker build \
  --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
  --build-arg VERSION=1.0.0 \
  -t shopnest-frontend:v1.0.0 \
  ./frontend
```

## STEP 2 — Create a shared Docker network

```bash
docker network create shopnest-network
```

This is why `nginx.conf` uses `http://backend:5000` — on this network, Docker's internal DNS resolves the container **name** `backend` to its IP automatically. No hardcoded IPs needed.

## STEP 3 — Run backend first

```bash
docker run -d \
  --name backend \
  --network shopnest-network \
  -p 5000:5000 \
  --env-file ./backend/.env \
  shopnest-backend:v1.0.0
```

Verify it's healthy:
```bash
docker logs -f backend
```

Wait for:
```
Server running on port 5000
MongoDB Connected: ...
```

Press `Ctrl+C` to stop following logs. Then:
```bash
curl http://localhost:5000/health
```

Should return `{"status":"ok"}`. Only move to Step 4 once this passes — frontend's Nginx can't proxy to a backend that isn't running.

## STEP 4 — Run frontend

```bash
docker run -d \
  --name frontend \
  --network shopnest-network \
  -p 3000:8080 \
  shopnest-frontend:v1.0.0
```

Verify:
```bash
docker logs -f frontend
```

Press `Ctrl+C` once you see Nginx start up (no errors). Then:
```bash
curl http://localhost:3000/health
```

Should return `OK`.

## STEP 5 — Verify end to end

```bash
# Frontend serving React app
curl -I http://localhost:3000

# API call going through Nginx → backend
curl http://localhost:3000/api/products
```

`curl -I` returns just headers — you want `HTTP/1.1 200 OK`. The `/api/products` call going through Nginx and returning product JSON confirms the full chain is working: browser → Nginx → Express → MongoDB Atlas → back.

Open `http://localhost:3000` in your browser too — full UI should load, products should appear, login should work.

## STEP 6 — Cleanup when done testing

```bash
docker stop frontend backend
docker rm frontend backend
docker network rm shopnest-network
```

Docker-compose

## Commands 

```bash
cd ~/shopnest-ecom

# Build and start everything
docker compose up -d

# Watch logs (both containers)
docker compose logs -f

# Watch logs (one container)
docker compose logs -f backend
docker compose logs -f frontend

# Check status and health
docker compose ps

# Stop (keeps containers)
docker compose stop

# Stop and remove containers + network
docker compose down

# Rebuild images and restart (after code changes)
docker compose up -d --build

# With explicit version
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") VERSION=1.0.0 docker compose up -d --build
```

## Run it now

First clean up your manual containers so there's no name conflict:

```bash
docker stop frontend backend
docker rm frontend backend
docker network rm shopnest-network
```

Then:

```bash
cd ~/shopnest-ecom
docker compose up -d
```

Watch the startup:
```bash
docker compose logs -f
```


```bash
docker compose ps
curl http://localhost:5000/health
curl http://localhost:3000/health
curl http://localhost:3000/api/products
```
