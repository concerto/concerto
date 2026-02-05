import { Controller } from "@hotwired/stimulus"

// Simple toggle controller for showing/hiding content
// Usage:
//   <div data-controller="toggle">
//     <button data-action="toggle#toggle">Toggle</button>
//     <div data-toggle-target="content" class="hidden">Hidden content</div>
//   </div>
export default class extends Controller {
  static targets = ["content"]

  toggle() {
    this.contentTargets.forEach(target => {
      target.classList.toggle("hidden")
    })
  }

  show() {
    this.contentTargets.forEach(target => {
      target.classList.remove("hidden")
    })
  }

  hide() {
    this.contentTargets.forEach(target => {
      target.classList.add("hidden")
    })
  }
}
