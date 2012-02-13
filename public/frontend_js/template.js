goog.require('concerto.frontend.position');
goog.require('goog.array');
goog.require('goog.dom');
goog.require('goog.style');

goog.provide('concerto.frontend.template');



/**
 * Screen Template.
 * The template being shown on the screen.
 * @param {=Object} div Div to hold template.
 *   will be created if needed.
 * @constructor
 */
concerto.frontend.Template = function(div) {
  this.id = null;
  this.positions = [];
  if (!goog.isDefAndNotNull(div)) {
    this.createDiv();
  } else {
    this.div_ = div;
  }
};


/**
 * Create the template div.
 * Create a default div to hold the template, and set it to
 * take up the full document body.
 */
concerto.frontend.Template.prototype.createDiv = function() {
  var div = goog.dom.createDom('div');
  goog.style.setSize(div, '100%', '100%');
  goog.style.setStyle(div, 'background-color', 'blue');
  goog.dom.appendChild(document.body, div);
  this.div_ = div;
};


/**
 * Load the template.
 * Build a template using an object with information about it.
 * This data will get passed on to create positions.
 * @param {!Object} data The template data.
 */
concerto.frontend.Template.prototype.load = function(data) {
  this.id = data.id;
  if (goog.isDefAndNotNull(data.positions)) {
    goog.array.forEach(data.positions, goog.bind(function(position_data) {
      var position = new concerto.frontend.Position(this);
      position.load(position_data);
      goog.array.insert(this.positions, position);
    }, this));
  }
};


concerto.frontend.Template.prototype.getDiv = function() { return this.div_; };
