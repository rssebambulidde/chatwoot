<script setup>
import { onMounted, computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';

import Banner from 'dashboard/components-next/banner/Banner.vue';

const router = useRouter();
const { t } = useI18n();
const store = useStore();
const { accountId, currentAccount } = useAccount();
const isConverraBillingEnabled = useMapGetter(
  'globalConfig/isConverraBillingEnabled'
);
const isOnChatwootCloud = useMapGetter('globalConfig/isOnChatwootCloud');

const accountLimits = computed(() => currentAccount.value?.limits || {});

const warningMessage = computed(() => {
  if (accountLimits.value.over_limit) {
    const warnings = accountLimits.value.usage_warnings || [];
    if (
      warnings.includes('agents') ||
      accountLimits.value.agents?.consumed > accountLimits.value.agents?.allowed
    ) {
      return t('BILLING_SETTINGS.CONVERRA.BANNER.AGENTS', {
        consumed: accountLimits.value.agents?.consumed,
        allowed: accountLimits.value.agents?.allowed,
      });
    }
    if (warnings.includes('conversation')) {
      return t('BILLING_SETTINGS.CONVERRA.BANNER.CONVERSATIONS', {
        consumed: accountLimits.value.conversation?.consumed,
        allowed: accountLimits.value.conversation?.allowed,
      });
    }
    if (warnings.includes('non_web_inboxes')) {
      return t('BILLING_SETTINGS.CONVERRA.BANNER.CHANNELS', {
        consumed: accountLimits.value.non_web_inboxes?.consumed,
        allowed: accountLimits.value.non_web_inboxes?.allowed,
      });
    }
  }

  const warnings = accountLimits.value.usage_warnings || [];
  if (warnings.includes('conversation')) {
    return t('BILLING_SETTINGS.CONVERRA.BANNER.CONVERSATIONS', {
      consumed: accountLimits.value.conversation?.consumed,
      allowed: accountLimits.value.conversation?.allowed,
    });
  }
  if (warnings.includes('agents')) {
    return t('BILLING_SETTINGS.CONVERRA.BANNER.AGENTS', {
      consumed: accountLimits.value.agents?.consumed,
      allowed: accountLimits.value.agents?.allowed,
    });
  }
  if (warnings.includes('non_web_inboxes')) {
    return t('BILLING_SETTINGS.CONVERRA.BANNER.CHANNELS', {
      consumed: accountLimits.value.non_web_inboxes?.consumed,
      allowed: accountLimits.value.non_web_inboxes?.allowed,
    });
  }
  return '';
});

const showBanner = computed(() => {
  if (!isConverraBillingEnabled.value || isOnChatwootCloud.value) return false;
  if (accountLimits.value.over_limit) return true;
  return (accountLimits.value.usage_warnings || []).length > 0;
});

const openBilling = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
};

onMounted(() => {
  if (isConverraBillingEnabled.value && !isOnChatwootCloud.value) {
    store.dispatch('accounts/converraLimits');
  }
});
</script>

<template>
  <Banner
    v-if="showBanner"
    color="amber"
    :action-label="$t('BILLING_SETTINGS.CONVERRA.BANNER.ACTION')"
    class="mx-4 mt-4 shrink-0"
    @action="openBilling"
  >
    {{ warningMessage }}
  </Banner>
</template>
