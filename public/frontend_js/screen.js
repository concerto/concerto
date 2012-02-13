goog.require('concerto.frontend.template');
goog.require('goog.net.XhrIo');
goog.require('goog.net.XhrManager');

goog.provide('concerto.frontend.screen');



/**
 * Screen Frontend.
 * @param {number} screen_id Screen ID number.
 * @constructor
 */
concerto.frontend.Screen = function(screen_id) {
  this.connection = new goog.net.XhrManager(2, null, 0, 2);
  this.id = screen_id;
  this.name = 'New Screen';

  this.setup();
};


/**
 * Configuration URL.
 * A temporary method to build the URL used for downloading
 * the screen setup data.
 * @return {string} Screen setup URL.
 */
concerto.frontend.Screen.prototype.config_url = function() {
  var url = ['/frontend/', this.id, '/setup.json'];
  return url.join('');
};


/**
 * Setup the screen.
 * Download the config, parse it, and start creating the template.
 */
concerto.frontend.Screen.prototype.setup = function() {
  var url = this.config_url();
  this.connection.send('setup', url, 'GET', '', null, 1, goog.bind(function(e) {
    var xhr = e.target;
    var obj = xhr.getResponseJson();

    this.name = obj.name;
    if (goog.isDefAndNotNull(obj.template)) {
      this.template = new concerto.frontend.Template();
      this.template.load(obj.template);
    }
  }, this));
};
