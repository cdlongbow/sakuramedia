<script setup lang="ts">
import { withBase } from 'vitepress'
import DefaultTheme from 'vitepress/theme'
import DemoVideo from './components/DemoVideo.vue'

const chapters = [
  { label: '概览', time: 0 },
  { label: '发现', time: 4.5 },
  { label: '详情', time: 9.5 },
  { label: '播放器', time: 14.5 },
  { label: '以图搜图', time: 22.5 },
  { label: '切片', time: 26.5 },
  { label: 'PornBox', time: 32 },
]

const previewImage = withBase('/images/readme/home-hero.jpg')
</script>

<template>
  <DefaultTheme.Layout>
    <template #home-features-before>
      <section id="demo" class="demo" aria-labelledby="demo-title">
        <div class="demo__head">
          <div>
            <p class="demo__eyebrow">产品演示 · 45 秒</p>
            <h2 id="demo-title" class="demo__title">看一遍完整流程</h2>
          </div>
          <p class="demo__note">演示数据，封面与缩略图已虚化；视频无旁白。</p>
        </div>
        <DemoVideo
          src="/videos/sakuramedia-demo.mp4"
          poster="/images/readme/desktop-overview.png"
          :chapters="chapters"
          caption="从概览、发现、详情和播放，到缩略图、以图搜图、切片与 PornBox。"
        />
      </section>

      <section class="story" aria-labelledby="story-title">
        <a class="story-card" :href="withBase('/guide/collection-strategy')">
          <h2 id="story-title">这部影片里，你真正想留下什么？</h2>
          <p>一部喜欢的作品，一个舍不得的画面，或是想好好保存的几分钟。聊聊我为什么做这个项目，以及我理解的收藏。</p>
          <span class="story-link">读读 SakuraMedia 的初衷 <span aria-hidden="true">→</span></span>
        </a>
      </section>

      <h2 class="features-title">功能一览</h2>
    </template>

    <template #home-features-after>
      <section class="preview" aria-labelledby="preview-title">
        <h2 id="preview-title" class="preview__title">界面预览</h2>
        <img
          class="preview__img"
          :src="previewImage"
          alt="SakuraMedia 界面预览"
          width="2200"
          height="1237"
          loading="lazy"
          decoding="async"
        />
        <p class="preview__caption">
          截图使用演示数据，封面与缩略图已虚化。
          <a :href="withBase('/manual/')">从使用手册开始 →</a>
        </p>
      </section>
    </template>
  </DefaultTheme.Layout>
</template>

<style scoped>
.demo,
.story,
.preview,
.features-title {
  margin: 0 auto 32px;
  padding: 0 24px;
  max-width: 1280px;
}

.demo {
  padding-top: 8px;
}

.demo__head {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 24px;
  margin-bottom: 20px;
}

.demo__eyebrow {
  color: var(--vp-c-brand-1);
  font-size: 13px;
  font-weight: 600;
  letter-spacing: 0.08em;
}

.demo__title {
  margin-top: 4px;
  color: var(--vp-c-text-1);
  font-size: 24px;
  font-weight: 600;
  line-height: 1.5;
}

.demo__note {
  color: var(--vp-c-text-3);
  font-size: 13px;
  line-height: 1.6;
  text-align: right;
}

.story-card {
  display: block;
  padding: 28px;
  border: 1px solid transparent;
  border-radius: 16px;
  background: var(--vp-c-brand-soft);
  color: var(--vp-c-text-1);
  transition: border-color 0.2s;
}

.story-card:hover {
  border-color: var(--vp-c-brand-1);
}

.story-card:focus-visible {
  outline: 2px solid var(--vp-c-brand-1);
  outline-offset: 4px;
}

.story-card h2 {
  font-size: 24px;
  font-weight: 600;
  line-height: 1.5;
  text-wrap: pretty;
}

.story-card p {
  margin: 12px 0 20px;
  max-width: 760px;
  color: var(--vp-c-text-2);
  font-size: 16px;
  line-height: 1.8;
}

.story-link {
  color: var(--vp-c-brand-1);
  font-size: 15px;
  font-weight: 600;
}

.features-title,
.preview__title {
  margin-bottom: 20px;
  color: var(--vp-c-text-1);
  font-size: 24px;
  font-weight: 600;
  line-height: 1.5;
}

.preview {
  margin-top: 8px;
  margin-bottom: 48px;
}

.preview__img {
  display: block;
  width: 100%;
  height: auto;
  border: 1px solid var(--vp-c-divider);
  border-radius: 16px;
  background: var(--vp-c-bg-soft);
}

.preview__caption {
  margin-top: 12px;
  color: var(--vp-c-text-3);
  font-size: 13px;
  line-height: 1.6;
  text-align: center;
}

.preview__caption a {
  color: var(--vp-c-brand-1);
  font-weight: 600;
  white-space: nowrap;
}

@media (min-width: 640px) {
  .demo,
  .story,
  .preview,
  .features-title {
    padding: 0 48px;
  }

  .story-card {
    padding: 32px 40px;
  }

  .story-card h2 {
    font-size: 28px;
  }
}

@media (min-width: 960px) {
  .demo,
  .story,
  .preview,
  .features-title {
    padding: 0 64px;
  }
}

@media (max-width: 639px) {
  .demo__head {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }

  .demo__note {
    text-align: left;
  }
}
</style>
