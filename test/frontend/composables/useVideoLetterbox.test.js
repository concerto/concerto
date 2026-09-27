import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { nextTick, ref } from 'vue'
import { useVideoLetterbox } from '../../../app/frontend/composables/useVideoLetterbox.js'

// JSDOM doesn't lay anything out, so the container's size comes from here.
// Its own clientWidth/clientHeight live on Element.prototype and read 0; we
// shadow them on HTMLElement.prototype and remove the shadow afterwards.
let box = { width: 0, height: 0 }

function mountWith(aspectRatio) {
  const ratio = ref(aspectRatio)
  const wrapper = mount({
    template: '<div ref="containerRef"><iframe :style="frameStyle" /></div>',
    setup() {
      return useVideoLetterbox(() => ratio.value)
    }
  })
  return { wrapper, ratio }
}

// A browser without container query units -- the path this composable owns.
function stubLegacyBrowser({ resizeObserver = false } = {}) {
  vi.stubGlobal('CSS', { supports: () => false })
  vi.stubGlobal('ResizeObserver', resizeObserver ? class {
    observe() {}
    disconnect() {}
  } : undefined)
}

describe('useVideoLetterbox', () => {
  beforeEach(() => {
    box = { width: 1000, height: 800 }
    Object.defineProperty(HTMLElement.prototype, 'clientWidth', { configurable: true, get: () => box.width })
    Object.defineProperty(HTMLElement.prototype, 'clientHeight', { configurable: true, get: () => box.height })
  })

  afterEach(() => {
    delete HTMLElement.prototype.clientWidth
    delete HTMLElement.prototype.clientHeight
    vi.unstubAllGlobals()
  })

  it('leaves sizing to CSS where container query units exist', () => {
    vi.stubGlobal('CSS', { supports: () => true })
    const { wrapper } = mountWith('16/9')

    expect(wrapper.vm.frameStyle).toEqual({})
  })

  it('fits a landscape video to the width of a squarer box', () => {
    stubLegacyBrowser()
    const { wrapper } = mountWith('16/9')

    expect(wrapper.vm.frameStyle).toEqual({ width: '1000px', height: '562.5px' })
  })

  it('fits a portrait video to the height of the box', () => {
    stubLegacyBrowser()
    const { wrapper } = mountWith('9/16')

    expect(wrapper.vm.frameStyle).toEqual({ width: '450px', height: '800px' })
  })

  it('keeps the CSS fill fallback for an unusable ratio', () => {
    stubLegacyBrowser()
    const { wrapper } = mountWith('auto')

    expect(wrapper.vm.frameStyle).toEqual({})
  })

  it('retries on the next frame until the box has been laid out', () => {
    stubLegacyBrowser()
    const frames = []
    vi.stubGlobal('requestAnimationFrame', (callback) => frames.push(callback))
    box = { width: 0, height: 0 }

    const { wrapper } = mountWith('16/9')
    expect(wrapper.vm.frameStyle).toEqual({})
    expect(frames).toHaveLength(1)

    box = { width: 1600, height: 900 }
    frames.shift()()
    expect(wrapper.vm.frameStyle).toEqual({ width: '1600px', height: '900px' })
  })

  it('gives up after a bounded number of frames', () => {
    stubLegacyBrowser()
    const frames = []
    vi.stubGlobal('requestAnimationFrame', (callback) => frames.push(callback))
    box = { width: 0, height: 0 }

    mountWith('16/9')
    let run = 0
    while (frames.length) {
      frames.shift()()
      run += 1
    }

    expect(run).toBe(10)
  })

  it('re-measures when the ratio changes, as Vimeo does after load', async () => {
    stubLegacyBrowser()
    const { wrapper, ratio } = mountWith('16/9')

    ratio.value = '4/3'
    await nextTick()

    expect(wrapper.vm.frameStyle).toEqual({ width: '1000px', height: '750px' })
  })

  it('re-measures on window resize where ResizeObserver is missing', () => {
    stubLegacyBrowser()
    const { wrapper } = mountWith('16/9')

    box = { width: 1920, height: 1080 }
    window.dispatchEvent(new Event('resize'))

    expect(wrapper.vm.frameStyle).toEqual({ width: '1920px', height: '1080px' })
  })

  it('stops listening to the window once unmounted', () => {
    stubLegacyBrowser()
    const removeSpy = vi.spyOn(window, 'removeEventListener')
    const { wrapper } = mountWith('16/9')

    wrapper.unmount()

    expect(removeSpy).toHaveBeenCalledWith('resize', expect.any(Function))
    removeSpy.mockRestore()
  })

  it('observes the container where ResizeObserver exists', () => {
    stubLegacyBrowser({ resizeObserver: true })
    const observe = vi.spyOn(ResizeObserver.prototype, 'observe')

    const { wrapper } = mountWith('16/9')

    expect(observe).toHaveBeenCalledWith(wrapper.element)
  })
})
