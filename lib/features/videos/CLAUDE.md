# lib/features/videos/ — PornBox 非 JAV 视频域

短视频/合集/连播/在线导入。是 movies 之外第二大的业务域,与 movies 平行但**没有订阅、番号筛选、磁力下载、评论**等 JAV 特化;强调**合集(collection)**与**在线导入(imports)**。域级通用范式看 `lib/features/CLAUDE.md`,尤其"短视频/切片域(videos / clips / clip_collections)要点"一节。本文件只讲本域特有约定与目录导航。

## 目录结构(套用 movies 样板:data + controllers 双镜像子域)

```
data/
  api/                             # 3 个 API,每类资源一个
    videos_api.dart                # 单集视频列表 / 详情 / 缩略图
    video_collections_api.dart     # 合集 CRUD / 成员 / 排序 / 拉全成员
    video_imports_api.dart         # 在线导入(SSE 流)
  dto/                             # 4 个 DTO,数量少不再分子域
    video_item_list_item_dto.dart
    video_item_detail_dto.dart
    video_collection_dto.dart
    video_import_job_dto.dart
presentation/
  controllers/
    listing/                       (3) paged_video_summary_controller
                                        + video_filter_state + video_list_page_state
    collections/                   (2) video_collection_detail_controller
                                        + video_collections_overview_controller
    imports/                       (1) video_import_controller
    notifiers/                     (1) video_mutation_change_notifier(跨页广播)
  pages/
    desktop/                       (4) video_list / video_collections /
                                        video_collection_detail / video_collection_play
    mobile/                        (7) pornbox(=mobile 视频列表) /
                                        video_collections / video_collection_detail /
                                        video_collection_play / video_player /
                                        video_actions_sheet / video_sort_drawer
    shared/                        (1) video_list_content
  widgets/
    listing/                       (3) summary_card / summary_grid / filter_toolbar
    collections/                   (4) sort_bar + add_to / create / pick_dialog
    player/                        (1) quick_play_dialog(被 moments 借用)
    imports/                       (1) video_import_dialog
```

**在其它 feature 内 import 时**:DTO 从 `features/videos/data/dto/` 拿,3 个 API 从 `features/videos/data/api/` 拿;跨页广播用 `controllers/notifiers/video_mutation_change_notifier.dart`;唯一被外部借用的 UI 是 `widgets/player/video_quick_play_dialog.dart`(moments)。**不要**从 `pages/` 拿。

## 与 movies 的差异(避免误移植经验)

- **无订阅**:没有 `MovieSubscriptionChangeNotifier` 那一路乐观更新 + 回滚 + toast,只有 `VideoMutationChangeNotifier` 一个总广播(创建/删除/加入合集/移出合集/更新)。
- **无番号筛选**:`VideoFilterState` 比 `MovieFilterState` 简单得多(只有 sort + include_uncollected)。
- **合集有独立的 API 类**:`video_collections_api.dart` 独立,和 videos_api 平级。detail 页 controller 是 `video_collection_detail_controller`(见 collections/)。
- **合集成员端点已分页 + `playUrl` 内联**:`getCollectionItems`/`getAllCollectionItems` 与「详情→连播」交接信箱见 `lib/features/CLAUDE.md`;连播页不再逐集 `getVideoDetail`。
- **移动连播页薄壳桌面**:`pages/mobile/video_collection_play_page.dart` 直接 `return` 桌面版,改桌面同时改移动。
- **无播放器控制器**:视频播放走共享 `widgets/media_player/`(和 clips/clip_collections 共用),没有 `MoviePlayerController` 那一层重逻辑。

## 与测试的关系

`test/features/videos/` 覆盖较薄:
- `data/api/`:3 个 API 全部有 test。
- `presentation/controllers/`:仅 `listing/video_list_page_state_test`、`collections/video_collection_detail_controller_test`。
- **无 page test、无 dialog test、无 imports controller test**;改这些区域没有回归网,需手动验证或补测试。
