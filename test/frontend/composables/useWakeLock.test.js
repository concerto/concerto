import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { mount } from '@vue/test-utils';
import { useWakeLock } from '../../../app/frontend/composables/useWakeLock.js';
import { nextTick } from 'vue';

/* global global */

// Test component that uses the composable
const TestComponent = {
  template: '<div>{{ isActive }}</div>',
  setup() {
    return useWakeLock();
  }
};

describe('useWakeLock', () => {
  let wakeLockSentinel;
  let wakeLockRequest;
  let originalNavigator;
  let originalDocument;
  let visibilityChangeListener;

  beforeEach(() => {
    // Save originals
    originalNavigator = global.navigator;
    originalDocument = global.document;

    // Mock WakeLockSentinel
    wakeLockSentinel = {
      release: vi.fn().mockResolvedValue(undefined),
      addEventListener: vi.fn((event, handler) => {
        // Store the release event handler for later
        if (event === 'release') {
          wakeLockSentinel._releaseHandler = handler;
        }
      }),
      removeEventListener: vi.fn()
    };

    // Mock navigator.wakeLock
    wakeLockRequest = vi.fn().mockResolvedValue(wakeLockSentinel);
    global.navigator.wakeLock = {
      request: wakeLockRequest
    };

    // Mock document visibility
    Object.defineProperty(global.document, 'visibilityState', {
      writable: true,
      configurable: true,
      value: 'visible'
    });

    // Spy on addEventListener to capture visibility change listener
    vi.spyOn(global.document, 'addEventListener').mockImplementation((event, handler) => {
      if (event === 'visibilitychange') {
        visibilityChangeListener = handler;
      }
    });
  });

  afterEach(() => {
    // Restore originals
    global.navigator = originalNavigator;
    global.document = originalDocument;
    visibilityChangeListener = null;
    vi.clearAllMocks();
  });

  describe('feature detection', () => {
    it('detects when Wake Lock API is supported', async () => {
      const wrapper = mount(TestComponent);
      await nextTick();

      expect(wrapper.vm.isSupported).toBe(true);
    });

    it('detects when Wake Lock API is not supported', async () => {
      delete global.navigator.wakeLock;

      const consoleSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});
      const wrapper = mount(TestComponent);
      await nextTick();

      expect(wrapper.vm.isSupported).toBe(false);
      expect(wrapper.vm.isActive).toBe(false);
      expect(consoleSpy).toHaveBeenCalledWith(
        '[Wake Lock] Screen Wake Lock API is not supported in this browser'
      );

      consoleSpy.mockRestore();
    });
  });

  describe('wake lock acquisition', () => {
    it('acquires wake lock on mount when supported', async () => {
      const consoleSpy = vi.spyOn(console, 'log').mockImplementation(() => {});
      const wrapper = mount(TestComponent);

      // Wait for async acquisition
      await nextTick();
      await new Promise(resolve => setTimeout(resolve, 0));

      expect(wakeLockRequest).toHaveBeenCalledWith('screen');
      expect(wrapper.vm.isActive).toBe(true);
      expect(consoleSpy).toHaveBeenCalledWith(
        '[Wake Lock] Screen wake lock acquired successfully'
      );

      consoleSpy.mockRestore();
    });

    it('handles wake lock acquisition failure gracefully', async () => {
      const error = new Error('Permission denied');
      wakeLockRequest.mockRejectedValueOnce(error);

      const consoleSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});
      const wrapper = mount(TestComponent);

      // Wait for async acquisition
      await nextTick();
      await new Promise(resolve => setTimeout(resolve, 0));

      expect(wrapper.vm.isActive).toBe(false);
      expect(wrapper.vm.error).toBe('Permission denied');
      expect(consoleSpy).toHaveBeenCalledWith(
        '[Wake Lock] Failed to acquire screen wake lock:',
        error
      );

      consoleSpy.mockRestore();
    });

    it('does not acquire wake lock when page is not visible', async () => {
      global.document.visibilityState = 'hidden';

      const consoleSpy = vi.spyOn(console, 'debug').mockImplementation(() => {});
      mount(TestComponent);

      // Wait for async acquisition
      await nextTick();
      await new Promise(resolve => setTimeout(resolve, 0));

      expect(wakeLockRequest).not.toHaveBeenCalled();
      expect(consoleSpy).toHaveBeenCalledWith(
        '[Wake Lock] Page is not visible, skipping wake lock acquisition'
      );

      consoleSpy.mockRestore();
    });

    it('listens for wake lock release events', async () => {
      mount(TestComponent);

      // Wait for async acquisition
      await nextTick();
      await new Promise(resolve => setTimeout(resolve, 0));

      expect(wakeLockSentinel.addEventListener).toHaveBeenCalledWith('release', expect.any(Function));
    });

    it('updates isActive when wake lock is released', async () => {
      const wrapper = mount(TestComponent);

      // Wait for async acquisition
      await nextTick();
      await new Promise(resolve => setTimeout(resolve, 0));

      expect(wrapper.vm.isActive).toBe(true);

      // Simulate wake lock release
      wakeLockSentinel._releaseHandler();
      await nextTick();

      expect(wrapper.vm.isActive).toBe(false);
    });
  });

  describe('visibility change handling', () => {
    it('registers visibility change listener on mount', async () => {
      mount(TestComponent);
      await nextTick();

      expect(global.document.addEventListener).toHaveBeenCalledWith(
        'visibilitychange',
        expect.any(Function)
      );
    });

    it('re-acquires wake lock when page becomes visible', async () => {
      mount(TestComponent);

      // Wait for initial acquisition
      await nextTick();
      await new Promise(resolve => setTimeout(resolve, 0));

      // Clear the mock to count new calls
      wakeLockRequest.mockClear();

      // Simulate page becoming visible
      global.document.visibilityState = 'visible';
      const consoleSpy = vi.spyOn(console, 'debug').mockImplementation(() => {});

      visibilityChangeListener();

      // Wait for async re-acquisition
      await nextTick();
      await new Promise(resolve => setTimeout(resolve, 0));

      expect(consoleSpy).toHaveBeenCalledWith(
        '[Wake Lock] Page became visible, re-acquiring wake lock'
      );
      expect(wakeLockRequest).toHaveBeenCalledWith('screen');

      consoleSpy.mockRestore();
    });

    it('updates state when page becomes hidden', async () => {
      const wrapper = mount(TestComponent);

      // Wait for initial acquisition
      await nextTick();
      await new Promise(resolve => setTimeout(resolve, 0));

      expect(wrapper.vm.isActive).toBe(true);

      // Simulate page becoming hidden
      global.document.visibilityState = 'hidden';
      const consoleSpy = vi.spyOn(console, 'debug').mockImplementation(() => {});

      visibilityChangeListener();
      await nextTick();

      expect(wrapper.vm.isActive).toBe(false);
      expect(consoleSpy).toHaveBeenCalledWith(
        '[Wake Lock] Page hidden, wake lock will be automatically released'
      );

      consoleSpy.mockRestore();
    });
  });

  describe('cleanup', () => {
    it('releases wake lock on unmount', async () => {
      const wrapper = mount(TestComponent);

      // Wait for async acquisition
      await nextTick();
      await new Promise(resolve => setTimeout(resolve, 0));

      const consoleSpy = vi.spyOn(console, 'log').mockImplementation(() => {});

      // Unmount component
      wrapper.unmount();
      await nextTick();

      expect(wakeLockSentinel.release).toHaveBeenCalled();
      expect(consoleSpy).toHaveBeenCalledWith(
        '[Wake Lock] Screen wake lock released manually'
      );

      consoleSpy.mockRestore();
    });

    it('removes visibility change listener on unmount', async () => {
      const removeEventListenerSpy = vi.spyOn(global.document, 'removeEventListener');
      const wrapper = mount(TestComponent);

      await nextTick();
      await new Promise(resolve => setTimeout(resolve, 0));

      wrapper.unmount();
      await nextTick();

      expect(removeEventListenerSpy).toHaveBeenCalledWith('visibilitychange', expect.any(Function));
    });

    it('handles unmount gracefully when wake lock was never acquired', async () => {
      delete global.navigator.wakeLock;

      const wrapper = mount(TestComponent);
      await nextTick();

      // Should not throw
      expect(() => wrapper.unmount()).not.toThrow();
    });

    it('handles release errors gracefully', async () => {
      wakeLockSentinel.release.mockRejectedValueOnce(new Error('Release failed'));

      const wrapper = mount(TestComponent);

      // Wait for async acquisition
      await nextTick();
      await new Promise(resolve => setTimeout(resolve, 0));

      const consoleSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});

      wrapper.unmount();
      await nextTick();
      await new Promise(resolve => setTimeout(resolve, 0));

      expect(consoleSpy).toHaveBeenCalledWith(
        '[Wake Lock] Error releasing wake lock:',
        expect.any(Error)
      );
      expect(wrapper.vm.isActive).toBe(false);

      consoleSpy.mockRestore();
    });
  });
});
