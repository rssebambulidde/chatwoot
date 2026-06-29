<script setup>
import { computed } from 'vue';
import { format } from 'date-fns';

const props = defineProps({
  payments: {
    type: Array,
    default: () => [],
  },
});

const rows = computed(() => props.payments || []);

const formatDate = value => {
  if (!value) return '—';
  return format(new Date(value), 'dd MMM yyyy');
};

const formatAmount = payment =>
  `${Number(payment.amount).toLocaleString()} ${payment.currency}`;
</script>

<template>
  <div class="px-5 pb-5">
    <p v-if="!rows.length" class="text-sm text-n-slate-11">
      {{ $t('BILLING_SETTINGS.CONVERRA.PAYMENTS.EMPTY') }}
    </p>
    <div v-else class="overflow-x-auto">
      <table class="w-full min-w-[32rem] text-sm text-left">
        <thead>
          <tr
            class="text-xs uppercase tracking-wider text-n-slate-10 border-b border-n-weak"
          >
            <th class="py-2 pr-4 font-medium">
              {{ $t('BILLING_SETTINGS.CONVERRA.PAYMENTS.DATE') }}
            </th>
            <th class="py-2 px-3 font-medium">
              {{ $t('BILLING_SETTINGS.CONVERRA.PAYMENTS.PLAN') }}
            </th>
            <th class="py-2 px-3 font-medium">
              {{ $t('BILLING_SETTINGS.CONVERRA.PAYMENTS.AMOUNT') }}
            </th>
            <th class="py-2 px-3 font-medium">
              {{ $t('BILLING_SETTINGS.CONVERRA.PAYMENTS.STATUS') }}
            </th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="payment in rows"
            :key="payment.id"
            class="border-b border-n-weak text-n-slate-12"
          >
            <td class="py-3 pr-4">
              {{ formatDate(payment.completed_at || payment.created_at) }}
            </td>
            <td class="py-3 px-3">
              {{ payment.plan_name }}
              <span class="text-n-slate-10 text-xs">
                ({{ payment.billing_interval }})
              </span>
            </td>
            <td class="py-3 px-3 tabular-nums">{{ formatAmount(payment) }}</td>
            <td class="py-3 px-3 capitalize">{{ payment.status }}</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>
