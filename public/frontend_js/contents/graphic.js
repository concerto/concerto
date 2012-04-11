goog.provide('concerto.frontend.Content.Graphic');

goog.require('concerto.frontend.Content');
goog.require('goog.Uri');
goog.require('goog.events.EventType');
goog.require('goog.net.ImageLoader');



/**
 * Graphic.
 *
 * @param {Object} data Properties for this piece of content.
 * @constructor
 * @extends {concerto.frontend.Content}
 */
concerto.frontend.Content.Graphic = function(data) {
  concerto.frontend.Content.call(this, data);

  /**
   * The image loader, so we don't load an image that isn't ready.
   * @type {goog.net.ImageLoader}
   * @private
   */
  this.loader_ = new goog.net.ImageLoader();
  goog.events.listen(this.loader_, goog.events.EventType.LOAD,
      this.loaderFinish_, false, this);

  /**
   * The height of the field the image is being shown in.
   * @type {number}
   * @private
   */
  this.field_height_ = data.field.size.height;

  /**
   * The width of the field the image is being shown in.
   * @type {number}
   * @private
   */
  this.field_width_ = data.field.size.width;

  var image_url = new goog.Uri(data.render_details.path);
  image_url.setParameterValue('height', this.field_height_);
  image_url.setParameterValue('width', this.field_width_);

  this.loader_.addImage('graphic', image_url.toString());
};
goog.inherits(concerto.frontend.Content.Graphic, concerto.frontend.Content);


/**
 * Load the image and get ready for the complete event.
 * @private
 */
concerto.frontend.Content.Graphic.prototype.load_ = function() {
  this.loader_.start();
};


/**
 * Called when the image finishes loading.
 * Put some margin on the div to center the image before showing it.
 * @param {goog.events.EventType} e The finish event.
 * @private
 */
concerto.frontend.Content.Graphic.prototype.loaderFinish_ = function(e) {
  var image = e.target;
  goog.dom.appendChild(this.div_, image);

  var side_margin = (this.field_width_ - image.width) / 2;
  var top_margin = (this.field_height_ - image.height) / 2;
  goog.style.setStyle(this.div_, 'margin',
      top_margin + 'px ' + side_margin + 'px');
  this.finishLoad();
};
