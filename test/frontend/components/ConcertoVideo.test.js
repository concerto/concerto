import { describe, it, expect } from 'vitest';

import { mount } from '@vue/test-utils';
import ConcertoVideo from '~/components/ConcertoVideo.vue';
import ConcertoYoutubeVideo from '~/components/ConcertoYoutubeVideo.vue';
import ConcertoVimeoVideo from '~/components/ConcertoVimeoVideo.vue';

describe('ConcertoVideo', () => {
  it('renders ConcertoYoutubeVideo when video_source is youtube', () => {
    const content = {
      video_source: 'youtube',
      video_id: 'z7HyF46-Zd0',
    };
    const wrapper = mount(ConcertoVideo, { props: { content: content } });

    expect(wrapper.findComponent(ConcertoYoutubeVideo).exists()).toBe(true);
    expect(wrapper.findComponent(ConcertoVimeoVideo).exists()).toBe(false);
  });

  it('renders ConcertoVimeoVideo when video_source is vimeo', () => {
    const content = {
      video_source: 'vimeo',
      video_id: '123456789',
    };
    const wrapper = mount(ConcertoVideo, { props: { content: content } });

    expect(wrapper.findComponent(ConcertoVimeoVideo).exists()).toBe(true);
    expect(wrapper.findComponent(ConcertoYoutubeVideo).exists()).toBe(false);
  });

  it('renders unsupported message for unknown video_source', () => {
    const content = {
      video_source: 'unknown',
    };
    const wrapper = mount(ConcertoVideo, { props: { content: content } });

    expect(wrapper.text()).toContain('Unsupported video source');
  });
});
