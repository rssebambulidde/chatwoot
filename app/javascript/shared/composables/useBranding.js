/**
 * Composable for branding-related utilities
 * Provides methods to customize text with installation-specific branding
 */
import { useMapGetter } from 'dashboard/composables/store.js';
import { applyInstallationBranding } from 'shared/helpers/brandingText';

export function useBranding() {
  const globalConfig = useMapGetter('globalConfig/get');

  const replaceInstallationName = text => {
    const installationName =
      globalConfig.value?.installationName || globalConfig.value?.brandName;

    return applyInstallationBranding(text, installationName);
  };

  return {
    replaceInstallationName,
  };
}
