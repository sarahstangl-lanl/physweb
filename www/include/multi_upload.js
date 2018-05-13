/**
 * Multiple file upload element
 * + ASYNC iFrame Uploads!
 *   Originally based on
 *   Stickman's mootools version - http://the-stickman.com
 */

function $defined(obj){
    return (obj != undefined);
};

var MultiUpload = new Class.create();

MultiUpload.prototype = {

    /**
     * Constructor
     * @param    HTMLInputElement    input_element        The file input element
     * @param    int            max            [Optional] Max number of elements (default = 0 = unlimited)
     * @param    HTMLFormElement     form_name           [Optional] Encapsulating form to remove
     * @param    string            name_suffix_template    [Optional] Template for appending to file name. Use {id} to insert row number (default = '_{id}')
     * @param    boolean            show_filename_only    [Optional] Whether to strip path info from file name when displaying in list (default = false)
     * @param    boolean            remove_empty_element    [Optional] Whether or not to remove the (empty) 'extra' element when the form is submitted (default = true)
     */
    initialize:function(input_element, args) {

        // Sanity check -- make sure it is a file input element
        if( !( $(input_element).tagName == 'INPUT' && $(input_element).type == 'file' ) ){
            alert( 'Error: not a file input element' );
            return;
        }

        // List of elements
        this.elements = [];
        // Lookup for row ID => array ID
        this.uid_lookup = {};
        // Current row ID
        this.uid = 0;
        // Are we uploading
        this.uploading = false;

        // File State Constants
        this.STATE_WAITING = 0;
        this.STATE_UPLOADING = 1;
        this.STATE_UPLOADED = 2;
        this.STATE_FAILED = 3;
        
        // Build options from defaults and what was passed in
        this.options = Object.extend({
        	allowDebug: false,
        	debug: false,
        	
            // URL to submit to
            // [optional]
        	action: '?',
        	
            // Maximum number of selected files (default = 0, ie. no limit)
            // [optional]
        	max: 0,
        	
            // Template for adding id to file name
            // [optional]
        	name_suffix_template: '_{id}',
        	
            // Show only filename (remove path)
            // [optional]
        	show_filename_only: false,
        	
            // Remove empty element before submitting form
            // [optional]
        	remove_empty_element: false,
        	
            // Show upload list
            // [optional]
        	showUploadList: true,
        	
            // Callbacks
            // [optional]
        	onAdd: undefined,
        	onDelete: undefined,
        	onUploadStart: undefined,
        	onUploadComplete: undefined,
		onUploadFail: undefined
        	
        }, args || {});


        // Attempt to make the action suitable for appending a
        // uid=# later on...
        if (this.options.action.indexOf('?') == -1)
        {
        	this.options.action += '?';
        } else {
        	if ((this.options.action.substring(this.options.action.length - 1) != '?') &&
        			(this.options.action.substring(this.options.action.length - 1) != '&'))
        		this.options.action += '&';
        }

        
        // remove the form around everything to allow individual submits
        if ($defined(this.options.form_name))
        {
            var form_name = $(this.options.form_name);
            form_name.replace(form_name.innerHTML);
        }

        // Add element methods
        input_element = $(input_element);

        // Wrap it in an individual form field
        var form = new Element(
                'form',
                {
                    'action':'test.html',
                    'method':'POST',
                    'style':'display: inline;'
                }
            );

        input_element.insert({ after: form });
        form.insert({ bottom: input_element.remove() });

        // Base name for input elements
        this.name = input_element.name;
        // Set up element for multi-upload functionality
        this.initializeElement(input_element, form);

        // Files list
        this.container = new Element(
            'div',
            {
                'class':'multiupload'
            }
        );

        if (this.options.showUploadList) {
            this.list = new Element(
                'div',
                {
                	'class':'list'
                }
            );
        }

        // Insert elements
        form.insert({ after: this.container });
        this.container.insert({ bottom: form });
        if (this.options.showUploadList)
            this.container.insert({ bottom: this.list });
        
        // Add debugging toggle link if requested
        // XXX currently broken due to the remove iframe on upload fix
        if (this.options.allowDebug) {
	        this.toggleDebugging = new Element('small');
	        this.toggleDebugging.innerHTML = '&nbsp;[<a href="#">Toggle Debugging</a>]';
	        this.toggleDebugging.observe('click', function (e) {
	        	this.debug.toggle();
	        }.bindAsEventListener(this));
        
        	//this.container.insert({ bottom: this.toggleDebugging });
        }
        
        // Causes the 'extra' (empty) element not to be submitted
        if (this.options.remove_empty_element){
            Event.observe(
                input_element.form,
                'submit',function(e){
                    this.elements.last().element.disabled = true;
                }.bindAsEventListener(this)
            );
        }
    },
    
    toggleDebugging: function() {
    	this.options.debug = !this.options.debug;
    	if (this.debugging && this.iframe) {
    		this.iframe.show();
    	} else if (this.iframe) {
    		this.iframe.hide();
    	}
    	
    },
    
    /**
     * Create Iframe for POSTing the image
     */
    createIframe: function() {
        // blank.html is needed for... wait for it... IE!!!
        // otherwise it tries to load http:// something, and warns about unsecure content. FFS!
        this.iframe = new Element
        (
            'iframe',
            {
                'name':'multi_upload_iframe',
                'src':'/include/blank.html',
                'style':(!this.options.debug ? 'display: none;' : '')
            }
        );
        
        this.container.insert({ bottom: this.iframe });
        
        return this.iframe;
    },
    
    /**
     * Removes the iframe (necessary to prevent it from messing with the history/reloading with the page)
     */
    removeIframe: function() {
    	if (!this.iframe)
    		return;
    	
    	this.iframe.remove();
    	this.iframe = null;
    },

    /**
     * Start a file upload
     */
    uploadStart: function(uid)
    {
        var row = this.elements[ this.uid_lookup[ uid ] ];

        if (row.uploaded || this.uploading || !$defined(row.ready) || !row.ready)
        {
            return;
        }

        this.uploading = true;
        this.state = this.STATE_UPLOADING;
    
        row.form_element.action = this.options.action + 'uid=' + uid;
        row.form_element.method = 'POST';
        row.form_element.encoding = 'multipart/form-data';
        row.form_element.target = 'multi_upload_iframe';

        // We are notified of upload complete via js in the loaded iframe doc

        this.createIframe();
        row.form_element.submit();

        try {
            if (this.options.onUploadStart)
            	this.options.onUploadStart({ upload_id: uid });
        } catch (e) {}
    },

    /**
     * Triggered when an upload completes by JS in the iframe
     */
    uploadComplete: function(uid)
    {
        row = this.elements[this.uid_lookup[uid]];
        if (!$defined(row))
            return;

        row.uploaded = true;
        this.uploading = false;
        this.state = this.STATE_UPLOADED;

        if ($defined(row.status_span))
        {
            row.status_span.update('&nbsp;[Done]');
        }

        if ($defined(row.action_span))
        {
            row.action_span.update('+');
        }

        try {
            if (this.options.onUploadComplete)
            	this.options.onUploadComplete({ upload_id: uid });
        } catch (e) {}

        
        this.removeIframe();
        this.uploadStart(uid+1);
    },

    /**
     * Triggered when an upload fails
     */
    uploadFail: function(uid)
    {
        row = this.elements[this.uid_lookup[uid]];
        if (!$defined(row))
            return;

        row.uploaded = true;
        this.uploading = false;
        this.state = this.STATE_FAILED;

        if ($defined(row.status_span))
            row.status_span.update('&nbsp;[Failed]');

        if ($defined(row.action_span))
            row.action_span.update('+');

        try {
            if (this.options.onUploadFail)
            this.options.onUploadFail({ upload_id: uid });
        } catch (e) {}

        
        this.removeIframe();
        this.uploadStart(uid+1);
    },
    
    /**
     * Called when a file is selected
     */
    addRow:function(){
        if (this.options.max == 0 || this.elements.length <= this.options.max) {
            current_element = this.elements.last();

            // Create new row in files list
            var name = current_element.element.value;
            // Extract file name?
            if( this.options.show_filename_only ){
                if( name.indexOf( '\\' ) != -1 ){
                    name = name.substring(name.lastIndexOf('\\') + 1);
                }
                if( name.indexOf( '/' ) != -1 ){
                    name = name.substring(name.lastIndexOf( '/') + 1);
                }
            }
            var item = new Element(
                'span'
            ).update(name);
            var status = new Element(
                'span'
            ).update('&nbsp;[Waiting]');


            var delete_button = new Element(
                'img',
                {
                    'src':'/images/cross_small.gif',
                    'alt':'Delete',
                    'title':'Delete'
                }
            );
            delete_button.observe(
                'click',
                function( e, uid ){
                    this.confirmDeleteRow( uid );
                }.bindAsEventListener( this, current_element.uid )
            );
            var delete_span = new Element(
                'span'
            ).insert({ bottom: delete_button });

            var row_element = new Element(
                'div',
                {
                    'class': 'item'
                })
	            .insert({ bottom: delete_span })
	            .insert({ bottom: item })
	            .insert({ bottom: status });
            if (this.options.showUploadList) {
                this.list.insert({ bottom: row_element });
                current_element.row = row_element;
            }
            current_element.action_span = delete_span;
            current_element.status_span = status;
            current_element.ready = true;
    
            
            // Wrap it in an individual form field
            var form = new Element(
                'form',
                {
                    'action': 'test.html',
                    'method': 'POST'
                }
            );

            // Create new file input element
            var new_input = new Element
            (
                'input',
                {
                    'type': 'file',
                    'disabled': (this.elements.length == this.options.max) ? true : false
                }
            );
            // Apply multi-upload functionality to new element
            this.initializeElement(new_input, form);

            // Add new element to page
            current_element.element.style.position = 'absolute';
            current_element.element.style.left = '-1000px';
            form.insert({ bottom: new_input });
            current_element.form_element.insert({ after: form });

            try {
                if (this.options.onAdd)
                this.options.onAdd({ upload_id: current_element.uid });
            } catch (e) {}

            this.uploadStart(current_element.uid);
        } else {
            alert('You may not upload more than ' + this.options.max + ' files');
        }
        
    },

    /**
     * Called when the delete button of a row is clicked
     */
    confirmDeleteRow: function(uid) {
        deleted_row = this.elements[this.uid_lookup[uid]];
        if (confirm('Are you sure you want to remove the item\r\n' +  deleted_row.element.value + '\r\nfrom the upload queue?')){
        	this.deleteRow(uid);
        	return true;
        }
        return false;
    },

    /**
     * Remove a row from the upload list
     */
    deleteRow: function(uid) {
        deleted_row = this.elements[ this.uid_lookup[ uid ] ];
        this.elements.last().element.disabled = false;
        deleted_row.form_element.remove();
        if (this.options.showUploadList)
            deleted_row.row.remove();
        // Get rid of this row in the elements list
        delete(this.elements[this.uid_lookup[uid]]);

        try {
            if (this.options.onDelete)
            	this.options.onDelete({ upload_id: uid });
        } catch (e) {}
        
        // Rewrite IDs
        var new_elements = [];
        this.uid_lookup = {};
        for (var i = 0; i < this.elements.length; i++){
            if ($defined(this.elements[i])) {
                this.elements[i].element.name = this.name + this.options.name_suffix_template.replace(/\{id\}/, new_elements.length);
                this.uid_lookup[this.elements[i].uid] = new_elements.length;
                new_elements.push(this.elements[i]);
            }
        }
        this.elements = new_elements;
    },

    /**
     * Apply multi-upload functionality to an element
     *
     * @param        HTTPFileInputElement        element        The element
     */
    initializeElement: function (element, form_element) {
        // What happens when a file is selected
        Event.observe(
            element,
            'change',
            function(){
                this.addRow()
            }.bindAsEventListener(this)
        );
        
        // Set the name
        element.name = this.name + this.options.name_suffix_template.replace(/\{id\}/, this.elements.length);

        // Store it for later
        this.uid_lookup[this.uid] = this.elements.length;
        this.elements.push({ 'uid':this.uid, 'element':element, 'form_element':form_element, 'state':this.STATE_WAITING, 'uploaded':false, 'ready':false });
        this.uid++;
    }
};
