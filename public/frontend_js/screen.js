goog.provide('concerto.frontend.Screen');

goog.require('concerto.frontend.Template');
goog.require('goog.Uri.QueryData');
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
   * Screen Options.
   * @type {concerto.frontend.ScreenOptions}
   */
  this.options = screen_options;

  /**
   * URL with setup info for this screen.
   * @type {string}
   */
  this.setup_url = this.options.setupPath;

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

  /**
   * Hash of current setup information.
   * @type {string}
   * @private
   */
  this.setup_key_ = '';

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
 * Refresh the screen by setting it up again.
 * Called typically when the content indicates a refresh is warranted
 * (due to something like a template needing to be changed).
 */
concerto.frontend.Screen.prototype.refresh = function() {
  // kill the outstanding xhr requests
  requests = this.connection.getOutstandingRequestIds();
  goog.array.forEach(requests, goog.bind(function(request) {
    this.connection.abort(request, true);
  }, this));

  // mark all the fields as invalid (by making their positions null)
  if (this.template) {
    goog.array.forEach(this.template.positions, goog.bind(function(position) {
      position.field.position = null;
    }, this));
  }

  this.setup();
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

  this.setup_key_ = '';

  var params = this.getQueryData();
  var url = this.setup_url + '?' + params.toString();
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


/**
 * Get the URI parameters a screen mandates.
 * These parameters will be included in all HTTP calls that originate from the
 * frontend, not including calls defined in individual content loading requests.
 *
 * @return {goog.Uri.QueryData}
 */
concerto.frontend.Screen.prototype.getQueryData = function() {
  var query_data = new goog.Uri.QueryData();
  if (this.options.isPreview) {
    query_data.add('preview', 'true');
  }
  return query_data;
};


/**
 * Trigger the refreshing the screen if the setup info has changed.
 *
 * @param {string} setup_key A key describing the current setup state.
 * @return {undefined} stops the current processing.
 */
concerto.frontend.Screen.prototype.processSetupKey = function(setup_key) {
  if (this.setup_key_ == '') {
    this.setup_key_ = setup_key;
  }
  if (this.setup_key_ != setup_key) {
    this.logger_.info('Triggering a screen refresh');
    return this.refresh();
  }
};
