const DEFAULT_INSTALLATION_NAME = 'Chatwoot';

const readInstallationName = () => {
  const { INSTALLATION_NAME: installationName, BRAND_NAME: brandName } =
    window.globalConfig || {};

  return installationName || brandName || DEFAULT_INSTALLATION_NAME;
};

export const applyInstallationBranding = (
  text,
  installationName = readInstallationName()
) => {
  if (!text || !installationName || installationName === DEFAULT_INSTALLATION_NAME) {
    return text;
  }

  return text
    .replace(/Chatwoot AI/g, `${installationName} AI`)
    .replace(/CHATWOOT/g, installationName.toUpperCase())
    .replace(/Chatwoot/g, installationName)
    .replace(/chatwoot/g, installationName.toLowerCase());
};

export const isCustomBrandedInstance = () =>
  readInstallationName() !== DEFAULT_INSTALLATION_NAME;
