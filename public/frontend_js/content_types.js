goog.provide('concerto.frontend.ContentTypes');

/*
 * Below is the list of all the content types that will be included in the
 * frontend javascript when it is minified.  To add an additional content type
 * just require it below, and make sure it registers itself in the
 * ContentTypeRegistry with the matching 'type'.
 */

goog.require('concerto.frontend.Content.ClientTime');
goog.require('concerto.frontend.Content.Graphic');
goog.require('concerto.frontend.Content.HtmlText');
goog.require('concerto.frontend.Content.Ticker');
goog.require('concerto.frontend.Content.RemoteVideo');
goog.require('concerto.frontend.Content.Iframe');
goog.require('concerto.frontend.Content.Audio');
goog.require('concerto.frontend.Content.EmergencyAlert');
