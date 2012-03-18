goog.provide('concerto.frontend.Content.Ticker');

goog.require('concerto.frontend.Content');



/**
 * Ticker Text.
 *
 * @param {Object} data Properties for this piece of content.
 * @constructor
 * @extends {concerto.frontend.Content}
 */
concerto.frontend.Content.Ticker = function(data) {
  concerto.frontend.Content.call(this, data);

  /**
   * The text.
   * @type {string}
   */
  this.text = data.render_details.data;

};
goog.inherits(concerto.frontend.Content.Ticker, concerto.frontend.Content);


/**
 * Load the text.
 * @private
 */
concerto.frontend.Content.Ticker.prototype.load_ = function() {
  goog.dom.setTextContent(this.div_, this.text);
  this.finishLoad();
};
