class Instagram::SendOnInstagramService < Instagram::BaseSendService
  private

  def channel_class
    Channel::Instagram
  end

  # Deliver a message with the given payload.
  # https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/messaging-api
  def send_message(message_content)
    access_token = channel.access_token
    instagram_id = channel.instagram_id.presence || 'me'
    api_version = GlobalConfigService.load('INSTAGRAM_API_VERSION', 'v22.0')

    response = HTTParty.post(
      "https://graph.instagram.com/#{api_version}/#{instagram_id}/messages",
      headers: {
        'Authorization' => "Bearer #{access_token}",
        'Content-Type' => 'application/json'
      },
      body: message_content.to_json
    )

    process_response(response, message_content)
  end

  def merge_human_agent_tag(params)
    global_config = GlobalConfig.get('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')

    return params unless global_config['ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT']
    return params unless outside_standard_messaging_window?

    # Instagram Login API uses `tag` only (not Messenger's messaging_type + tag).
    params[:tag] = 'HUMAN_AGENT'
    params
  end
end
