goog.require('goog.style');

goog.provide('concerto.frontend.position');



/**
 * A Position on a Template.
 * @param {!Object} template The concerto.frontend.Template that
 *   is holding this position.
 * @param {?Object} div The div to use for the position.
 * @constructor
 */
concerto.frontend.Position = function(template, div) {
  this.id = null;
  this.template = template;
  if (!goog.isDefAndNotNull(div)) {
    this.createDiv();
  } else {
    this.div_ = div;
  }
};


/**
 * Create the div to use for the position.
 */
concerto.frontend.Position.prototype.createDiv = function() {
  var div = goog.dom.createDom('div');
  goog.style.setStyle(div, 'position', 'absolute');
  goog.style.setStyle(div, 'background-color', 'green');
  goog.dom.appendChild(this.template.getDiv(), div);
  this.div_ = div;
};


/**
 * Setup the position.
 * Load data and use it to setup the position, then draw it.
 * @param {!Object} data The position information.
 */
concerto.frontend.Position.prototype.load = function(data) {
  this.id = data.id;
  this.bottom = parseFloat(data.bottom);
  this.left = parseFloat(data.left);
  this.right = parseFloat(data.right);
  this.top = parseFloat(data.top);
  this.style = data.style;

  this.draw();
};


/**
 * Draw the position.
 * Set the position (top, left) of the div, and
 * set the size of it using the stored data.
 */
concerto.frontend.Position.prototype.draw = function() {
  var left = this.left * 100;
  var top = this.top * 100;
  goog.style.setPosition(this.div_, left + '%', top + '%');
  var height = (this.bottom - this.top) * 100;
  var width = (this.right - this.left) * 100;
  goog.style.setSize(this.div_, width + '%', height + '%');
};
