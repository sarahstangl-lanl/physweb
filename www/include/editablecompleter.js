/*
Editable Dropdown SHAZAM!
Or something like that.

clayton@physics.umn.edu
*/

  var EditableCompleter = new Class.create();

  EditableCompleter.prototype = {
    /*
        options parameters:
        textArea: id of input to autocomplete
        dropdown: id(s) of input(s) to use as argument(s); can be single id string or array of ids
        dropdownTitle: title of dropdown box
        url: url for autocompleter
        paramName: key used for textArea value
        ddParamName: key used for arguments; default: vlan
        noDropdownButton: prevents displaying dropdown button
        ddMinWidth: minimum dropdown width
        acOptions: options hash to pass to autocompleter constructor

        post prototype: url?paramname=$(textArea).value&dropdownparamname=$(dropdown[0]).value&dropdownparamname=$(dropdown[1]).value...
    */
    initialize: function(options) {
      textArea = $(options.textArea);
      if (options.dropdown.constructor != Array)
          options.dropdown = [ options.dropdown ];
      dropdowns = $A(options.dropdown).collect(function(s) { return $(s) } );
      this.url = options.url;
      this.paramName = options.paramName;
      this.textArea = textArea;
      this.dropdowns = dropdowns;
      this.acOptions = Object.extend({
          paramName: this.paramName,
          select: 'selectText',
          defaultParams: null
      }, options.acOptions || {});
      this.dropdownTitle = options.dropdownTitle || '';
      this.dropdownOffset = options.dropdownOffset || '';
      this.dropdownPosition = options.dropdownPosition || '';
      this.ddParamName = options.ddParamName || 'vlan';
      this.noDropdownButton = options.noDropdownButton || false;
      this.ddMinWidth = options.ddMinWidth || null;
      this.doblur = false;
      this.active = false;
      this.allowUnfocus = false;

      imagename = 'dropdown.gif'; // 17x17 pixels

      // Temporarily make textArea input visible for button position calculationsa unless dropdownOffset is specified
      if (!this.dropdownOffset) {
        textAreaOffset = textArea.cumulativeOffset();
        origParent = textArea.parentNode;
        origNextSibling = textArea.nextSibling;
        textArea = document.body.appendChild(textArea.remove());
        textAreaDims = textArea.getDimensions();

        imagePos = { top: ((textAreaDims.height - 17) / 2) + 'px', left: '2px' };
      }
      else {
        imagePos = { top: this.dropdownOffset, left: '2px' };
      }

      if (!this.dropdownOffset && this.dropdownPosition == 'top') {
        buttonLink = new Element('a', {
              id: options.textArea + '_magic_button',
              href: '#',
              title: this.dropdownTitle
        }).setStyle({
              position: 'absolute', top: textAreaOffset.top + 'px', left: textAreaOffset.left + textAreaDims.width + 'px'
        });
      }
      else {
        buttonLink = new Element('a', { id: options.textArea + '_magic_button', href: '#', title: this.dropdownTitle }).setStyle({ position: 'relative', top: imagePos.top, left: imagePos.left });
      }
      buttonImage = new Element('img', { src: '/images/' + imagename }).setStyle({ border: 0 });
      buttonLink.appendChild(buttonImage);
      listDiv = new Element('div', { id: options.textArea + '_magic_list' }).addClassName('editabledrop').setStyle({ display: 'none', zIndex: 100, textAlign: 'left' });

      // Restore textArea visibility unless dropdownOffset is specified
      if (!this.dropdownOffset) {
        textArea = textArea.remove();
        if (origNextSibling)
          origParent.insertBefore(textArea, origNextSibling);
        else
          origParent.appendChild(textArea);
      }

      if (!this.noDropdownButton) {
        textArea.insert({ after: buttonLink });
        this.dropbutton = $(options.textArea + '_magic_button');
        this.dropbutton.observe('click', this.onClick.bindAsEventListener(this));
      }

      textArea.insert({ after: listDiv });
      this.completionbox = $(options.textArea + '_magic_list');
      this.completer = new Ajax.Autocompleter(options.textArea, options.textArea + '_magic_list', this.url, Object.clone(this.acOptions));

      // This should fix the case of clicking from the textbox to the selections drop
      // (Otherwise the textbox blur sets a timer which hides the box after click)
      this.completer.options.onHide = function(element, update){ if (!this.active || this.doblur) { new Effect.Fade(update,{duration:0.15}); } else { this.completer.show(); } }.bind(this);

      // Copied from AutoCompleter and changed so width is not forced to be the same
      // as the textbox
      this.completer.options.onShow = function(element, update){
        if(!update.style.position || update.style.position=='absolute') {
          update.style.position = 'absolute';
          Position.clone(element, update, {
            setHeight: false,
            setWidth: false,
            offsetTop: element.offsetHeight
          });
          if (this.ddMinWidth)
            update.style.width = this.ddMinWidth;
          update.style.overflowX = 'hidden';
          // Ensure dropdown isn't off the page
          setTimeout(function () {
            if (document.viewport.getWidth() < this.cumulativeOffset().left + this.getWidth())
              this.setStyle({ left: 'auto', right: 0 });
          }.bind(update), 50);
        }
        Effect.Appear(update,{duration:0.15});
      }.bind(this);

      this.textArea.observe('blur', this.onBlur.bindAsEventListener(this));
      this.textArea.observe('keypress', this.onKeyPress.bindAsEventListener(this));
      this.dropdowns.each(function (s) { s.observe('change', function(e){ this.asEmptyUpdate(); }.bindAsEventListener(this)) }.bind(this));
    },

    onKeyPress: function(e) {
        this.active = true;
        this.completer.doAsEmpty = false;
        this.asEmptyUpdate();
    },

    asEmptyUpdate: function () {
      if (this.completer.doAsEmpty) {
        this.completer.options.defaultParams = this.acOptions.defaultParams || '';
        this.dropdowns.each(function (s) { this.completer.options.defaultParams += '&' + encodeURIComponent(this.ddParamName) + '=' + encodeURIComponent(s.value); }.bind(this));
      } else {
        this.completer.options.defaultParams = this.acOptions.defaultParams;
      }
    },

    onClick: function(evt) {
      if (this.active) {
        this.allowUnfocus = false;
        // onBlur gets called and handles the rest...
      } else {
        this.doblur = false;
        this.active = true;
        this.completer.doAsEmpty = true;
        this.asEmptyUpdate();
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
      this.doblur = true;
      this.active = false;
      this.allowUnfocus = false;
      setTimeout(this.doBlur.bind(this), 250);
    },

    doBlur: function() {
      if (this.doblur) {
        this.completer.doAsEmpty = false;
        this.asEmptyUpdate();
        this.completer.hide();
        this.doblur = false;
      }
    }
  };
