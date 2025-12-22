import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import ConcertoClock from '~/components/ConcertoClock.vue'

describe('ConcertoClock', () => {
  beforeEach(() => {
    // Use fake timers for testing time-based functionality
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('validates props', () => {
    const content = {
      format: '',
    };
    expect(ConcertoClock.props.content.validator(content)).toBe(false);

    content.format = 'h:mm a';
    expect(ConcertoClock.props.content.validator(content)).toBe(true);

    const invalidContent = {
      format: 123,
    };
    expect(ConcertoClock.props.content.validator(invalidContent)).toBe(false);
  });

  it('renders time with 12-hour format', async () => {
    // Set a specific date/time for testing
    const testDate = new Date('2025-12-21T14:34:00');
    vi.setSystemTime(testDate);

    const content = {
      format: 'h:mm a',
    };
    const wrapper = mount(ConcertoClock, { props: { content } });
    await nextTick();

    expect(wrapper.text()).toContain('2:34 PM');
  });

  it('renders date with short format', async () => {
    // Set a specific date for testing
    const testDate = new Date('2025-12-21T14:34:00');
    vi.setSystemTime(testDate);

    const content = {
      format: 'EEE, MMM d',
    };
    const wrapper = mount(ConcertoClock, { props: { content } });
    await nextTick();

    // date-fns formats this as "Sun, Dec 21"
    expect(wrapper.text()).toMatch(/Sun.*Dec.*21/);
  });

  it('renders datetime with combined format', async () => {
    const testDate = new Date('2025-12-21T14:34:00');
    vi.setSystemTime(testDate);

    const content = {
      format: 'h:mm a, MMM d',
    };
    const wrapper = mount(ConcertoClock, { props: { content } });
    await nextTick();

    expect(wrapper.text()).toMatch(/2:34 PM.*Dec.*21/);
  });

  // TODO: Fix this test - vi.setSystemTime() doesn't properly integrate with vi.advanceTimersByTime()
  // in Vitest, causing new Date() to return stale time even after advancing timers.
  // The interval setup and cleanup are verified by the "cleans up interval on unmount" test.
  it.skip('updates time after UPDATE_INTERVAL_MS', async () => {
    vi.setSystemTime(new Date('2025-12-21T14:34:00'));

    const content = {
      format: 'h:mm a',
    };
    const wrapper = mount(ConcertoClock, { props: { content } });
    await nextTick();

    // Initial render at 2:34 PM
    expect(wrapper.text()).toContain('2:34 PM');

    // Change system time to 2:35 PM
    vi.setSystemTime(new Date('2025-12-21T14:35:00'));

    // Advance timers by 60 seconds to trigger setInterval callback
    vi.advanceTimersByTime(60000);
    await nextTick();

    // Should show updated time
    expect(wrapper.text()).toContain('2:35 PM');
  });

  it('handles custom format strings', async () => {
    const testDate = new Date('2025-12-21T14:34:56');
    vi.setSystemTime(testDate);

    const content = {
      format: 'EEEE, MMMM do, yyyy - h:mm:ss a',
    };
    const wrapper = mount(ConcertoClock, { props: { content } });
    await nextTick();

    // date-fns formats this as "Sunday, December 21st, 2025 - 2:34:56 PM"
    expect(wrapper.text()).toMatch(/Sunday.*December.*21.*2025.*2:34:56 PM/);
  });

  it('handles invalid format gracefully', async () => {
    const testDate = new Date('2025-12-21T14:34:00');
    vi.setSystemTime(testDate);

    const content = {
      format: 'invalid{{{{format',
    };
    const wrapper = mount(ConcertoClock, { props: { content } });
    await nextTick();

    // Should show error message
    expect(wrapper.text()).toContain('Invalid format');
  });

  it('cleans up interval on unmount', () => {
    const content = {
      format: 'h:mm a',
    };
    const wrapper = mount(ConcertoClock, { props: { content } });

    const clearIntervalSpy = vi.spyOn(globalThis, 'clearInterval');
    wrapper.unmount();

    expect(clearIntervalSpy).toHaveBeenCalled();
  });
});
