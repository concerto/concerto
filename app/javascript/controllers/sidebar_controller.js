import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  connect() {
    this.isMobileOpen = false
  }

  toggle() {
    if (this.isMobileOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    if (!this.hasSidebarTarget || !this.hasOverlayTarget) return
    
    this.isMobileOpen = true
    this.sidebarTarget.classList.remove("-translate-x-full")
    this.sidebarTarget.classList.add("translate-x-0")
    this.overlayTarget.style.display = "block"
    
    // Prevent body scroll when mobile menu is open
    document.body.style.overflow = "hidden"
  }

  close() {
    if (!this.hasSidebarTarget || !this.hasOverlayTarget) return

    this.isMobileOpen = false
    this.sidebarTarget.classList.add("-translate-x-full")
    this.sidebarTarget.classList.remove("translate-x-0")
    this.overlayTarget.style.display = "none"
    
    // Restore body scroll
    document.body.style.overflow = ""
  }


  // Handle window resize
  handleResize() {
    if (window.innerWidth >= 1024) { // lg breakpoint
      this.close() // Close mobile menu on desktop
    }
  }

  // Add event listener for window resize
  initialize() {
    this.handleResize = this.handleResize.bind(this)
    window.addEventListener('resize', this.handleResize)
  }

  disconnect() {
    window.removeEventListener('resize', this.handleResize)
    document.body.style.overflow = "" // Ensure body scroll is restored
  }
}