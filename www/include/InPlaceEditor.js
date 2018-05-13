/**
 * InPlaceEditor
 * 
 * Based, in part, off of http://yura.thinkweb2.com/playground/in-place-select/
 */

var InPlaceEditor = Class.create({
	initialize: function(id, url, args) {
		this.config = Object.extend({
	        parameters: {},
	        
	    }, args || { });
		
		this.url = url;
        this.ajaxoptions = {
        	method: 'post',
        	asynchronous: true,
	    	onSuccess: this.onAjaxSuccess.bind(this),
	    	onFailure: this.onAjaxFailure.bind(this)
        };

		// Replace the innertext with a span (so we can style the text alone)
		this.container = $(id);
	    this.viewingContainer = new Element('span');
	    this.viewingContainer.innerHTML = this.container.innerHTML;
	    this.container.innerHTML = '';
	    this.container.appendChild(this.viewingContainer);
	    
	    this.active = false;
	    this.currentValue = this.viewingContainer.innerHTML;
	    
	    this.viewingContainer.addClassName('inplaceeditable');
	    this.viewingContainer.addClassName('inplaceeditables');
	    if (!this.currentValue) {
	    	this.viewingContainer.addClassName('inplaceeditable-empty');
	    	this.viewingContainer.innerHTML = 'none';
	    }
	     
	    this.container.observe('click', this.onClick.bindAsEventListener(this));
	},
	
	startEditing: function() {
		if (this.active) { return; }
		
		this.active = true;

		this.editingInput = new Element('input', {type: 'input', value: this.currentValue});
		this.editingInput.style.border = '1px solid black';
		if (window.getComputedStyle) {
			// This does not work on IE. I don't care.
			var inWidth = window.getComputedStyle(this.container, "").getPropertyValue('width');
			this.container.style.width = inWidth;
		}
		var width = this.container.getWidth() - 30;
		if (width < 40) { width = 40; }
		this.editingInput.style.width = width + 'px';
		this.editingInput.addClassName('inplaceeditables');
		this.viewingContainer.remove();
		
		this.container.appendChild(this.editingInput);
		
		this.editingInput.focus();
		this.editingInput.select();
		
		this.editingInput.observe('keypress', this.onKeypress.bindAsEventListener(this));
		this.editingInput.observe('blur', this.onBlur.bindAsEventListener(this));
	},
	
	removeInput: function() {
		if (this.editingInput) {
			this.editingInput.remove();
			this.editingInput = null;
			this.container.style.width = '';
		}
	},
	
	startSaving: function() {
		this.removeInput();
		
		this.wait = new Element('img', {src: '/images/ajax-loader.gif'});
		this.container.appendChild(this.wait);
	},
	
	stopEditing: function() {
		if (!this.active) { return; }
		
		if (this.wait) {
			this.wait.remove();
			this.wait = null;
		}
		
		this.removeInput();
		
	    if (this.currentValue) {
	    	this.viewingContainer.removeClassName('inplaceeditable-empty');
	    }
	    
	    this.viewingContainer.innerHTML = this.currentValue;
		
		this.container.appendChild(this.viewingContainer);
		
		this.active = false;		
	},
	
	onClick: function(e) {
		this.startEditing();
	},
	
	onBlur: function(e) {		
		if (this.currentValue != this.editingInput.value) {
			this.savingValue = this.editingInput.value;
			
			this.startSaving();
			
			this.ajaxoptions.parameters = this.config.parameters;
			this.ajaxoptions.parameters.oldval = this.currentValue;
			this.ajaxoptions.parameters.newval = this.savingValue;
			
			new Ajax.Request(this.url, this.ajaxoptions);
		} else {
			this.stopEditing();
		}
	},
	
	onKeypress: function(e) {
		// Handle tabbing between inplaceeditable fields
		if (e.keyCode == Event.KEY_TAB) {
			// Get all editables & find ourself
			var tabElements = this.container.up().up().select('.inplaceeditables');
			var currentIndex = tabElements.indexOf(this.editingInput);
			if (currentIndex != -1) {
				// Find next or prev el to tab to based on index +/- 1
				var tabTo = tabElements[currentIndex + (e.shiftKey ? -1 : 1)];
				if (tabTo) { tabTo.simulate('click'); }
			}
			e.stop();
		} else if (e.keyCode == Event.KEY_ESC) {
			// We can't just blur because we do not want to save
			this.stopEditing();
		}
	},
	
	onAjaxSuccess: function(transport) {
		var response;
		try {
			response = transport.responseText.evalJSON();
		} catch (e) { }
		
		if (response && response.result == 'ok') {
			this.currentValue = this.savingValue;
		} else {
			if (response && response.message) {
				alert(response.message);
			} else {
				alert('Failed to update!');
			}
		}
		
		this.stopEditing();
	},
	
	onAjaxFailure: function() {
		alert('Failed to update!');
		
		this.stopEditing();
	},
	
});