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

  /**
   * We are casting the 0 or 1 into true or false with the !!+, do not remove it.
   * This is because we need to negate the variable for our internal code, which
   * was making javascript upset when it had to negate a numeric value.
   */
  var disable_text_autosize = !!+(data['field']['config'] ?
                               data['field']['config']['disable_text_autosize'] : 0);

  var marquee = !!+(data['field']['config'] ?
                               data['field']['config']['marquee'] : 0);
  /**
   * Should the font size be automatically adjusted to optimize
   * display within the field?
   * @type {boolean}
   */
  this.autosize_font = !disable_text_autosize;

  /**
   * Should ticker be displayed as a scrolling marquee
   * @type {boolean}
   * @private
   */
  this.marquee_ = marquee;

  if (this.marquee_) {
    // make sure appropriate css gets applied
    goog.dom.classes.add(this.div_, 'marquee');
    this.autosize_font = false;
  }

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
  this.field_height_ = parseFloat(data['field']['size']['height']);

  /**
   * The width of the field the ticker is being shown in.
   * @type {number}
   * @private
   */
  this.field_width_ = parseFloat(data['field']['size']['width']);

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
  goog.dom.removeChildren(this.div_);
  var frag = null;
  if (this.marquee_) {
    frag = goog.dom.htmlToDocumentFragment(
      '<div class="marquee-bundle">' + this.text + '</div>' +
      '<div class="marquee-bundle">' + this.text + '</div>'
      );
  } else {
    frag = goog.dom.htmlToDocumentFragment('<div>' + this.text + '</div>');
  }

  goog.dom.appendChild(this.div_, frag);

  if (this.marquee_) {
    // override the contents duration so it cycles twice before reloading
    this.duration = this.setScrollDuration_(this.div_) * 2;
  }

  this.finishLoad();
};

/**
 * Set the scroll animation duration based on length of text to scroll.
 * @param {Object} node Element to determine and set speed for.
 * @return {number} duration of animation.
 * @private
 */
concerto.frontend.Content.Ticker.prototype.setScrollDuration_ = function(node) {
  var dur = Math.floor(goog.dom.getNodeTextLength(node) / 14);

  goog.style.setStyle(node, 'webkitAnimationDuration', dur + 's');
  goog.style.setStyle(node, 'mozAnimationDuration', dur + 's');
  goog.style.setStyle(node, 'msAnimationDuration', dur + 's');
  goog.style.setStyle(node, 'animationDuration', dur + 's');

  return dur;
};

/**
 * Extend the default style application.
 * We need to take into account relative positioning for scrolling
 * @extends {concerto.frontend.Content.applyStyles}
 */
concerto.frontend.Content.Ticker.prototype.applyStyles = function(styles) {
  concerto.frontend.Content.Ticker.superClass_.applyStyles.call(this, styles);
  if (this.marquee_) {
    goog.style.setStyle(this.div_, 'position', 'relative');
  }
};
