import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

import { mount } from '@vue/test-utils';
import ConcertoVimeoVideo from '~/components/ConcertoVimeoVideo.vue';

// Mock Vimeo API
/* global global */
global.Vimeo = {
  Player: vi.fn().mockImplementation(function() {
    this.on = vi.fn();
  }),
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
    global.Vimeo.Player.mockImplementation(function() {
      return mockPlayer;
    });
  });

  it('takes over timer control when video has no duration', async () => {
    const content = {
      video_id: '123456789',
      duration: null,
    };
    const wrapper = mount(ConcertoVimeoVideo, { props: { content: content } });

    // Simulate 'play' event
    const playCallback = mockPlayer.on.mock.calls.find(call => call[0] === 'play')?.[1];
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
    const endedCallback = mockPlayer.on.mock.calls.find(call => call[0] === 'ended')?.[1];
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
    const playCallback = mockPlayer.on.mock.calls.find(call => call[0] === 'play')?.[1];
    playCallback();

    expect(wrapper.emitted('takeOverTimer')).toBeFalsy();
  });

  it('registers a timeupdate listener for watchdog', async () => {
    const content = {
      video_id: '123456789',
      duration: null,
    };
    mount(ConcertoVimeoVideo, { props: { content: content } });

    const timeupdateCall = mockPlayer.on.mock.calls.find(call => call[0] === 'timeupdate');
    expect(timeupdateCall).toBeTruthy();
  });
});

describe('ConcertoVimeoVideo watchdog', () => {
  let mockPlayer;

  beforeEach(() => {
    vi.useFakeTimers();
    mockPlayer = {
      on: vi.fn(),
      destroy: vi.fn(),
    };
    global.Vimeo.Player.mockImplementation(function() {
      return mockPlayer;
    });
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('emits next when player stalls after playing', async () => {
    const content = {
      video_id: '123456789',
      duration: null,
    };
    const wrapper = mount(ConcertoVimeoVideo, { props: { content: content } });

    // Simulate play event to start watchdog.
    const playCallback = mockPlayer.on.mock.calls.find(call => call[0] === 'play')?.[1];
    playCallback();

    // No timeupdate events for 15 seconds (player crashed).
    vi.advanceTimersByTime(15000);

    const nextEvents = wrapper.emitted('next');
    expect(nextEvents).toBeTruthy();
    expect(nextEvents).toHaveLength(1);
  });

  it('does not emit next when timeupdate events keep arriving', async () => {
    const content = {
      video_id: '123456789',
      duration: null,
    };
    const wrapper = mount(ConcertoVimeoVideo, { props: { content: content } });

    const playCallback = mockPlayer.on.mock.calls.find(call => call[0] === 'play')?.[1];
    const timeupdateCallback = mockPlayer.on.mock.calls.find(call => call[0] === 'timeupdate')?.[1];
    playCallback();

    // Simulate regular timeupdate events.
    for (let i = 0; i < 10; i++) {
      vi.advanceTimersByTime(5000);
      timeupdateCallback();
    }

    expect(wrapper.emitted('next')).toBeUndefined();
  });

  it('does not trigger watchdog after video ends normally', async () => {
    const content = {
      video_id: '123456789',
      duration: null,
    };
    const wrapper = mount(ConcertoVimeoVideo, { props: { content: content } });

    const playCallback = mockPlayer.on.mock.calls.find(call => call[0] === 'play')?.[1];
    const endedCallback = mockPlayer.on.mock.calls.find(call => call[0] === 'ended')?.[1];
    playCallback();
    endedCallback();

    // The ended event already emitted next once. Watchdog should not fire again.
    vi.advanceTimersByTime(15000);

    expect(wrapper.emitted('next')).toHaveLength(1);
  });
});
