import { describe, it, expect } from 'vitest'

import { mount } from '@vue/test-utils'
import ConcertoRichText from '~/components/ConcertoRichText.vue'

describe('ConcertoRichText', () => {
  it('displays plain text', () => {
    const content = {
        text: 'This is <strong>plain</strong> text which should not be HTML',
        render_as: 'plaintext',
    };
    const wrapper = mount(ConcertoRichText, { props: { content: content }});

    expect(wrapper.html()).toContain('This is &lt;strong&gt;plain&lt;/strong&gt; text');
  });

  it('displays HTML', () => {
    const content = {
        text: 'This is <strong>HTML</strong>',
        render_as: 'html',
    };
    const wrapper = mount(ConcertoRichText, { props: { content: content }});

    expect(wrapper.html()).toContain('This is <strong>HTML</strong>');
  });
})
