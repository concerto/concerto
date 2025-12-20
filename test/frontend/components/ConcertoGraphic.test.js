import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'

import { mount } from '@vue/test-utils'
import ConcertoGraphic, { preload } from '~/components/ConcertoGraphic.vue'

describe('ConcertoGraphic', () => {
  it('displays image', () => {
    const content = {
      image: 'image.jpg'
    };
    const wrapper = mount(ConcertoGraphic, { props: { content: content }});

    const style = getComputedStyle(wrapper.get('.graphic').element);

    expect(style.cssText).toContain('url(image.jpg)');
  })
})

describe('ConcertoGraphic.preload', () => {
  let imageLoadCallback;
  let imageErrorCallback;
  let imageSrc;

  beforeEach(() => {
    // Mock Image constructor to simulate successful load
    // eslint-disable-next-line no-undef
    global.Image = class {
      constructor() {
        setTimeout(() => {
          if (imageLoadCallback) imageLoadCallback();
        }, 0);
      }

      set src(value) {
        imageSrc = value;
      }

      set onload(callback) {
        imageLoadCallback = callback;
      }

      set onerror(callback) {
        imageErrorCallback = callback;
      }
    };
  });

  afterEach(() => {
    vi.restoreAllMocks();
    imageLoadCallback = null;
    imageErrorCallback = null;
    imageSrc = null;
  });

  it('resolves when image loads successfully', async () => {
    const content = { image: 'test.jpg' };

    const promise = preload(content);
    await expect(promise).resolves.toBeUndefined();
  });

  it('resolves even when image fails to load', async () => {
    // eslint-disable-next-line no-undef
    global.Image = class {
      set src(value) { imageSrc = value; }
      set onload(callback) { imageLoadCallback = callback; }
      set onerror(callback) {
        imageErrorCallback = callback;
        setTimeout(() => {
          if (imageErrorCallback) {
            imageErrorCallback(new Error('Load failed'));
          }
        }, 0);
      }
    };

    const content = { image: 'missing.jpg' };

    const promise = preload(content);
    await expect(promise).resolves.toBeUndefined();
  });

  it('resolves when content has no image', async () => {
    const content = {};

    const promise = preload(content);
    await expect(promise).resolves.toBeUndefined();
  });

  it('resolves when content is null', async () => {
    const promise = preload(null);
    await expect(promise).resolves.toBeUndefined();
  });

  it('times out after 30 seconds', async () => {
    vi.useFakeTimers();

    // eslint-disable-next-line no-undef
    global.Image = class {
      set src(value) { imageSrc = value; }
      set onload(callback) { /* Never call */ }
      set onerror(callback) { /* Never call */ }
    };

    const content = { image: 'slow.jpg' };
    const promise = preload(content);

    vi.advanceTimersByTime(30000);

    await expect(promise).resolves.toBeUndefined();
    vi.useRealTimers();
  });

  it('sets correct image src', async () => {
    const content = { image: 'https://example.com/image.png' };

    await preload(content);
    expect(imageSrc).toBe('https://example.com/image.png');
  });
})
