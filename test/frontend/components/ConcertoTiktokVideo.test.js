import { describe, it, expect, beforeEach, vi } from 'vitest'

import { mount } from '@vue/test-utils'
import ConcertoTiktokVideo from '~/components/ConcertoTiktokVideo.vue'

describe('ConcertoTiktokVideo', () => {
  it('displays iframe with correct URL', () => {
    const content = {
      video_id: '6718335390845095173'
    };
    const wrapper = mount(ConcertoTiktokVideo, { props: { content: content } });

    const iframe = wrapper.find('iframe');
    expect(iframe.attributes('src')).toBe('https://www.tiktok.com/player/v1/6718335390845095173?autoplay=1&muted=1&loop=0&controls=0');
  })
})

describe('ConcertoTiktokVideo duration control', () => {
  beforeEach(() => {
    // Clear any existing event listeners
    vi.clearAllMocks();
  });

  it('takes over timer control when video has no duration', async () => {
    const content = {
      video_id: '6718335390845095173',
      duration: null
    };
    const wrapper = mount(ConcertoTiktokVideo, { props: { content: content } });

    // Simulate TikTok player message for playing state
    const event = new MessageEvent('message', {
      origin: 'https://www.tiktok.com',
      data: {
        'x-tiktok-player': true,
        type: 'onStateChange',
        value: 1 // Playing state
      }
    });

    window.dispatchEvent(event);
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('takeOverTimer')).toBeTruthy();
  });

  it('emits next event when video ends and has no duration', async () => {
    const content = {
      video_id: '6718335390845095173',
      duration: null
    };
    const wrapper = mount(ConcertoTiktokVideo, { props: { content: content } });

    // Simulate TikTok player message for ended state
    const event = new MessageEvent('message', {
      origin: 'https://www.tiktok.com',
      data: {
        'x-tiktok-player': true,
        type: 'onStateChange',
        value: 0 // Ended state
      }
    });

    window.dispatchEvent(event);
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('next')).toBeTruthy();
  });

  it('does not take over timer when video has duration', async () => {
    const content = {
      video_id: '6718335390845095173',
      duration: 30
    };
    const wrapper = mount(ConcertoTiktokVideo, { props: { content: content } });

    // Simulate TikTok player message for playing state
    const event = new MessageEvent('message', {
      origin: 'https://www.tiktok.com',
      data: {
        'x-tiktok-player': true,
        type: 'onStateChange',
        value: 1 // Playing state
      }
    });

    window.dispatchEvent(event);
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('takeOverTimer')).toBeFalsy();
  });

  it('ignores non-TikTok player messages', async () => {
    const content = {
      video_id: '6718335390845095173',
      duration: null
    };
    const wrapper = mount(ConcertoTiktokVideo, { props: { content: content } });

    // Simulate a message without the x-tiktok-player flag
    const event = new MessageEvent('message', {
      origin: 'https://www.tiktok.com',
      data: {
        type: 'someOtherEvent',
        value: 1
      }
    });

    window.dispatchEvent(event);
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('takeOverTimer')).toBeFalsy();
  });

  it('ignores messages from untrusted origins', async () => {
    const content = {
      video_id: '6718335390845095173',
      duration: null
    };
    const wrapper = mount(ConcertoTiktokVideo, { props: { content: content } });

    // Simulate a message from a malicious origin
    const event = new MessageEvent('message', {
      origin: 'https://evil.com',
      data: {
        'x-tiktok-player': true,
        type: 'onStateChange',
        value: 1
      }
    });

    window.dispatchEvent(event);
    await wrapper.vm.$nextTick();

    expect(wrapper.emitted('takeOverTimer')).toBeFalsy();
  });
});
