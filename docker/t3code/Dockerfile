# Inspiré de /workspace/VPS/docker/t3code, sans configuration propre au VPS.
FROM docker:28-cli AS docker-cli
FROM node:22-bookworm-slim

ARG T3_VERSION=0.1.9
ARG CODEX_VERSION=0.167.1
ARG CLAUDE_VERSION=2.1.322
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl git openssh-client procps python3 tar \
    && rm -rf /var/lib/apt/lists/* \
    && npm install --global "t3@${T3_VERSION}" "@openai/codex@${CODEX_VERSION}" "@anthropic-ai/claude-code@${CLAUDE_VERSION}" --no-audit --no-fund \
    && mkdir -p /data/userdata /data/workspace /home/node/.npm-global \
    && chown -R node:node /data /home/node
COPY --from=docker-cli /usr/local/bin/docker /usr/local/bin/docker

ENV T3CODE_HOME=/data/userdata \
    NPM_CONFIG_PREFIX=/home/node/.npm-global \
    PATH=/home/node/.npm-global/bin:/usr/local/bin:/usr/bin:/bin \
    DOCKER_HOST=tcp://agent-docker:2375
USER node
WORKDIR /data/workspace
EXPOSE 3773
CMD ["t3", "serve", "--host", "0.0.0.0", "--port", "3773", "--base-dir", "/data/userdata", "--mode", "web", "/data/workspace"]
