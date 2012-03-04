goog.provide('concerto.frontend.Screen');

goog.require('concerto.frontend.Template');
goog.require('goog.debug.Logger');
goog.require('goog.dom');
goog.require('goog.net.XhrIo');
goog.require('goog.net.XhrManager');
goog.require('goog.style');



/**
 * Screen Frontend.
 *
 * @param {number} screen_id Screen ID number.
 * @param {ELement=} opt_div Optional load to put the screen in.  Defaults
 *   to document.body, so the screen will take over the entire body.
 * @constructor
 */
concerto.frontend.Screen = function(screen_id, opt_div) {
  /**
   * Manages connections to the backend server.
   * @type {!goog.new.XhrManager}
   */
  this.connection = new goog.net.XhrManager(2, null, 0, 2);

  /**
   * Screen ID number.
   * @type {number}
   */
  this.id = screen_id;

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
 * Configuration URL.
 * A temporary method to build the URL used for downloading
 * the screen setup data.
 *
 * @return {string} Screen setup URL.
 */
concerto.frontend.Screen.prototype.configUrl = function() {
  var url = ['/frontend/', this.id, '/setup.json'];
  return url.join('');
};


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

  var url = this.configUrl();
  this.logger_.info('Requesting screen config from ' + url);
  this.connection.send('setup', url, 'GET', '', null, 1, goog.bind(function(e) {
    var xhr = e.target;
    var obj = xhr.getResponseJson();

    this.name = obj.name;
    if (goog.isDefAndNotNull(obj.template)) {
      this.template = new concerto.frontend.Template(this);
      this.template.load(obj.template);
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
