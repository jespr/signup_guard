# frozen_string_literal: true

require "set"

module SignupGuard
  module DisposableEmail
    FREEMAIL_DOMAINS = %w[
      gmail.com googlemail.com yahoo.com ymail.com hotmail.com outlook.com
      live.com msn.com aol.com icloud.com me.com mac.com protonmail.com
      proton.me mail.com gmx.com gmx.de yandex.com yandex.ru
    ].to_set.freeze

    class << self
      def disposable_domain?(domain)
        return false if domain.blank?
        domains.include?(domain.downcase)
      end

      def domains
        @domains ||= load_domains
      end

      def reload!
        @domains = nil
      end

      private

      def load_domains
        path = SignupGuard.configuration.disposable_domains_path
        File.foreach(path).map(&:strip).reject(&:empty?).to_set
      rescue Errno::ENOENT
        Set.new
      end
    end
  end
end
