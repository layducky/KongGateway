FROM ubuntu:22.04

WORKDIR /app

RUN apt update && apt install -y \
    curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY . .

EXPOSE 11434 9178

CMD ["./start.sh"]
