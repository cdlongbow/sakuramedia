---
outline: [2, 3]
---

# 快速开始

这份指引只做一件事：部署 SakuraMedia 后端，把宿主机上已有的影片导入本地媒体库。

自动下载（qBittorrent + 索引器）、以图搜图、115 网盘等是可选扩展，见[自动下载与索引器](/guide/auto-download)、[进阶部署](/guide/docker)和[推荐插件](/guide/plugins)。

## 开始前

- 一台持续运行的主机或 NAS，已安装 Docker 和 Docker Compose。
- 一个 SSD 目录存放后端运行数据（数据库、配置、日志、插件）。
- 一个存放已有影片的宿主机目录，例如 `/mnt/volume1/media/av`。
- 客户端从 [GitHub Releases](https://github.com/tinypinglite/sakuramedia/releases/latest) 下载（iOS 端要求 iOS 15.0 及以上）。

## 阶段 1：部署后端

### 1. 准备目录

```bash
# 后端运行数据；config、logs、plugins 等子目录由容器首次启动自动创建
mkdir -p sakuramedia/sakuramedia-data/postgres

# 在已有影片目录的同一父目录下，新建媒体库目录
mkdir -p /mnt/volume1/media/library
```

目录结构示例：

```text
/mnt/volume1/media/
├── av/          # 已有影片（示例名，换成你的实际目录）
└── library/     # SakuraMedia 媒体库
```

`av` 和 `library` 在同一个宿主机目录下，后面只挂载它们的父目录 `/mnt/volume1/media`。这样导入时两个目录在同一个挂载点，选择「保留源文件」才能使用硬链接。

### 2. 写 `.env` 和 `compose.yaml`

在 `sakuramedia/` 目录中新建 `.env`：

```bash
STORAGE_ROOT=/mnt/volume1/media
```

再新建 `compose.yaml`：

```yaml
services:
  postgres:
    image: postgres:16-alpine
    container_name: sakuramedia-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: sakuramedia
      POSTGRES_USER: sakuramedia
      POSTGRES_PASSWORD: sakuramedia
    volumes:
      - ./sakuramedia-data/postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U sakuramedia -d sakuramedia"]
      interval: 10s
      timeout: 5s
      retries: 10

  sakuramedia:
    image: tinyping/sakuramediabe:latest
    container_name: sakuramedia
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      # 需要使用其他宿主机端口时修改左侧的 38000。
      - "38000:8000"
    environment:
      # 如果你知道 PUID/PGID 的含义，可以改成和宿主机用户一致。
      PUID: 0
      PGID: 0
      # 不使用中国时区时修改为宿主机所在时区。
      TZ: "Asia/Shanghai"
      # 若部署机器无法直连 JavDB API 或 GFriends，取消下方三行注释并填入代理地址。
      # HTTP_PROXY: "http://192.168.1.1:7890"
      # HTTPS_PROXY: "http://192.168.1.1:7890"
      # NO_PROXY: "localhost,127.0.0.1"
      MALLOC_TRIM_THRESHOLD_: "131072"
    volumes:
      - ./sakuramedia-data:/data
      - ${STORAGE_ROOT}:/media
```

::: danger 保存前必须修改
- `STORAGE_ROOT` 改成宿主机上包含「已有影片目录」和「媒体库目录」的父目录，必须是绝对路径。
- 不使用中国时区时修改 `TZ`。
- 如果 SakuraMedia 以非 root 运行，确保 PUID/PGID 对 `${STORAGE_ROOT}` 有读写权限。
:::

SakuraMedia 的 `/data` 是后端运行数据，`/media` 才是媒体数据。不要把媒体库放到 `/data` 下面。

::: tip 数据库
后端默认按 `postgres` 服务名连接内置 PostgreSQL，照抄示例即可运行。使用外部 PostgreSQL 时，按[配置说明](/guide/config#database)修改 `[database].url`。
:::

### 3. 启动

```bash
cd sakuramedia
docker compose up -d
docker compose ps
```

首次启动会自动建表、安装官方预装插件。`docker compose ps` 中 `postgres` 为 `healthy`、`sakuramedia` 为 `running` 后，打开客户端，首次登录时填写后端地址：

```text
http://你的IP:38000
```

默认用户名和密码是 `account` 和 `account`。登录后建议立即修改密码。

## 阶段 2：创建媒体库并导入已有影片

官方镜像已经预装并启用「本地存储与 qBittorrent」，不需要再上传插件。

### 1. 创建媒体库

「系统设置 → 媒体库 → 新增」，选择「本地存储与 qBittorrent」，填写：

| 字段 | 填写 | 对应宿主机目录 |
|---|---|---|
| 媒体库路径 | `/media/library` | `${STORAGE_ROOT}/library` |
| 手动导入根目录 | `/media/av` | `${STORAGE_ROOT}/av` |

媒体库路径是影片导入后的最终目录；手动导入根目录是浏览已有文件时使用的范围。

`/media/av` 是容器内路径，对应宿主机上的 `${STORAGE_ROOT}/av`。已有影片目录必须挂进容器，来源浏览器里才能看到它。如果你已有目录叫别的名字，把 `/media/av` 换成 `/media/<实际目录名>`。

::: tip 路径映射
- 宿主机 `${STORAGE_ROOT}` → 容器 `/media`
- 已有影片 `${STORAGE_ROOT}/av` → 容器 `/media/av`
- 新媒体库 `${STORAGE_ROOT}/library` → 容器 `/media/library`

完整规则见[容器路径与硬链接](/guide/container-paths)。
:::

<Screenshot src="/images/guide/media-library-form.png" alt="新增媒体库表单" caption="界面示意：新增媒体库；字段由所选存储插件提供。" />

### 2. 导入已有影片

「管理 → 资源导入」→「JAV 影片」→「新建导入」→ 选择刚才的媒体库 → 在来源浏览器中选中影片文件或目录 → 选择导入方式 → 开始导入。

三种导入方式：

| 方式 | 实际行为 | 源文件 | 适合 |
|---|---|---|---|
| 保留源文件 | 优先硬链接；不能硬链接时复制 | 保留 | 同一挂载点，想省空间、保持做种 |
| 导入成功后删除源文件 | 复制到媒体库，成功后删除源文件（效果等同移动） | 删除 | 不想保留原件 |
| 原地导入 | 不复制也不硬链接，媒体直接引用源文件 | 不动 | 文件已整理好，不想动 |

- **保留源文件**：同一挂载点且文件系统支持硬链接时，导入几乎瞬间完成，不占额外空间；不能硬链接时会复制，导入慢一些，并占用双倍空间。
- **导入成功后删除源文件**：先复制到媒体库，导入成功后再删除源文件；导入期间会临时占用双倍空间，但跨文件系统也能用。选择前确认文件没有在做种或被其他程序使用。
- **原地导入**：只支持从手动导入目录导入；之后移动、重命名或修改源文件，媒体会失效；删除 SakuraMedia 中的媒体记录不会删除源文件。

第一次导入建议先选一个小目录，用「保留源文件」验证流程。

提交后在「任务中心」查看进度。导入成功后打开影片详情，确认媒体出现并能播放。

更完整的导入步骤见[导入已有资源](/manual/import)。

::: warning JavDB 图片与元数据
导入时会从 JavDB 获取元数据和图片。容器无法访问 JavDB API 或图片 CDN（`tp.spfcas.com`）时，影片可能缺少封面、剧照或部分信息；使用代理时请确认这些域名能正常访问。
:::

## 可选：自动下载

想让系统为订阅的影片自动寻找资源、下载并导入时，再配置 qBittorrent 和索引器：

- [自动下载与索引器](/guide/auto-download)
- [获得第一部想看的影片](/manual/first-movie)

## 下一步

- 导入更多影片：[导入已有资源](/manual/import)
- 路径与硬链接：[容器路径与硬链接](/guide/container-paths)
- 以图搜图 / 相似影片：[进阶部署](/guide/docker)
- 115 网盘和其他插件：[推荐插件](/guide/plugins)
- 字段和任务频率：[配置说明](/guide/config)、[后台任务](/guide/tasks)
