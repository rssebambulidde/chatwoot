<script setup>
import { ref, computed, onBeforeMount } from 'vue';
import { useStore } from 'vuex';
import SignupForm from './components/Signup/Form.vue';
import Testimonials from './components/Testimonials/Index.vue';
import Spinner from 'shared/components/Spinner.vue';
import signupBg from 'assets/images/auth/signup-bg.jpg';
import converraSignupBg from 'assets/images/auth/converra-signup-bg.png';

const store = useStore();

const isLoading = ref(false);
const globalConfig = computed(() => store.getters['globalConfig/get']);
const isAChatwootInstance = computed(
  () => globalConfig.value.installationName === 'Chatwoot'
);
const signupBackground = computed(() =>
  isAChatwootInstance.value ? signupBg : converraSignupBg
);

onBeforeMount(() => {
  isLoading.value = isAChatwootInstance.value;
});

const resizeContainers = () => {
  isLoading.value = false;
};
</script>

<template>
  <div
    class="relative w-full h-full min-h-screen flex flex-col items-center justify-center bg-cover bg-center bg-no-repeat p-4 sm:px-6 lg:px-8"
    :style="{ backgroundImage: `url(${signupBackground})` }"
  >
    <div
      class="absolute inset-0 backdrop-blur-sm"
      :class="
        isAChatwootInstance
          ? 'bg-n-gray-12/60 dark:bg-n-gray-1/80'
          : 'bg-n-brand/70 dark:bg-n-gray-12/75'
      "
    />
    <div
      v-show="!isLoading"
      class="relative bg-white dark:bg-n-solid-2 outline outline-1 outline-n-container"
      :class="
        isAChatwootInstance
          ? 'flex max-w-[960px] rounded-lg shadow-sm'
          : 'w-full max-w-lg p-11 shadow sm:shadow-lg sm:rounded-lg'
      "
    >
      <div
        class="flex-1 flex items-center justify-center"
        :class="isAChatwootInstance ? 'py-10 px-10' : ''"
      >
        <div class="max-w-[420px] w-full">
          <div class="mb-6">
            <img
              :src="globalConfig.logo"
              :alt="globalConfig.installationName"
              class="block w-auto h-7 dark:hidden"
            />
            <img
              v-if="globalConfig.logoDark"
              :src="globalConfig.logoDark"
              :alt="globalConfig.installationName"
              class="hidden w-auto h-7 dark:block"
            />
            <h2 class="mt-6 text-2xl font-semibold text-n-slate-12">
              {{
                isAChatwootInstance
                  ? $t('REGISTER.GET_STARTED')
                  : $t('REGISTER.TRY_WOOT')
              }}
            </h2>
            <p class="mt-2 text-sm text-n-slate-11">
              {{ $t('REGISTER.HAVE_AN_ACCOUNT') }}{{ ' '
              }}<router-link
                class="text-n-blue-10 font-medium hover:text-n-blue-11"
                to="/app/login"
              >
                {{ $t('LOGIN.SUBMIT') }}
              </router-link>
            </p>
          </div>
          <SignupForm />
        </div>
      </div>
      <Testimonials
        v-if="isAChatwootInstance"
        class="flex-1 hidden xl:flex"
        @resize-containers="resizeContainers"
      />
    </div>
    <div
      v-show="isLoading"
      class="relative flex items-center justify-center w-full h-full"
    >
      <Spinner color-scheme="primary" size="" />
    </div>
  </div>
</template>
