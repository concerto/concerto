goog.provide('concerto.frontend.Content.SampleImage');

goog.require('concerto.frontend.Content');
goog.require('goog.events.EventType');
goog.require('goog.net.ImageLoader');



/**
 * The Concerto Logo.
 *
 * @param {Object} data Properties for this piece of content.
 * @constructor
 * @extends {concerto.frontend.Content}
 */
concerto.frontend.Content.SampleImage = function(data) {
  concerto.frontend.Content.call(this, data);

  /**
   * The image loader, so we don't load an image that isn't ready.
   * @type {goog.net.ImageLoader}
   * @private
   */
  this.loader_ = new goog.net.ImageLoader();
  goog.events.listen(this.loader_, goog.events.EventType.LOAD,
      this.loaderFinish_, false, this);

  var images = [
    'http://farm7.staticflickr.com/6239/6238391413_f853130115_o.jpg',
    'http://www.concerto-signage.org/assets/conclogo_menu.png',
    'http://rpi.edu/graphic4/rpi_logo_tag_lg_22.gif'
  ];
  var image = images[Math.floor(Math.random() * 3)];

  this.loader_.addImage('graphic', image);
};
goog.inherits(concerto.frontend.Content.SampleImage, concerto.frontend.Content);


/**
 * Load the image and get ready for the complete event.
 * @private
 */
concerto.frontend.Content.SampleImage.prototype.load_ = function() {
  this.loader_.start();
};


/**
 * Called when the image finishes loading.
 * @param {goog.events.EventType} e The finish event.
 * @private
 */
concerto.frontend.Content.SampleImage.prototype.loaderFinish_ = function(e) {
  var image = e.target;
  goog.dom.appendChild(this.div_, image);
  this.finishLoad();
};
