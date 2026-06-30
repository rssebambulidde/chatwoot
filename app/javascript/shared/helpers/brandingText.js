const DEFAULT_INSTALLATION_NAME = 'Chatwoot';
const DEFAULT_CAPTAIN_NAME = 'Captain';

const readInstallationName = () => {
  const { INSTALLATION_NAME: installationName, BRAND_NAME: brandName } =
    window.globalConfig || {};

  return installationName || brandName || DEFAULT_INSTALLATION_NAME;
};

const readCaptainName = () => {
  const { CAPTAIN_NAME: captainName } = window.globalConfig || {};

  return captainName || DEFAULT_CAPTAIN_NAME;
};

export const applyCaptainBranding = (text, captainName = readCaptainName()) => {
  if (!text || !captainName || captainName === DEFAULT_CAPTAIN_NAME) {
    return text;
  }

  return text
    .replace(/Captain AI/g, captainName)
    .replace(/CAPTAIN/g, captainName.toUpperCase())
    .replace(/Captain/g, captainName);
};

export const applyInstallationBranding = (
  text,
  installationName = readInstallationName()
) => {
  if (!text) {
    return text;
  }

  let result = text;

  if (installationName && installationName !== DEFAULT_INSTALLATION_NAME) {
    result = result
      .replace(/Chatwoot AI/g, `${installationName} AI`)
      .replace(/CHATWOOT/g, installationName.toUpperCase())
      .replace(/Chatwoot/g, installationName)
      .replace(/chatwoot/g, installationName.toLowerCase());
  }

  return applyCaptainBranding(result);
};

export const isCustomBrandedInstance = () =>
  readInstallationName() !== DEFAULT_INSTALLATION_NAME;
