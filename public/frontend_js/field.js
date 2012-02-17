goog.require('goog.dom');
goog.require('goog.style');
goog.require('goog.text.LoremIpsum');

goog.provide('concerto.frontend.Field');



/**
 * A Position's Field.
 * Responsible for rendering the content in a position.
 * @param {!concerto.frontend.Position} position The position that owns this.
 * @param {number} id The field ID number.
 * @constructor
 */
concerto.frontend.Field = function(position, id) {
  this.position = position;
  this.id = id;

  this.createDiv();
  goog.dom.setTextContent(this.div_, this.junkText(4));
};


/**
 * Create a div for the field.
 */
concerto.frontend.Field.prototype.createDiv = function() {
  if (!goog.isDefAndNotNull(this.div_)) {
    var div = goog.dom.createDom('div');
    goog.style.setSize(div, '100%', '100%');
    this.position.inject(div);
    this.div_ = div;
  }
};


/**
 * Generate some filler text.
 * @param {number} length Number of paragraphs.
 * @return {string} Random text.
 */
concerto.frontend.Field.prototype.junkText = function(length) {
  var x = '';
  var generator = new goog.text.LoremIpsum();
  for (var i = 0; i < length; i++) {
    x += generator.generateParagraph();
  }
  return x;
};
