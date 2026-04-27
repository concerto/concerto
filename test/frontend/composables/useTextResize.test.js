import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import { useTextResize } from '../../../app/frontend/composables/useTextResize.js'

/* global global */

const TestComponent = {
  template: `
    <div ref="containerRef">
      <div ref="childRef">content</div>
    </div>
  `,
  setup() {
    return useTextResize()
  }
}

// JSDOM doesn't lay out content, so we mock layout: scrollHeight and scrollWidth
// on the container scale linearly with the font-size percent set on it. The
// "natural" size at 100% font is configurable to simulate wide vs tall content.
function mockLayout(wrapper, { fieldWidth, fieldHeight, naturalWidth, naturalHeight }) {
  const containerEl = wrapper.vm.containerRef
  const childEl = wrapper.vm.childRef

  Object.defineProperty(containerEl, 'clientWidth', { configurable: true, get: () => fieldWidth })
  Object.defineProperty(containerEl, 'clientHeight', { configurable: true, get: () => fieldHeight })

  const fontPercent = () => parseFloat(containerEl.style.fontSize) || 100
  Object.defineProperty(containerEl, 'scrollWidth', {
    configurable: true,
    get: () => Math.ceil(naturalWidth * fontPercent() / 100)
  })
  Object.defineProperty(containerEl, 'scrollHeight', {
    configurable: true,
    get: () => Math.ceil(naturalHeight * fontPercent() / 100)
  })

  // Child scrollHeight is only used for the zero-dimension early-bail check.
  Object.defineProperty(childEl, 'scrollHeight', { configurable: true, get: () => naturalHeight })
}

describe('useTextResize', () => {
  beforeEach(() => {
    // Disable ResizeObserver so onMounted doesn't observe; we drive resizeText() directly.
    global.ResizeObserver = undefined
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('shrinks font when content height overflows', async () => {
    const wrapper = mount(TestComponent, { attachTo: document.body })
    await nextTick()
    mockLayout(wrapper, { fieldWidth: 100, fieldHeight: 100, naturalWidth: 50, naturalHeight: 1000 })

    wrapper.vm.resizeText()
    expect(parseFloat(wrapper.vm.containerRef.style.fontSize)).toBeLessThanOrEqual(10)
    wrapper.unmount()
  })

  it('shrinks font when content width overflows even if height fits', async () => {
    const wrapper = mount(TestComponent, { attachTo: document.body })
    await nextTick()
    // Wide non-wrapping content. Without the width check, height alone would say
    // 100% font fits (50 <= 100), but the text overflows sideways.
    mockLayout(wrapper, { fieldWidth: 100, fieldHeight: 100, naturalWidth: 1000, naturalHeight: 50 })

    wrapper.vm.resizeText()
    expect(parseFloat(wrapper.vm.containerRef.style.fontSize)).toBeLessThanOrEqual(10)
    wrapper.unmount()
  })

  it('grows font when content fits comfortably', async () => {
    const wrapper = mount(TestComponent, { attachTo: document.body })
    await nextTick()
    mockLayout(wrapper, { fieldWidth: 100, fieldHeight: 100, naturalWidth: 1, naturalHeight: 1 })

    wrapper.vm.resizeText()
    expect(parseFloat(wrapper.vm.containerRef.style.fontSize)).toBeGreaterThan(1000)
    wrapper.unmount()
  })

  it('bails when container has zero width', async () => {
    const wrapper = mount(TestComponent, { attachTo: document.body })
    await nextTick()
    const errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
    mockLayout(wrapper, { fieldWidth: 0, fieldHeight: 100, naturalWidth: 50, naturalHeight: 50 })

    wrapper.vm.resizeText()
    expect(errorSpy).toHaveBeenCalled()
    wrapper.unmount()
  })
})
