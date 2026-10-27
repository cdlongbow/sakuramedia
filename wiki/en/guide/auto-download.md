---
outline: [2, 3]
---

# Auto-Download and Indexers

[Quick Start](/en/guide/quick-start) focuses on importing existing movies. Only after a download client and an indexer are configured can SakuraMedia automatically find resources for movies you subscribe to, submit downloads and import them into the media library.

This page assumes you have already finished the deployment and media library creation from Quick Start.

## Before you begin

- A reachable qBittorrent on the same machine as SakuraMedia (Docker on the same host or a NAS package).
- A Jackett or Prowlarr indexer.
- If you want to use hard links, the download directory and the media library must be on the same mount point (which usually also means the same filesystem).

## 1. Make qBittorrent and SakuraMedia see the same download directory

The path rules are the same as for importing existing movies: **the same host directory, mounted at the same path in both containers.**

Recommended qBittorrent container mount:

```yaml
volumes:
  - ${STORAGE_ROOT}/downloads:/media/downloads
```

If the download directory does not exist on the host yet, create it first (using the example path from Quick Start; the real path follows your `STORAGE_ROOT`):

```bash
mkdir -p /mnt/volume1/media/downloads
```

SakuraMedia already mounts `${STORAGE_ROOT}:/media`, so it sees `/media/downloads`. In qBittorrent, go to "Settings → Downloads → Default Save Path" and enter `/media/downloads`.

If qBittorrent is not running in Docker or its paths cannot be changed, see [qBittorrent paths for automatic downloading](/en/guide/container-paths#qbittorrent-paths-for-automatic-downloading).

## 2. Add a download client

Go to "System Settings → Download Clients → Add" and select the target media library:

| Field | Value |
|---|---|
| qBittorrent address | qB on the host: `http://<host-ip>:8080` (use your qB WebUI port); qB and SakuraMedia in the same compose: `http://qbittorrent:8080` |
| Username / password | The qBittorrent WebUI credentials |
| qBittorrent save root | `/media/downloads` |
| Backend download root | `/media/downloads` |

Click "Test Configuration" before saving to confirm that the directory mapping and hard links pass. A directory mapping failure usually means the two root directories do not point at the same physical directory; see [qBittorrent paths for automatic downloading](/en/guide/container-paths#qbittorrent-paths-for-automatic-downloading) for how to fix it.

<Screenshot src="/images/guide/download-client-form.png" alt="Add download client form" caption="Interface illustration: when adding a download client, select the target media library and fill in the configuration fields provided by the plugin." />

## 3. Configure an indexer and bind a download client

Go to "System Settings → Indexers → Add". The "Feed URL" must be the full Torznab URL, not the home page of a site or aggregator:

| Source | Feed URL | API Key |
|---|---|---|
| Jackett | The site's "Copy Torznab Feed" link | Copy it from the top-right corner of the dashboard |
| Prowlarr | The RSS icon URL in the indexer list, shaped like `http://<host>:9696/<indexer-ID>/api?apikey=...` | The URL already contains `apikey`, so you can leave this empty |

After saving, bind one or more download clients (the first one becomes the default download target), then click "Test Torznab Connectivity".

## 4. Verify

1. On the "Overview" page, run "Component Diagnostics" to confirm connectivity to the media library, indexers and JavDB; check the download client separately with "Test Configuration" on the download clients page.
2. Subscribe to a movie and wait for the background task to look for resources.
3. To actively verify the automatic flow, manually trigger "Auto-download missing subscribed movies" in the Task Center and check the run result. When no suitable resource exists, a completed run does not mean a successful download.

See [Get your first movie](/en/manual/first-movie) for the full flow. Importing existing movies does not need this step; see [Import existing assets](/en/manual/import).

## Path rules

- qBittorrent and SakuraMedia mount the same host directory at the same container path.
- SakuraMedia mounts the parent directory only once so that the media library and the download directory are on the same mount point, which is what makes hard links work.
- Do not mount `downloads` and `library` separately, otherwise imports fall back to copying.

See [Container Paths and Hard Links](/en/guide/container-paths) for the full path mapping and the three import modes.
