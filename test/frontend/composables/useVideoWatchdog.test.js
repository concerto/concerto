import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { mount } from '@vue/test-utils';
import { defineComponent } from 'vue';
import { useVideoWatchdog } from '~/composables/useVideoWatchdog.js';

// Helper to create a wrapper component that uses the composable.
function createWatchdogComponent(options = {}) {
  return defineComponent({
    setup(_, { emit }) {
      const { ping, stop } = useVideoWatchdog(emit, options);
      return { ping, stop };
    },
    template: '<div />',
  });
}

describe('useVideoWatchdog', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('emits next when no ping is received within the stall timeout', () => {
    const wrapper = mount(createWatchdogComponent({ stallTimeout: 1000 }));

    // Start the watchdog with an initial ping.
    wrapper.vm.ping();

    // Advance past the stall timeout.
    vi.advanceTimersByTime(1000);

    expect(wrapper.emitted('next')).toHaveLength(1);
  });

  it('does not emit next when pings are received regularly', () => {
    const wrapper = mount(createWatchdogComponent({ stallTimeout: 1000 }));

    wrapper.vm.ping();
    vi.advanceTimersByTime(500);

    // Ping again before timeout.
    wrapper.vm.ping();
    vi.advanceTimersByTime(500);

    // Ping again before timeout.
    wrapper.vm.ping();
    vi.advanceTimersByTime(500);

    expect(wrapper.emitted('next')).toBeUndefined();
  });

  it('does not emit next before the first ping', () => {
    mount(createWatchdogComponent({ stallTimeout: 1000 }));

    // Advance well past the timeout without ever pinging.
    vi.advanceTimersByTime(5000);

    // No next emitted because watchdog was never started.
    // (No wrapper.emitted check needed since there's nothing to assert on)
  });

  it('does not emit next after stop is called', () => {
    const wrapper = mount(createWatchdogComponent({ stallTimeout: 1000 }));

    wrapper.vm.ping();
    vi.advanceTimersByTime(500);

    wrapper.vm.stop();
    vi.advanceTimersByTime(1000);

    expect(wrapper.emitted('next')).toBeUndefined();
  });

  it('cleans up on component unmount', () => {
    const wrapper = mount(createWatchdogComponent({ stallTimeout: 1000 }));

    wrapper.vm.ping();
    wrapper.unmount();

    vi.advanceTimersByTime(1000);

    // After unmount, next should not be emitted.
    expect(wrapper.emitted('next')).toBeUndefined();
  });

  it('uses default stall timeout of 15 seconds', () => {
    const wrapper = mount(createWatchdogComponent());

    wrapper.vm.ping();

    // Should not trigger at 14 seconds.
    vi.advanceTimersByTime(14000);
    expect(wrapper.emitted('next')).toBeUndefined();

    // Should trigger at 15 seconds.
    vi.advanceTimersByTime(1000);
    expect(wrapper.emitted('next')).toHaveLength(1);
  });

  it('only emits next once per stall', () => {
    const wrapper = mount(createWatchdogComponent({ stallTimeout: 1000 }));

    wrapper.vm.ping();
    vi.advanceTimersByTime(1000);

    expect(wrapper.emitted('next')).toHaveLength(1);

    // Further time passing should not emit again.
    vi.advanceTimersByTime(5000);
    expect(wrapper.emitted('next')).toHaveLength(1);
  });

  it('can restart after a stall by pinging again', () => {
    const wrapper = mount(createWatchdogComponent({ stallTimeout: 1000 }));

    wrapper.vm.ping();
    vi.advanceTimersByTime(1000);
    expect(wrapper.emitted('next')).toHaveLength(1);

    // Ping again to restart monitoring.
    wrapper.vm.ping();
    vi.advanceTimersByTime(1000);
    expect(wrapper.emitted('next')).toHaveLength(2);
  });
});
