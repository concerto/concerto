import { describe, it, expect } from 'vitest';

import { mount } from '@vue/test-utils';
import ConcertoIframe from '~/components/ConcertoIframe.vue';

describe('ConcertoIframe', () => {
  it('renders an iframe with the content url as src', () => {
    const content = { url: 'https://example.com/dashboard' };
    const wrapper = mount(ConcertoIframe, { props: { content } });

    const iframe = wrapper.find('iframe');
    expect(iframe.exists()).toBe(true);
    expect(iframe.attributes('src')).toBe('https://example.com/dashboard');
  });

  it('sandboxes the embedded page', () => {
    const content = { url: 'https://example.com' };
    const wrapper = mount(ConcertoIframe, { props: { content } });

    const iframe = wrapper.find('iframe');
    expect(iframe.attributes('sandbox')).toContain('allow-scripts');
    expect(iframe.attributes('referrerpolicy')).toBe('no-referrer');
  });

  it('applies the provided box style', () => {
    const content = { url: 'https://example.com' };
    const wrapper = mount(ConcertoIframe, {
      props: { content, boxStyle: 'border-radius: 8px;' },
    });

    expect(wrapper.find('iframe').attributes('style')).toContain('border-radius: 8px');
  });
});
