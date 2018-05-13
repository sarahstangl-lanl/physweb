var DirectoryAddLookup = new Class.create();

function $defined(obj){
        return (obj != undefined);
};

DirectoryAddLookup.prototype = {

    initialize: function(textboxid, statusboxid, url) {
      this.observer = null;
      this.textbox = $(textboxid);
      this.statusbox = $(statusboxid);
      this.frequency = 0.4;
      this.url = url;
      this.lastupdate = null;
      this.fields = new Array("x500", "emplid", "first_name", "last_name", "ucard", "dw_position", "email");
      this.minlength = 2;
      this.existingurl = null;
      this.options = {
        asynchronous: true,
        onComplete: this.onLookupComplete.bind(this)
      };

      Event.observe(this.textbox, 'keypress', this.onKeyPress.bindAsEventListener(this));
      Event.observe(this.textbox, 'change', this.onKeyPress.bindAsEventListener(this));

      // Reset the form state and then do a lookup in case there is already a value
      // (Like if the field has a value and then the page is reloaded)
      this.clearFields();
      this.forceFetchUpdate();
    },

    /*
     * Handle input lookup (Internet ID/Student ID) keypress
     */
    onKeyPress: function(evt) {
      // Wait for the user to finish typing before we lookup
      // (so we don't lookup with each keypress)
      if (this.observer) clearTimeout(this.observer);
      this.observer = setTimeout(this.onTimeout.bind(this), this.frequency*1000);
    },

    /*
     * KeyPress timeout has triggered... do the lookup
     */
    onTimeout: function() {
      this.fetchUpdate();
    },

    /*
     * Force a lookup even if the value hasn't changed from the last lookup
     */
    forceFetchUpdate: function() {
      this.lastupdate = null;
      this.fetchUpdate();
    },

    /*
     * Start a lookup on the entered value
     */
    fetchUpdate: function() {
      if (this.lastupdate == this.textbox.value)
        return;

      this.lastupdate = this.textbox.value;

      if (this.textbox.value.length < this.minlength) {
        this.clearFields();
        return;
      }

      this.options.parameters = { search: this.textbox.value };
      new Ajax.Request(this.url, this.options);
      this.statusbox.innerHTML = '<img src="/images/ajax-loader.gif"> Looking Up...';
    },

    /*
     * Handle a successful lookup (update the page)
     */
    doUpdate: function(values) {
      if ($defined(values['err'])) {
        // There was an error
        this.statusbox.style.textAlign = 'left';
        this.statusbox.innerHTML = "<pre>" + values['err'] + "</pre>";
      }
      else if ($defined(values['found'])) {
        // The user was found somewhere
        if (values['found'] == 'directory') {
          // This user is already in the directory. Display a link to the directory entry.

          this.statusbox.innerHTML = 'This user already exists in the directory';
          try {
            $('h2_existinguser').show();
            $('h2_newuser').hide();
            $('div_newuser').hide();
            $('div_existinguser').show();
            $('span_existingname').innerHTML = values['first_name'] + " " + values['last_name'];
            if (!$defined(this.existingurl)) {
              this.existingurl = $('a_existingname').href;
            }
            $('a_existingname').href = this.existingurl.sub('#UID#', values['uid'])
                                                       .sub('#EMPLID#', values['emplid'])
                                                       .sub('#X500#', values['x500']);
          } catch (e) {}
        } else {
          // This user was found in peoplesoft. Fill the form with the info we found.

          this.statusbox.innerHTML = 'Match found in PeopleSoft';
          try {
            $('h2_existinguser').hide();
            $('h2_newuser').show();
            $('div_newuser').show();
            $('div_existinguser').hide();
          } catch (e) {}

          this.fields.each(function (name) {
            try {
              if (values[name]) {
                $('autodir_' + name).value = values[name];
              } else {
                $('autodir_' + name).value = '';
              }
            } catch (e) {}
          });
        }
      }
    },

    /*
     * Reset the form to the state where it is waiting for a user to lookup
     */
    clearFields: function(label) {
      this.statusbox.innerHTML = ($defined(label) ? label : 'Enter Employee ID or X.500 to lookup');
      $('h2_existinguser').hide();
      $('h2_newuser').show();
      $('div_newuser').show();
      $('div_existinguser').hide();
      this.textbox.enable();
      this.fields.each(function (name) {
        try {
          $('autodir_' + name).value = '';
        } catch (e) {}
      });
    },

    /*
     * AJAX Callback
     */
    onLookupComplete: function(request) {
      try {
        json = request.responseText.evalJSON();
        this.doUpdate(json);
      } catch (e) {
        this.clearFields('No match found');
      }
    }

};
