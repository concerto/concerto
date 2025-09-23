import { describe, it, expect } from 'vitest'

import { mount } from '@vue/test-utils'
import ConcertoRichText from '~/components/ConcertoRichText.vue'

describe('ConcertoRichText', () => {
  it('validates props', () => {
    const content = {
      text: 'This is <strong>HTML</strong>',
      render_as: 'invalid_format',
    };
    expect(ConcertoRichText.props.content.validator(content)).toBe(false);

    content.render_as = [];
    expect(ConcertoRichText.props.content.validator(content)).toBe(false);
    
    content.render_as = 'html';
    expect(ConcertoRichText.props.content.validator(content)).toBe(true);

    content.render_as = 'plaintext';
    expect(ConcertoRichText.props.content.validator(content)).toBe(true);
  });

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
