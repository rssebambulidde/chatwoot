/* global axios */
import ApiClient from './ApiClient';

class ConverraBillingAPI extends ApiClient {
  constructor() {
    super('converra_billing', { accountScoped: true });
  }

  getStatus() {
    return axios.get(`${this.url}/status`);
  }

  getPayments() {
    return axios.get(`${this.url}/payments`);
  }

  checkout(planSlug, billingInterval = 'monthly') {
    return axios.post(`${this.url}/checkout`, {
      plan_slug: planSlug,
      billing_interval: billingInterval,
    });
  }

  scheduleDowngrade() {
    return axios.post(`${this.url}/schedule_downgrade`);
  }
}

export default new ConverraBillingAPI();
