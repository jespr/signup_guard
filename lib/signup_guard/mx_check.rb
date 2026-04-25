# frozen_string_literal: true

require "resolv"

module SignupGuard
  module MxCheck
    DNS_TIMEOUT_SECONDS = 2
    CACHE_TTL = 24 * 60 * 60

    class << self
      def valid?(domain)
        return false if domain.blank?

        Rails.cache.fetch("signup_guard/mx/#{domain.downcase}", expires_in: CACHE_TTL) do
          lookup(domain)
        end
      end

      private

      def lookup(domain)
        Resolv::DNS.open do |dns|
          dns.timeouts = DNS_TIMEOUT_SECONDS
          dns.getresources(domain, Resolv::DNS::Resource::IN::MX).any?
        end
      rescue Resolv::ResolvError, Resolv::ResolvTimeout, IOError, Errno::ECONNREFUSED
        false
      end
    end
  end
end
