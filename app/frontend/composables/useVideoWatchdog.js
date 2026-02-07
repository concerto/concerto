import { onBeforeUnmount } from 'vue';

// If no ping is received within this time, assume the player has crashed.
const STALL_TIMEOUT_MS = 15000;

/**
 * Monitors video player health by expecting periodic pings.
 * If no ping is received within the stall timeout, assumes the player
 * has crashed and emits 'next' to advance to the next content.
 *
 * Usage: Call ping() on every player event (play, timeupdate, stateChange, etc.).
 * Call stop() when the video ends normally to prevent a false trigger.
 *
 * @param {Function} emit - Vue emit function
 * @param {Object} options - Configuration options
 * @param {number} options.stallTimeout - Timeout in ms before assuming crash (default: 15000)
 * @returns {{ ping: Function, stop: Function }}
 */
export function useVideoWatchdog(emit, options = {}) {
  const stallTimeout = options.stallTimeout || STALL_TIMEOUT_MS;
  let stallTimer = null;
  let active = false;

  function ping() {
    if (!active) {
      active = true;
      console.debug('Video watchdog: monitoring started');
    }

    clearTimeout(stallTimer);
    stallTimer = setTimeout(() => {
      console.warn('Video watchdog: player appears stalled, advancing to next content');
      active = false;
      stallTimer = null;
      emit('next', {});
    }, stallTimeout);
  }

  function stop() {
    clearTimeout(stallTimer);
    stallTimer = null;
    active = false;
  }

  onBeforeUnmount(() => {
    stop();
  });

  return { ping, stop };
}
