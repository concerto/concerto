goog.provide('concerto.frontend.Content.HtmlText');

goog.require('concerto.frontend.Content');
goog.require('concerto.frontend.Helpers');

goog.require('goog.debug.Logger');
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

  /*
   * Must use bracket notation and NOT dot notation for all references into the data
   * object because when the the closure compiler optimizes it also obfuscates
   * (but not external objects like those that come back via ajax calls-- like the
   * data object) therefore using dot notation may cause it to not be able to access
   * the property.
   */

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
  this.field_height_ = parseFloat(data['field']['size']['height']);

  /**
   * The width of the field the html is being shown in.
   * @type {number}
   * @private
   */
  this.field_width_ = parseFloat(data['field']['size']['width']);

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


/**
 * The logger for this class.
 * @type {goog.debug.Logger}
 * @private
 */
concerto.frontend.Content.HtmlText.prototype.logger_ = goog.debug.Logger.getLogger(
    'concerto.frontend.Content.HtmlText');

