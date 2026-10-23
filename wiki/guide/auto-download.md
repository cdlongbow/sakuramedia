---
outline: [2, 3]
---

# 自动下载与索引器

[快速开始](/guide/quick-start)以「导入已有影片」为主。配置好下载器和索引器后，SakuraMedia 才能为订阅的影片自动寻找资源、提交下载并导入媒体库。

这页默认已经完成快速开始中的部署和媒体库创建。

## 开始前

- 一个可访问的 qBittorrent，和 SakuraMedia 在同一台机器上（本机 Docker 或 NAS 套件）。
- 一个 Jackett 或 Prowlarr 索引器。
- 想使用硬链接时，下载目录和媒体库需要在同一个挂载点下（通常也意味着同一个文件系统）。

## 1. 让 qBittorrent 和 SakuraMedia 看到同一个下载目录

路径规则和导入已有影片一样：**同一个宿主机目录，挂到两个容器里的同一个路径。**

推荐 qBittorrent 容器挂载：

```yaml
volumes:
  - ${STORAGE_ROOT}/downloads:/media/downloads
```

如果宿主机上还没有下载目录，先创建它（按快速开始的示例路径，实际路径以你的 `STORAGE_ROOT` 为准）：

```bash
mkdir -p /mnt/volume1/media/downloads
```

SakuraMedia 已经挂载了 `${STORAGE_ROOT}:/media`，所以它看到的是 `/media/downloads`。在 qBittorrent「设置 → 下载 → 默认保存路径」中填 `/media/downloads`。

qBittorrent 不是 Docker 或路径改不了时，见[容器路径与硬链接](/guide/container-paths#自动下载时的-qbittorrent-路径)。

## 2. 添加下载器

「系统设置 → 下载器 → 新增」，选择目标媒体库：

| 字段 | 填写 |
|---|---|
| qBittorrent 地址 | qB 在宿主机：`http://宿主机IP:8080`（按你的 qB WebUI 端口）；qB 和 SakuraMedia 在同一 compose：`http://qbittorrent:8080` |
| 用户名 / 密码 | qBittorrent WebUI 的登录信息 |
| qBittorrent 保存根目录 | `/media/downloads` |
| 后端下载根目录 | `/media/downloads` |

保存前点「测试配置」，确认目录映射和硬链接通过。目录映射失败通常是两个根目录没有指向同一个物理目录；处理方式见[容器路径与硬链接](/guide/container-paths#自动下载时的-qbittorrent-路径)。

<Screenshot src="/images/guide/download-client-form.png" alt="添加下载器表单" caption="界面示意：添加下载器时选择目标媒体库，并填写插件提供的配置字段。" />

## 3. 配置索引器并绑定下载器

「系统设置 → 索引器 → 新增」。「资源地址」要填完整的 Torznab 地址，不要填网站或聚合器的首页：

| 来源 | 资源地址 | API Key |
|---|---|---|
| Jackett | 站点对应的「Copy Torznab Feed」 | 面板右上角复制 |
| Prowlarr | 索引器列表的 RSS 图标地址，形如 `http://<主机>:9696/<索引器ID>/api?apikey=...` | 地址已包含 `apikey`，可留空 |

保存后绑定一个或多个下载器（第一个作为默认下载目标），再点「测试 Torznab 连通性」。

## 4. 验证

1. 在「概览」页运行「组件诊断」，确认媒体库、索引器、JavDB 的连通性；下载器用下载器页的「测试配置」单独检查。
2. 订阅一部影片，等待后台任务查询资源。
3. 想主动验证自动流程时，在任务中心手动触发「已订阅缺失影片自动下载」，然后查看运行结果。没有合适资源时，任务运行完成也不代表成功下载。

完整流程见[获得第一部想看的影片](/manual/first-movie)。导入已有影片不需要这一步，见[导入已有资源](/manual/import)。

## 路径规则

- qBittorrent 和 SakuraMedia 把同一个宿主机目录挂到同一个容器路径。
- SakuraMedia 只挂一次父目录，让媒体库和下载目录在同一个挂载点下，硬链接才能工作。
- 不要分别挂载 `downloads` 和 `library`，否则导入会退化为复制。

完整的路径映射和三种导入方式见[容器路径与硬链接](/guide/container-paths)。
