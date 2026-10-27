---
outline: [2, 3]
---

# Container Paths and Hard Links

This page answers two questions:

1. **Importing existing movies**: how to map the movie directory on the host into the container so the source browser can see it.
2. **Automatic downloading**: which paths to enter for qBittorrent and SakuraMedia.

Remember one sentence first: **configuration takes paths inside the container, not paths on the host. A host directory must be mounted into the container first.**

## `/data` and `/media`

| Container path | Purpose | Used by |
|---|---|---|
| `/data` | Backend runtime data: configuration, logs, plugins, cache, clips | SakuraMedia |
| `/media` | Media data: existing movies, media libraries, downloads | SakuraMedia; with automatic downloading, qBittorrent also mounts the download subdirectory |

The `/data/...` paths in `config.toml` are the backend's own runtime data; the media library path and the manual import root are entered in System Settings and usually use `/media/...`. Do not mix the two.

## Importing existing movies: how directories map

### Recommended layout

Host:

```text
${STORAGE_ROOT}/
├── av/          # Existing movies (example name; use your own directory)
└── library/     # SakuraMedia media library
```

Container mounts:

```yaml
volumes:
  - ./sakuramedia-data:/data
  - ${STORAGE_ROOT}:/media
```

Media library form:

| Field | Value | Host equivalent |
|---|---|---|
| Media library path | `/media/library` | `${STORAGE_ROOT}/library` |
| Manual import root | `/media/av` | `${STORAGE_ROOT}/av` |

`/media/av` is a path inside the container. If the existing movies directory is not mounted into the container, the source browser cannot see it and you cannot import from it.

### Why not mount the subdirectories separately

Incorrect example:

```yaml
# SakuraMedia
volumes:
  - ${STORAGE_ROOT}/av:/media/av
  - ${STORAGE_ROOT}/library:/media/library
```

They look like they are both under `/media`, but Docker treats them as two independent mount points. When importing with "Keep source file", a hard link cannot be created across mount points, so files are copied instead.

The correct approach is to mount only the parent directory:

```yaml
volumes:
  - ${STORAGE_ROOT}:/media
```

Now `/media/av` and `/media/library` are on the same mount point, and hard links work.

### Existing movies elsewhere or on another disk

- **Existing movies and media library under the same parent directory**: mount the parent directory and hard links are available.
- **Existing movies in another directory**: mount it at `/media/av` and the media library at `/media/library`. Import still works, but the two directories are different mount points, so "Keep source file" copies files.
- **Existing movies spread across several directories**: mount their common parent at `/media/av`, set the manual import root to `/media/av`, and then pick subdirectories in the source browser.
- **Existing movies on another disk or network storage**: mount it at `/media/av` the same way. Hard links do not work across filesystems, so the import copies files.
- **Files are already organized and you do not want to copy them**: use "Import in place". It does not rely on hard links; the source file only has to be visible inside the container.

## The three import modes

| Mode | What actually happens | Source file | Best for |
|---|---|---|---|
| Keep source file | Prefers a hard link; copies when a hard link is not possible | Kept | Same mount point, saving space and keeping the torrent seeding |
| Delete source file after import | Copies into the media library and deletes the source file on success (effectively a move) | Deleted | You do not want to keep the original |
| Import in place | No copy and no hard link; the media references the source file directly | Untouched | Files are already organized and you do not want to touch them |

### Keep source file

- Same mount point and a filesystem that supports hard links: the import finishes almost instantly and uses no extra space.
- Hard link not possible: files are copied automatically, the import is slower, and it uses twice the space.
- Two hard-linked names point at the same data. Deleting one name leaves the other usable; modifying the file content affects both.

### Delete source file after import

- The file is copied into the media library first, and the source is deleted after a successful import.
- It temporarily uses twice the space during the import, and it also works across filesystems.
- The effect is similar to a move, but it is not an atomic move; the source file still exists until the import succeeds.

### Import in place

- Only supported when importing from a "manual import directory" source.
- Nothing is copied and no hard link is created; the media references the source file at its current location.
- If the source file is later moved, renamed or modified, the media becomes broken.
- Deleting the media record in SakuraMedia does not delete the source file.

## qBittorrent paths for automatic downloading

This section is only needed when you configure automatic downloading. Skip it if you only import existing movies.

### qBittorrent and SakuraMedia both run in Docker

qBittorrent only needs to see the download directory:

```yaml
volumes:
  - ${STORAGE_ROOT}/downloads:/media/downloads
```

SakuraMedia already mounts `${STORAGE_ROOT}:/media`, so both sides see `/media/downloads`. Enter `/media/downloads` as qBittorrent's default save path, and `/media/downloads` for both root directories of the download client.

### qBittorrent is a NAS package and its paths cannot be changed

qBittorrent sees host paths, for example `/volume1/downloads`. Mount the common parent of the download directory and the media library into `/media` in SakuraMedia:

```yaml
volumes:
  - /volume1:/media
```

Enter in the download client:

```text
qBittorrent save root   /volume1/downloads
Backend download root   /media/downloads
```

As long as `/volume1/downloads` and `/media/downloads` are the same directory, the mapping test passes. When the media library and the download directory are both under `/volume1`, hard links still work.

See [Auto-Download and Indexers](/guide/auto-download) for the full automatic download setup.

## Verification

### Importing existing movies

- The source browser shows the files under `/media/av`.
- The import task in the Task Center succeeds.
- The movie detail page shows media that plays.

### Download client "Test Configuration"

Click "Test Configuration" before saving the download client; it checks:

- qBittorrent connectivity and authentication;
- whether the two download root directories point at the same physical directory;
- whether the download directory and the media library can create hard links.

Save only after both connectivity and directory mapping pass. If hard links show a warning you can still save, but imports will copy files.

### Checking hard links manually

Run this on the host:

```bash
ls -alhi /path/to/library /path/to/av
```

Find the same file in the output; the two hard links should share an inode and the link count should be at least 2.

## Common errors

| Symptom | Common cause | Fix |
|---|---|---|
| The source browser does not show existing movies | The directory is not mounted into the container; the manual import root is wrong | Check the compose mounts and the media library's manual import root |
| Keep source file is slow and disk usage doubles | The two directories are on different mount points; the filesystem does not support hard links | Mount a single parent directory; switch to a filesystem that supports hard links such as ext4/btrfs/xfs |
| Media breaks after importing in place | The source file was moved, renamed or modified | Keep the source file's location and content unchanged |
| The download client reports that the two paths are not mapped to the same directory | The root directories in qB and the backend are not the same physical directory | Check both mounts against the qB mapping table above |
| Permission errors | PUID/PGID do not match the directory owner | Align PUID/PGID, or make sure SakuraMedia can read and write `${STORAGE_ROOT}`; for automatic downloading, qB must also be able to read and write the download directory |
| The path configuration is rejected | The path contains a symbolic link | Use the real directory instead of a symlink pointing at the media directory |

## 115 and other providers

The rules above only apply to local storage + qBittorrent. The 115 cloud drive provider does not use local media directories or hard links; configure it as described in the 115 plugin section of [Recommended Plugins](/guide/plugins).
