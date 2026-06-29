<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { format } from 'date-fns';
import sessionStorage from 'shared/helpers/sessionStorage';

import BillingMeter from './components/BillingMeter.vue';
import BillingCard from './components/BillingCard.vue';
import BillingHeader from './components/BillingHeader.vue';
import DetailItem from './components/DetailItem.vue';
import PurchaseCreditsModal from './components/PurchaseCreditsModal.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ButtonV4 from 'next/button/Button.vue';

const router = useRouter();
const { currentAccount, isOnChatwootCloud } = useAccount();
const isConverraBillingEnabled = useMapGetter(
  'globalConfig/isConverraBillingEnabled'
);
const {
  captainEnabled,
  captainLimits,
  documentLimits,
  responseLimits,
  fetchLimits,
  isFetchingLimits,
} = useCaptain();

const uiFlags = useMapGetter('accounts/getUIFlags');
const store = useStore();

const BILLING_REFRESH_ATTEMPTED = 'billing_refresh_attempted';
const isWaitingForBilling = ref(false);
const purchaseCreditsModalRef = ref(null);
const isCheckoutLoading = ref(false);

const customAttributes = computed(
  () => currentAccount.value.custom_attributes || {}
);

const converraPlan = computed(() => currentAccount.value.converraPlan || {});

const planName = computed(() => {
  if (isConverraBillingEnabled.value) {
    return converraPlan.value.name || customAttributes.value.converra_plan_name;
  }
  return customAttributes.value.plan_name;
});

const canPurchaseCredits = computed(() => {
  const plan = planName.value?.toLowerCase();
  return plan && plan !== 'hacker';
});

const subscribedQuantity = computed(
  () => customAttributes.value.subscribed_quantity
);

const subscriptionRenewsOn = computed(() => {
  const endsOn =
    converraPlan.value.subscription_ends_on ||
    customAttributes.value.subscription_ends_on;
  if (!endsOn) return '';
  return format(new Date(endsOn), 'dd MMM, yyyy');
});

const hasABillingPlan = computed(() => {
  if (isConverraBillingEnabled.value) return true;
  return !!planName.value;
});

const converraLimits = computed(() => currentAccount.value.limits || {});

const showConverraBilling = computed(
  () => isConverraBillingEnabled.value && !isOnChatwootCloud.value
);

const fetchAccountDetails = async () => {
  if (showConverraBilling.value) {
    await store.dispatch('accounts/converraLimits');
    fetchLimits();
    return;
  }

  if (!hasABillingPlan.value) {
    await store.dispatch('accounts/subscription');
  }
  fetchLimits();
};

const handleBillingPageLogic = async () => {
  if (!isOnChatwootCloud.value && !isConverraBillingEnabled.value) {
    router.push({ name: 'home' });
    return;
  }

  if (showConverraBilling.value) {
    await fetchAccountDetails();
    return;
  }

  const billingRefreshAttempted = sessionStorage.get(BILLING_REFRESH_ATTEMPTED);
  await fetchAccountDetails();

  if (!hasABillingPlan.value) {
    if (!billingRefreshAttempted) {
      isWaitingForBilling.value = true;
      sessionStorage.set(BILLING_REFRESH_ATTEMPTED, true);
      setTimeout(() => {
        window.location.reload();
      }, 5000);
    } else {
      sessionStorage.remove(BILLING_REFRESH_ATTEMPTED);
    }
  } else {
    sessionStorage.remove(BILLING_REFRESH_ATTEMPTED);
  }
};

const onClickBillingPortal = () => {
  store.dispatch('accounts/checkout');
};

const onConverraCheckout = async planSlug => {
  isCheckoutLoading.value = true;
  try {
    await store.dispatch('accounts/converraCheckout', planSlug);
  } catch (error) {
    isCheckoutLoading.value = false;
  }
};

const onToggleChatWindow = () => {
  if (window.$chatwoot) {
    window.$chatwoot.toggle();
  }
};

const openPurchaseCreditsModal = () => {
  purchaseCreditsModalRef.value?.open();
};

const handleTopupSuccess = () => {
  fetchLimits();
};

onMounted(handleBillingPageLogic);
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetchingItem || isWaitingForBilling"
    :loading-message="
      isWaitingForBilling
        ? $t('BILLING_SETTINGS.NO_BILLING_USER')
        : $t('ATTRIBUTES_MGMT.LOADING')
    "
    :no-records-found="!hasABillingPlan && !isWaitingForBilling"
    :no-records-message="$t('BILLING_SETTINGS.NO_BILLING_USER')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('BILLING_SETTINGS.TITLE')"
        :description="
          showConverraBilling
            ? $t('BILLING_SETTINGS.CONVERRA.DESCRIPTION')
            : $t('BILLING_SETTINGS.DESCRIPTION')
        "
        :link-text="$t('BILLING_SETTINGS.VIEW_PRICING')"
        feature-name="billing"
      />
    </template>
    <template #body>
      <section v-if="showConverraBilling" class="grid gap-4">
        <BillingCard
          :title="$t('BILLING_SETTINGS.CONVERRA.TITLE')"
          :description="$t('BILLING_SETTINGS.CONVERRA.DESCRIPTION')"
        >
          <div
            class="grid lg:grid-cols-3 sm:grid-cols-2 grid-cols-1 gap-2 divide-x divide-n-weak"
          >
            <DetailItem
              :label="$t('BILLING_SETTINGS.CONVERRA.CURRENT_PLAN')"
              :value="planName"
            />
            <DetailItem
              v-if="subscriptionRenewsOn"
              :label="$t('BILLING_SETTINGS.CONVERRA.RENEWS_ON')"
              :value="subscriptionRenewsOn"
            />
          </div>
          <p
            v-if="converraPlan.subscription_active === false"
            class="px-5 pt-3 text-sm text-n-ruby-11"
          >
            {{ $t('BILLING_SETTINGS.CONVERRA.EXPIRED') }}
          </p>
          <div class="flex flex-wrap gap-2 px-5 pt-4">
            <ButtonV4
              sm
              solid
              blue
              :is-loading="isCheckoutLoading"
              @click="onConverraCheckout('growth')"
            >
              {{ $t('BILLING_SETTINGS.CONVERRA.UPGRADE_GROWTH') }}
            </ButtonV4>
            <ButtonV4
              sm
              solid
              slate
              :is-loading="isCheckoutLoading"
              @click="onConverraCheckout('business')"
            >
              {{ $t('BILLING_SETTINGS.CONVERRA.UPGRADE_BUSINESS') }}
            </ButtonV4>
            <a
              href="/pricing"
              class="inline-flex items-center px-3 text-sm font-medium text-n-brand"
              target="_blank"
              rel="noopener noreferrer"
            >
              {{ $t('BILLING_SETTINGS.CONVERRA.VIEW_PUBLIC_PRICING') }}
            </a>
          </div>
        </BillingCard>

        <BillingCard
          :title="$t('BILLING_SETTINGS.CONVERRA.USAGE')"
          :description="$t('BILLING_SETTINGS.CONVERRA.USAGE_DESCRIPTION')"
        >
          <div v-if="converraLimits.conversation" class="px-5">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CONVERRA.CONVERSATIONS')"
              :total-count="converraLimits.conversation.allowed"
              :consumed="converraLimits.conversation.consumed"
            />
          </div>
          <div v-if="converraLimits.agents" class="px-5">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CONVERRA.AGENTS')"
              :total-count="converraLimits.agents.allowed"
              :consumed="converraLimits.agents.consumed"
            />
          </div>
          <div v-if="converraLimits.non_web_inboxes" class="px-5">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CONVERRA.CHANNELS')"
              :total-count="converraLimits.non_web_inboxes.allowed"
              :consumed="converraLimits.non_web_inboxes.consumed"
            />
          </div>
        </BillingCard>
      </section>

      <section v-else class="grid gap-4">
        <BillingCard
          :title="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.TITLE')"
          :description="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.DESCRIPTION')"
        >
          <template #action>
            <ButtonV4 sm solid blue @click="onClickBillingPortal">
              {{ $t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.BUTTON_TXT') }}
            </ButtonV4>
          </template>
          <div
            v-if="planName || subscribedQuantity || subscriptionRenewsOn"
            class="grid lg:grid-cols-4 sm:grid-cols-3 grid-cols-1 gap-2 divide-x divide-n-weak"
          >
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.TITLE')"
              :value="planName"
            />
            <DetailItem
              v-if="subscribedQuantity"
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.SEAT_COUNT')"
              :value="subscribedQuantity"
            />
            <DetailItem
              v-if="subscriptionRenewsOn"
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.RENEWS_ON')"
              :value="subscriptionRenewsOn"
            />
          </div>
        </BillingCard>
        <BillingCard
          v-if="captainEnabled"
          :title="$t('BILLING_SETTINGS.CAPTAIN.TITLE')"
          :description="$t('BILLING_SETTINGS.CAPTAIN.DESCRIPTION')"
        >
          <template #action>
            <div class="flex gap-2">
              <ButtonV4
                sm
                flushed
                slate
                icon="i-lucide-refresh-cw"
                :is-loading="isFetchingLimits"
                @click="fetchLimits"
              >
                {{ $t('BILLING_SETTINGS.CAPTAIN.REFRESH_CREDITS') }}
              </ButtonV4>
              <ButtonV4
                v-if="canPurchaseCredits"
                sm
                solid
                blue
                @click="openPurchaseCreditsModal"
              >
                {{ $t('BILLING_SETTINGS.TOPUP.BUY_CREDITS') }}
              </ButtonV4>
            </div>
          </template>
          <div v-if="captainLimits && responseLimits" class="px-5">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CAPTAIN.RESPONSES')"
              v-bind="responseLimits"
            />
          </div>
          <div v-if="captainLimits && documentLimits" class="px-5">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CAPTAIN.DOCUMENTS')"
              v-bind="documentLimits"
            />
          </div>
        </BillingCard>
        <BillingCard
          v-else
          :title="$t('BILLING_SETTINGS.CAPTAIN.TITLE')"
          :description="$t('BILLING_SETTINGS.CAPTAIN.UPGRADE')"
        >
          <template #action>
            <ButtonV4 sm solid slate @click="onClickBillingPortal">
              {{ $t('CAPTAIN.PAYWALL.UPGRADE_NOW') }}
            </ButtonV4>
          </template>
        </BillingCard>

        <BillingHeader
          class="px-1 mt-5"
          :title="$t('BILLING_SETTINGS.CHAT_WITH_US.TITLE')"
          :description="$t('BILLING_SETTINGS.CHAT_WITH_US.DESCRIPTION')"
        >
          <ButtonV4
            sm
            solid
            slate
            icon="i-lucide-life-buoy"
            @click="onToggleChatWindow"
          >
            {{ $t('BILLING_SETTINGS.CHAT_WITH_US.BUTTON_TXT') }}
          </ButtonV4>
        </BillingHeader>
      </section>
      <PurchaseCreditsModal
        v-if="!showConverraBilling"
        ref="purchaseCreditsModalRef"
        @success="handleTopupSuccess"
      />
    </template>
  </SettingsLayout>
</template>
