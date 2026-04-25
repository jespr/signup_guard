# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial extraction from a working production app
- `RiskScorer` with 13 weighted signals (honeypot, Turnstile, fingerprint
  reuse, IP burst, MX validity, disposable email, freemail+digits,
  fast-submit detection, IPQS Tor / datacenter / fraud-score)
- `SignupGuard::Configuration` for host-app integration (Devise-friendly
  defaults, all coupling points overridable as lambdas)
- Async `EnrichSignalJob` for IPQualityScore lookups, retroactively flips
  `requires_review` if post-signup data upgrades risk level
- `SignupGuard::CapturesSignals` controller concern (before_action enforces,
  after_action persists)
- `SignupGuard::BlocksPendingReview` concern for gating downstream creation
- `SignupGuard::Enforcement` kill switch
- `signup_guard:refresh_disposable_domains` rake task + standalone
  `bin/refresh-disposable-domains` for gem maintainers

[Unreleased]: https://github.com/jespr/signup_guard/compare/main...HEAD
