var FormEditor = new Class.create();

FormEditor.prototype = {
    initialize: function(divid, parentid, headid, args) {
        this.images = {};
        this.placeholders = {};
        this.container = $(divid);
        this.containerHead = $(headid);
        this.parentid = parentid;
        this.noFade = true;

        if ($defined(args['uploader'])) {
            this.uploader = args['uploader'];
        } else {
            this.uploader = false;
        }

        if ($defined(args['placeholderImgTag'])) {
            this.placeholderImgTag = args['placeholderImgTag'];
        } else {
            this.placeholderImgTag = false;
        }

        if ($defined(args['placeholderHeight'])) {
            this.placeholderHeight = args['placeholderHeight'];
        } else {
            this.placeholderHeight = false;
        }

        
        // Create the edit div
        // TODO: clean up... messygross in more ways than one
        this.editor = new Element('div', { id: 'image__properties' });
        this.editor.innerHTML = '<table>' + 
            '<tr><td>Rescale</td><td><input type="textbox" id="imageEditor_rescale" size="5"> pixels wide</td></tr>' +
            '<tr><td></td><td id="imageEditor_imgSize">Currently 0x0 pixels</td></tr>' +
            '<tr><td>Alt Text</td><td><input type="textbox" id="imageEditor_altText"></td></tr>' + 
            '<tr><td>Caption</td><td><input type="textbox" id="imageEditor_caption" size="30"></td></tr>' + 
            '<tr><td>Photo Credit</td><td><input type="textbox" id="imageEditor_photoCredit"></td></tr>' +
            '<tr><td>Alignment</td><td><select id="imageEditor_alignment"><option value="left">left</option><option value="right">right</option></select></td></tr>' +
            '<tr><td colspan="2" align="right"><button type="button" id="imageEditor_cancel" class="toolbutton"><small>Cancel</small></button> <button type="button" id="imageEditor_save" class="toolbutton"><small>Save</small></button></td></tr></table>';
        this.editor.hide();
        this.container.insert({ after: this.editor });
        $('imageEditor_cancel').observe('click', this.editImage_cancel.bindAsEventListener(this));
        $('imageEditor_save').observe('click', this.editImage_save.bindAsEventListener(this));
        this.editor.getElementsBySelector('input').each(function(i) {
            i.observe('keypress', this.fixSubmit.bindAsEventListener(this));
        });
    },

    fixSubmit: function (e) {
      var chCode = e.which ? e.which : e.keyCode;
      if (chCode == 13) 
      {
        // do nothing on ENTER
        e.stop();
      }
    },

    confirmDeleteImage: function (e, id) {
      if (confirm('Are you sure you want to delete this image?'))
        this.deleteImage(id);
    },

    confirmCancelUpload: function (e, upload_id) {
        //if (confirm('Are you sure you want to cancel this upload?'))
        // the multiUpload bit has a confirm...
            this.cancelUpload(upload_id);
    },

    // Delete the given imageid from the db
    // Also calls removeImage upon successful deletion
    deleteImage: function (id) {
        new Ajax.Request('/imagedb/delete_image_ajax.html', {
            method: 'post',
            onSuccess: function (transport) { this.removeImage(id); }.bindAsEventListener(this),
            onFailure: function (transport) { alert('Image delete call failed!'); },
            parameters: {
                imageid: this.images[id].iid
            }
        });
    },

    cancelUpload: function (upload_id) {
        if ((!this.placeholders[upload_id]) && this.uploader)
            return;

        this.uploader.deleteRow(upload_id);

        new Effect.Fade(this.placeholders[upload_id].container, {
            afterFinish: this.removeImageDiv.bind(this,
            this.placeholders[upload_id].container)
        });

        delete(this.placeholders[upload_id]);
    },

    // Remove the given imageid from the display
    removeImage: function (id) {
        if (!this.images[id])
            return;
        // handle the html/dom

        new Effect.Fade(this.images[id].container, {
            afterFinish: this.removeImageDiv.bind(this, this.images[id].container)
        });
        //this.images[id].container.remove();

        // handle our arrays
        delete(this.images[id]);
    },

    removeImageDiv: function (container) {
      container.remove();
    },

    enableFade: function() {
      this.noFade = false;
    },

    insertImageTag: function(e, wid, text) {
      insertAtCarret(wid, text);
    },

    addPlaceholder: function (upload_id) {
        if (!this.placeholderImgTag || !this.placeholderHeight)
            return;

        var wrapper = new Element('div', {
            'class': 'imagepick'
        });
        var img_div = new Element('div', {
            style: 'margin-top: ' + Math.ceil((85 - this.placeholderHeight) / 2) + 'px;' +
                    'margin-bottom: ' + Math.floor((85 - this.placeholderHeight) / 2) + 'px;'
        });
        var center = new Element('center', { });
        var btn_delete = new Element('img', {
            src: '/images/imgsel_delete.png',
            alt: 'Delete'
        });

        Event.observe(btn_delete, 'click', this.confirmCancelUpload.bindAsEventListener(this, upload_id));

        center.insert(btn_delete);
        img_div.insert('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;').insert(this.placeholderImgTag).insert('&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;');
        wrapper.insert(img_div).insert(img_div).insert(center);

        if (!this.noFade)
            wrapper.hide();

        this.container.insert(wrapper);
    
        if (!this.noFade)
            new Effect.Appear(wrapper);

        this.placeholders[upload_id] = { container: wrapper };
    },

    // Add the given imageid to the display
    // imgtag is the tag to display the img
    // id is indexid (unique only to a specific profile)
    // iid is the (globally unique) -imageid- of the image
    // info is the variable args assoc array
    addImage: function (id, imgtag, tsizey, iid, info) {
        if ($defined(this.images[id]))
        {
            // That image is already here... just update image info
            this.images[id].info = info;
        } else {
            var placeholder = false;
            var upload_id = false;

            if ($defined(info['upload_id']) &&
            $defined(this.placeholders[info['upload_id']]))
            {
                upload_id = info['upload_id'];
                placeholder = this.placeholders[upload_id];
            }

            var wrapper = new Element('div', {
                'class': 'imagepick'
            });
            var img_div = new Element('div', {
                style: 'margin-top: ' + Math.ceil((85 - tsizey) / 2) + 'px;' +
                        'margin-bottom: ' + Math.floor((85 - tsizey) / 2) + 'px;'
            });
            var center = new Element('center', { });
            var btn_delete = new Element('img', {
                src: '/images/imgsel_delete.png',
                alt: 'Delete'
            });
            var btn_edit = new Element('img', {
                src: '/images/imgsel_edit.png',
                alt: 'Edit'
            });

            Event.observe(btn_delete, 'click', this.confirmDeleteImage.bindAsEventListener(this, id));
            Event.observe(btn_edit, 'click', this.editImage.bindAsEventListener(this, id));
            Event.observe(img_div, 'click', this.insertImageTag.bindAsEventListener(this, 'wiki__text', '{{image|' + id + '}}'));
        
            center.insert('<b>' + id + '</b>&nbsp;&nbsp;&nbsp;').insert(btn_delete).insert('&nbsp;&nbsp;&nbsp;').insert(btn_edit);
            img_div.insert(imgtag);
            wrapper.insert(img_div).insert(img_div).insert(center);

            if (!this.noFade)
              wrapper.hide();

            if (placeholder)
            {
                placeholder.container.replace(wrapper);
                delete(this.placeholders[upload_id]);
            } else {
                this.container.insert(wrapper);
            }
            
            if (!this.noFade)
              new Effect.Appear(wrapper);

            this.images[id] = { container: wrapper, 'tsizey': tsizey, 'iid': iid, 'info': info };
        }
    },

    editImage: function(e, id) {
        this.editing = id;
        var noRescale = (this.images[this.editing].info['owidth'] == '' || !$defined(this.images[this.editing].info['owidth']) || this.images[this.editing].info['owidth'] == 0);
        $('imageEditor_rescale').value = '';
        $('imageEditor_rescale').disabled = noRescale;
        $('imageEditor_altText').value = this.images[this.editing]['info']['altText'];
        $('imageEditor_caption').value = this.images[this.editing]['info']['caption'];
        $('imageEditor_photoCredit').value = this.images[this.editing].info['photoCredit'];
        $('imageEditor_alignment').selectedIndex = (this.images[this.editing].info['alignment'] == 'left' ? 0 : 1);
        $('imageEditor_imgSize').update('<small>Currently <b>' + this.images[this.editing].info['width'] + '</b>x' + this.images[this.editing].info['height'] + ' pixels.' + (!noRescale ? ' Original size ' + this.images[this.editing].info['owidth'] + 'x' + this.images[this.editing].info['oheight'] + '.' : '<i>Original image unavailable (cannot resize).</i>') + '</small>')
        this.container.hide();
        this.editor.show();
        if ($defined(this.containerHead))
            this.containerHead.update('Editing Image #' + this.editing);
    },

    editImage_cancel: function() {
        this.editing = null;
        this.editor.hide();
        this.container.show();
        if ($defined(this.containerHead))
            this.containerHead.update('Available Images');
    },

    editImage_save: function() {
        if (!$defined(this.editing))
            return;
        new Ajax.Request('/imagedb/upload_image_ajax.html', {
            method: 'post',
            onSuccess: this.editImage_saveSuccess.bindAsEventListener(this),
            evalJS: 'force',
            parameters: {
                jsonly: 1,
                image: '',
                category: 'profiles',
                parentid: this.parentid,
                indexid: this.editing,
                imageid: this.images[this.editing].iid,
                width: $F('imageEditor_rescale'),
                alt: $F('imageEditor_altText'),
                caption: $F('imageEditor_caption'),
                credit: $F('imageEditor_photoCredit'),
                align: $F('imageEditor_alignment')
            }
        });
    },

    editImage_saveSuccess: function(transport) {
       this.editImage_cancel();
    }
};
