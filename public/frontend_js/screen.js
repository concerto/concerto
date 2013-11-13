goog.provide('concerto.frontend.Screen');

goog.require('concerto.frontend.Template');
goog.require('goog.debug.FancyWindow');
goog.require('goog.debug.Logger');
goog.require('goog.dom');
goog.require('goog.net.XhrManager');
goog.require('goog.style');



/**
 * Screen Frontend.
 *
 * @param {number} screen_id Screen ID number.
 * @param {Element=} opt_div Optional load to put the screen in.  Defaults
 *   to document.body, so the screen will take over the entire body.
 * @param {concerto.frontend.ScreenOptions} screen_options Options to set for
 *   the screen.
 * @constructor
 */
concerto.frontend.Screen = function(screen_id, opt_div, screen_options) {
  /**
   * Manages connections to the backend server.
   * @type {!goog.net.XhrManager}
   */
  this.connection = new goog.net.XhrManager(2, null, 0, 2);

  /**
   * Screen ID number.
   * @type {number}
   */
  this.id = screen_id;

  /**
   * URL with setup info for this screen.
   * @type {string}
   */
  this.setup_url = screen_options.setupPath;

  /**
   * Screen name.
   * @type {string}
   */
  this.name = 'New Screen';

  /**
   * Element containing the screen.
   * @type {!Element}
   * @private
   */
  this.container_ = opt_div || document.body;

  this.setup();
};
goog.exportSymbol('concerto.frontend.Screen', concerto.frontend.Screen);


/**
 * The logger for this class.
 * @type {goog.debug.Logger}
 * @private
 */
concerto.frontend.Screen.prototype.logger_ = goog.debug.Logger.getLogger(
    'concerto.frontend.Screen');


/**
 * Setup the screen.
 * Download the config, parse it, and start creating the template.
 */
concerto.frontend.Screen.prototype.setup = function() {
  var properties = {'id': 'screen_' + this.id, 'class': 'screen'};
  var div = goog.dom.createDom('div', properties);
  goog.style.setSize(div, '100%', '100%');
  goog.style.setStyle(div, 'position', 'relative');
  goog.dom.removeChildren(this.container_);
  goog.dom.appendChild(this.container_, div);
  this.div_ = div;

  var url = this.setup_url;
  this.logger_.info('Requesting screen config from ' + url);
  this.connection.send('setup', url, 'GET', '', null, 1, goog.bind(function(e) {
    var xhr = e.target;
    var data = xhr.getResponseJson();

    this.name = data['name'];
    if (goog.isDefAndNotNull(data['template'])) {
      this.template = new concerto.frontend.Template(this);
      this.template.load(data['template']);
    }
  }, this));
};


/**
 * Insert the something into the screen.
 *
 * @param {Element} div The thing to insert into the screen.
 */
concerto.frontend.Screen.prototype.inject = function(div) {
  goog.dom.appendChild(this.div_, div);
};
