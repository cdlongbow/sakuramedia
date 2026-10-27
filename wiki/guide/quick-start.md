---
outline: [2, 3]
---

# Quick Start

This guide does exactly one thing: deploy the SakuraMedia backend and import movies that already exist on the host into a local media library.

Automatic downloading (qBittorrent + indexers), image search, the 115 cloud drive and other features are optional extensions; see [Auto-Download and Indexers](/guide/auto-download), [Advanced Deployment](/guide/docker) and [Recommended Plugins](/guide/plugins).

## Before you begin

- A host or NAS that runs continuously, with Docker and Docker Compose installed.
- An SSD directory for backend runtime data (database, configuration, logs, plugins).
- A host directory that holds your existing movies, for example `/mnt/volume1/media/av`.
- The client, downloaded from [GitHub Releases](https://github.com/tinypinglite/sakuramedia/releases/latest) (the iOS client requires iOS 15.0 or later).

## Stage 1: Deploy the backend

### 1. Prepare the directories

```bash
# Backend runtime data; subdirectories such as config, logs and plugins are created by the container on first start
mkdir -p sakuramedia/sakuramedia-data/postgres

# Create the media library directory under the same parent as the existing movies directory
mkdir -p /mnt/volume1/media/library
```

Example directory layout:

```text
/mnt/volume1/media/
├── av/          # Existing movies (example name; use your own directory)
└── library/     # SakuraMedia media library
```

`av` and `library` sit under the same host directory; later you mount only their parent directory `/mnt/volume1/media`. That way both directories are on the same mount point during import, which is what makes hard links available when you choose "Keep source file".

### 2. Write `.env` and `compose.yaml`

Create a `.env` file inside the `sakuramedia/` directory:

```bash
STORAGE_ROOT=/mnt/volume1/media
```

Then create `compose.yaml`:

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
      # Change the 38000 on the left if you need a different host port.
      - "38000:8000"
    environment:
      # If you know what PUID/PGID mean, set them to match the host user.
      PUID: 0
      PGID: 0
      # Change this to the host time zone if you are not on China time.
      TZ: "Asia/Shanghai"
      # If the host cannot reach the JavDB API or GFriends directly, uncomment the next three lines and fill in your proxy address.
      # HTTP_PROXY: "http://192.168.1.1:7890"
      # HTTPS_PROXY: "http://192.168.1.1:7890"
      # NO_PROXY: "localhost,127.0.0.1"
      MALLOC_TRIM_THRESHOLD_: "131072"
    volumes:
      - ./sakuramedia-data:/data
      - ${STORAGE_ROOT}:/media
```

::: danger Must be changed before saving
- Change `STORAGE_ROOT` to the host parent directory that contains both the "existing movies directory" and the "media library directory". It must be an absolute path.
- Change `TZ` if you are not in the China time zone.
- If SakuraMedia runs as a non-root user, make sure PUID/PGID have read and write access to `${STORAGE_ROOT}`.
:::

SakuraMedia's `/data` holds backend runtime data, while `/media` holds media data. Never put the media library under `/data`.

::: tip Database
By default the backend connects to the built-in PostgreSQL through the service name `postgres`, so the example works as-is. To use an external PostgreSQL, change `[database].url` as described in the [Configuration Reference](/guide/config#database).
:::

### 3. Start

```bash
cd sakuramedia
docker compose up -d
docker compose ps
```

The first start creates the tables and installs the officially preinstalled plugins. Once `postgres` shows `healthy` and `sakuramedia` shows `running` in `docker compose ps`, open the client and enter the backend address on first login:

```text
http://your-ip:38000
```

The default username and password are `account` and `account`. Change the password right after logging in.

## Stage 2: Create a media library and import your existing movies

The official image already has "Local Storage & qBittorrent" installed and enabled, so there is no need to upload a plugin.

### 1. Create a media library

Go to "System Settings → Media Library → Add", choose "Local Storage & qBittorrent" and fill in:

| Field | Value | Host directory |
|---|---|---|
| Media library path | `/media/library` | `${STORAGE_ROOT}/library` |
| Manual import root | `/media/av` | `${STORAGE_ROOT}/av` |

The media library path is the final destination for imported movies; the manual import root is the scope used when browsing existing files.

`/media/av` is a path inside the container and maps to `${STORAGE_ROOT}/av` on the host. The existing movies directory must be mounted into the container, otherwise it will not appear in the source browser. If your directory has a different name, replace `/media/av` with `/media/<actual-directory-name>`.

::: tip Path mapping
- Host `${STORAGE_ROOT}` → container `/media`
- Existing movies `${STORAGE_ROOT}/av` → container `/media/av`
- New media library `${STORAGE_ROOT}/library` → container `/media/library`

See [Container Paths and Hard Links](/guide/container-paths) for the full rules.
:::

<Screenshot src="/images/guide/media-library-form.png" alt="Add media library form" caption="Interface illustration: adding a media library; the fields come from the selected storage plugin." />

### 2. Import your existing movies

"Manage → Media Import" → "JAV Movies" → "New Import" → select the media library you just created → select movie files or directories in the source browser → choose an import mode → start the import.

The three import modes:

| Mode | What actually happens | Source file | Best for |
|---|---|---|---|
| Keep source file | Prefers a hard link; copies when a hard link is not possible | Kept | Same mount point, saving space and keeping the torrent seeding |
| Delete source file after import | Copies into the media library and deletes the source file on success (effectively a move) | Deleted | You do not want to keep the original |
| Import in place | No copy and no hard link; the media references the source file directly | Untouched | Files are already organized and you do not want to touch them |

- **Keep source file**: on the same mount point with a filesystem that supports hard links, the import finishes almost instantly and uses no extra space; when a hard link is not possible it copies instead, which is slower and uses twice the space.
- **Delete source file after import**: the file is copied into the media library first and the source is deleted after a successful import; during the import it temporarily uses twice the space, but it also works across filesystems. Before choosing it, make sure the file is not seeding or in use by another program.
- **Import in place**: only supported from a manual import directory; if the source file is later moved, renamed or modified, the media becomes broken; deleting the media record in SakuraMedia does not delete the source file.

For a first import, pick a small directory and verify the flow with "Keep source file".

After submitting, watch the progress in the "Task Center". Once the import succeeds, open the movie detail page to confirm the media appears and plays.

See [Import existing assets](/manual/import) for the fuller import walkthrough.

::: warning JavDB images and metadata
Metadata and images are fetched from JavDB during import. If the container cannot reach the JavDB API or the image CDN (`tp.spfcas.com`), movies may be missing covers, stills or part of their information; when you use a proxy, make sure these domains are reachable.
:::

## Optional: automatic downloading

To have the system find resources, download and import movies you have subscribed to, configure qBittorrent and an indexer:

- [Auto-Download and Indexers](/guide/auto-download)
- [Get your first movie](/manual/first-movie)

## Next steps

- Import more movies: [Import existing assets](/manual/import)
- Paths and hard links: [Container Paths and Hard Links](/guide/container-paths)
- Image search / similar movies: [Advanced Deployment](/guide/docker)
- The 115 cloud drive and other plugins: [Recommended Plugins](/guide/plugins)
- Fields and task schedules: [Configuration Reference](/guide/config), [Background Tasks](/guide/tasks)
