# File Compression/Decompression Tool

A high-performance microservice for file compression and decompression supporting multiple algorithms including Huffman, LZSS, DEFLATE, and GZIP.

## 🚀 Features

- **Multiple Algorithms**: Huffman, LZSS, DEFLATE (Flate), and GZIP compression
- **RESTful API**: Clean HTTP endpoints for compression and decompression
- **Containerized**: Docker and docker-compose support for easy deployment
- **Production Ready**: Graceful shutdown, health checks, and resource limits
- **CORS Enabled**: Public API access from any domain
- **File Size Limits**: Configurable limits (default: 50MB)
- **Detailed Statistics**: Compression ratios and processing information

## 📋 API Endpoints

### Base URL
```
Production: https://your-deployment-domain.com
Development: http://localhost:8080
```

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` | Service information |
| `GET` | `/health` | Health check |
| `POST` | `/compress` | Compress a file |
| `POST` | `/decompress` | Decompress a file |
| `GET` | `/api/v1/info` | Detailed API information |

## 🔧 API Usage Examples

### 1. Compress a File

```bash
# Using curl
curl -X POST http://localhost:8080/compress \
  -F "algorithm=gzip" \
  -F "file=@example.txt" \
  -o compressed.gz

# Using curl with custom options (for flate/gzip)
curl -X POST http://localhost:8080/compress \
  -F "algorithm=flate" \
  -F "btype=2" \
  -F "bfinal=1" \
  -F "file=@example.txt" \
  -o compressed.flate
```

**JavaScript/Fetch Example:**
```javascript
const formData = new FormData();
formData.append('algorithm', 'gzip');
formData.append('file', fileInput.files[0]);

fetch('http://localhost:8080/compress', {
  method: 'POST',
  body: formData
})
.then(response => response.blob())
.then(blob => {
  // Handle compressed file download
  const url = window.URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'compressed.gz';
  a.click();
});
```

**Python Example:**
```python
import requests

# Compress file
with open('example.txt', 'rb') as f:
    files = {'file': f}
    data = {'algorithm': 'gzip'}
    
    response = requests.post('http://localhost:8080/compress', 
                           files=files, data=data)
    
    with open('compressed.gz', 'wb') as output:
        output.write(response.content)
```

### 2. Decompress a File

```bash
# Using curl
curl -X POST http://localhost:8080/decompress \
  -F "algorithm=gzip" \
  -F "file=@compressed.gz" \
  -o decompressed.txt
```

### 3. Get Service Information

```bash
curl http://localhost:8080/info
```

**Response:**
```json
{
  "service": "File Compression/Decompression Tool",
  "version": "1.0.0",
  "algorithms": {
    "supported": ["huffman", "lzss", "flate", "gzip"],
    "descriptions": {
      "huffman": "Huffman coding - lossless data compression using variable-length codes",
      "lzss": "Lempel-Ziv-Storer-Szymanski - dictionary-based compression",
      "flate": "DEFLATE - combination of LZ77 and Huffman coding",
      "gzip": "GZIP - wrapper around DEFLATE with headers and checksums"
    }
  },
  "limits": {
    "max_file_size": "52428800 bytes (50.0 MB)"
  },
  "endpoints": {
    "compress": "POST /compress - Upload file for compression",
    "decompress": "POST /decompress - Upload file for decompression",
    "info": "GET /info - Get service information",
    "health": "GET /health - Health check"
  }
}
```

## 🛠 Development Setup

### Prerequisites
- Go 1.23.5 or later
- Docker and docker-compose (for containerized deployment)
- Make (optional, for using Makefile commands)

### Local Development

1. **Clone the repository:**
```bash
git clone https://github.com/adilg123/file-compression-decompression-tool.git
cd file-compression-decompression-tool
```

2. **Install dependencies:**
```bash
go mod tidy
```

3. **Run the server:**
```bash
go run main.go
# or using Makefile
make run
```

4. **Test the service:**
```bash
curl http://localhost:8080/health
```

### Using VS Code

1. Open the project in VS Code
2. Install Go extension
3. Use `Ctrl+Shift+P` → "Go: Install/Update Tools"
4. Run with `F5` or use integrated terminal

## 🐳 Docker Deployment

### Using Docker Compose (Recommended)

1. **Deploy the service:**
```bash
docker-compose up -d
```

2. **View logs:**
```bash
docker-compose logs -f compression-service
```

3. **Stop the service:**
```bash
docker-compose down
```

### Using Docker directly

1. **Build the image:**
```bash
docker build -t compression-service .
```

2. **Run the container:**
```bash
docker run -p 8080:8080 compression-service
```

## ☁️ Public Deployment (Coolify)

### Coolify Deployment Steps

1. **Create new application in Coolify**
2. **Configure Git repository:**
   - Repository: `https://github.com/adilg123/file-compression-decompression-tool.git`
   - Branch: `main`

3. **Set build configuration:**
   - Build command: `docker build -t compression-service .`
   - Start command: `./main`

4. **Environment variables:**
```bash
PORT=8080
GO_ENV=production
```

5. **Domain configuration:**
   - Set your custom domain or use Coolify's provided domain
   - Enable SSL certificate

6. **Resource limits:**
   - CPU: 1 core
   - Memory: 512MB
   - Storage: 2GB

### Manual VPS Deployment

1. **Clone and build:**
```bash
git clone https://github.com/adilg123/file-compression-decompression-tool.git
cd file-compression-decompression-tool
docker-compose up -d
```

2. **Setup reverse proxy (nginx):**
```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 📊 Supported Algorithms

### Huffman Coding
- **Best for**: Text files with repetitive characters
- **Compression ratio**: Good for text, poor for binary
- **Speed**: Fast
- **Usage**: `algorithm=huffman`

### LZSS (Lempel-Ziv-Storer-Szymanski)
- **Best for**: General purpose text compression
- **Compression ratio**: Good balance
- **Speed**: Moderate
- **Usage**: `algorithm=lzss`

### DEFLATE (Flate)
- **Best for**: General purpose compression
- **Compression ratio**: Excellent
- **Speed**: Good
- **Usage**: `algorithm=flate`
- **Options**: `btype` (1-3), `bfinal` (0-1)

### GZIP
- **Best for**: Web content, general files
- **Compression ratio**: Excellent (DEFLATE + headers)
- **Speed**: Good
- **Usage**: `algorithm=gzip`
- **Options**: `btype` (1-3), `bfinal` (0-1)

## 🔍 Error Handling

The API returns structured error responses:

```json
{
  "error": "Invalid algorithm",
  "code": 400,
  "message": "Supported algorithms: [huffman, lzss, flate, gzip]"
}
```

Common error codes:
- `400`: Bad request (invalid algorithm, missing file, file too large)
- `500`: Internal server error (compression/decompression failed)

## 📈 Performance & Limits

- **Maximum file size**: 50MB (configurable)
- **Concurrent requests**: Handled by Go's goroutines
- **Memory usage**: Optimized with streaming processing
- **Timeout**: 30 seconds for read/write operations

## 🔧 Configuration

Environment variables:

```bash
PORT=8080                    # Server port
GO_ENV=production           # Environment (development/production)
MAX_FILE_SIZE=52428800      # Maximum file size in bytes
```

## 🧪 Testing

```bash
# Run all tests
make test

# Test specific algorithm
go test -v ./internal/compression/algorithms/huffman

# Test API endpoints
curl -X POST http://localhost:8080/compress \
  -F "algorithm=gzip" \
  -F "file=@test-files/sample.txt"
```

## 📝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Repository**: https://github.com/adilg123/file-compression-decompression-tool
- **Issues**: https://github.com/adilg123/file-compression-decompression-tool/issues
- **Documentation**: https://github.com/adilg123/file-compression-decompression-tool/wiki

## 📞 Support

For support, please open an issue on GitHub or contact the maintainers.