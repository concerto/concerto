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
 * We are casting the 0 or 1 into true or false with the !!+, do not remove it.
 * This is because we need to negate the variable for our internal code, which
 * was making javascript upset when it had to negate a numeric value.
 */
var disable_text_autosize = !!+(data['field']['config'] ?
                             data['field']['config']['disable_text_autosize'] : 0);

/**
 * Should the font size be automatically adjusted to optimize
 * display within the field?
 * @type {boolean}
 */
this.autosize_font = !disable_text_autosize;


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
  this.finishLoad();
};
