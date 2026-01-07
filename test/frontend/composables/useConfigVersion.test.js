import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { useConfigVersion } from '../../../app/frontend/composables/useConfigVersion.js';

describe('useConfigVersion', () => {
  let reloadMock;
  let originalLocation;

  beforeEach(() => {
    // Save the original location
    originalLocation = window.location;
    // Create a mock reload function
    reloadMock = vi.fn();
    // Replace window.location with a mock that has our reload function
    delete window.location;
    window.location = { reload: reloadMock };
  });

  afterEach(() => {
    // Restore the original location
    window.location = originalLocation;
  });

  it('stores the version on first check', () => {
    const { check } = useConfigVersion('Test');
    const response = createMockResponse('version1');

    const result = check(response);

    expect(result).toBe(false);
    expect(reloadMock).not.toHaveBeenCalled();
  });

  it('does not reload when version is unchanged', () => {
    const { check } = useConfigVersion('Test');
    const response1 = createMockResponse('version1');
    const response2 = createMockResponse('version1');

    check(response1); // Store initial version
    const result = check(response2); // Check with same version

    expect(result).toBe(false);
    expect(reloadMock).not.toHaveBeenCalled();
  });

  it('reloads when version changes', () => {
    const { check } = useConfigVersion('Test');
    const response1 = createMockResponse('version1');
    const response2 = createMockResponse('version2');

    check(response1); // Store initial version
    const result = check(response2); // Check with different version

    expect(result).toBe(true);
    expect(reloadMock).toHaveBeenCalledOnce();
  });

  it('logs the component name when reloading', () => {
    const consoleSpy = vi.spyOn(console, 'log').mockImplementation(() => {});
    const { check } = useConfigVersion('TestComponent');
    const response1 = createMockResponse('version1');
    const response2 = createMockResponse('version2');

    check(response1);
    check(response2);

    expect(consoleSpy).toHaveBeenCalledWith(
      '[TestComponent] Config version changed, reloading page...',
      { old: 'version1', new: 'version2' }
    );

    consoleSpy.mockRestore();
  });

  it('handles null config version header', () => {
    const { check } = useConfigVersion('Test');
    const response = createMockResponse(null);

    const result = check(response);

    expect(result).toBe(false);
    expect(reloadMock).not.toHaveBeenCalled();
  });

  it('detects change from null to actual version', () => {
    const { check } = useConfigVersion('Test');
    const response1 = createMockResponse(null);
    const response2 = createMockResponse('version1');

    check(response1); // Store null as initial version
    const result = check(response2); // Check with actual version

    expect(result).toBe(true);
    expect(reloadMock).toHaveBeenCalledOnce();
  });
});

/**
 * Creates a mock fetch Response object with X-Config-Version header
 */
function createMockResponse(configVersion) {
  const headers = new Map();
  if (configVersion !== null) {
    headers.set('x-config-version', configVersion);
  }

  return {
    headers: {
      get: (name) => {
        if (name.toLowerCase() === 'x-config-version') {
          return headers.get('x-config-version') || null;
        }
        return null;
      }
    }
  };
}
