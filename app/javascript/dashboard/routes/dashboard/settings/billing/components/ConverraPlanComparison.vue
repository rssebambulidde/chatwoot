<script setup>
import { computed } from 'vue';

const props = defineProps({
  plans: {
    type: Array,
    default: () => [],
  },
  currentPlanSlug: {
    type: String,
    default: 'starter',
  },
});

const orderedPlans = computed(() => {
  const order = ['starter', 'growth', 'business'];
  return [...props.plans].sort(
    (a, b) => order.indexOf(a.slug) - order.indexOf(b.slug)
  );
});

const formatPrice = (amount, suffix = '/mo') => {
  if (!amount) return 'Free';
  return `${Number(amount).toLocaleString()} UGX${suffix}`;
};
</script>

<template>
  <div class="px-5 pb-5 overflow-x-auto">
    <table class="w-full min-w-[36rem] text-sm text-left border-collapse">
      <thead>
        <tr class="text-xs uppercase tracking-wider text-n-slate-10">
          <th class="py-2 pr-4 font-medium" />
          <th
            v-for="plan in orderedPlans"
            :key="plan.slug"
            class="py-2 px-3 font-medium"
          >
            <div class="flex items-center gap-2">
              <span>{{ plan.name }}</span>
              <span
                v-if="plan.slug === currentPlanSlug"
                class="px-2 py-0.5 text-[10px] rounded-full bg-n-brand/10 text-n-brand normal-case"
              >
                {{ $t('BILLING_SETTINGS.CONVERRA.CURRENT_BADGE') }}
              </span>
            </div>
          </th>
        </tr>
      </thead>
      <tbody class="text-n-slate-12">
        <tr class="border-t border-n-weak">
          <td class="py-3 pr-4 text-n-slate-11">
            {{ $t('BILLING_SETTINGS.CONVERRA.COMPARE.PRICE') }}
          </td>
          <td
            v-for="plan in orderedPlans"
            :key="`${plan.slug}-price`"
            class="py-3 px-3"
          >
            {{ formatPrice(plan.price_ugx) }}
          </td>
        </tr>
        <tr class="border-t border-n-weak">
          <td class="py-3 pr-4 text-n-slate-11">
            {{ $t('BILLING_SETTINGS.CONVERRA.COMPARE.ANNUAL') }}
          </td>
          <td
            v-for="plan in orderedPlans"
            :key="`${plan.slug}-annual`"
            class="py-3 px-3"
          >
            <span v-if="plan.annual_price_ugx">
              {{ formatPrice(plan.annual_price_ugx, '/yr') }}
            </span>
            <span v-else class="text-n-slate-10">—</span>
          </td>
        </tr>
        <tr class="border-t border-n-weak">
          <td class="py-3 pr-4 text-n-slate-11">
            {{ $t('BILLING_SETTINGS.CONVERRA.AGENTS') }}
          </td>
          <td
            v-for="plan in orderedPlans"
            :key="`${plan.slug}-agents`"
            class="py-3 px-3"
          >
            {{ plan.limits?.agents }}
          </td>
        </tr>
        <tr class="border-t border-n-weak">
          <td class="py-3 pr-4 text-n-slate-11">
            {{ $t('BILLING_SETTINGS.CONVERRA.CHANNELS') }}
          </td>
          <td
            v-for="plan in orderedPlans"
            :key="`${plan.slug}-channels`"
            class="py-3 px-3"
          >
            {{ plan.non_web_inboxes }}
          </td>
        </tr>
        <tr class="border-t border-n-weak">
          <td class="py-3 pr-4 text-n-slate-11">
            {{ $t('BILLING_SETTINGS.CONVERRA.CONVERSATIONS') }}
          </td>
          <td
            v-for="plan in orderedPlans"
            :key="`${plan.slug}-conv`"
            class="py-3 px-3"
          >
            {{ Number(plan.conversations_monthly).toLocaleString() }}
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
