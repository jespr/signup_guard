# frozen_string_literal: true

module SignupGuard
  class IpQualityScore
    include HTTParty
    base_uri "https://ipqualityscore.com"
    default_timeout 5

    CACHE_TTL = 6 * 60 * 60

    Result = Struct.new(:fraud_score, :asn, :country_code, :is_vpn, :is_tor, :is_datacenter, keyword_init: true)
    EMPTY = Result.new.freeze

    class << self
      def lookup(ip)
        return EMPTY if ip.blank? || !configured?

        Rails.cache.fetch("signup_guard/ipqs/#{ip}", expires_in: CACHE_TTL) { fetch(ip) }
      end

      def configured?
        api_key.present?
      end

      private

      def fetch(ip)
        json = get("/api/json/ip/#{api_key}/#{ip}").parsed_response
        return EMPTY unless json.is_a?(Hash) && json["success"] == true

        Result.new(
          fraud_score: json["fraud_score"],
          asn: json["ASN"]&.to_s,
          country_code: json["country_code"],
          is_vpn: json["vpn"] == true,
          is_tor: json["tor"] == true,
          is_datacenter: json["is_datacenter"] == true || json["connection_type"] == "Data Center"
        )
      rescue HTTParty::Error, JSON::ParserError, SocketError, Timeout::Error
        EMPTY
      end

      def api_key
        SignupGuard.configuration.ipqs_credentials.call&.dig(:key)
      end
    end
  end
end
