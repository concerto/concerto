goog.require('concerto.frontend.template');
goog.require('goog.net.XhrIo');
goog.require('goog.net.XhrManager');

goog.provide('concerto.frontend.screen');



/**
 * Screen Frontend.
 * @param {number} screen_id Screen ID number.
 * @param {Object=} opt_div Optional load to put the screen in.  Defaults
 *   to document.body, so the screen will take over the entire body.
 * @constructor
 */
concerto.frontend.Screen = function(screen_id, opt_div) {
  this.connection = new goog.net.XhrManager(2, null, 0, 2);
  this.id = screen_id;
  this.name = 'New Screen';

  if (goog.isDefAndNotNull(opt_div)) {
    this.container_ = opt_div;
  } else {
    this.container_ = document.body;
  }

  this.setup();
};


/**
 * Configuration URL.
 * A temporary method to build the URL used for downloading
 * the screen setup data.
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
 * @param {!Object} div The thing to insert into the screen.
 */
concerto.frontend.Screen.prototype.inject = function(div) {
  goog.dom.appendChild(this.div_, div);
};

