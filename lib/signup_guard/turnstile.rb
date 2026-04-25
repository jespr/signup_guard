# frozen_string_literal: true

module SignupGuard
  class Turnstile
    include HTTParty
    base_uri "https://challenges.cloudflare.com"
    default_timeout 5

    Result = Struct.new(:success, :score, keyword_init: true) do
      alias_method :success?, :success
    end

    class << self
      def verify(token, remote_ip)
        return Result.new(success: false, score: 0.0) if token.blank?

        response = post("/turnstile/v0/siteverify", body: {
          secret: secret,
          response: token,
          remoteip: remote_ip
        }.compact)

        success = response.parsed_response.is_a?(Hash) && response.parsed_response["success"] == true
        Result.new(success: success, score: success ? 1.0 : 0.0)
      rescue HTTParty::Error, JSON::ParserError, SocketError, Timeout::Error
        Result.new(success: false, score: 0.0)
      end

      def site_key
        credentials&.dig(:site_key)
      end

      def configured?
        site_key.present? && secret.present?
      end

      private

      def secret
        credentials&.dig(:secret)
      end

      def credentials
        SignupGuard.configuration.turnstile_credentials.call
      end
    end
  end
end
