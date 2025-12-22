import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["customInput", "customRadio"]

  connect() {
    this.updateCustomInputState(false) // Don't clear on initial load
  }

  // Called when any radio button changes
  handleRadioChange() {
    this.updateCustomInputState(true) // Clear when switching radios
  }

  updateCustomInputState(shouldClearWhenDisabled = false) {
    // Check if the custom format radio is selected
    const isCustomSelected = this.hasCustomRadioTarget && this.customRadioTarget.checked

    if (this.hasCustomInputTarget) {
      if (isCustomSelected) {
        // Enable and focus the custom input
        this.customInputTarget.disabled = false
        this.customInputTarget.focus()
      } else {
        // Disable the custom input when a preset is selected
        this.customInputTarget.disabled = true
        // Only clear the value when user is actively switching (not on page load)
        if (shouldClearWhenDisabled) {
          this.customInputTarget.value = ''
        }
      }
    }
  }
}
