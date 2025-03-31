import { describe, it, expect, beforeEach, vi } from 'vitest';

import { mount } from '@vue/test-utils';
import ConcertoVimeoVideo from '~/components/ConcertoVimeoVideo.vue';

// Mock Vimeo API
/* global global */
global.Vimeo = {
  Player: vi.fn().mockImplementation(() => ({
    on: vi.fn(),
  })),
};

describe('ConcertoVimeoVideo', () => {
  it('renders iframe with correct video URL', () => {
    const content = {
      video_id: '123456789',
    };
    const wrapper = mount(ConcertoVimeoVideo, { props: { content: content } });

    expect(wrapper.html()).toContain('src="https://player.vimeo.com/video/123456789?autoplay=1&amp;muted=1&amp;loop=0&amp;api=1&amp;background=1"');
  });
});

describe('ConcertoVimeoVideo duration control', () => {
  let mockPlayer;

  beforeEach(() => {
    mockPlayer = {
      on: vi.fn(),
    };
    global.Vimeo.Player.mockImplementation(() => mockPlayer);
  });

  it('takes over timer control when video has no duration', async () => {
    const content = {
      video_id: '123456789',
      duration: null,
    };
    const wrapper = mount(ConcertoVimeoVideo, { props: { content: content } });

    // Simulate 'play' event
    const playCallback = mockPlayer.on.mock.calls.find(call => call[0] === 'play')[1];
    playCallback();

    expect(wrapper.emitted('takeOverTimer')).toBeTruthy();
  });

  it('emits next event when video ends and has no duration', async () => {
    const content = {
      video_id: '123456789',
      duration: null,
    };
    const wrapper = mount(ConcertoVimeoVideo, { props: { content: content } });

    // Simulate 'ended' event
    const endedCallback = mockPlayer.on.mock.calls.find(call => call[0] === 'ended')[1];
    endedCallback();

    expect(wrapper.emitted('next')).toBeTruthy();
  });

  it('does not take over timer when video has duration', async () => {
    const content = {
      video_id: '123456789',
      duration: 30,
    };
    const wrapper = mount(ConcertoVimeoVideo, { props: { content: content } });

    // Simulate 'play' event
    const playCallback = mockPlayer.on.mock.calls.find(call => call[0] === 'play')[1];
    playCallback();

    expect(wrapper.emitted('takeOverTimer')).toBeFalsy();
  });
});
