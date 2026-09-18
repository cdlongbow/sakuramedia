---
outline: [2, 4]
---

# 可选向量服务与 SigLIP2 硬件方案

快速开始中的 CPU 镜像适用于 AMD、Intel 和 ARM64 主机。SigLIP2 镜像已包含模型和运行时，**不需要**下载模型、挂载模型目录或预先缩放图片。

后端和嵌入服务在同一个 Compose 项目中时，不需要映射端口；后端默认通过 `http://siglip2-embed:8080` 访问服务。

## 按需启用

基础部署不需要这两个服务。仅需相似影片时启动 Qdrant 并在桌面高级设置中开启「相似影片与向量服务」；需要图搜时再部署 SigLIP2，开启「图片与文字搜图」。完整 Compose 和操作步骤见[快速开始](./quick-start#以图搜图嵌入服务-可选)。保存后需重启后端容器。

缩略图与时刻收藏独立保留。每日推荐和时刻推荐在关闭向量能力后仍使用其他候选信号。重新启用时保留原索引；关闭期间发生删除或更新的，应在「系统设置 → 系统维护」重建图搜索引，并在任务中心运行「影片相似度重算」。

## Intel 核显

适用于 Linux amd64 的 Intel 核显主机。将快速开始中的 `siglip2-embed` 服务替换为：

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
      EMBEDDING_BACKEND: "intel_gpu"
      CPU_CONCURRENCY: "1"
```

在宿主机执行 `getent group render` 查看 `render` 组的 GID，并在同目录的 `.env` 文件写入 `RENDER_GID=实际GID`。确认 `/dev/dri` 存在后再启动容器。

## NVIDIA CUDA

宿主机需要已安装 NVIDIA 驱动、`nvidia-container-toolkit`，且 `nvidia-smi` 能正常显示显卡。将快速开始中的服务替换为：

```yaml
  siglip2-embed:
    image: tinyping/siglip2-embed-service:cuda
    container_name: siglip2-embed
    restart: unless-stopped
    gpus: all
    environment:
      EMBEDDING_BACKEND: "cuda"
      CPU_CONCURRENCY: "1"
```

若容器启动后没有使用 GPU，先检查 `docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi` 是否成功，再检查 NVIDIA Container Toolkit 配置。

## 只做图片搜图：关闭文本塔

SigLIP2 默认同时加载图片塔与文本塔。只检索相似图片、不需要文字搜画面时，可以在 `siglip2-embed` 的 `environment` 中加上：

```yaml
      TEXT_TOWER_ENABLED: "false"
```

服务启动时会跳过文本编码器与 tokenizer，只保留图片塔，内存占用更低。文字搜画面会失败（文本接口返回 503），图片搜图、相似图片和图片索引都不受影响。改回 `"true"` 或删掉这一行并重启容器即可恢复。

## 将嵌入服务部署到其他主机

仅在后端与 SigLIP2 不在同一个 Compose 网络时才需要映射端口，例如添加：

```yaml
    ports:
      - "8080:8080"
```

然后在桌面高级设置中将 SigLIP2 地址改为该服务的可访问 HTTP 地址，按需填写 API Key，保存后重启后端。Qdrant 同样支持远程地址；使用远程服务时不必启动对应的本地容器。
