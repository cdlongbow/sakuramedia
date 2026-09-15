import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'SakuraMedia',
  description: '桌面优先的 SakuraMedia 媒体管理工作台',
  base: '/sakuramedia/',
  lang: 'zh-CN',

  themeConfig: {
    logo: '/brand/sakuramedia-logo.png',
    nav: [
      { text: '开始使用', link: '/guide/introduction' },
      { text: '使用手册', link: '/manual/' },
      { text: '设计理念', link: '/guide/collection-strategy' },
    ],

    sidebar: [
      {
        text: '开始使用',
        collapsed: false,
        items: [
          { text: '介绍', link: '/guide/introduction' },
          { text: '快速开始', link: '/guide/quick-start' },
          { text: '开源插件', link: '/guide/plugins' },
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
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/tinypinglite/sakuramedia' },
    ],

    search: {
      provider: 'local',
    },

    footer: {
      message: 'Released under the GNU GPL v3 License.',
      copyright: 'Copyright © 2024-present SakuraMedia',
    },
  },
})
