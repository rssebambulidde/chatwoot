export const FACEBOOK_PAGE_SCOPES = [
  'pages_manage_metadata',
  'business_management',
  'pages_messaging',
  'pages_show_list',
  'pages_read_engagement',
];

// Instagram DMs via a linked Facebook Page only (optional).
export const INSTAGRAM_SCOPES = [
  'instagram_business_basic',
  'instagram_business_manage_messages',
];

export const buildFacebookLoginScopes = ({
  includeInstagramScopes = false,
} = {}) => {
  const scopes = [...FACEBOOK_PAGE_SCOPES];
  if (includeInstagramScopes) {
    scopes.push(...INSTAGRAM_SCOPES);
  }
  return scopes.join(',');
};
