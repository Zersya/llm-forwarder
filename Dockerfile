FROM docker.litellm.ai/berriai/litellm-database:main-latest

WORKDIR /app

COPY config.yaml /app/config.yaml

EXPOSE 4000

CMD ["--config", "/app/config.yaml", "--detailed_debug"]