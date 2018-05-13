/**
* based off of http://remysharp.com/2007/01/25/jquery-tutorial-text-box-hints/
*/

function hintInput(input) {
	input = $(input);
    var title = input.readAttribute('title');
    var form = $(input.form);
    var blurClass = 'hinted';

    function removeHint() {
        input.removeClassName(blurClass);
        if (input.value === title) {
            input.value = '';
        }
    }
    
    function addHint() {
        if (input.value === '') {
            input.value = title;
            input.addClassName(blurClass);
        }
    }

    // only apply logic if the element has the attribute
    if (title) {
        // on blur, set value to title attr if text is blank
        input.observe('blur', addHint);
        input.observe('focus', removeHint);
        addHint();
        
        // clear the pre-defined text when form is submitted
        if (form) {
        	form.observe('submit', removeHint);
        }
        Event.observe(window, 'unload', removeHint); // handles Firefox's autocomplete
    }
}

/*
document.observe('dom:loaded', function () {
    var blurClass = 'blur';
    
    $$('input[type="text"][title]').each(function (input) {
        var title = input.readAttribute('title');
        var form = $(this.form);
        var win = $(window);

        function remove() {
            if (this.value === title && input.hasClassName(blurClass)) {
                input.writeAttribute('value', '');
                input.removeClassName(blurClass);
            }
        }

        // only apply logic if the element has the attribute
        if (title) {
            // on blur, set value to title attr if text is blank
            input.observe('blur', function () {
                if (this.readAttribute('value') === '') {
                    input.writeAttribute('value', title);
                    input.addClassName(blurClass);
                }
            });
            
            input.observe('focus', remove)
            input.blur(); // now change all inputs to title
            
            // clear the pre-defined text when form is submitted
            form.observe('submit', remove);
            win.observe('unload', remove); // handles Firefox's autocomplete
        }
    });
});
*/
