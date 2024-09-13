import { describe, it, expect } from 'vitest'

import { mount } from '@vue/test-utils'
import ConcertoGraphic from '~/components/ConcertoGraphic.vue'

describe('ConcertoGraphic', () => {
  it('displays image', () => {
    const content = {
      image: 'image.jpg'
    };
    const wrapper = mount(ConcertoGraphic, { props: { content: content }});

    const style = getComputedStyle(wrapper.get('.graphic').element);

    expect(style.cssText).toContain('url(image.jpg)');
  })
})
