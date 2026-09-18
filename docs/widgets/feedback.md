# feedback —— 加载、错误、空态和确认

## 空态和错误

- `AppEmptyState`：路径 `lib/widgets/base/feedback/app_empty_state.dart`，用于无数据、无匹配结果或无可用功能。
- `AppSectionError`：路径 `lib/widgets/base/feedback/app_section_error.dart`，桌面内容区的错误和重试。
- `AppMobileSectionError`：路径 `lib/widgets/base/feedback/app_mobile_section_error.dart`，移动内容区的错误和重试。

错误态要提供用户能执行的重试或返回动作；没有旧内容时才用整块错误态。

## 骨架和加载

- `AppSectionSkeleton`：桌面 section 骨架；列表条目是结构明显的卡片时不要用它兜底。
- `AppSkeletonBlock`、`AppMobileSkeletonCard`、`AppMobileSkeletonList`：移动页面和局部占位。
- `AppCoverCardSkeleton`：封面网格占位。
- `AppLeftCoverCardSkeleton`、`AppLeftCoverCardSkeletonList`：左封面卡列表占位，复用 `AppLeftCoverCard` 的壳与尺寸 token；真实卡行内有固定结构（如底部操作行）时由调用方传 `body`。
- `AppInlineSpinner`：按钮、卡片或局部异步操作中的小型 loading，随平台自适应。
- `AppFilterUpdateBar`：筛选请求更新中的行内反馈。

文件均位于 `lib/widgets/base/feedback/`（卡片骨架也可与所属 feature 的卡片文件同目录）。骨架只描述布局轮廓，不应把真实业务数据写进组件；`SliverPagedAsyncSection.skeletonBuilder` 用于把分页列表首屏骨架替换成与真实卡片同高同形的形态，避免加载完成时列表整片跳变。

## 确认和状态

- `showAppConfirmDialog`：路径 `app_confirm_dialog.dart`，桌面/移动自适应确认弹窗；破坏性动作传 danger 语义。
- `AppStatusChip`：路径 `app_status_chip.dart`，展示有限集合的状态标签。

异步确认动作应使用组件提供的 loading、取消禁用和错误反馈；API 请求仍由调用方或 Provider 负责。

## 页面状态顺序

通常按“初始加载 → 错误/重试 → 空态 → 内容”表达状态。分页加载失败保留已有内容，在列表底部使用分页反馈，不要用整页错误覆盖已有结果。

异步确认窗的关闭按钮遵守请求中的返回限制；长内容可滚动，适配横屏和放大字体。
