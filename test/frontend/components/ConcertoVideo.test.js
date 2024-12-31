import { describe, it, expect } from 'vitest'

import { mount } from '@vue/test-utils'
import ConcertoVideo from '~/components/ConcertoVideo.vue'

describe('ConcertoVideo', () => {
  it('displays image', () => {
    const content = {
      video_id: 'z7HyF46-Zd0'
    };
    const wrapper = mount(ConcertoVideo, { props: { content: content }});

    expect(wrapper.html()).toContain('src="http://www.youtube-nocookie.com/embed/z7HyF46-Zd0?rel=0&amp;iv_load_policy=3&amp;autoplay=1');
  })
})