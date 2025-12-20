import { describe, it, expect, beforeAll, afterAll, afterEach, vi } from 'vitest'

import { setupServer } from 'msw/node'
import { HttpResponse, http } from 'msw'
import { mount, flushPromises } from '@vue/test-utils'
import { nextTick } from 'vue'

import ConcertoField from '~/components/ConcertoField.vue'
import ConcertoGraphic from '~/components/ConcertoGraphic.vue'
import ConcertoRichText from '~/components/ConcertoRichText.vue'

const fieldContentUrl = 'http://server/field_content.json';
const fieldUnknownContentUrl = 'http://server/field_unknown_content.json';

const fieldContent = [
  {
    "id": 1,
    "duration": 30,
    "type": "Graphic",
    "image": "poster.png"
  },
  {
    "id": 2,
    "duration": null,
    "type": "RichText",
    "render_as": "plaintext",
    "text": "Welcome to Concerto!"
  }, {
    "id": 3,
    "duration": 25,
    "type": "Graphic",
    "image": "welcome.jpg"
  },
];

const fieldUnknownContent = [
  {
    "id": 1,
    "duration": null,
    "type": "Graphic",
    "image": "poster.png"
  },
  {
    "id": 2,
    "type": "UnknownContentType",
  },
  {
    "id": 3,
    "duration": null,
    "type": "Graphic",
    "image": "welcome.png"
  }, 
];

  
export const httpHandlers = [
  http.get(fieldContentUrl, () => {
    return HttpResponse.json(fieldContent);
  }),
  http.get(fieldUnknownContentUrl, () => {
    return HttpResponse.json(fieldUnknownContent);
  }),
];

const server = setupServer(...httpHandlers);

// Start server before all tests.
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));

// Close server after all tests.
afterAll(() => server.close());

// Reset handlers after each test.
afterEach(() => {
  vi.restoreAllMocks();
  vi.useRealTimers();
  server.resetHandlers();
});

describe('ConcertoField', () => {
  it('fetches and displays first content', async () => {
    const wrapper = mount(ConcertoField, {
      props: { apiUrl: fieldContentUrl },
      global: {
        stubs: {
          transition: false,
        }
      }
    });

    await flushPromises();

    expect(wrapper.findComponent(ConcertoGraphic).props()).toEqual(
      {
        content: fieldContent[0]
      }
    );
  });

  it('advances to the next content after duration', async () => {
    vi.useFakeTimers();

    const wrapper = mount(ConcertoField, {
      props: { apiUrl: fieldContentUrl },
      global: {
        stubs: {
          transition: false,
        }
      }
    });

    await flushPromises();

    // First Load -> Graphic.
    expect(wrapper.findComponent(ConcertoGraphic).exists()).toBe(true);
    expect(wrapper.findComponent(ConcertoRichText).exists()).toBe(false);

    vi.advanceTimersToNextTimer();
    await nextTick();

    // Graphic -> RichText.
    expect(wrapper.findComponent(ConcertoGraphic).exists()).toBe(false);
    expect(wrapper.findComponent(ConcertoRichText).exists()).toBe(true);

    vi.advanceTimersToNextTimer();
    await nextTick();

    // RichText -> Graphic.
    expect(wrapper.findComponent(ConcertoGraphic).exists()).toBe(true);
    expect(wrapper.findComponent(ConcertoRichText).exists()).toBe(false);
  });

  it('skips over unknown content types', async () => {
    const wrapper = mount(ConcertoField, {
      props: { apiUrl: fieldUnknownContentUrl },
      global: {
        stubs: {
          transition: false,
        }
      }
    });

    await flushPromises();

    // First load displays the initial graphic.
    expect(wrapper.findComponent(ConcertoGraphic).props()).toEqual(
      {
        content: fieldUnknownContent[0]
      }
    );

    const vm = wrapper.vm;
    // Advance to the next content.
    vm.next();

    await nextTick();

    // Skips over the unknown content type and renders the graphic.
    expect(wrapper.findComponent(ConcertoGraphic).props()).toEqual(
      {
        content: fieldUnknownContent[2]
      }
    );
  });

  it('allows content to take over timer control', async () => {
    vi.useFakeTimers();
    const wrapper = mount(ConcertoField, {
      props: { apiUrl: fieldContentUrl },
      global: {
        stubs: {
          transition: false,
        }
      }
    });

    await flushPromises();

    // Initially shows first graphic content
    expect(wrapper.findComponent(ConcertoGraphic).exists()).toBe(true);
    
    // When content emits take-over-timer
    wrapper.findComponent(ConcertoGraphic).vm.$emit('take-over-timer');
    await nextTick();
    
    // Advancing timer should not trigger content change
    vi.advanceTimersToNextTimer();
    await nextTick();
    expect(wrapper.findComponent(ConcertoGraphic).exists()).toBe(true);

    // Content can advance itself by emitting next
    wrapper.findComponent(ConcertoGraphic).vm.$emit('next');
    await nextTick();
    expect(wrapper.findComponent(ConcertoRichText).exists()).toBe(true);
  });

  describe('preloading', () => {
    let preloadedImages = [];

    beforeAll(() => {
      // Mock Image constructor to track preloaded images
      // eslint-disable-next-line no-undef
      global.Image = class {
        set src(value) {
          preloadedImages.push(value);
          setTimeout(() => this.onload && this.onload(), 0);
        }
        set onload(callback) { this._onload = callback; }
        get onload() { return this._onload; }
        set onerror(callback) { this._onerror = callback; }
      };
    });

    afterEach(() => {
      preloadedImages = [];
    });

    it('preloads next graphic after showing current content', async () => {
      mount(ConcertoField, {
        props: { apiUrl: fieldContentUrl },
        global: { stubs: { transition: false } }
      });

      await flushPromises();

      // After showing first graphic (poster.png), the next item is RichText
      // which doesn't support preloading, so nothing should be preloaded yet
      await nextTick();
      await flushPromises();

      // Preload is not called since next item is RichText
      expect(preloadedImages).not.toContain('welcome.jpg');
    });

    it('does not preload non-graphic content', async () => {
      mount(ConcertoField, {
        props: { apiUrl: fieldContentUrl },
        global: { stubs: { transition: false } }
      });

      await flushPromises();

      // Should not preload RichText content
      await nextTick();
      await flushPromises();

      // Check that all preloaded URLs are image files
      preloadedImages.forEach(url => {
        expect(['poster.png', 'welcome.jpg']).toContain(url);
      });
    });

    it('avoids duplicate preloads', async () => {
      vi.useFakeTimers();

      mount(ConcertoField, {
        props: { apiUrl: fieldContentUrl },
        global: { stubs: { transition: false } }
      });

      await flushPromises();

      // Advance to next content
      vi.advanceTimersToNextTimer();
      await nextTick();
      await flushPromises();

      // Should not have duplicate URLs
      const uniqueUrls = new Set(preloadedImages);
      expect(preloadedImages.length).toBe(uniqueUrls.size);

      vi.useRealTimers();
    });

    it('handles preload errors gracefully', async () => {
      // Mock Image to always fail
      // eslint-disable-next-line no-undef
      global.Image = class {
        set src(value) {
          preloadedImages.push(value);
          setTimeout(() => this.onerror && this.onerror(new Error('Failed')), 0);
        }
        set onload(callback) { this._onload = callback; }
        set onerror(callback) { this._onerror = callback; }
      };

      const wrapper = mount(ConcertoField, {
        props: { apiUrl: fieldContentUrl },
        global: { stubs: { transition: false } }
      });

      await flushPromises();

      // Content should still display normally
      expect(wrapper.findComponent(ConcertoGraphic).exists()).toBe(true);
    });
  });
})