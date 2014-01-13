goog.provide('concerto.frontend.Content.Ticker');

goog.require('concerto.frontend.Content');
goog.require('concerto.frontend.Helpers');
goog.require('goog.dom');



/**
 * Ticker Text.
 *
 * @param {Object} data Properties for this piece of content.
 * @constructor
 * @extends {concerto.frontend.Content}
 */
concerto.frontend.Content.Ticker = function(data) {
  concerto.frontend.Content.call(this, data);

  this.autosize_font = true;

  /**
   * The text.
   * @type {string}
   */
  this.text = data['render_details']['data'];

  /**
   * The height of the field the ticker is being shown in.
   * @type {number}
   * @private
   */
  this.field_height_ = data.field.size.height;

  /**
   * The width of the field the ticker is being shown in.
   * @type {number}
   * @private
   */
  this.field_width_ = data.field.size.width;

};
goog.inherits(concerto.frontend.Content.Ticker, concerto.frontend.Content);

// Register the content type.
concerto.frontend.ContentTypeRegistry['Ticker'] =
    concerto.frontend.Content.Ticker;


/**
 * Load the text.
 * @private
 */
concerto.frontend.Content.Ticker.prototype.load_ = function() {
  // plain text ticker
  // goog.dom.setTextContent(this.div_, this.text);

  // html ticker, wrapped in single node
  goog.dom.removeChildren(this.div_);
  var frag = goog.dom.htmlToDocumentFragment('<div>' + this.text + '</div>');
  goog.dom.appendChild(this.div_, frag);
  this.finishLoad();
};
