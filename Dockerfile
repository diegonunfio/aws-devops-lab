FROM node:18-alpine AS deps

WORKDIR /app

COPY app/package.json app/package-lock.json ./

RUN npm ci --omit=dev && \
    npm cache clean --force


FROM node:18-alpine AS test

WORKDIR /app

COPY app/package.json app/package-lock.json ./

RUN npm ci

COPY app/ .

RUN npm run lint
RUN npm run test:ci


FROM node:18-alpine AS production

ARG APP_VERSION=unknown
ARG GIT_SHA=unknown

LABEL org.opencontainers.image.title="aws-devops-lab-api" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.authors="Diego Nunfio" \
      org.opencontainers.image.source="https://github.com/diegonunfio/aws-devops-lab"

RUN apk add --no-cache dumb-init

RUN addgroup -g 1001 -S nodejs && \
    adduser -u 1001 -S nodejs -G nodejs

WORKDIR /app

COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --chown=nodejs:nodejs app/src ./src
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