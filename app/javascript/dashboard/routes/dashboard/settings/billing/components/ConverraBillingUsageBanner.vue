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
  const warnings = accountLimits.value.usage_warnings || [];
  const { agents, captain } = accountLimits.value;
  const responses = captain?.responses;

  if (warnings.includes('subscription_lapsed_agents')) {
    return t('BILLING_SETTINGS.CONVERRA.BANNER.SUBSCRIPTION_LAPSED');
  }

  if (accountLimits.value.over_limit) {
    if (warnings.includes('agents') || agents?.consumed > agents?.allowed) {
      return t('BILLING_SETTINGS.CONVERRA.BANNER.AGENTS', {
        consumed: agents?.consumed,
        allowed: agents?.allowed,
      });
    }
    if (
      warnings.includes('captain_responses') ||
      responses?.consumed > responses?.total_count
    ) {
      return t('BILLING_SETTINGS.CONVERRA.BANNER.COPILOT', {
        consumed: responses?.consumed,
        allowed: responses?.total_count,
      });
    }
  }

  if (warnings.includes('agents')) {
    return t('BILLING_SETTINGS.CONVERRA.BANNER.AGENTS', {
      consumed: agents?.consumed,
      allowed: agents?.allowed,
    });
  }
  if (warnings.includes('captain_responses')) {
    return t('BILLING_SETTINGS.CONVERRA.BANNER.COPILOT', {
      consumed: responses?.consumed,
      allowed: responses?.total_count,
    });
  }
  return '';
});

const showBanner = computed(() => {
  if (!isConverraBillingEnabled.value || isOnChatwootCloud.value) return false;
  if (
    accountLimits.value.subscription_lapsed &&
    accountLimits.value.over_limit
  ) {
    return true;
  }
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
