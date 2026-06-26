# frozen_string_literal: true

class BrevoApiDeliveryMethod
  API_URL = 'https://api.brevo.com/v3/smtp/email'

  class DeliveryError < StandardError; end

  def initialize(settings = {})
    @api_key = settings[:api_key].presence || ENV['BREVO_API_KEY']
    raise DeliveryError, 'BREVO_API_KEY is not configured' if @api_key.blank?
  end

  def deliver!(mail)
    response = HTTParty.post(
      API_URL,
      headers: {
        'api-key' => @api_key,
        'Content-Type' => 'application/json',
        'accept' => 'application/json'
      },
      body: build_payload(mail).to_json,
      timeout: 30
    )

    return if response.success?

    raise DeliveryError, "Brevo API error (#{response.code}): #{response.body}"
  end

  private

  def build_payload(mail)
    sender = parse_address(mail[:from]&.value || mail.from&.first).first
    raise DeliveryError, 'Missing sender address' if sender.blank?

    html = html_body(mail)
    text = text_body(mail)
    text = ActionView::Base.full_sanitizer.sanitize(html) if text.blank? && html.present?
    raise DeliveryError, 'Email must have html or text content' if html.blank? && text.blank?

    payload = {
      sender: sender,
      to: parse_addresses(mail.to),
      subject: mail.subject,
      htmlContent: html,
      textContent: text
    }.compact

    payload[:cc] = parse_addresses(mail.cc) if mail.cc.present?
    payload[:bcc] = parse_addresses(mail.bcc) if mail.bcc.present?
    payload[:replyTo] = parse_address(mail.reply_to&.first).first if mail.reply_to.present?
    payload[:attachment] = attachments_payload(mail) if mail.attachments.any?

    payload
  end

  def html_body(mail)
    return mail.html_part.body.decoded if mail.multipart? && mail.html_part

    return mail.body.decoded if mail.content_type.to_s.include?('text/html')

    nil
  end

  def text_body(mail)
    return mail.text_part.body.decoded if mail.multipart? && mail.text_part

    return mail.body.decoded unless mail.content_type.to_s.include?('text/html')

    nil
  end

  def parse_addresses(addresses)
    Array(addresses).flat_map { |address| parse_address(address) }
  end

  def parse_address(address)
    return [] if address.blank?

    parsed = Mail::Address.new(address)
    entry = { email: parsed.address }
    entry[:name] = parsed.display_name if parsed.display_name.present?
    [entry]
  rescue Mail::Field::ParseError
    [{ email: address.to_s.strip }]
  end

  def attachments_payload(mail)
    mail.attachments.map do |attachment|
      {
        name: attachment.filename,
        content: Base64.strict_encode64(attachment.body.raw_source)
      }
    end
  end
end
