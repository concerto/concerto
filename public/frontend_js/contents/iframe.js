goog.provide('concerto.frontend.Content.Iframe');

goog.require('concerto.frontend.Content');
goog.require('concerto.frontend.ContentTypeRegistry');
goog.require('goog.Uri');
goog.require('goog.dom');
goog.require('goog.events');
goog.require('goog.events.EventType');
goog.require('goog.style');



/**
 * Iframe.
 *
 * @param {Object} data Properties for this piece of content.
 * @constructor
 * @extends {concerto.frontend.Content}
 */
concerto.frontend.Content.Iframe = function(data) {
  concerto.frontend.Content.call(this, data);

  /**
   * The height of the field the image is being shown in.
   * @type {number}
   * @private
   */
  this.field_height_ = parseFloat(data['field']['size']['height']);

  /**
   * The width of the field the image is being shown in.
   * @type {number}
   * @private
   */
  this.field_width_ = parseFloat(data['field']['size']['width']);

  /**
   * The iframe being displayed.
   * @type {Object}
   */
  this.iframe = null;

  /**
   * The URL for the video / iframe.
   * @type {string}
   */
  this.url = data['render_details']['path'];

  /**
   * Bump the duration of this content by 1 second.
   * This attempts to account for 1 second of load time and should be
   * improved in the future.
   */
  this.duration = this.duration + 1;
};
goog.inherits(concerto.frontend.Content.Iframe, concerto.frontend.Content);

// Register the content type.
concerto.frontend.ContentTypeRegistry['Iframe'] =
    concerto.frontend.Content.Iframe;


/**
 * Build the embed iframe and signal that we're ready to use it.
 * @private
 */
concerto.frontend.Content.Iframe.prototype.load_ = function() {
  this.iframe = goog.dom.createElement('iframe');
  this.iframe.src = this.url;
  this.iframe.frameborder = 0;
  this.iframe.scrolling = 'no';
  goog.style.setSize(this.iframe, '100%', '100%');
  goog.style.setSize(this.div_, '100%', '100%');
  goog.style.setStyle(this.iframe, 'border', 0);
  goog.dom.appendChild(this.div_, this.iframe);
  this.finishLoad();
};
