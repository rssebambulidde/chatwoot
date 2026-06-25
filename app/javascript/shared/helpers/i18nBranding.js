import { applyInstallationBranding } from './brandingText';

const brandTranslatedValue = value => {
  if (typeof value === 'string') {
    return applyInstallationBranding(value);
  }

  if (Array.isArray(value)) {
    return value.map(item => brandTranslatedValue(item));
  }

  return value;
};

export const applyBrandingToI18n = i18n => {
  const originalT = i18n.global.t.bind(i18n.global);

  i18n.global.t = (key, ...args) => brandTranslatedValue(originalT(key, ...args));

  return i18n;
};
