goog.provide('concerto.frontend.Position');

goog.require('concerto.frontend.Field');
goog.require('goog.array');
goog.require('goog.debug.Logger');
goog.require('goog.dom');
goog.require('goog.object');
goog.require('goog.style');



/**
 * A Position on a Template.
 *
 * @param {!concerto.frontend.Template} template The template
 *   is holding this position.
 * @param {Element=} opt_div The div to use for the position.
 * @constructor
 */
concerto.frontend.Position = function(template, opt_div) {
  /**
   * Position ID.
   * @type {?number}
   */
  this.id = null;

  /**
   * Template holding the position.
   * @type {!concerto.frontend.Template}
   */
  this.template = template;

  /**
   * Div holding the position
   * @type {!Element}
   * @private
   */
  this.div_ = opt_div || this.createDiv_();
};


/**
 * The logger for this class.
 * @type {goog.debug.Logger}
 * @private
 */
concerto.frontend.Position.prototype.logger_ = goog.debug.Logger.getLogger(
    'concerto.frontend.Position');


/**
 * Create the div to use for the position.
 *
 * @private
 * @return {Element} Div used for holding the position.
 */
concerto.frontend.Position.prototype.createDiv_ = function() {
  var properties = {'id': 'position_' + this.id, 'class': 'position'};
  var div = goog.dom.createDom('div', properties);
  goog.style.setStyle(div, 'position', 'absolute');
  goog.style.setStyle(div, 'background-color', 'green');
  this.template.inject(div);
  return div;
};


/**
 * Setup the position.
 * Load data and use it to setup the position, then draw it.
 *
 * @param {!Object} data The position information.
 */
concerto.frontend.Position.prototype.load = function(data) {
  this.id = data.id;

  /**
   * Bottom %.
   * @type {number}
   * @private
   */
  this.bottom_ = parseFloat(data.bottom);

  /**
   * Left %.
   * @type {number}
   * @private
   */
  this.left_ = parseFloat(data.left);

  /**
   * Right %.
   * @type {number}
   * @private
   */
  this.right_ = parseFloat(data.right);

  /**
   * Top %.
   * @type {number}
   * @private
   */
  this.top_ = parseFloat(data.top);

  /**
   * CSS styling information.
   * @type {string}
   * @private
   */
  this.style_ = data.style;

  /**
   * ID of the field for this position.
   * @type {number}
   */
  this.field_id = data.field_id;

  this.draw();
  this.setProperties();

  /**
   * Field in this position.
   * @type {concerto.frontend.Field}
   */
  this.field = new concerto.frontend.Field(this, this.field_id,
      data.field_contents_path);
};


/**
 * Draw the position.
 * Set the position (top, left) of the div, and
 * set the size of it using the stored data.
 */
concerto.frontend.Position.prototype.draw = function() {
  var left = this.left_ * 100;
  var top = this.top_ * 100;
  goog.style.setPosition(this.div_, left + '%', top + '%');
  var height = (this.bottom_ - this.top_) * 100;
  var width = (this.right_ - this.left_) * 100;
  goog.style.setSize(this.div_, width + '%', height + '%');
};


/**
 * Inset a div into the position.
 * We treat the position div as a private variable,
 * so we should avoid touching it outside the position class.
 *
 * @param {Element} div The thing to insert into the position.
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
    'class': 'position'
  };
  goog.dom.setProperties(this.div_, properties);

  // Load the styles into an map.
  var loaded_styles = goog.style.parseStyleAttribute(this.style_);
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
 *
 * @type {Array.<string>} Style names.
 */
concerto.frontend.Position.LOCKED_STYLES = [
  'overflow', 'width', 'height', 'top', 'left', 'bottom', 'right'
];


/**
 * Default styles.
 *
 * @type {Object.<string, (number|string)>} Default style-value mapping.
 */
concerto.frontend.Position.DEFAULT_STYLES = {
  'overflow': 'hidden'
};
