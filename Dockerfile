FROM node:22-alpine

WORKDIR /app

COPY package.json models.json agent-tools.json zen-proxy.mjs ./
COPY public ./public
COPY assets ./assets

ENV ZEN_PROXY_CONFIG=/config/zen-proxy.json \
    HOST=0.0.0.0 \
    PORT=8787

RUN mkdir -p /config && chown -R node:node /config /app
USER node

EXPOSE 8787

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||8787)+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "zen-proxy.mjs"]
