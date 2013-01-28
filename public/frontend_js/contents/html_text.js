goog.provide('concerto.frontend.Content.HtmlText');

goog.require('concerto.frontend.Content');
goog.require('goog.dom');



/**
 * HTML Text.
 *
 * @param {Object} data Properties for this piece of content.
 * @constructor
 * @extends {concerto.frontend.Content}
 */
concerto.frontend.Content.HtmlText = function(data) {
  concerto.frontend.Content.call(this, data);

  /**
   * The html.
   * @type {string}
   */
  this.html = data['render_details']['data'];

};
goog.inherits(concerto.frontend.Content.HtmlText, concerto.frontend.Content);

// Register the content type.
concerto.frontend.ContentTypeRegistry['HtmlText'] =
    concerto.frontend.Content.HtmlText;


/**
 * Load the text.
 * @private
 */
concerto.frontend.Content.HtmlText.prototype.load_ = function() {
  this.div_.innerHTML = this.html;
  this.finishLoad();
};
