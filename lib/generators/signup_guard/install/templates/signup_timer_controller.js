import { Controller } from "@hotwired/stimulus";
import FingerprintJS from "@fingerprintjs/fingerprintjs";

// Populates two hidden fields on the signup form so the server can score
// time-to-submit and per-device fingerprint signals. Fingerprinting may be
// blocked by the browser; an empty field is itself a signal.
export default class extends Controller {
  static targets = ["renderedAt", "fingerprint"];

  connect() {
    this.renderedAtTarget.value = Date.now().toString();
    this.loadFingerprint();
  }

  async loadFingerprint() {
    try {
      const fp = await FingerprintJS.load();
      const result = await fp.get();
      // Guard against Turbo navigation detaching the controller mid-await.
      if (!this.hasFingerprintTarget) return;
      this.fingerprintTarget.value = result.visitorId;
    } catch {
      // Browser blocked fingerprinting — leave the field empty intentionally.
    }
  }
}
