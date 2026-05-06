# next.config.ts sets output: "standalone". `next start` does not apply — run the traced
# server bundle instead (`node server.js` from the standalone directory contents copied below).
# Also copy `.next/static` next to that bundle so `/_next/static` assets resolve.

FROM node:22-alpine AS deps

WORKDIR /app

COPY package*.json ./
RUN npm ci

FROM node:22-alpine AS builder

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN mkdir -p public

RUN npm run build

FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 3000

# Equivalent local command after build: `node .next/standalone/server.js`
CMD ["node", "server.js"]
