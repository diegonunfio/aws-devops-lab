# ──────────────────────────────────────────────────────────────────────────────
# Stage 1 — Dependencies
# Only production deps here. Layer is cached until package-lock.json changes —
# code edits don't invalidate this layer.
# ──────────────────────────────────────────────────────────────────────────────
FROM node:18-alpine AS deps

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci --omit=dev && \
    npm cache clean --force


# ──────────────────────────────────────────────────────────────────────────────
# Stage 2 — Test runner
# Targeted explicitly in CI (`--target test`). Never pushed to the registry.
# ──────────────────────────────────────────────────────────────────────────────
FROM node:18-alpine AS test

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci   # devDependencies needed for jest + eslint

COPY . .
RUN npm run lint
RUN npm run test:ci


# ──────────────────────────────────────────────────────────────────────────────
# Stage 3 — Production image
# Minimal: no devDeps, runs as non-root UID 1001, dumb-init for PID 1.
# ──────────────────────────────────────────────────────────────────────────────
FROM node:18-alpine AS production

ARG APP_VERSION=unknown
ARG GIT_SHA=unknown

LABEL org.opencontainers.image.title="aws-devops-lab-api" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.authors="Diego Nunfio" \
      org.opencontainers.image.source="https://github.com/diegonunfio/aws-devops-lab"

# dumb-init: proper PID 1 so SIGTERM is forwarded to Node and
# zombie processes are reaped correctly inside the container.
RUN apk add --no-cache dumb-init

RUN addgroup -g 1001 -S nodejs && \
    adduser  -u 1001 -S nodejs -G nodejs

WORKDIR /app

COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs app/src       ./src
COPY --chown=nodejs:nodejs app/package.json ./

USER nodejs

ENV NODE_ENV=production \
    PORT=3000 \
    APP_VERSION=${APP_VERSION}

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "src/index.js"]
