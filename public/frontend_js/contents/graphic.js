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

  var image_url = new goog.Uri(data.render_details.path);
  image_url.setParameterValue('height', data.field.size.height);
  image_url.setParameterValue('width', data.field.size.width);

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
 * @param {goog.events.EventType} e The finish event.
 * @private
 */
concerto.frontend.Content.Graphic.prototype.loaderFinish_ = function(e) {
  var image = e.target;
  goog.dom.appendChild(this.div_, image);
  this.finishLoad();
};
