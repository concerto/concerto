goog.require('goog.net.XhrIo');
goog.require('goog.net.XhrManager');
goog.require('concerto.frontend.template');

goog.provide('concerto.frontend.screen');

concerto.frontend.Screen = function(screen_id) {
  this.connection =  new goog.net.XhrManager(2, null, 0, 2);
  this.id = screen_id;
  this.name = "New Screen";

  this.setup();
};


concerto.frontend.Screen.prototype.config_url = function() {
  var url = ['/frontend/', this.id, '/setup.json'];
  return url.join('');
};

concerto.frontend.Screen.prototype.setup = function() {
  var url = this.config_url();
  this.connection.send('setup', url, 'GET', '', null, 1, goog.bind(function(e) {
      var xhr = e.target;
      var obj = xhr.getResponseJson();

      this.name = obj.name;
      if(goog.isDefAndNotNull(obj.template)){
        this.template = new concerto.frontend.Template();
        this.template.load(obj.template);
      }
  }, this));
};
