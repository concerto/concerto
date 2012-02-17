goog.require('concerto.frontend.Field');
goog.require('goog.array');
goog.require('goog.object');
goog.require('goog.style');

goog.provide('concerto.frontend.position');



/**
 * A Position on a Template.
 * @param {!concerto.frontend.Template} template The template
 *   is holding this position.
 * @param {Object=} opt_div The div to use for the position.
 * @constructor
 */
concerto.frontend.Position = function(template, opt_div) {
  this.id = null;
  this.template = template;
  if (!goog.isDefAndNotNull(opt_div)) {
    this.createDiv();
  } else {
    this.div_ = opt_div;
  }
};


/**
 * Create the div to use for the position.
 */
concerto.frontend.Position.prototype.createDiv = function() {
  var div = goog.dom.createDom('div', {'id': this.id, 'class': 'field'});
  goog.style.setStyle(div, 'position', 'absolute');
  goog.style.setStyle(div, 'background-color', 'green');
  this.template.inject(div);
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

  this.field_id = data.field_id;
  this.draw();
  this.setProperties();
  this.field = new concerto.frontend.Field(this, this.field_id);
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


/**
 * Inset a div into the position.
 * We treat the position div as a private variable,
 * so we should avoid touching it outside the position class.
 * @param {!Object} div The think to insert into the position.
 */
concerto.frontend.Position.prototype.inject = function(div) {
  goog.dom.appendChild(this.div_, div);
};


/**
 * Apply the styles and properties to the position.
 * Strip out any LOCKED_STYLES, add in any
 * needed DEFAULT_STYLES, and then append to the
 * current styling information.
 */
concerto.frontend.Position.prototype.setProperties = function() {
  // Set the ID and class.
  var properties = {
    'id': 'position_' + this.id,
    'class': 'field'
  };
  goog.dom.setProperties(this.div_, properties);

  // Load the styles into an map.
  var loaded_styles = goog.style.parseStyleAttribute(this.style);
  // Filter out the locked properties.
  var clean_styles = goog.object.filter(loaded_styles, function(value, key, o) {
    return !goog.array.contains(concerto.frontend.Position.LOCKED_STYLES,
        key.toLowerCase());
  });
  // Add the sanitized user styles on top of the default styles.
  var styles = concerto.frontend.Position.DEFAULT_STYLES;
  goog.object.extend(styles, clean_styles);

  // Apply the styles.
  goog.style.setStyle(this.div_, styles);
};


/**
 * Styles the user may not overwrite.
 * Names should be in lower case.
 * @define {Array.string} Style names.
 */
concerto.frontend.Position.LOCKED_STYLES = [
  'overflow', 'width', 'height', 'top', 'left', 'bottom', 'right'
];


/**
 * Default styles.
 * @define {Object.string, (number|string)} Default style-value mapping.
 */
concerto.frontend.Position.DEFAULT_STYLES = {
  'overflow': 'hidden'
};

