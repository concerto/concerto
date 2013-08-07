goog.provide('concerto.frontend.Template');

goog.require('concerto.frontend.Position');
goog.require('goog.Uri');
goog.require('goog.array');
goog.require('goog.debug.Logger');
goog.require('goog.dom');
goog.require('goog.style');



/**
 * Screen Template.
 * The template being shown on the screen.
 *
 * @param {!concerto.frontend.Screen} screen The screen showing this template.
 * @param {Element=} opt_div Div to hold template.
 *   Will be created if needed.
 * @constructor
 */
concerto.frontend.Template = function(screen, opt_div) {
  /**
   * The screen showing this template.
   * @type {!concerto.frontend.Screen}
   */
  this.screen = screen;

  /**
   * The template ID number.
   * @type {?number}
   */
  this.id = null;

  /**
   * The URL to the template.
   * @type {?string}
   */
  this.path = null;

  /**
   * Positions being shown on this template.
   * @type {?Array.<concerto.frontend.Position>}
   */
  this.positions = [];

  /**
   * The div holding the template.
   * @type {Element}
   * @private
   */
  this.div_ = opt_div || this.createDiv_();
};


/**
 * The logger for this class.
 * @type {goog.debug.Logger}
 * @private
 */
concerto.frontend.Template.prototype.logger_ = goog.debug.Logger.getLogger(
    'concerto.frontend.Template');


/**
 * Create the template div.
 * Create a default div to hold the template, and set it to
 * take up the full document body.
 *
 * @private
 * @return {Element} Div used to hold the template.
 */
concerto.frontend.Template.prototype.createDiv_ = function() {
  var div = goog.dom.createDom('div', {'id': 'template', 'class': 'template'});
  goog.style.setSize(div, '100%', '100%');
  this.screen.inject(div);
  return div;
};


/**
 * Load the template.
 * Build a template using an object with information about it.
 * This data will get passed on to create positions.
 *
 * @param {!Object} data The template data.
 */
concerto.frontend.Template.prototype.load = function(data) {
  this.id = data['id'];
  this.path_ = data['path'];
  goog.dom.setProperties(this.div_, {'id': 'template_' + this.id});

  this.render_();

  if (goog.isDefAndNotNull(data['positions'])) {
    goog.array.forEach(data['positions'], goog.bind(function(position_data) {
      var position = new concerto.frontend.Position(this);
      position.load(position_data);
      goog.array.insert(this.positions, position);
    }, this));
  }
};


/**
 * Render the template styles.
 * Set the correect background image and stuff.
 * Does not render the background url if there is no path_.
 *
 * @private
 */
concerto.frontend.Template.prototype.render_ = function() {
  var size = goog.style.getSize(this.div_);

  if (this.path_ != null) {
    var background_url = new goog.Uri(this.path_);
    background_url.setParameterValue('height', size.height);
    background_url.setParameterValue('width', size.width);

    goog.style.setStyle(this.div_, 'background-image',
        'url(' + background_url.toString() + ')');
  }

  goog.style.setStyle(this.div_, 'background-size', '100% 100%');
  goog.style.setStyle(this.div_, 'background-repeat', 'no-repeat');
};


/**
 * Insert a div into the template.
 * We treat the template div as a private variable,
 * so we should avoid touching it outside the Template class.
 *
 * @param {Element} div The thing to insert into the template.
 */
concerto.frontend.Template.prototype.inject = function(div) {
  goog.dom.appendChild(this.div_, div);
};
