import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';

import { mount } from '@vue/test-utils';
import ConcertoVimeoVideo from '~/components/ConcertoVimeoVideo.vue';

// Mock Vimeo API
/* global global */
global.Vimeo = {
  Player: vi.fn().mockImplementation(function() {
    this.on = vi.fn();
    this.play = vi.fn().mockResolvedValue();
    this.setMuted = vi.fn().mockResolvedValue();
  }),
};

describe('ConcertoVimeoVideo', () => {
  it('renders iframe with correct video URL', () => {
    const content = {
      video_id: '123456789',
    };
    const wrapper = mount(ConcertoVimeoVideo, { props: { content: content } });

    expect(wrapper.html()).toContain('src="https://player.vimeo.com/video/123456789?autoplay=1&amp;loop=0&amp;api=1&amp;muted=1&amp;background=1"');
  });

  it('applies a backend-provided aspect_ratio', () => {
    const wrapper = mount(ConcertoVimeoVideo, {
      props: { content: { video_id: '123456789', aspect_ratio: '4/3' } }
    });
    expect(wrapper.find('iframe').attributes('style')).toContain('aspect-ratio: 4/3');
  });

  it('uses muted background mode when audio is disabled', () => {
    const wrapper = mount(ConcertoVimeoVideo, {
      props: { content: { video_id: '123456789', audio: false } }
    });
    const src = wrapper.find('iframe').attributes('src');
    expect(src).toContain('muted=1');
    expect(src).toContain('background=1');
  });

  it('omits muted and background params when audio is enabled', () => {
    const wrapper = mount(ConcertoVimeoVideo, {
      props: { content: { video_id: '123456789', audio: true } }
    });
    const src = wrapper.find('iframe').attributes('src');
    expect(src).not.toContain('muted=1');
    expect(src).not.toContain('background=1');
    expect(src).toContain('controls=0');
  });
});

describe('ConcertoVimeoVideo audio fallback', () => {
  let mockPlayer;

  beforeEach(() => {
    mockPlayer = {
      on: vi.fn(),
      play: vi.fn(),
      setMuted: vi.fn(),
    };
    global.Vimeo.Player.mockImplementation(function() {
      return mockPlayer;
    });
  });

  it('falls back to muted when play() rejects', async () => {
    mockPlayer.play.mockRejectedValueOnce(new Error('NotAllowedError'));
    mockPlayer.setMuted.mockResolvedValue();
    mockPlayer.play.mockResolvedValueOnce();

    mount(ConcertoVimeoVideo, {
      props: { content: { video_id: '123456789', audio: true } }
    });

    // Wait for the rejection-then-fallback chain to settle.
    await vi.waitFor(() => {
      expect(mockPlayer.setMuted).toHaveBeenCalledWith(true);
    });
    // play() is called once optimistically, then again after setMuted resolves.
    expect(mockPlayer.play.mock.calls.length).toBeGreaterThanOrEqual(2);
  });

  it('does not call play() when audio is disabled', () => {
    mount(ConcertoVimeoVideo, {
      props: { content: { video_id: '123456789', audio: false } }
    });
    expect(mockPlayer.play).not.toHaveBeenCalled();
  });
});

describe('ConcertoVimeoVideo dynamic aspect ratio', () => {
  let mockPlayer;

  beforeEach(() => {
    mockPlayer = {
      on: vi.fn(),
      getVideoWidth: vi.fn().mockResolvedValue(1080),
      getVideoHeight: vi.fn().mockResolvedValue(1920),
    };
    global.Vimeo.Player.mockImplementation(function() {
      return mockPlayer;
    });
  });

  it('updates aspect ratio from the Player API when aspect_ratio_auto is true', async () => {
    const wrapper = mount(ConcertoVimeoVideo, {
      props: { content: { video_id: '123456789', aspect_ratio: '16/9', aspect_ratio_auto: true } }
    });

    // Wait for the getVideoWidth/getVideoHeight promises to settle.
    await vi.waitFor(() => {
      expect(wrapper.find('iframe').attributes('style')).toContain('aspect-ratio: 1080/1920');
    });
  });

  it('does not override the user-provided ratio when aspect_ratio_auto is false', async () => {
    const wrapper = mount(ConcertoVimeoVideo, {
      props: { content: { video_id: '123456789', aspect_ratio: '16/9', aspect_ratio_auto: false } }
    });

    // Allow any pending microtasks to flush before asserting no change.
    await Promise.resolve();
    await Promise.resolve();
    expect(mockPlayer.getVideoWidth).not.toHaveBeenCalled();
    expect(wrapper.find('iframe').attributes('style')).toContain('aspect-ratio: 16/9');
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
