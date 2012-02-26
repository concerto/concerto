goog.provide('concerto.frontend.Content.RandomText');

goog.require('concerto.frontend.Content');
goog.require('goog.text.LoremIpsum');



/**
 * Randome Text from the Lorem Ipsum generator,
 *
 * @param {Object} data Properties for this piece of content.
 * @constructor
 * @extends {concerto.frontend.Content}
 */
concerto.frontend.Content.RandomText = function(data) {
  concerto.frontend.Content.call(this, data);
};
goog.inherits(concerto.frontend.Content.RandomText, concerto.frontend.Content);


/**
 * Load some random text, and wait .5 second.
 * @private
 */
concerto.frontend.Content.RandomText.prototype.load_ = function() {
  var generator = new goog.text.LoremIpsum();
  goog.dom.setTextContent(this.div_, generator.generateParagraph());
  setTimeout(goog.bind(this.finishLoad, this), 500);
};
