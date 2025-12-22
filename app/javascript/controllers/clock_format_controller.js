import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["customInput", "presetRadio"]

  connect() {
    this.updateCustomInputState()
  }

  // Called when any radio button changes
  handleRadioChange(event) {
    this.updateCustomInputState()
  }

  updateCustomInputState() {
    // Check if the custom format radio is selected
    const customRadio = this.element.querySelector('#clock_format_custom')
    const isCustomSelected = customRadio && customRadio.checked

    if (this.hasCustomInputTarget) {
      if (isCustomSelected) {
        // Enable and focus the custom input
        this.customInputTarget.disabled = false
        this.customInputTarget.focus()
      } else {
        // Disable and clear the custom input when a preset is selected
        this.customInputTarget.disabled = true
        this.customInputTarget.value = ''
      }
    }
  }
}
