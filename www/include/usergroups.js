var UserGroups = new Class.create();

UserGroups.prototype = {

    initialize: function(textboxid, selectid, url) {
      this.observer = null;
      this.textbox = $(textboxid);
      this.select = $(selectid);
      this.frequency = 0.2;
      this.url = url;
      this.selected = null;
      this.lastupdate = null;
      this.options = {
        asynchronous: true,
        onComplete: this.onComplete.bind(this)
        };

      Event.observe(this.textbox, 'keypress', this.onKeyPress.bindAsEventListener(this));
      Event.observe(this.textbox, 'change', this.onKeyPress.bindAsEventListener(this));

      this.forceFetchUpdate();
    },

    onKeyPress: function(evt) {
      // Set timeout for update
      if(this.observer) clearTimeout(this.observer);
      this.observer = setTimeout(this.onTimeout.bind(this), this.frequency*1000);
    },

    onTimeout: function() {
      this.fetchUpdate();
    },

    forceFetchUpdate: function() {
      this.lastupdate = null;
      this.fetchUpdate();
    },

    fetchUpdate: function() {
      if (this.lastupdate == this.textbox.value)
       return;
      this.lastupdate = this.textbox.value;

      this.options.parameters = { name: this.textbox.value };
      new Ajax.Request(this.url, this.options);
      if (this.select.selectedIndex) {
        this.selected = this.select.options[this.select.selectedIndex].value;
      }
      this.select.options.length = 0;
      this.select.options[0] = new Option('Loading...','');
    },

    doUpdate: function(text) {
      while (this.select.firstChild) 
      {
        this.select.removeChild(this.select.firstChild);
      }

      var groups = text.split('^');
      for(j = 0; j < groups.length; j++) {
        if (groups[j].length <= 0) continue;
        var group = groups[j].split('+');
        if (group.length < 2) continue;

        var addingTo = null;
        var optGroup = null;

        if (group[0].length > 0) {
          optGroup = document.createElement('OPTGROUP');
          optGroup.label = unescape(group[0]);
          addingTo = optGroup;
        } else {
          addingTo = this.select;
        }
          
        var options = group[1].split(',');
        for(i = 0; i < options.length; i++) {
          if (options[i].length > 0) {
            var option = options[i].split('|');
            if (option.length > 1) {
              var optionEl = document.createElement('OPTION');
              optionEl.text = unescape(option[1]);
              optionEl.value = unescape(option[0]);
              if (optionEl.value == this.selected)
                optionEl.selected = true;
              addingTo.appendChild(optionEl);
            }
          }
        }

        if (optGroup)
          this.select.appendChild(optGroup);
      }
    },

    olddoUpdate: function(text) {
      var options = text.split(',');
      this.select.options.length = 0;
      for(i = 0; i < options.length; i++) {
        if (options[i].length > 0) {
          var option = options[i].split('|');
          if (option.length > 1) {
            this.select.options[this.select.options.length] = new Option(unescape(option[1]), unescape(option[0]));
          }
        }
      }
    },

    onComplete: function(request) {
      this.doUpdate(request.responseText);
    }

};
