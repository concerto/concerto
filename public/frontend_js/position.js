goog.provide('concerto.frontend.Position');

goog.require('concerto.frontend.Field');
goog.require('concerto.frontend.Transition');
goog.require('concerto.frontend.Transition.Fade');
goog.require('concerto.frontend.Transition.Slide');
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
  this.id = data['id'];

  /**
   * Bottom %.
   * @type {number}
   * @private
   */
  this.bottom_ = parseFloat(data['bottom']);

  /**
   * Left %.
   * @type {number}
   * @private
   */
  this.left_ = parseFloat(data['left']);

  /**
   * Right %.
   * @type {number}
   * @private
   */
  this.right_ = parseFloat(data['right']);

  /**
   * Top %.
   * @type {number}
   * @private
   */
  this.top_ = parseFloat(data['top']);

  /**
   * CSS styling information.
   * @type {string}
   * @private
   */
  this.style_ = data['style'];

  this.draw();

  var transition = concerto.frontend.Transition.Fade;
  var config = null;
  if (goog.isDefAndNotNull(data['field']['config'])) {
    config = data['field']['config'];
    if (goog.isDefAndNotNull(config['transition'])) {
      switch (config['transition'].toLowerCase()) {
        case 'slide':
          transition = concerto.frontend.Transition.Slide;
          break;
        case 'replace':
          transition = concerto.frontend.Transition;
          break;
        default:
          transition = concerto.frontend.Transition.Fade;
          break;
      }
    }
  }

  /**
   * Field in this position.
   * @type {concerto.frontend.Field}
   */
  this.field = new concerto.frontend.Field(this, data['field']['id'],
    data['field']['name'], data['field_contents_path'], transition, config);

  this.setProperties();
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
 * Get the size of the position.
 * @return {!goog.math.Size} Object with width/height properties.
 */
concerto.frontend.Position.prototype.getSize = function() {
  return goog.style.getSize(this.div_);
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
 * Apply the default styles and properties to the position.
 */
concerto.frontend.Position.prototype.setProperties = function() {
  // Set the ID and class.
  var properties = {
    'id': 'position_' + this.id,
    'class': 'position'
  };
  goog.dom.setProperties(this.div_, properties);

  goog.style.setStyle(this.div_, concerto.frontend.Position.DEFAULT_STYLES);
};


/**
 * Generate the styles that should be applied to content.
 * Strip out any LOCKED_STYLES, add in any
 * needed DEFAULT_CONTENT_STYLES, and then append to the
 * current styling information for this position.
 *
 * @return {Object} Styles to be applied to content.
 */
concerto.frontend.Position.prototype.getContentStyles = function() {
  // Load the styles into an map.
  var loaded_styles = goog.style.parseStyleAttribute(this.style_);
  // Filter out the locked properties.
  var clean_styles = goog.object.filter(loaded_styles, function(value, key, o) {
    return !goog.array.contains(concerto.frontend.Position.LOCKED_STYLES,
        key.toLowerCase());
  });
  // Add the sanitized user styles on top of the default styles.
  // We clone the two different source styles on top of a new one to prevent
  // pulling in a reference to either of them.
  var styles = {};
  goog.object.extend(styles, concerto.frontend.Position.DEFAULT_CONTENT_STYLES);
  goog.object.extend(styles, clean_styles);
  return styles;
};


/**
 * Styles the field may not overwrite.
 * Names should be in lower case.
 *
 * @type {Array.<string>} Style names.
 * @const
 */
concerto.frontend.Position.LOCKED_STYLES = [
  'overflow', 'width', 'height', 'top', 'left', 'bottom', 'right'
];


/**
 * Default styles.
 *
 * @type {Object.<string, (number|string)>} Default style-value mapping.
 * @const
 */
concerto.frontend.Position.DEFAULT_STYLES = {
  'overflow': 'hidden'
};


/**
 * Default content styles.
 *
 * @type {Object.<string, (number|string)>} Default style-value mapping.
 * @const
 */
concerto.frontend.Position.DEFAULT_CONTENT_STYLES = {
  /* slide transition requires absolutely positioned elements */
  'position': 'absolute'
};
