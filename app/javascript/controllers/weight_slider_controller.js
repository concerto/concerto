import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slider", "weightInput", "label"]
  static values = {
    // Mapping: slider positions (1-5) to actual weight values
    weights: { type: Array, default: [2, 4, 5, 6, 8] },
    labels: { type: Array, default: ["Low", "", "Normal", "", "High"] }
  }

  connect() {
    // Initialize slider position based on current weight
    this.updateSliderFromWeight()
    this.updateLabel()
  }

  // Update the slider position based on the current weight value
  updateSliderFromWeight() {
    if (!this.hasWeightInputTarget || !this.hasSliderTarget) return

    const currentWeight = parseInt(this.weightInputTarget.value) || 5
    // Find the closest weight position
    const position = this.findClosestPosition(currentWeight)
    this.sliderTarget.value = position
  }

  // Find the slider position (1-5) that corresponds to the given weight
  findClosestPosition(weight) {
    let closestPosition = 3 // Default to middle (Normal)
    let minDifference = Infinity

    this.weightsValue.forEach((w, index) => {
      const difference = Math.abs(w - weight)
      if (difference <= minDifference) {
        minDifference = difference
        closestPosition = index + 1 // positions are 1-indexed
      }
    })

    return closestPosition
  }

  // Handle slider value changes
  handleSliderChange() {
    if (!this.hasSliderTarget || !this.hasWeightInputTarget) return

    const position = parseInt(this.sliderTarget.value)
    const weight = this.weightsValue[position - 1] // positions are 1-indexed

    this.weightInputTarget.value = weight
    this.updateLabel()
  }

  // Update the label display
  updateLabel() {
    if (!this.hasLabelTarget || !this.hasSliderTarget) return

    const position = parseInt(this.sliderTarget.value)
    const label = this.labelsValue[position - 1]

    // Only show the label for "Normal" (position 3), since "Low" and "High"
    // are already shown as slider endpoint labels
    if (label && label !== "Low" && label !== "High") {
      this.labelTarget.textContent = label
      this.labelTarget.classList.remove("invisible")
    } else {
      this.labelTarget.classList.add("invisible")
    }
  }

  // Submit the form (for inline editing)
  submitForm() {
    const form = this.element.closest("form")
    if (form) {
      form.requestSubmit()
    }
  }
}
