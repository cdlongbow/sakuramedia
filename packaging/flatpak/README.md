# Flatpak 分发

SakuraMedia Linux 桌面通过 Flatpak 分发,单 `.flatpak` 文件即可安装,自带
libmpv + 完整 codec(通过 `org.freedesktop.Platform.ffmpeg-full` 扩展),
不吃系统包。发布走 GitHub Releases,不投 Flathub。

## 分层结构

| 文件 | 作用 |
|---|---|
| `io.github.tinypinglite.SakuraMedia.yml` | Flatpak manifest — runtime/权限/build 步骤 |
| `io.github.tinypinglite.SakuraMedia.desktop` | 桌面启动项(Wayland/GNOME/KDE 皆识别) |
| `io.github.tinypinglite.SakuraMedia.metainfo.xml` | AppData 元信息(为将来投 Flathub 保留) |
| `launcher.sh` | `/app/bin/sakuramedia` 启动壳 |
| `scripts/generate-icons.sh` | 从 macOS 1024×1024 图标缩出 128/256/512 |
| `bundle/`(生成) | Flutter Linux 产物(由 CI 或本地脚本填充,gitignore) |
| `icons/`(生成) | 128/256/512 图标(由脚本填充,gitignore) |

## App ID / 权限

- App ID: `io.github.tinypinglite.SakuraMedia`
- 沙箱权限最小集:网络 · GUI(Wayland+X11 fallback) · 音频(PulseAudio) ·
  GPU(dri) · Secret Service(存凭据) —— 文件选择器/URL 打开走 xdg-desktop-portal,
  自动可用,不需要 `--filesystem` 声明

## 本地打包

```bash
# 1. 一次性装依赖
sudo dnf install -y flatpak flatpak-builder ImageMagick
flatpak remote-add --user --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user --noninteractive --assumeyes flathub \
  org.freedesktop.Platform//24.08 \
  org.freedesktop.Sdk//24.08 \
  org.freedesktop.Platform.ffmpeg-full//24.08

# 2. 构建 Flutter Linux 产物
flutter build linux --release

# 3. 移交 bundle 到 flatpak 工作区
rsync -a --delete build/linux/x64/release/bundle/ \
  packaging/flatpak/bundle/

# 4. 生成图标
bash packaging/flatpak/scripts/generate-icons.sh

# 5. 构建 flatpak
cd packaging/flatpak
flatpak-builder --user --force-clean --install-deps-from=flathub \
  --repo=repo build-dir io.github.tinypinglite.SakuraMedia.yml

# 6. 打成单文件 bundle
flatpak build-bundle repo sakuramedia.flatpak \
  io.github.tinypinglite.SakuraMedia
```

产物在 `packaging/flatpak/sakuramedia.flatpak`。

## 本地安装/试运行

```bash
flatpak install --user ./sakuramedia.flatpak
flatpak run io.github.tinypinglite.SakuraMedia
```

卸载:

```bash
flatpak uninstall --user io.github.tinypinglite.SakuraMedia
```

## CI 分发

推 `v*` tag 触发 `.github/workflows/release.yml`,并行调 5 个平台 workflow,
Linux 侧是 `release-linux.yml`:

1. Ubuntu runner 装 Flutter + Linux 桌面 build 依赖
2. `flutter build linux --release --build-name="<tag 去 v>"`
3. rsync bundle → `packaging/flatpak/bundle/`
4. 用 apt 装 flatpak + flatpak-builder,装 `org.freedesktop.Platform/Sdk/ffmpeg-full`
5. `flatpak-builder` 出 flatpak repo,`build-bundle` 打包成 `.flatpak`
6. 上传 workflow artifact + 发布到 GitHub Release,附 sha256

**升级 libmpv 版本时**:manifest 里 libmpv 的 `tag` 和 `commit` 同时锁定,
避免上游移动 tag 导致构建不可复现。升级步骤:

```bash
# 假设升到 v0.40.0
git ls-remote https://github.com/mpv-player/mpv.git refs/tags/v0.40.0
# 把 sha 填到 manifest 的 commit: 字段,tag: 同步改
```

## 已知踩坑

- **`add-extensions` 的挂载点必须提前存在**:manifest 里 `cleanup-commands`
  已经 `mkdir -p /app/lib/ffmpeg`,不能删。
- **libmpv 用 SDK 里的基础 ffmpeg 链接、运行时被 ffmpeg-full 覆盖**:要求
  soname 一致;若 SDK 与 ffmpeg-full 版本对不齐(如 24.08 vs 23.08 混用),
  会 dlopen 失败。所以 SDK / Platform / ffmpeg-full 三者的 `//24.08` 必须保持一致。
- **libsecret 依赖 org.freedesktop.secrets**:GNOME Keyring、KWallet、
  KeepassXC(装了 Secret Service 集成)都实现该接口。装了才能保存密码;
  没装 flutter_secure_storage 会静默失败,登录页失去自动填充能力,
  但不影响主功能(见 `lib/core/CLAUDE.md`)。
- **APPLICATION_ID 已从 `com.example.sakuramedia` 改为 App ID**
  (`linux/CMakeLists.txt`),让 Wayland WM class / GNOME 任务栏能正确关联
  到 `.desktop` 条目。
