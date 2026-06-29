/* global axios */
import ApiClient from './ApiClient';

class ConverraBillingAPI extends ApiClient {
  constructor() {
    super('converra_billing', { accountScoped: true });
  }

  getStatus() {
    return axios.get(`${this.url}/status`);
  }

  checkout(planSlug) {
    return axios.post(`${this.url}/checkout`, { plan_slug: planSlug });
  }
}

export default new ConverraBillingAPI();
