import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="template-editor"
export default class extends Controller {
  static targets = [
    "canvas",
    "image",
    "placeholder",
    "positionsList",
    "inspector",
    "fieldSelect",
    "styleInput",
    "coordLeft",
    "coordTop",
    "coordRight",
    "coordBottom",
    "imageInput",
    "addPositionButton"
  ]

  static values = {
    positions: Array
  }

  connect() {
    this.positions = this.positionsValue || []
    const maxId = Math.max(0, ...this.positions.map(p => parseInt(p.id.replace('pos_', ''), 10) || 0))
    this.nextId = maxId + 1
    this.selectedPosition = null
    this.dragging = null
    this.resizing = null
    this.imageWidth = 1920
    this.imageHeight = 1080

    // Bind event handlers
    this.boundMouseMove = this.handleMouseMove.bind(this)
    this.boundMouseUp = this.handleMouseUp.bind(this)

    // Add global listeners
    document.addEventListener('mousemove', this.boundMouseMove)
    document.addEventListener('mouseup', this.boundMouseUp)

    // Disable Add Position button if no image is attached
    if (this.hasAddPositionButtonTarget) {
      const hasImage = this.imageTarget.style.display !== 'none' && this.imageTarget.src
      this.addPositionButtonTarget.disabled = !hasImage
    }

    // Render existing positions if any
    if (this.positions.length > 0) {
      this.positions.forEach(pos => this.renderPosition(pos))
    }
  }

  disconnect() {
    document.removeEventListener('mousemove', this.boundMouseMove)
    document.removeEventListener('mouseup', this.boundMouseUp)
  }

  // Image upload handler
  imageChanged(event) {
    const file = event.target.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      const img = new Image()
      img.onload = () => {
        this.imageWidth = img.width
        this.imageHeight = img.height
        this.imageTarget.src = e.target.result
        this.imageTarget.style.display = 'block'

        // Hide placeholder
        if (this.hasPlaceholderTarget) {
          this.placeholderTarget.style.display = 'none'
        }

        // Enable Add Position button now that image is loaded
        if (this.hasAddPositionButtonTarget) {
          this.addPositionButtonTarget.disabled = false
        }

        // Re-render all positions with new image dimensions
        this.clearCanvas()
        this.positions.forEach(pos => this.renderPosition(pos))
      }
      img.src = e.target.result
    }
    reader.readAsDataURL(file)
  }

  // Add new position
  addPosition() {
    // Validate that fields exist before adding position
    if (!this.hasFieldSelectTarget || this.fieldSelectTarget.options.length === 0) {
      alert('Cannot add position: No fields available. Please create fields first.')
      return
    }

    // Create new position in center, 200x150px default
    const scale = this.getScale()

    const width = 200 / (this.imageWidth * scale)
    const height = 150 / (this.imageHeight * scale)
    const left = 0.5 - (width / 2)
    const top = 0.5 - (height / 2)

    const position = {
      id: `pos_${this.nextId++}`,
      field_id: this.getDefaultFieldId(),
      field_name: this.getDefaultFieldName(),
      left: left,
      top: top,
      right: left + width,
      bottom: top + height,
      style: '',
      _destroy: false
    }

    this.positions.push(position)
    this.renderPosition(position)
    this.selectPosition(position.id)
  }

  // Remove selected position
  removePosition() {
    if (!this.selectedPosition) return

    const position = this.positions.find(p => p.id === this.selectedPosition)
    if (!position) return

    // Mark for destruction
    position._destroy = true

    // Remove from DOM
    const element = this.canvasTarget.querySelector(`[data-position-id="${position.id}"]`)
    if (element) {
      element.remove()
    }

    // Deselect
    this.selectedPosition = null
    this.inspectorTarget.style.display = 'none'

    this.updatePositionsList()
  }

  // Select a position
  selectPosition(id) {
    // Deselect previous
    if (this.selectedPosition) {
      const prev = this.canvasTarget.querySelector(`[data-position-id="${this.selectedPosition}"]`)
      if (prev) prev.classList.remove('selected')
    }

    this.selectedPosition = id
    const position = this.positions.find(p => p.id === id)
    if (!position) return

    // Highlight selected
    const element = this.canvasTarget.querySelector(`[data-position-id="${id}"]`)
    if (element) element.classList.add('selected')

    // Show inspector with details
    this.inspectorTarget.style.display = 'block'
    this.fieldSelectTarget.value = position.field_id
    this.styleInputTarget.value = position.style || ''
    this.updateCoordinateDisplay(position)
  }

  // Update field selection
  updateField(event) {
    if (!this.selectedPosition) return

    const position = this.positions.find(p => p.id === this.selectedPosition)
    if (!position) return

    position.field_id = event.target.value
    position.field_name = event.target.options[event.target.selectedIndex].text

    // Update label
    const element = this.canvasTarget.querySelector(`[data-position-id="${position.id}"]`)
    const label = element.querySelector('.position-label')
    if (label) {
      label.textContent = position.field_name
    }

    this.updatePositionsList()
  }

  // Update style
  updateStyle(event) {
    if (!this.selectedPosition) return

    const position = this.positions.find(p => p.id === this.selectedPosition)
    if (!position) return

    position.style = event.target.value
  }

  // Render a position rectangle on canvas
  renderPosition(position) {
    if (position._destroy) return

    const rect = document.createElement('div')
    rect.className = 'position-rectangle'
    rect.dataset.positionId = position.id

    // Calculate pixel position
    this.updatePositionElement(rect, position)

    // Add label (positioning will be handled by updateLabelPosition via updatePositionElement)
    const label = document.createElement('div')
    label.className = 'position-label'
    label.textContent = position.field_name || `Position ${position.id}`
    rect.appendChild(label)

    // Add resize handles
    const handles = ['nw', 'ne', 'sw', 'se']
    handles.forEach(handle => {
      const div = document.createElement('div')
      div.className = `resize-handle ${handle}`
      div.dataset.handle = handle
      div.addEventListener('mousedown', (e) => this.startResize(e, position.id, handle))
      rect.appendChild(div)
    })

    // Add click handler
    rect.addEventListener('mousedown', (e) => {
      if (e.target.classList.contains('resize-handle')) return
      this.startDrag(e, position.id)
    })

    this.canvasTarget.appendChild(rect)
    this.updatePositionsList()
  }

  // Update position element's visual position/size
  updatePositionElement(element, position) {
    const scale = this.getScale()

    const left = position.left * this.imageWidth * scale
    const top = position.top * this.imageHeight * scale
    const width = (position.right - position.left) * this.imageWidth * scale
    const height = (position.bottom - position.top) * this.imageHeight * scale

    element.style.left = `${left}px`
    element.style.top = `${top}px`
    element.style.width = `${width}px`
    element.style.height = `${height}px`

    // Update label position based on position's top coordinate
    this.updateLabelPosition(element, position)
  }

  // Update label position (flip to bottom if near top, inside if very tall)
  updateLabelPosition(element, position) {
    const label = element.querySelector('.position-label')
    if (!label) return

    const height = position.bottom - position.top

    // Remove all positioning classes first
    label.classList.remove('label-below', 'label-inside')

    // If position takes up most of the canvas height, put label inside
    if (height > 0.85) {
      label.classList.add('label-inside')
    }
    // If position is near top of canvas, put label below
    else if (position.top < 0.08) {
      label.classList.add('label-below')
    }
    // Otherwise label stays above (default)
  }

  // Start dragging
  startDrag(event, id) {
    event.preventDefault()
    event.stopPropagation()

    this.selectPosition(id)

    const position = this.positions.find(p => p.id === id)
    if (!position) return

    this.dragging = {
      id: id,
      startX: event.clientX,
      startY: event.clientY,
      startLeft: position.left,
      startTop: position.top,
      width: position.right - position.left,
      height: position.bottom - position.top,
      scale: this.getScale()
    }
  }

  // Start resizing
  startResize(event, id, handle) {
    event.preventDefault()
    event.stopPropagation()

    this.selectPosition(id)

    const position = this.positions.find(p => p.id === id)
    if (!position) return

    this.resizing = {
      id: id,
      handle: handle,
      startX: event.clientX,
      startY: event.clientY,
      startLeft: position.left,
      startTop: position.top,
      startRight: position.right,
      startBottom: position.bottom,
      scale: this.getScale()
    }
  }

  // Handle mouse move (drag/resize)
  handleMouseMove(event) {
    if (this.dragging) {
      this.drag(event)
    } else if (this.resizing) {
      this.resize(event)
    }
  }

  // Drag handler
  drag(event) {
    if (!this.dragging) return

    const position = this.positions.find(p => p.id === this.dragging.id)
    if (!position) return

    const scale = this.dragging.scale
    const deltaX = (event.clientX - this.dragging.startX) / (this.imageWidth * scale)
    const deltaY = (event.clientY - this.dragging.startY) / (this.imageHeight * scale)

    let newLeft = this.dragging.startLeft + deltaX
    let newTop = this.dragging.startTop + deltaY

    // Constrain to bounds
    newLeft = Math.max(0, Math.min(1 - this.dragging.width, newLeft))
    newTop = Math.max(0, Math.min(1 - this.dragging.height, newTop))

    position.left = newLeft
    position.top = newTop
    position.right = newLeft + this.dragging.width
    position.bottom = newTop + this.dragging.height

    const element = this.canvasTarget.querySelector(`[data-position-id="${this.dragging.id}"]`)
    this.updatePositionElement(element, position)
    this.updateCoordinateDisplay(position)
  }

  // Resize handler
  resize(event) {
    if (!this.resizing) return

    const position = this.positions.find(p => p.id === this.resizing.id)
    if (!position) return

    const scale = this.resizing.scale
    const deltaX = (event.clientX - this.resizing.startX) / (this.imageWidth * scale)
    const deltaY = (event.clientY - this.resizing.startY) / (this.imageHeight * scale)

    const handle = this.resizing.handle

    // Update position based on which handle is being dragged
    if (handle.includes('n')) {
      position.top = Math.max(0, Math.min(this.resizing.startBottom - 0.05, this.resizing.startTop + deltaY))
    }
    if (handle.includes('s')) {
      position.bottom = Math.max(this.resizing.startTop + 0.05, Math.min(1, this.resizing.startBottom + deltaY))
    }
    if (handle.includes('w')) {
      position.left = Math.max(0, Math.min(this.resizing.startRight - 0.05, this.resizing.startLeft + deltaX))
    }
    if (handle.includes('e')) {
      position.right = Math.max(this.resizing.startLeft + 0.05, Math.min(1, this.resizing.startRight + deltaX))
    }

    const element = this.canvasTarget.querySelector(`[data-position-id="${this.resizing.id}"]`)
    this.updatePositionElement(element, position)
    this.updateCoordinateDisplay(position)
  }

  // Handle mouse up (end drag/resize)
  handleMouseUp() {
    if (this.dragging || this.resizing) {
      this.updateHiddenFields()
    }
    this.dragging = null
    this.resizing = null
  }

  // Update coordinate display in inspector
  updateCoordinateDisplay(position) {
    if (!this.hasCoordLeftTarget) return

    this.coordLeftTarget.textContent = position.left.toFixed(3)
    this.coordTopTarget.textContent = position.top.toFixed(3)
    this.coordRightTarget.textContent = position.right.toFixed(3)
    this.coordBottomTarget.textContent = position.bottom.toFixed(3)
  }

  // Update positions list in sidebar
  updatePositionsList() {
    const list = this.positionsListTarget
    list.innerHTML = ''

    this.positions.filter(p => !p._destroy).forEach(position => {
      const item = document.createElement('div')
      item.className = 'position-list-item'
      if (position.id === this.selectedPosition) {
        item.classList.add('selected')
      }

      const container = document.createElement('div')
      container.className = 'flex items-center justify-between p-2 border rounded cursor-pointer hover:bg-gray-50'

      const content = document.createElement('div')

      const fieldName = document.createElement('div')
      fieldName.className = 'font-medium'
      fieldName.textContent = position.field_name || 'Unnamed'

      const coords = document.createElement('div')
      coords.className = 'text-xs text-gray-500'
      coords.textContent = `${position.left.toFixed(3)}, ${position.top.toFixed(3)} → ${position.right.toFixed(3)}, ${position.bottom.toFixed(3)}`

      content.appendChild(fieldName)
      content.appendChild(coords)
      container.appendChild(content)
      item.appendChild(container)

      item.addEventListener('click', () => this.selectPosition(position.id))
      list.appendChild(item)
    })
  }

  // Clear canvas
  clearCanvas() {
    const rectangles = this.canvasTarget.querySelectorAll('.position-rectangle')
    rectangles.forEach(rect => rect.remove())
  }

  // Get canvas scale factor
  getScale() {
    const canvasRect = this.canvasTarget.getBoundingClientRect()
    const scaleX = canvasRect.width / this.imageWidth
    const scaleY = canvasRect.height / this.imageHeight
    return Math.min(scaleX, scaleY)
  }

  // Get default field option - prefers unused fields
  getDefaultFieldOption() {
    if (!this.hasFieldSelectTarget || this.fieldSelectTarget.options.length === 0) {
      return null
    }

    // Get all field IDs currently in use (excluding destroyed positions)
    const usedFieldIds = this.positions
      .filter(p => !p._destroy)
      .map(p => p.field_id?.toString())

    // Find first unused field
    for (let i = 0; i < this.fieldSelectTarget.options.length; i++) {
      const option = this.fieldSelectTarget.options[i]
      if (!usedFieldIds.includes(option.value)) {
        return option
      }
    }

    // If all fields are used, return the first one
    return this.fieldSelectTarget.options[0]
  }

  // Get default field ID - prefers unused fields
  getDefaultFieldId() {
    const option = this.getDefaultFieldOption()
    return option ? option.value : null
  }

  // Get default field name - matches the default field ID
  getDefaultFieldName() {
    const option = this.getDefaultFieldOption()
    return option ? option.text : 'Unnamed'
  }

  // Update hidden form fields before submission
  updateHiddenFields() {
    const form = this.element.closest('form')
    if (!form) return

    // Remove existing position field containers
    const existingContainers = form.querySelectorAll('[data-position-fields]')
    existingContainers.forEach(container => container.remove())

    // Create new containers for each position
    this.positions.forEach((position, index) => {
      const container = document.createElement('div')
      container.dataset.positionFields = true
      container.className = 'hidden'

      const prefix = `template[positions_attributes][${index}]`

      const fields = {
        'id': position.record_id || '',
        'field_id': position.field_id,
        'left': position.left,
        'top': position.top,
        'right': position.right,
        'bottom': position.bottom,
        'style': position.style || '',
        '_destroy': position._destroy ? '1' : '0'
      }

      Object.entries(fields).forEach(([key, value]) => {
        const input = document.createElement('input')
        input.type = 'hidden'
        input.name = `${prefix}[${key}]`
        input.value = value
        container.appendChild(input)
      })

      form.appendChild(container)
    })
  }

  // Before form submission
  submitForm() {
    this.updateHiddenFields()
  }
}
