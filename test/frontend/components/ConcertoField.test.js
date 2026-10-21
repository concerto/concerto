import { describe, it, expect, beforeAll, beforeEach, afterAll, afterEach, vi } from 'vitest'

import { setupServer } from 'msw/node'
import { HttpResponse, http } from 'msw'
import { mount, enableAutoUnmount } from '@vue/test-utils'
import { nextTick } from 'vue'

import ConcertoField from '~/components/ConcertoField.vue'
import ConcertoGraphic from '~/components/ConcertoGraphic.vue'
import ConcertoRichText from '~/components/ConcertoRichText.vue'
import { eventually } from '../support/eventually.js'

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

beforeAll(() => server.listen({ onUnhandledFrame: 'error' }));
afterAll(() => server.close());

// Unmount every field after its test so its timers and fetches can't leak into
// the next test.
enableAutoUnmount(afterEach);

afterEach(() => {
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
  vi.useRealTimers();
  server.resetHandlers();
});

function mountField(props = {}) {
  return mount(ConcertoField, {
    props: { apiUrl: fieldContentUrl, ...props },
    global: { stubs: { transition: false } },
  });
}

// The content the field is currently showing, or null if it shows nothing.
function shownContent(wrapper) {
  for (const component of [ConcertoGraphic, ConcertoRichText]) {
    const found = wrapper.findComponent(component);
    if (found.exists()) return found.props('content');
  }
  return null;
}

describe('ConcertoField', () => {
  it('fetches and displays first content', async () => {
    const wrapper = mountField();

    await eventually(() => expect(shownContent(wrapper)).toEqual(fieldContent[0]));
  });

  it('shows each content for its duration, defaulting to 10 seconds', async () => {
    vi.useFakeTimers();
    const wrapper = mountField();
    await eventually(() => expect(shownContent(wrapper)).toEqual(fieldContent[0]));

    // fieldContent[0] lasts 30 seconds.
    vi.advanceTimersByTime(29_999);
    await nextTick();
    expect(shownContent(wrapper)).toEqual(fieldContent[0]);

    vi.advanceTimersByTime(1);
    await nextTick();
    expect(shownContent(wrapper)).toEqual(fieldContent[1]);

    // fieldContent[1] has no duration, so it gets the 10 second default.
    vi.advanceTimersByTime(9_999);
    await nextTick();
    expect(shownContent(wrapper)).toEqual(fieldContent[1]);

    vi.advanceTimersByTime(1);
    await nextTick();
    expect(shownContent(wrapper)).toEqual(fieldContent[2]);
  });

  it('skips over unknown content types', async () => {
    const wrapper = mountField({ apiUrl: fieldUnknownContentUrl });
    await eventually(() => expect(shownContent(wrapper)).toEqual(fieldUnknownContent[0]));

    // Clicking content advances to the next one.
    await wrapper.findComponent(ConcertoGraphic).trigger('click');

    expect(shownContent(wrapper)).toEqual(fieldUnknownContent[2]);
  });

  it('allows content to take over timer control', async () => {
    vi.useFakeTimers();
    const wrapper = mountField();
    await eventually(() => expect(shownContent(wrapper)).toEqual(fieldContent[0]));

    wrapper.findComponent(ConcertoGraphic).vm.$emit('take-over-timer');

    // Long past fieldContent[0]'s 30 second duration, the field leaves it alone.
    vi.advanceTimersByTime(60_000);
    await nextTick();
    expect(shownContent(wrapper)).toEqual(fieldContent[0]);

    // Content advances itself by emitting next.
    wrapper.findComponent(ConcertoGraphic).vm.$emit('next');
    await nextTick();
    expect(shownContent(wrapper)).toEqual(fieldContent[1]);
  });

  describe('style splitting', () => {
    it('applies text styles to .field and box styles to content component', async () => {
      const wrapper = mountField({
        fieldStyle: 'color:#000; border:1px solid #ccc; font-family:Arial;',
      });
      const graphic = await eventually(() => wrapper.getComponent(ConcertoGraphic));

      const fieldStyle = wrapper.get('.field').attributes('style');
      expect(fieldStyle).toContain('font-family: Arial');
      expect(fieldStyle).not.toContain('border');

      expect(graphic.props('boxStyle')).toBe('border:1px solid #ccc;');
    });

    it('passes empty boxStyle when only text styles present', async () => {
      const wrapper = mountField({ fieldStyle: 'font-weight:bold;' });
      const graphic = await eventually(() => wrapper.getComponent(ConcertoGraphic));

      const fieldStyle = wrapper.get('.field').attributes('style');
      expect(fieldStyle).toContain('font-weight');

      expect(graphic.props('boxStyle')).toBe('');
    });

    it('passes empty boxStyle and no field style when fieldStyle is empty', async () => {
      const wrapper = mountField({ fieldStyle: '' });
      const graphic = await eventually(() => wrapper.getComponent(ConcertoGraphic));

      const fieldStyle = wrapper.get('.field').attributes('style') || '';
      expect(fieldStyle).toBe('');

      expect(graphic.props('boxStyle')).toBe('');
    });

    it('passes box styles to content when no text styles', async () => {
      const wrapper = mountField({ fieldStyle: 'border:solid 2px #663333;' });
      const graphic = await eventually(() => wrapper.getComponent(ConcertoGraphic));

      const fieldStyle = wrapper.get('.field').attributes('style') || '';
      expect(fieldStyle).not.toContain('border');

      expect(graphic.props('boxStyle')).toBe('border:solid 2px #663333;');
    });
  });

  describe('empty content retry', () => {
    it('retries after 30 seconds when content is initially empty', async () => {
      vi.useFakeTimers();
      const setTimeoutSpy = vi.spyOn(globalThis, 'setTimeout');

      let callCount = 0;
      server.use(
        http.get(fieldContentUrl, () => {
          callCount++;
          if (callCount === 1) {
            return HttpResponse.json([]);
          }
          return HttpResponse.json(fieldContent);
        })
      );

      const wrapper = mountField();

      // The empty response has been handled once the retry is scheduled.
      await eventually(() =>
        expect(setTimeoutSpy).toHaveBeenCalledWith(expect.any(Function), 30_000)
      );
      expect(shownContent(wrapper)).toBeNull();

      vi.advanceTimersByTime(30_000);

      // The retry fetched content, which is now displayed.
      await eventually(() => expect(shownContent(wrapper)).toEqual(fieldContent[0]));
      expect(callCount).toBe(2);
    });
  });

  describe('preloading', () => {
    let preloadedImages;

    // Stands in for the browser's Image so tests can see what gets preloaded,
    // and whether those loads succeed.
    function stubImage({ fails = false } = {}) {
      vi.stubGlobal('Image', class {
        set src(value) {
          preloadedImages.push(value);
          setTimeout(() => (fails ? this.onerror?.(new Error('Failed')) : this.onload?.()), 0);
        }
      });
    }

    beforeEach(() => {
      preloadedImages = [];
      vi.useFakeTimers();
    });

    // fieldContent is Graphic (30s) -> RichText (10s) -> Graphic (welcome.jpg).

    it('does not preload content that does not support it', async () => {
      stubImage();
      const wrapper = mountField();
      await eventually(() => expect(shownContent(wrapper)).toEqual(fieldContent[0]));

      // Next up is RichText, which has nothing to preload.
      expect(preloadedImages).toEqual([]);
    });

    it('preloads the next graphic while the current content is showing', async () => {
      stubImage();
      const wrapper = mountField();
      await eventually(() => expect(shownContent(wrapper)).toEqual(fieldContent[0]));

      vi.advanceTimersByTime(30_000);
      await nextTick();
      expect(shownContent(wrapper)).toEqual(fieldContent[1]);

      expect(preloadedImages).toEqual(['welcome.jpg']);
    });

    it('does not load a graphic again when it is shown', async () => {
      stubImage();
      const wrapper = mountField();
      await eventually(() => expect(shownContent(wrapper)).toEqual(fieldContent[0]));

      vi.advanceTimersByTime(30_000 + 10_000);
      await nextTick();
      expect(shownContent(wrapper)).toEqual(fieldContent[2]);

      expect(preloadedImages).toEqual(['welcome.jpg']);
    });

    it('handles preload errors gracefully', async () => {
      stubImage({ fails: true });
      const warn = vi.spyOn(console, 'warn').mockImplementation(() => {});
      const wrapper = mountField();
      await eventually(() => expect(shownContent(wrapper)).toEqual(fieldContent[0]));

      // Showing RichText starts the preload of welcome.jpg, which fails...
      vi.advanceTimersByTime(30_000);
      await nextTick();
      expect(shownContent(wrapper)).toEqual(fieldContent[1]);

      // ...but the graphic still shows on schedule.
      vi.advanceTimersByTime(10_000);
      await nextTick();
      expect(shownContent(wrapper)).toEqual(fieldContent[2]);
      expect(warn).toHaveBeenCalledWith(
        expect.stringContaining('Failed to preload graphic: welcome.jpg'),
        expect.any(Error)
      );
    });
  });
})
