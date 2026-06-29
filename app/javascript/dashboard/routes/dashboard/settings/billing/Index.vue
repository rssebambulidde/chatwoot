<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useAlert } from 'dashboard/composables';
import { format } from 'date-fns';
import sessionStorage from 'shared/helpers/sessionStorage';

import BillingMeter from './components/BillingMeter.vue';
import BillingCard from './components/BillingCard.vue';
import BillingHeader from './components/BillingHeader.vue';
import DetailItem from './components/DetailItem.vue';
import PurchaseCreditsModal from './components/PurchaseCreditsModal.vue';
import ConverraPlanComparison from './components/ConverraPlanComparison.vue';
import ConverraPaymentHistory from './components/ConverraPaymentHistory.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ButtonV4 from 'next/button/Button.vue';
import Banner from 'dashboard/components-next/banner/Banner.vue';

const router = useRouter();
const route = useRoute();
const { t } = useI18n();
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
const isDowngradeLoading = ref(false);
const billingInterval = ref('monthly');

const customAttributes = computed(
  () => currentAccount.value.custom_attributes || {}
);

const converraPlan = computed(() => currentAccount.value.converraPlan || {});
const converraPlans = computed(() => currentAccount.value.converraPlans || []);
const converraPayments = computed(
  () => currentAccount.value.converraPayments || []
);
const converraBillingMeta = computed(
  () => currentAccount.value.converraBillingMeta || {}
);

const currentPlanSlug = computed(
  () => converraPlan.value.slug || customAttributes.value.plan_name || 'starter'
);

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

const isPaidPlan = computed(() => currentPlanSlug.value !== 'starter');

const isSubscriptionExpired = computed(
  () => converraPlan.value.subscription_active === false
);

const showSandboxBanner = computed(
  () => converraBillingMeta.value.pesapal_env === 'sandbox'
);

const showOverLimitBanner = computed(
  () => converraLimits.value.over_limit === true
);

const showCancelNotice = computed(
  () => converraBillingMeta.value.cancel_at_period_end === true
);

const captainResponseLimits = computed(() => {
  const responses = converraLimits.value.captain?.responses;
  if (!responses?.total_count) return null;
  return {
    totalCount: responses.total_count,
    consumed: responses.consumed,
  };
});

const captainDocumentLimits = computed(() => {
  const documents = converraLimits.value.captain?.documents;
  if (!documents?.total_count && documents?.total_count !== 0) return null;
  return {
    totalCount: documents.total_count,
    consumed: documents.consumed,
  };
});

const upgradeOptions = computed(() => {
  const options = [
    { slug: 'growth', labelKey: 'UPGRADE_GROWTH' },
    { slug: 'business', labelKey: 'UPGRADE_BUSINESS' },
  ];
  return options.filter(option => option.slug !== currentPlanSlug.value);
});

const formatPlanPrice = slug => {
  const plan = converraPlans.value.find(item => item.slug === slug);
  if (!plan) return '';
  if (billingInterval.value === 'annual' && plan.annual_price_ugx) {
    return `${Number(plan.annual_price_ugx).toLocaleString()} UGX/yr`;
  }
  if (!plan.price_ugx) return 'Free';
  return `${Number(plan.price_ugx).toLocaleString()} UGX/mo`;
};

const fetchAccountDetails = async () => {
  if (showConverraBilling.value) {
    await store.dispatch('accounts/converraLimits');
    await store.dispatch('accounts/converraPayments');
    fetchLimits();
    return;
  }

  if (!hasABillingPlan.value) {
    await store.dispatch('accounts/subscription');
  }
  fetchLimits();
};

const handlePaymentNotice = () => {
  const payment = route.query.payment;
  if (payment === 'success') {
    useAlert(t('BILLING_SETTINGS.CONVERRA.PAYMENT_SUCCESS'));
  } else if (payment === 'cancelled') {
    useAlert(t('BILLING_SETTINGS.CONVERRA.PAYMENT_CANCELLED'));
  }
  if (payment) {
    router.replace({ query: {} });
  }
};

const handleBillingPageLogic = async () => {
  if (!isOnChatwootCloud.value && !isConverraBillingEnabled.value) {
    router.push({ name: 'home' });
    return;
  }

  if (showConverraBilling.value) {
    await fetchAccountDetails();
    handlePaymentNotice();
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
    await store.dispatch('accounts/converraCheckout', {
      planSlug,
      billingInterval: billingInterval.value,
    });
  } catch (error) {
    isCheckoutLoading.value = false;
  }
};

const onScheduleDowngrade = async () => {
  isDowngradeLoading.value = true;
  try {
    await store.dispatch('accounts/converraScheduleDowngrade');
    useAlert(t('BILLING_SETTINGS.CONVERRA.DOWNGRADE_SCHEDULED'));
    await fetchAccountDetails();
  } finally {
    isDowngradeLoading.value = false;
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
        <Banner v-if="showSandboxBanner" color="amber" class="mx-1">
          {{ $t('BILLING_SETTINGS.CONVERRA.SANDBOX_BANNER') }}
        </Banner>
        <Banner v-if="showOverLimitBanner" color="ruby" class="mx-1">
          {{ $t('BILLING_SETTINGS.CONVERRA.OVER_LIMIT') }}
        </Banner>
        <Banner v-if="showCancelNotice" color="slate" class="mx-1">
          {{ $t('BILLING_SETTINGS.CONVERRA.CANCEL_SCHEDULED') }}
        </Banner>

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
            v-if="isSubscriptionExpired"
            class="px-5 pt-3 text-sm text-n-ruby-11"
          >
            {{ $t('BILLING_SETTINGS.CONVERRA.EXPIRED') }}
          </p>
          <div class="flex flex-wrap items-center gap-2 px-5 pt-4">
            <div
              class="inline-flex rounded-lg border border-n-weak overflow-hidden text-sm"
            >
              <button
                type="button"
                class="px-3 py-1.5"
                :class="
                  billingInterval === 'monthly'
                    ? 'bg-n-brand text-white'
                    : 'text-n-slate-11'
                "
                @click="billingInterval = 'monthly'"
              >
                {{ $t('BILLING_SETTINGS.CONVERRA.INTERVAL_MONTHLY') }}
              </button>
              <button
                type="button"
                class="px-3 py-1.5"
                :class="
                  billingInterval === 'annual'
                    ? 'bg-n-brand text-white'
                    : 'text-n-slate-11'
                "
                @click="billingInterval = 'annual'"
              >
                {{ $t('BILLING_SETTINGS.CONVERRA.INTERVAL_ANNUAL') }}
              </button>
            </div>
            <ButtonV4
              v-for="option in upgradeOptions"
              :key="option.slug"
              sm
              solid
              :blue="option.slug === 'growth'"
              :slate="option.slug !== 'growth'"
              :is-loading="isCheckoutLoading"
              @click="onConverraCheckout(option.slug)"
            >
              {{ $t(`BILLING_SETTINGS.CONVERRA.${option.labelKey}`) }}
              — {{ formatPlanPrice(option.slug) }}
            </ButtonV4>
            <ButtonV4
              v-if="
                isPaidPlan && (isSubscriptionExpired || subscriptionRenewsOn)
              "
              sm
              solid
              blue
              :is-loading="isCheckoutLoading"
              @click="onConverraCheckout(currentPlanSlug)"
            >
              {{ $t('BILLING_SETTINGS.CONVERRA.RENEW_PLAN') }}
              — {{ formatPlanPrice(currentPlanSlug) }}
            </ButtonV4>
            <ButtonV4
              v-if="isPaidPlan && !showCancelNotice"
              sm
              flushed
              slate
              :is-loading="isDowngradeLoading"
              @click="onScheduleDowngrade"
            >
              {{ $t('BILLING_SETTINGS.CONVERRA.SCHEDULE_DOWNGRADE') }}
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
          :title="$t('BILLING_SETTINGS.CONVERRA.COMPARE.TITLE')"
          :description="$t('BILLING_SETTINGS.CONVERRA.COMPARE.DESCRIPTION')"
        >
          <ConverraPlanComparison
            :plans="converraPlans"
            :current-plan-slug="currentPlanSlug"
          />
        </BillingCard>

        <BillingCard
          :title="$t('BILLING_SETTINGS.CONVERRA.USAGE')"
          :description="$t('BILLING_SETTINGS.CONVERRA.USAGE_DESCRIPTION')"
        >
          <div v-if="converraLimits.conversation" class="px-5 pb-4">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CONVERRA.CONVERSATIONS')"
              :total-count="converraLimits.conversation.allowed"
              :consumed="converraLimits.conversation.consumed"
            />
          </div>
          <div v-if="converraLimits.agents" class="px-5 pb-4">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CONVERRA.AGENTS')"
              :total-count="converraLimits.agents.allowed"
              :consumed="converraLimits.agents.consumed"
            />
          </div>
          <div v-if="converraLimits.non_web_inboxes" class="px-5 pb-4">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CONVERRA.CHANNELS')"
              :total-count="converraLimits.non_web_inboxes.allowed"
              :consumed="converraLimits.non_web_inboxes.consumed"
            />
          </div>
          <div v-if="captainResponseLimits" class="px-5 pb-4">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CAPTAIN.RESPONSES')"
              v-bind="captainResponseLimits"
            />
          </div>
          <div v-if="captainDocumentLimits" class="px-5 pb-4">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CAPTAIN.DOCUMENTS')"
              v-bind="captainDocumentLimits"
            />
          </div>
        </BillingCard>

        <BillingCard
          :title="$t('BILLING_SETTINGS.CONVERRA.PAYMENTS.TITLE')"
          :description="$t('BILLING_SETTINGS.CONVERRA.PAYMENTS.DESCRIPTION')"
        >
          <ConverraPaymentHistory :payments="converraPayments" />
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
