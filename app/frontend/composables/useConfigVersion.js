import { ref } from 'vue';

/**
 * Composable for tracking and detecting screen configuration version changes.
 * Monitors the X-Config-Version header from API responses and triggers a page
 * reload when a change is detected.
 *
 * @param {string} componentName - Name of the component using this composable (for logging)
 * @returns {Object} Object with check function
 */
export function useConfigVersion(componentName) {
  const configVersion = ref(null);
  const initialized = ref(false);

  /**
   * Checks the config version from the response header.
   * Reloads the page if a change is detected.
   *
   * @param {Response} response - The fetch response object
   * @returns {boolean} True if a page reload was triggered, otherwise false
   */
  const check = (response) => {
    const newConfigVersion = response.headers.get('X-Config-Version');

    // On first successful load, just store the version
    if (!initialized.value) {
      configVersion.value = newConfigVersion;
      initialized.value = true;
      return false;
    }

    // If version has changed, log and reload
    if (newConfigVersion !== configVersion.value) {
      console.log(`[${componentName}] Config version changed, reloading page...`, {
        old: configVersion.value,
        new: newConfigVersion,
      });
      window.location.reload();
      return true;
    }

    return false;
  };

  return { check };
}
