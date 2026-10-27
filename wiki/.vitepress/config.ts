import { defineConfig } from 'vitepress'

const zhNav = [
  { text: '开始使用', link: '/guide/introduction' },
  { text: '使用手册', link: '/manual/' },
  { text: '设计理念', link: '/guide/collection-strategy' },
]

const enNav = [
  { text: 'Getting started', link: '/en/guide/introduction' },
  { text: 'User manual', link: '/en/manual/' },
  { text: 'Design', link: '/en/guide/collection-strategy' },
]

const zhSidebar = [
  {
    text: '开始使用',
    collapsed: false,
    items: [
      { text: '介绍', link: '/guide/introduction' },
      { text: '快速开始', link: '/guide/quick-start' },
      { text: '容器路径与硬链接', link: '/guide/container-paths' },
      { text: '自动下载与索引器', link: '/guide/auto-download' },
      { text: '推荐插件', link: '/guide/plugins' },
      { text: '配置说明', link: '/guide/config' },
      { text: '进阶部署', link: '/guide/docker' },
      { text: '后台任务', link: '/guide/tasks' },
      { text: '媒体存储迁移', link: '/guide/media-storage-transfer' },
      { text: '常用命令', link: '/guide/commands' },
      { text: '常见问题', link: '/faq' },
      { text: '插件开发', link: '/guide/plugin-development' },
    ],
  },
  {
    text: '使用手册',
    collapsed: false,
    items: [
      { text: '阅读导航', link: '/manual/' },
      {
        text: '入门',
        collapsed: false,
        items: [
          { text: '认识系统', link: '/manual/concepts' },
          { text: '获得第一部影片', link: '/manual/first-movie' },
          { text: '导入已有资源', link: '/manual/import' },
        ],
      },
      {
        text: '日常使用',
        collapsed: false,
        items: [
          { text: '发现与女优订阅', link: '/manual/discover' },
          { text: '订阅与下载进度', link: '/manual/subscriptions' },
          { text: '开始观看', link: '/manual/playback' },
          { text: '收藏与整理', link: '/manual/collections' },
        ],
      },
      {
        text: '进阶使用',
        collapsed: true,
        items: [
          { text: '媒体库管理', link: '/manual/media-management' },
          { text: '以图搜图', link: '/manual/image-search' },
          { text: 'PornBox 与普通视频', link: '/guide/videos' },
        ],
      },
    ],
  },
  {
    text: '设计理念',
    collapsed: true,
    items: [
      { text: '为什么做 SakuraMedia', link: '/guide/collection-strategy' },
      { text: '从喜欢的画面开始看', link: '/guide/watch-from-a-frame' },
      { text: '有空的时候，想看的已经在了', link: '/guide/waiting-for-a-movie' },
    ],
  },
]

const enSidebar = [
  {
    text: 'Getting started',
    collapsed: false,
    items: [
      { text: 'Introduction', link: '/en/guide/introduction' },
      { text: 'Quick start', link: '/en/guide/quick-start' },
      { text: 'Container paths and hard links', link: '/en/guide/container-paths' },
      { text: 'Auto download and indexers', link: '/en/guide/auto-download' },
      { text: 'Recommended plugins', link: '/en/guide/plugins' },
      { text: 'Configuration', link: '/en/guide/config' },
      { text: 'Advanced deployment', link: '/en/guide/docker' },
      { text: 'Background tasks', link: '/en/guide/tasks' },
      { text: 'Media storage transfer', link: '/en/guide/media-storage-transfer' },
      { text: 'Common commands', link: '/en/guide/commands' },
      { text: 'FAQ', link: '/en/faq' },
      { text: 'Plugin development', link: '/en/guide/plugin-development' },
    ],
  },
  {
    text: 'User manual',
    collapsed: false,
    items: [
      { text: 'Reading guide', link: '/en/manual/' },
      {
        text: 'Getting started',
        collapsed: false,
        items: [
          { text: 'Understanding the system', link: '/en/manual/concepts' },
          { text: 'Getting your first movie', link: '/en/manual/first-movie' },
          { text: 'Importing existing files', link: '/en/manual/import' },
        ],
      },
      {
        text: 'Daily use',
        collapsed: false,
        items: [
          { text: 'Discovery and actor subscriptions', link: '/en/manual/discover' },
          { text: 'Subscriptions and download progress', link: '/en/manual/subscriptions' },
          { text: 'Start watching', link: '/en/manual/playback' },
          { text: 'Collections and organizing', link: '/en/manual/collections' },
        ],
      },
      {
        text: 'Advanced use',
        collapsed: true,
        items: [
          { text: 'Media library management', link: '/en/manual/media-management' },
          { text: 'Image search', link: '/en/manual/image-search' },
          { text: 'PornBox and regular videos', link: '/en/guide/videos' },
        ],
      },
    ],
  },
  {
    text: 'Design',
    collapsed: true,
    items: [
      { text: 'Why SakuraMedia', link: '/en/guide/collection-strategy' },
      { text: 'Start from a frame you love', link: '/en/guide/watch-from-a-frame' },
      { text: 'When you are free, it is already there', link: '/en/guide/waiting-for-a-movie' },
    ],
  },
]

const zhThemeConfig = {
  nav: zhNav,
  sidebar: zhSidebar,
  footer: {
    message: 'Released under the GNU GPL v3 License.',
    copyright: 'Copyright © 2024-present SakuraMedia',
  },
}

const enThemeConfig = {
  nav: enNav,
  sidebar: enSidebar,
  footer: {
    message: 'Released under the GNU GPL v3 License.',
    copyright: 'Copyright © 2024-present SakuraMedia',
  },
}

const zhSearchTranslations = {
  button: {
    buttonText: '搜索',
    buttonAriaLabel: '搜索',
  },
  modal: {
    displayDetails: '显示详细列表',
    resetButtonTitle: '重置搜索条件',
    backButtonTitle: '返回上一处',
    noResultsText: '没有找到结果：',
    footer: {
      selectText: '选择',
      selectKeyAriaLabel: '回车键',
      navigateText: '切换',
      navigateUpKeyAriaLabel: '上箭头',
      navigateDownKeyAriaLabel: '下箭头',
      closeText: '关闭',
      closeKeyAriaLabel: 'Esc 键',
    },
  },
}

const enSearchTranslations = {
  button: {
    buttonText: 'Search',
    buttonAriaLabel: 'Search',
  },
  modal: {
    displayDetails: 'Display detailed list',
    resetButtonTitle: 'Reset search criteria',
    backButtonTitle: 'Back to previous location',
    noResultsText: 'No results for',
    footer: {
      selectText: 'to select',
      selectKeyAriaLabel: 'enter key',
      navigateText: 'to navigate',
      navigateUpKeyAriaLabel: 'up arrow',
      navigateDownKeyAriaLabel: 'down arrow',
      closeText: 'to close',
      closeKeyAriaLabel: 'escape key',
    },
  },
}

export default defineConfig({
  title: 'SakuraMedia',
  description: '桌面优先的 SakuraMedia 媒体管理工作台',
  base: '/sakuramedia/',
  lang: 'zh-CN',

  locales: {
    root: {
      label: '简体中文',
      lang: 'zh-CN',
      description: '桌面优先的 SakuraMedia 媒体管理工作台',
      themeConfig: zhThemeConfig,
    },
    en: {
      label: 'English',
      lang: 'en',
      description: 'A desktop-first media library workbench for SakuraMedia',
      themeConfig: enThemeConfig,
    },
  },

  themeConfig: {
    logo: '/brand/sakuramedia-logo.png',

    socialLinks: [
      { icon: 'github', link: 'https://github.com/tinypinglite/sakuramedia' },
    ],

    search: {
      provider: 'local',
      options: {
        locales: {
          root: { translations: zhSearchTranslations },
          en: { translations: enSearchTranslations },
        },
      },
    },
  },
})
