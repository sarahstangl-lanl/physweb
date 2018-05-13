var ShopDbJob = new Class.create();

ShopDbJob.prototype = {

    initialize: function(job_id, options) {
        this.options = Object.extend({
            editDiv: 'shopdb-job-details-edit',
            editForm: 'shopdb-job-edit-form',
            attachmentsDiv: 'shopdb-job-attachments',
            detailsAttachmentsDiv: 'shopdb-job-details-attachments',
            toggleDetailsAttachmentsLink: 'shopdb-job-details-toggle-attachments',
            noAttachmentsDiv: 'shopdb-job-attachment-none',
            summaryURL: 'job_summary.html'
        }, options || { });
        this.job_id = job_id;
        this.attachments = $H();
        this.isDirty = false;
        document.observe('dom:loaded', this.addEventHandlers.bind(this));
    },

    addEventHandlers: function() {
        // Add edit form validation hooks
        this.editForm = $(this.options.editForm);
        Event.observe(window, 'beforeunload', this.checkForChanges.bind(this));
        if (this.editForm) {
            this.editForm.getInputs('submit').each(function (button) {
                button.observe('click', this.validateEditForm.bindAsEventListener(this, button));
            }.bind(this));
            this.editForm.getElements().each(function (input) {
                input.observe('change', this.markDirty.bind(this));
                input.observe('blur', this.validateElementDelayed.bind(this, null, input));
            }.bind(this));
        }
        // Handle 'more...' link for attachments
        this.toggleDetailsAttachmentsLink = $(this.options.toggleDetailsAttachmentsLink);
        if (this.toggleDetailsAttachmentsLink)
            this.toggleDetailsAttachmentsLink.observe('click', this.toggleDetailsAttachments.bind(this));
    },

    checkForChanges: function(e) {
        if (this.isDirty) {
            var message = "You have unsaved changes. Are you sure you want to leave this page?";
            (e || window.event).returnValue = message;
            return message;
        }
    },

    validateEditForm: function(e, button) {
        this.editForm = this.editForm || $(this.options.editForm);
        if (this.editForm.getElements().reject(this.validateElement.bind(this, button)).length) {
            Event.stop(e);
            return false;
        }
        this.isDirty = false;
        return true;
    },

    validateElementDelayed: function(button, element) {
        setTimeout(this.validateElement.bind(this, button, element), 300);
    },

    validateElement: function(button, element) {
        if (element.validateMethod) {
            if (!element.validateMethod(button)) {
                this.addError(element);
                return false;
            }
            else {
                this.clearError(element);
            }
        }
        return true;
    },

    markDirty: function(e) {
        this.isDirty = true;
    },

    addError: function(element) {
        if (!element.errorNode) {
            errorMsg = new Element('div');
            errorMsg.update(element.errorMsg).setStyle({color: 'red'});
            element.parentNode.appendChild(errorMsg);
            element.errorNode = errorMsg;
            element.clearError = this.clearError.bind(this, element);
            this.editForm.select('label').find(function(e) {
                if (e.htmlFor == element.id) {
                    e.setStyle({color: 'red'});
                    return true;
                }
            });
        }
    },

    clearError: function(element) {
        if (element.errorNode) {
            this.editForm.select('label').find(function(e) {
                if (e.htmlFor == element.id) {
                    e.setStyle({color: 'black'});
                    return true;
                }
            });
            element.errorNode.remove();
            delete element.errorNode;
        }
    },

    toggleEditForm: function() {
        if (this.isDirty)
            location.reload(true);
        this.editDiv = this.editDiv || $(this.options.editDiv);
        if (this.editDiv.getStyle('display') == 'none') {
            var viewportOffsets = document.viewport.getScrollOffsets();
            var viewportDims = document.viewport.getDimensions();
            var parentOffsets = this.editDiv.getOffsetParent().cumulativeOffset();
            var top = viewportOffsets.top + (viewportDims.height / 2) - (this.editDiv.getHeight() / 2) - parentOffsets.top + 'px';
            var left = viewportOffsets.left + (viewportDims.width / 2) - (this.editDiv.getWidth() / 2) - parentOffsets.left + 'px';
            this.editDiv.setStyle({ position: 'absolute', display: 'inline', top: top, left: left });
        }
        else
            this.editDiv.setStyle({ display: 'none' });
        return false;
    },

    toggleDetailsAttachments: function(e) {
        this.detailsAttachmentsDiv = this.detailsAttachmentsDiv || $(this.options.detailsAttachmentsDiv);
        if (this.detailsAttachmentsDiv) {
            $(Event.findElement(e, 'a')).blur();
            if (this.toggleDetailsAttachmentsLink.getText() == 'More') {
                Effect.BlindDown(this.detailsAttachmentsDiv);
                this.toggleDetailsAttachmentsLink.update('Less');
            }
            else {
                Effect.BlindUp(this.detailsAttachmentsDiv);
                this.toggleDetailsAttachmentsLink.update('More');
            }
        }
        Event.stop(e);
    },

    refreshData: function(updates) {
        try {
        updates.each(function (update) {
            if (update == 'summary')
                this.updateSummary();
            else if (update == 'audits')
                this.updateAudits();
            else if (update == 'comments')
                this.updateComments();
            else if (update == 'labor' || update == 'material')
                this.updateChargeLines(update);
        }.bind(this));
        } catch (e) { console.log('refreshData failure args', e, arguments); }
    },

    updateChargeLines: function(type) {
        if (type == 'labor') {
            $$('form[name="ll_tsform"]').first().submit();
        }
        else {
            $$('form[name="ml_tsform"]').first().submit();
            /* Update material lines roweditor unit form element in case a new unit was added via ajax */
            new Ajax.Request('charge_lines.html', {
                parameters: {
                    get_updated_ed_html: 1,
                    job_id: this.job_id,
                    type: 'material'
                },
                onSuccess: function(response) {
                    $('ml_unit').up().replace(response.responseText);
                }
            });
        }
    },

    updateSummary: function() {
        new Ajax.Request(this.options.summaryURL, {
            parameters: {
                ajax: 1,
                job_id: this.job_id
            },
            onSuccess: function(response) {
                response = response.responseText.evalJSON();
                response.each(function(item) {
                    $('summary_' + item.column).update(item.value);
                });
            }
        });
    },

    updateComments: function() {
        $$('form[name="comments_tsform"]').first().submit();
    },

    updateAudits: function() {
        $$('form[name="audits_tsform"]').first().submit();
    },

    addAttachment: function(filename, attachment_id) {
        this.attachmentsDiv = this.attachmentsDiv || $(this.options.attachmentsDiv);
        this.noAttachmentsDiv = $(this.options.noAttachmentsDiv);
        if (this.noAttachmentsDiv)
            this.noAttachmentsDiv.remove();
        aLink = new Element('a').setStyle({ position: 'relative', top: '-4px' });
        aRenameImage = new Element('img', { src: '/images/b_edit.png' }).setStyle({ border: 0, paddingRight: '3px' });
        aRename = new Element('a', { href: '', title: 'Rename file' }).observe('click', this.renameAttachment.bindAsEventListener(this, attachment_id));
        aRename.appendChild(aRenameImage);
        aDeleteImage = new Element('img', { src: '/images/b_drop.png' }).setStyle({ border: 0, paddingRight: '3px' });
        aDelete = new Element('a', { href: '', title: 'Delete file' }).observe('click', this.deleteAttachment.bindAsEventListener(this, attachment_id))
        aDelete.appendChild(aDeleteImage);
        aDiv = new Element('div').setStyle({ paddingBottom: '4px', whiteSpace: 'nowrap' });
        aDiv.appendChild(aRename);
        aDiv.appendChild(aDelete);
        aDiv.appendChild(aLink);
        this.attachments.set(attachment_id, $H({ attachmentDiv: aDiv, attachmentLink: aLink, filename: filename }));
        this.updateAttachment(attachment_id, filename);
        this.attachmentsDiv.appendChild(aDiv);
        this.attachmentsDiv.scrollTop = this.attachmentsDiv.scrollHeight;
    },

    updateAttachment: function(attachment_id, filename) {
        attachment = this.attachments.get(attachment_id);
        aLink = new Element('a', { href: "get_file.html?attachment_id=" + attachment_id, title: filename.escapeHTML() }).setStyle({ position: 'relative', top: '-4px' }).update(filename.escapeHTML());
        attachment.get('attachmentLink').replace(aLink);
        attachment.set('attachmentLink', aLink);
        attachment.set('filename', filename);
    },

    removeAttachment: function(attachment_id) {
        this.attachments.unset(attachment_id).get('attachmentDiv').remove();
        if (this.attachments.keys().length == 0) {
            aEmptyDiv = new Element('div', { id: this.options.noAttachmentsDiv }).setStyle({ marginTop: '-2px' }).update('None');
            this.attachmentsDiv = this.attachmentsDiv || $(this.options.attachmentsDiv);
            this.attachmentsDiv.appendChild(aEmptyDiv);
        }
    },

    renameAttachment: function(e, attachment_id) {
        $(Event.findElement(e, 'a')).blur();
        Event.stop(e);
        attachment = this.attachments.get(attachment_id);
        aLink = attachment.get('attachmentLink');
        aDiv = new Element('span');
        aInput = new Element('input', { value: attachment.get('filename'), type: 'text' }).setStyle({ margin: '0 0 -3px -2px', position: 'relative', top: '-4px', left: '-2px', height: aLink.getHeight() + 'px' });
        aUpdateButton = new Element('button').update('Update').setStyle({ fontSize: '8pt', width: '50px', margin: '0 0 -5px 0', position: 'relative', top: '-5px', backgroundColor: '#CCC' });
        aUpdateButton.observe('click', this.submitAttachmentRename.bindAsEventListener(this, attachment_id, aInput));
        aCancelButton = aUpdateButton.cloneNode(false).update('Cancel');
        aCancelButton.observe('click', this.cancelAttachmentRename.bindAsEventListener(this, attachment_id));
        aDiv.appendChild(aInput);
        aDiv.appendChild(aUpdateButton);
        aDiv.appendChild(aCancelButton);
        aLink.replace(aDiv);
        aInput.select();
        attachment.set('attachmentLink', aDiv);
    },

    submitAttachmentRename: function(e, attachment_id, input) {
        Event.stop(e);
        $(Event.findElement(e, 'button')).blur();
        this.submitAttachmentRequest('rename', attachment_id, input.value);
    },

    cancelAttachmentRename: function(e, attachment_id) {
        Event.stop(e);
        this.updateAttachment(attachment_id, this.attachments.get(attachment_id).get('filename'));
    },

    deleteAttachment: function(e, attachment_id) {
        $(Event.findElement(e, 'a')).blur();
        Event.stop(e);
        if (confirm("Are you sure you want to delete '" + this.attachments.get(attachment_id).get('filename') + "'?")) {
            this.submitAttachmentRequest('delete', attachment_id);
        }
    },

    submitAttachmentRequest: function(action, attachment_id, filename) {
        new Ajax.Request('modify_file.html', {
            parameters: {
                action: action,
                attachment_id: attachment_id,
                filename: filename
            },
            onSuccess: this.onAttachmentRequestSuccess.bind(this)
        });
    },

    onAttachmentRequestSuccess: function(response) {
        response = response.responseText.evalJSON();
        if (response) {
            if (response.action == 'delete') {
                this.removeAttachment(response.attachment_id);
            }
            else if (response.action == 'rename') {
                this.updateAttachment(response.attachment_id, response.filename);
            }
            else {
            }
        }
        else {
        }
    }

}
