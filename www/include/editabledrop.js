/*
Editable Dropdown SHAZAM!
Or something like that.

clayton@physics.umn.edu
*/

  var EditableDrop = new Class.create();

  EditableDrop.prototype = {
    initialize: function(textArea, Entries) {
      options = { textArea: textArea };
      textArea = $(textArea);
      this.textArea = textArea;
      this.doBlur = false;
      this.active = false;
      this.allowUnfocus = false;

      imageName = 'dropdown.gif'; // 17x17 pixels

      // Temporarily make textArea input visible for button position calculations
      origParent = textArea.parentNode;
      origNextSibling = textArea.nextSibling;
      textArea = document.body.appendChild(textArea.remove());
      textAreaDims = textArea.getDimensions();

      imagePos = { top: (textAreaDims.height - 17) / 2 + 1, left: 0 };

      buttonLink = new Element('a', { id: options.textArea + '_magic_button', href: '#' }).setStyle({ padding: '2px' });
      buttonImage = new Element('img', { src: '/images/' + imageName }).setStyle({ border: 0, position: 'relative', top: imagePos.top + 'px', left: imagePos.left + 'px' });
      buttonLink.appendChild(buttonImage);
      listDiv = new Element('div', { id: options.textArea + '_magic_list' }).addClassName('editabledrop').setStyle({ display: 'none', zIndex: 100 });

      // Restore textArea visibility
      textArea = textArea.remove();
      if (origNextSibling)
        origParent.insertBefore(textArea, origNextSibling);
      else
        origParent.appendChild(textArea);

      if (!this.noDropdownButton) {
        textArea.insert({ after: buttonLink });
        this.dropButton = $(options.textArea + '_magic_button');
        this.dropButton.observe('click', this.onClick.bindAsEventListener(this));
      }

      textArea.insert({ after: listDiv });

      this.completionBox = $(options.textArea + '_magic_list');
      this.completer = new Autocompleter.Local(this.textArea, this.completionBox, Entries, {
        choices: 999,
        selector: function(instance) {
          var ret       = []; // Beginning matches
          var partial   = []; // Inside matches
          var entry     = (instance.doAsEmpty ? '' : instance.getToken());
          var count     = 0;

          for (var i = 0; i < instance.options.array.length && ret.length < instance.options.choices ; i++) {

            var elem = instance.options.array[i];
            var foundPos = instance.options.ignoreCase ?
              elem.toLowerCase().indexOf(entry.toLowerCase()) :
              elem.indexOf(entry);

            while (foundPos != -1) {
              if (foundPos == 0 && elem.length != entry.length) {
                ret.push("<li><strong>" + elem.substr(0, entry.length) + "</strong>" +
                  elem.substr(entry.length) + "</li>");
                break;
              } else if (entry.length >= instance.options.partialChars &&
                instance.options.partialSearch && foundPos != -1) {
                if (instance.options.fullSearch || /\s/.test(elem.substr(foundPos-1,1))) {
                  partial.push("<li>" + elem.substr(0, foundPos) + "<strong>" +
                    elem.substr(foundPos, entry.length) + "</strong>" + elem.substr(
                    foundPos + entry.length) + "</li>");
                  break;
                }
              }

              foundPos = instance.options.ignoreCase ?
                elem.toLowerCase().indexOf(entry.toLowerCase(), foundPos + 1) :
                elem.indexOf(entry, foundPos + 1);

              if (foundPos == 0)
                break;
            }
          }
          if (partial.length)
            ret = ret.concat(partial.slice(0, instance.options.choices - ret.length))
          return "<ul>" + ret.join('') + "</ul>";
        }
      });

      // This should fix the case of clicking from the textbox to the selections drop
      // (Otherwise the textbox blur sets a timer which hides the box after click)
      this.completer.options.onHide = function(element, update) {
        if (!this.active || this.doBlur) {
          new Effect.Fade(update,{duration:0.15});
        }
        else {
          this.completer.show();
        }
      }.bind(this);

      // Copied from AutoCompleter and changed so width is not forced to be the same
      // as the textbox
      this.completer.options.onShow = function(element, update) {
	    if(!update.style.position || update.style.position=='absolute') {
	      update.style.position = 'absolute';
	      Position.clone(element, update, {
            setHeight: false,
            setWidth: false,
            offsetTop: element.offsetHeight
	      });
          update.style.width = 'auto';
          update.style.overflowX = 'hidden';
	    }
	    Effect.Appear(update,{ duration: 0.15 });
	  };

      this.dropButton.observe('click', this.onClick.bind(this));
      this.textArea.observe('blur', this.onBlur.bind(this));
    },

    onClick: function(evt) {
      if (this.active) {
        this.allowUnfocus = false;
        // onBlur gets called and handles the rest...
      } else {
        this.doBlur = false;
        this.active = true;
        this.completer.doAsEmpty = true;
        this.completer.getUpdatedChoices();
        this.completer.activate();
        setTimeout(this.unfocusWaitOver.bind(this), 250);
      }
      this.textArea.focus();
      evt.preventDefault();
    },

    unfocusWaitOver: function() {
      if (this.active) {
        this.allowUnfocus = true;
      }
    },

    onBlur: function(evt) {
      this.doBlur = true;
      this.active = false;
      this.allowUnfocus = false;
      setTimeout(this.doBlur.bind(this), 250);
    },

    doBlur: function() {
      if (this.doBlur) {
        this.completer.doAsEmpty = false;
        this.completer.hide();
        this.doBlur = false;
      }
    }
  };
