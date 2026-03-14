# ─────────────────────────────────────────
# Stage 1: Build React/Vite frontend
# ─────────────────────────────────────────
FROM node:20-alpine AS frontend-build

WORKDIR /app/frontend
COPY frontend/ .
RUN npm ci

ARG VITE_API_URL=/api
ENV VITE_API_URL=$VITE_API_URL

RUN npm run build

# ─────────────────────────────────────────
# Stage 2: Install Python dependencies
# ─────────────────────────────────────────
FROM python:3.11-slim AS backend-build

WORKDIR /app
COPY backend/requirements.txt .
# aiomysql λείπει από το requirements.txt
RUN pip install --no-cache-dir -r requirements.txt aiomysql cryptography
COPY backend/ .

# ─────────────────────────────────────────
# Stage 3: Final image (nginx + python)
# ─────────────────────────────────────────
FROM python:3.11-slim AS final

RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

# Python packages από stage 2
COPY --from=backend-build /usr/local/lib/python3.11 /usr/local/lib/python3.11
COPY --from=backend-build /usr/local/bin/uvicorn /usr/local/bin/uvicorn
COPY --from=backend-build /app /app/backend

# React build από stage 1
COPY --from=frontend-build /app/frontend/dist /usr/share/nginx/html

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80


CMD ["/docker-entrypoint.sh"]
