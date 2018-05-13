/**
 * Gee, thanks phpMyAdmin!
 * enables highlight and marking of rows in data tables
 *
 * (?)            -- Changed to work for grids of checkboxes
 * (Aug 26, 2008) -- Changed to use prototype selector magic
 *                   so only rows under .rowmagic are affected
 *
 */

/**
 * This array is used to remember mark status of data in browse mode
 */
var marked_data = new Array;


function PMA_markRowsInit() {
    // for every table row contained in .rowmagic ...
    $$('.rowmagic tr').each(function (el) {
	// ... with the class 'odd' or 'even' ...
	if ( 'odd' != el.className.substr(0,3) && 'even' != el.className.substr(0,4) && 'magic' != el.className.substr(0,5) ) {
	    return;
	}

	// Do not set click events if not wanted
	if (el.className.search(/noclick/) != -1) {
	    return;
	}
	el.select('td,th').each(function (cell) {
	  // ... add event listeners ...
	  // ... to highlight the row on mouseover ...
	  if ( navigator.appName == 'Microsoft Internet Explorer' ) {
	    // but only for IE, other browsers are handled by :hover in css
	    cell.onmouseover = function() {
		this.className += ' hover';
	    }
	    cell.onmouseout = function() {
		this.className = this.className.replace( ' hover', '' );
	    }
	  }

	    // ... and to mark the box on click ...
	    cell.onmousedown = function() {
		var unique_id;
		var checkbox;

		checkbox = el.getElementsByTagName( 'input' )[0];
		if ( checkbox && checkbox.type == 'checkbox') {
		    unique_id = checkbox.name + checkbox.value;
		} else if ( this.id.length > 0 ) {
		    unique_id = this.id;
		} else {
		    return true;
		}

		if ( typeof(marked_data[unique_id]) == 'undefined' ) {
		    marked_data[unique_id] = checkbox.checked;
		}

		if ( typeof(marked_data[unique_id]) == 'undefined' || !marked_data[unique_id] ) {
		    marked_data[unique_id] = true;
		} else {
		    marked_data[unique_id] = false;
		}

		if ( marked_data[unique_id] ) {
		    this.className += ' marked';
		} else {
		    this.className = this.className.replace('marked', '');
		}

		if ( checkbox && checkbox.disabled == false ) {
                    var changed = checkbox.checked != marked_data[unique_id];
		    checkbox.checked = marked_data[unique_id];
                    if (changed && document.createEvent) {
                      try {
                        var evt = document.createEvent("HTMLEvents");
                        evt.initEvent('change', true, false);
                        checkbox.dispatchEvent(evt);
                      } catch (err) {}
                    }
		}
	    }

	    // ... and disable label ...
	    var labeltag = cell.getElementsByTagName('label')[0];
	    if ( labeltag ) {
		labeltag.onclick = function() {
		    return false;
		}
	    }
	    // .. and checkbox clicks
	    var checkbox = cell.getElementsByTagName('input')[0];
	    if ( checkbox ) {
		checkbox.onclick = function() {
		    // opera does not recognize return false;
		    this.checked = ! this.checked;
		}
	    }
	});
    });
}

function formReset() {
  if (confirm('Are you sure?')) {
  marked_data = new Array;

    $$('.rowmagic tr').each(function (el) {
	// ... with the class 'odd' or 'even' ...
	if ( 'odd' != rows[i].className.substr(0,3) && 'even' != rows[i].className.substr(0,4) && 'magic' != rows[i].className.substr(0,5) ) {
	    return;
	}
	
	el.select('td,th').each(function (cell) {
	    var checkbox = data[j].getElementsByTagName('input')[0];
	    if ( checkbox ) {
		    checkbox.checked = false;
	    }
	});
    });
  }
  return false;
}

Event.observe(window, 'load', PMA_markRowsInit);
