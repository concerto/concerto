goog.provide('concerto.frontend.Content.HtmlText');

goog.require('concerto.frontend.Content');
goog.require('concerto.frontend.Helpers');
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
   * The height of the field the html is being shown in.
   * @type {number}
   * @private
   */
  this.field_height_ = data.field.size.height;

  /**
   * The width of the field the html is being shown in.
   * @type {number}
   * @private
   */
  this.field_width_ = data.field.size.width;

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
  this.div_ = concerto.frontend.Helpers.Autofit(this.div_, this.field_width_,
                                                this.field_height_);
  this.finishLoad();
};
