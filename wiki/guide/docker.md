---
outline: [2, 4]
---

# Optional Vector Services and SigLIP2 Hardware Options

The CPU images used in the examples on this page work on AMD, Intel and ARM64 hosts. The SigLIP2 image already bundles the model and runtime — you do **not** need to download models, mount a model directory, or pre-scale images. On startup the service automatically picks an inference backend based on the runtimes installed in the image; no configuration is required.

When the backend and the embedding service are in the same Compose project, no port mapping is needed; the backend reaches the service at `http://siglip2-embed:8080` by default.

## Enabling on demand

A basic deployment does not need either service. If you only want similar movies, start Qdrant and turn on "Similar Movies & Vector Service" in desktop advanced settings; if you want image search, deploy SigLIP2 as well and turn on "Image & Text Search". See the [Full Compose example](#full-compose-example) below. Restart the backend container after saving.

Thumbnails and moment favorites are kept independently. Daily recommendations and moment recommendations still use other candidate signals after vector capabilities are turned off. Re-enabling keeps the existing index; if deletions or updates happened while it was off, rebuild the image search index in "System Settings → System Maintenance" and run "Movie Similarity Recalculation" in the Task Center.

## Full Compose example

Append these two services to the basic compose file from Quick Start. A basic deployment does not need them; they are only required when you enable similar movies or image search. Enabling image search on ARM platforms is not recommended.

```yaml
  qdrant:
    image: qdrant/qdrant:v1.12.4
    container_name: qdrant
    restart: unless-stopped
    environment:
      QDRANT__SERVICE__HTTP_PORT: "6333"
      QDRANT__LOG_LEVEL: "INFO"
    volumes:
      - ./sakuramedia-data/image-search-index:/qdrant/storage
    ulimits:
      nofile:
        soft: 65536
        hard: 65536

  siglip2-embed:
    image: tinyping/siglip2-embed-service:cpu
    container_name: siglip2-embed
    restart: unless-stopped
    environment:
      CPU_CONCURRENCY: "1"
      MALLOC_TRIM_THRESHOLD_: "131072"
      # If memory is tight, try setting this to false to lower the memory used by text search.
      TEXT_TOWER_ENABLED: "true"
```

## Intel integrated graphics

For Linux amd64 hosts with Intel integrated graphics. Replace the `siglip2-embed` service above with:

```yaml
  siglip2-embed:
    image: tinyping/siglip2-embed-service:intel
    container_name: siglip2-embed
    restart: unless-stopped
    devices:
      - /dev/dri:/dev/dri
    group_add:
      - "${RENDER_GID:-0}"
    environment:
      CPU_CONCURRENCY: "1"
```

Run `getent group render` on the host to look up the GID of the `render` group, then write `RENDER_GID=<actual GID>` into the `.env` file in the same directory. Confirm that `/dev/dri` exists before starting the container.

## NVIDIA CUDA

The host needs the NVIDIA driver and `nvidia-container-toolkit` installed, and `nvidia-smi` must display the GPU correctly. Replace the service above with:

```yaml
  siglip2-embed:
    image: tinyping/siglip2-embed-service:cuda
    container_name: siglip2-embed
    restart: unless-stopped
    gpus: all
    environment:
      CPU_CONCURRENCY: "1"
```

If the container does not use the GPU after starting, first check whether `docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi` succeeds, then check the NVIDIA Container Toolkit configuration.

## Image search only: disable the text tower

By default SigLIP2 loads both the image tower and the text tower. If you only search for similar images and do not need text-to-frame search, add this to the `environment` of `siglip2-embed`:

```yaml
      TEXT_TOWER_ENABLED: "false"
```

On startup the service skips the text encoder and tokenizer and keeps only the image tower, which lowers memory usage. Text-to-frame search then fails (the text endpoint returns 503), while image search, similar images and image indexing are unaffected. Set it back to `"true"` or delete the line and restart the container to restore it.

## Deploying the embedding service on another host

Port mapping is only needed when the backend and SigLIP2 are not on the same Compose network, for example by adding:

```yaml
    ports:
      - "8080:8080"
```

Then, in desktop advanced settings, change the SigLIP2 address to a reachable HTTP address for that service, fill in the API key if needed, and restart the backend after saving. Qdrant likewise supports a remote address; when you use a remote service, you do not need to start the corresponding local container.
