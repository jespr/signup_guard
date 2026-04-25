# frozen_string_literal: true

namespace :signup_guard do
  desc "Download the latest disposable email domains blocklist"
  task refresh_disposable_domains: :environment do
    require "net/http"

    url = URI("https://disposable.github.io/disposable-email-domains/domains.txt")
    path = SignupGuard.configuration.disposable_domains_path

    body = Net::HTTP.get(url)
    if body.blank? || body.lines.size < 100
      abort "Refusing to overwrite #{path}: response looks empty or truncated (#{body.lines.size} lines)"
    end

    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, body)
    SignupGuard::DisposableEmail.reload!

    puts "Wrote #{body.lines.size} domains to #{path}"
  end
end
