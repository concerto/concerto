/* ============================================================
 * bootstrap-dropdown.js v1.4.0
 * http://twitter.github.com/bootstrap/javascript.html#dropdown
 * ============================================================
 * Copyright 2011 Twitter, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ============================================================ */


!function( $ ){

  "use strict"

  /* DROPDOWN PLUGIN DEFINITION
   * ========================== */

  $.fn.dropdown = function ( selector, options ) {
    return this.each(function () {
		
	  	var settings = $.extend( {
				'type': 		'closeEasily'
			}, options)
	  
	  	$(this).delegate(selector || d, 'click', function (e) {
        if (options['type'] == 'closeOnButton') {
					$('a.dropdown-close').on("click", clearMenus)
          var KEYCODE_ESC = 27;
          
          $('html').on("keyup", function(keyEvent) {
            if (keyEvent.keyCode == KEYCODE_ESC) {
              clearMenus()
            }
          })

				}	else {
					$('html').on("click", clearMenus)
				}
				
				var li = $(this).parent('li')
          , isActive = li.hasClass('open')

        clearMenus()
        !isActive && li.toggleClass('open')
        return false
      })
      
    })
  }

  /* APPLY TO STANDARD DROPDOWN ELEMENTS
   * =================================== */

  var d = 'a.menu, .dropdown-toggle'
  
  function clearMenus() {
    $(d).parent('li').removeClass('open')
  }

  $(function () {
    $('body').dropdown( '[data-dropdown] a.menu.auto-close, [data-dropdown] .dropdown-toggle.auto-close', {
  		'type' : 'closeEasily'
  	})
    $('body').dropdown( '[data-dropdown] a.menu.manual-close, [data-dropdown] .dropdown-toggle.manual-close', {
  		'type' : 'closeOnButton'
  	})
  })

}( window.jQuery || window.ender );