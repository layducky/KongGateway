# AI Stack với Ollama, Kong, Prometheus & Grafana

## 🚀 Cách chạy

### 1. Chạy setup

```bash
chmod +x ./setup.sh
./setup.sh
```
### 2. Truy cập Grafana

Sau khi setup xong, mở trình duyệt:

```
http://localhost:3000
```

**Login mặc định:**
- Username: `admin`
- Password: `admin`

## Request mẫu
### 1. Gọi qua Kong Gateway

```bash
curl http://localhost:8000/ollama/api/generate -d '{
  "model": "qwen2.5-coder:1.5b",
  "prompt": "Explain Docker in one sentence",
  "stream": false
}'
```

### 2. Chat completion

```bash
curl http://localhost:8000/ollama/api/chat -d '{
  "model": "qwen2.5-coder:1.5b",
  "messages": [
    {
      "role": "user",
      "content": "Write a Python function to calculate fibonacci"
    }
  ],
  "stream": false
}'
```

## 🛑 Dừng services

```bash
docker compose down
```

---