# MinIO Docker Images

Automated builds of [MinIO](https://github.com/minio/minio) Docker images from official releases.

Since MinIO stopped providing pre-built Docker images for new releases, this repository automatically builds and publishes them to GitHub Container Registry.

## Available Images

Images are available at:
```
ghcr.io/<your-username>/minio-oss:<tag>
```

### Tags

- `latest` - Latest MinIO release
- `RELEASE.2024-10-13T13-34-11Z` - Specific release version (full release name)
- `2024-10-13T13-34-11Z` - Specific release version (without RELEASE. prefix)

## Usage

### Basic Usage

```bash
docker run -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  -v /path/to/data:/data \
  ghcr.io/<your-username>/minio-oss:latest \
  server /data --console-address ":9001"
```

### Docker Compose

```yaml
version: '3.8'

services:
  minio:
    image: ghcr.io/<your-username>/minio-oss:latest
    container_name: minio
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    volumes:
      - minio-data:/data
    command: server /data --console-address ":9001"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

volumes:
  minio-data:
```

## How It Works

1. **Scheduled Checks**: A GitHub Action runs daily to check for new MinIO releases
2. **Version Detection**: Fetches the latest release from the official MinIO repository
3. **Build Process**: Builds multi-architecture images (amd64, arm64) from source
4. **Publishing**: Pushes images to GitHub Container Registry with appropriate tags
5. **Skip Existing**: Avoids rebuilding if the version already exists

## Building Locally

To build an image locally:

```bash
# Build latest version
docker build -t minio:test .

# Build specific version
docker build --build-arg MINIO_VERSION=RELEASE.2024-10-13T13-34-11Z -t minio:test .
```

## Architecture

- **Multi-platform**: Built for both `linux/amd64` and `linux/arm64`
- **Source-based**: Compiled from official MinIO source code
- **Minimal base**: Uses Red Hat UBI9 micro image for security and size
- **Official entrypoint**: Uses MinIO's official docker-entrypoint.sh script

## Ports

- **9000**: MinIO S3 API endpoint
- **9001**: MinIO Web Console (admin UI)

## Environment Variables

- `MINIO_ROOT_USER`: Root access key (username)
- `MINIO_ROOT_PASSWORD`: Root secret key (password)
- `MINIO_CONFIG_ENV_FILE`: Path to configuration file
- See [MinIO documentation](https://min.io/docs/minio/linux/reference/minio-server/minio-server.html) for more options

## License

This build automation is provided as-is. MinIO itself is licensed under AGPL-3.0.

**Note**: According to MinIO's license terms, production use of compiled-from-source binaries is at your own risk. For production deployments, MinIO recommends their enterprise offerings.

## Links

- [MinIO Official Repository](https://github.com/minio/minio)
- [MinIO Documentation](https://min.io/docs/minio/)
- [MinIO Releases](https://github.com/minio/minio/releases)
