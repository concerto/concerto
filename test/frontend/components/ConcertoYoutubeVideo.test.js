import { describe, it, expect, beforeEach, vi } from 'vitest'

import { mount } from '@vue/test-utils'
import ConcertoYoutubeVideo from '~/components/ConcertoYoutubeVideo.vue'

// Disable some eslint rules for this test file since we mock out YT.
/* global global */
/* global YT */

describe('ConcertoYoutubeVideo', () => {
  it('displays image', () => {
    const content = {
      video_id: 'z7HyF46-Zd0'
    };
    const wrapper = mount(ConcertoYoutubeVideo, { props: { content: content } });

    expect(wrapper.html()).toContain('src="https://www.youtube-nocookie.com/embed/z7HyF46-Zd0?rel=0&amp;iv_load_policy=3&amp;autoplay=1');
  })
})

describe('ConcertoYoutubeVideo duration control', () => {
  beforeEach(() => {
    // Mock YouTube API
    global.YT = {
      Player: vi.fn(),
      PlayerState: {
        PLAYING: 1,
        PAUSED: 2,
        ENDED: 0
      }
    };
  });

  it('takes over timer control when video has no duration', async () => {
    const content = {
      video_id: 'z7HyF46-Zd0',
      duration: null
    };
    const wrapper = mount(ConcertoYoutubeVideo, { props: { content: content } });

    // Get the callback registered with YT.Player
    const playerCallback = global.YT.Player.mock.calls[0][1].events.onStateChange;

    // Simulate video starting to play
    playerCallback({ data: YT.PlayerState.PLAYING });

    expect(wrapper.emitted('takeOverTimer')).toBeTruthy();
  });

  it('emits next event when video ends and has no duration', async () => {
    const content = {
      video_id: 'z7HyF46-Zd0',
      duration: null
    };
    const wrapper = mount(ConcertoYoutubeVideo, { props: { content: content } });

    // Get the callback registered with YT.Player
    const playerCallback = global.YT.Player.mock.calls[0][1].events.onStateChange;

    // Simulate video ending
    playerCallback({ data: YT.PlayerState.ENDED });

    expect(wrapper.emitted('next')).toBeTruthy();
  });

  it('does not take over timer when video has duration', async () => {
    const content = {
      video_id: 'z7HyF46-Zd0',
      duration: 30
    };
    const wrapper = mount(ConcertoYoutubeVideo, { props: { content: content } });

    // Get the callback registered with YT.Player
    const playerCallback = global.YT.Player.mock.calls[0][1].events.onStateChange;

    // Simulate video starting to play
    playerCallback({ data: YT.PlayerState.PLAYING });

    expect(wrapper.emitted('takeOverTimer')).toBeFalsy();
  });
});