goog.require('goog.style');

goog.provide('concerto.frontend.position');

concerto.frontend.Position = function(template, div){
  this.id = null;
  this.template = template;
  if (!goog.isDefAndNotNull(div)){
    this.createDiv();
  } else {
    this.div_ = div;
  }
};

concerto.frontend.Position.prototype.createDiv = function(){
  var div = goog.dom.createDom('div');
  goog.style.setStyle(div, 'position', 'absolute');
  goog.style.setStyle(div, 'background-color', 'green');
  goog.dom.appendChild(this.template.getDiv(), div);
  this.div_ = div;
};

concerto.frontend.Position.prototype.load = function(data){
  this.id = data.id;
  this.bottom = parseFloat(data.bottom);
  this.left = parseFloat(data.left);
  this.right = parseFloat(data.right);
  this.top = parseFloat(data.top);
  this.style = data.style;

  this.draw();
};

concerto.frontend.Position.prototype.draw = function(){
  goog.style.setPosition(this.div_, (this.left*100) + '%', (this.top*100) + '%');
  var height = this.bottom - this.top;
  var width = this.right - this.left;
  goog.style.setSize(this.div_, (width*100) + '%', (height*100) + '%');
};
