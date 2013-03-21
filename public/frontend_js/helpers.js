goog.provide('concerto.frontend.Helpers');

goog.require('goog.style');


/**
 * Set the font size on an element to maximize space usage.
 *
 * @param {Element} dom Element that needs to be resize.
 * @param {number} width Width to fit into.
 * @param {number} height Height to fit into.
 * @return {Element} Element with updated fontSize.
 */
concerto.frontend.Helpers.Autofit = function(dom, width, height) {
  var target_size = new goog.math.Size(width, height);

  var font_size = 100;
  var temp_dom = dom.cloneNode(true);
  goog.style.showElement(temp_dom, false);
  document.body.appendChild(temp_dom);
  goog.style.setStyle(temp_dom, 'fontSize', font_size + 'px');
  while (font_size > 1 &&
         !goog.style.getSize(temp_dom).fitsInside(target_size)) {
    goog.style.setStyle(temp_dom, 'fontSize', --font_size + 'px');
  }
  document.body.removeChild(temp_dom);
  delete temp_dom;

  goog.style.setStyle(dom, 'fontSize', font_size + 'px');
  return dom;
};
