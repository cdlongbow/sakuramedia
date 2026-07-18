#!/usr/bin/env bash
# /app/bin/sakuramedia 启动壳:切到 bundle 目录后 exec Flutter 二进制。
# 切目录是为了保证任何相对路径行为都以 bundle 为根(与非 flatpak Linux 一致)。
set -e
cd /app/lib/sakuramedia
exec /app/lib/sakuramedia/sakuramedia "$@"
