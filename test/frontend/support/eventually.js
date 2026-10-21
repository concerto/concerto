import { vi } from 'vitest'
import { flushPromises } from '@vue/test-utils'

/**
 * Retries `assertion` until it stops throwing, letting promises and I/O run
 * between attempts. Returns whatever the assertion returns.
 *
 * Use this instead of a bare `flushPromises()` after anything that goes through
 * the msw-mocked network. msw 3 sends `fetch` through Node's real HTTP client
 * over an intercepted socket, so a response takes an unpredictable number of
 * event-loop turns to arrive.
 *
 * Unlike `vi.waitFor`, this never moves a fake clock, so tests that control
 * time keep exact control of it. (Moving it mid-request can also fire the HTTP
 * client's own connect timeout.) It does run fake timers that are already due,
 * as a real event loop would: the HTTP client waits on a 0ms timer before
 * reusing a kept-alive connection. It relies on `setImmediate` and
 * `performance` not being faked, which holds for our `fakeTimers.toFake`.
 */
export async function eventually(assertion, { timeout = 1000 } = {}) {
  const deadline = performance.now() + timeout;
  for (;;) {
    try {
      return assertion();
    } catch (error) {
      if (performance.now() > deadline) throw error;
    }
    if (vi.isFakeTimers()) vi.advanceTimersByTime(0);
    await flushPromises();
  }
}
