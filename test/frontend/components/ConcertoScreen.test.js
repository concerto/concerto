import { describe, it, expect, beforeAll, afterAll, afterEach } from 'vitest'

import { setupServer } from 'msw/node'
import { HttpResponse, http } from 'msw'
import { mount, enableAutoUnmount } from '@vue/test-utils'

import ConcertoScreen from '~/components/ConcertoScreen.vue'
import ConcertoField from '~/components/ConcertoField.vue'
import { eventually } from '../support/eventually.js'


const screenSetupUrl = 'http://server/screen_setup.json';
const fieldContentUrl = 'http://server/field_content.json';

const screenSetup = {
  template: {
    background_uri: "http://server/BlueSwooshNeo_16x9.jpg"
  },
  positions: [
    {
      id: 1,
      top: "0.026",
      left: "0.025",
      bottom: "0.796",
      right: "0.592",
      style: "border:solid 2px #ccc;",
      content_uri: fieldContentUrl
    },
    {
      id: 2,
      top: "0.885",
      left: "0.221",
      bottom: "0.985",
      right: "0.975",
      style: "color:#FFF; font-family:Frobisher, Arial, sans-serif; font-weight:bold !important;",
      content_uri: fieldContentUrl
    },
    {
      id: 3,
      top: "0.015",
      left: "0.68",
      bottom: "0.811",
      right: "0.98",
      style: "color:#FFF; font-family:Frobisher, Arial, sans-serif;",
      content_uri: fieldContentUrl
    },
    {
      id: 4,
      top: "0.885",
      left: "0.024",
      bottom: "0.974",
      right: "0.18",
      style: "color:#ccc; font-family:Frobisher, Arial, sans-serif; font-weight:bold !important; letter-spacing:.12em !important;border:solid 2px #ccc;",
      content_uri: fieldContentUrl
    }
  ]
};
  
export const httpHandlers = [
  http.get(screenSetupUrl, () => {
    return HttpResponse.json(screenSetup)
  }),
  http.get(fieldContentUrl, () => {
    return HttpResponse.json([] /* No content */);
  })
];

const server = setupServer(...httpHandlers);

// Start server before all tests.
beforeAll(() => server.listen({ onUnhandledFrame: 'error' }));

// Close server after all tests.
afterAll(() => server.close());

// Reset handlers after each test.
afterEach(() => server.resetHandlers());

// Unmount every screen after its test so its fetches can't leak into the next.
enableAutoUnmount(afterEach);

describe('ConcertoScreen', () => {
  it('displays screen', async () => {
    const wrapper = mount(ConcertoScreen, {
      props: { apiUrl: screenSetupUrl },
      global: {
        stubs: {
          ConcertoField: true
        }
      }
    } );

    const fields = await eventually(() => {
      const fields = wrapper.findAllComponents(ConcertoField);
      expect(fields).toHaveLength(4);
      return fields;
    });

    const screen = wrapper.get('.screen');
    expect(screen.attributes('style')).toContain('url("http://server/BlueSwooshNeo_16x9.jpg");');

    expect(fields[0].attributes('style')).toMatch(/top: 2.60?%;/);
    expect(fields[0].attributes('style')).toMatch(/left: 2.50?%;/);
    expect(fields[0].attributes('style')).toMatch(/height: 77(.00?)?%;/);
    expect(fields[0].attributes('style')).toMatch(/width: 56.70?%;/);

    expect(fields[1].html()).toContain(screenSetup.positions[1].style);

    expect(fields[2].html()).toContain(screenSetup.positions[2].content_uri);
  })

  it('quotes background URLs containing parentheses', async () => {
    // Regression for #1773: filenames like "tall (1).png" produce URLs
    // with raw parens that terminate an unquoted CSS url() function.
    const trickyUrl = 'http://server/blobs/tall_yes%20(1).png';
    server.use(
      http.get(screenSetupUrl, () => {
        return HttpResponse.json({
          template: { background_uri: trickyUrl },
          positions: []
        });
      })
    );

    const wrapper = mount(ConcertoScreen, {
      props: { apiUrl: screenSetupUrl },
      global: { stubs: { ConcertoField: true } }
    });

    await eventually(() =>
      expect(wrapper.get('.screen').attributes('style'))
        .toContain(`url("${trickyUrl}");`)
    );
  })
})