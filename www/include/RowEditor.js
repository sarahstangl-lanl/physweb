/**
 * RowEditor
 */

// Add custom methods for getting/setting element text depending on browser support
var customMethods = {
        getText: function(element) {
            element = $(element);
            innerText = element.innerText;
            textContent = element.textContent;
            if (innerText != undefined && innerText != "") {
                return innerText;
            }
            if (textContent != undefined) {
                return textContent;
            }
            return ""
        },
        setText: function(element, value) {
            if (element.innerText != undefined) {
                element.innerText = value;
            }
            else {
                element.textContent = value;
            }
        }
};

Element.addMethods(customMethods);

/*
    RowEditor(table, url, columns, args)

    table   => Table ID
    url     => Form action URL
    columns => Array of column names
    args    => Hash of config options
        newID               => ID of 'add new' button
        checkAllID          => ID of 'check all' link
        clearAllID          => ID of 'clear all' link
        parameters          => Hash of parameters to submit alongside new/update form values
        activeParameters    => Hash of parameters to submit alongside mark active form values
        inactiveParameters  => Hash of parameters to submit alongside mark inactive form values
        postSuccessCallback => Function to call upon successful creation/update/deletion
        useFormDivs         => True = use column-specific form elements instead of generic text inputs
                               Looks for elements with IDs matching `'re_' + parameters.prefix + columns[i]`
                               ShopDb::Field::Widget::Form::RowEditor takes care of wrapping inputs in a
                               hidden div with the appropriate 're_' prefix
        skipUpdates         => Allow postSuccessCallback to do all the updating
        tdClassName         => HTML class to add to each row td
        hiddenAttributes    => Hash of attributes to add as hidden inputs to forms
                               Each row must have an attribute named `'data-' + attribute.key`
                               Hidden input will be named `attribute.value` and have value `row.getAttribute('data-' + attribute.key)`
*/
    var RowEditor = Class.create({
    initialize: function(table, url, columns, args) {
        this.config = Object.extend({
            newID: null,
            checkAllID: null,
            clearAllID: null,
            editColumnName: 'edit',
            editColumnsSelector: '#' + table + ' td.roweditor_edit',
            columnDefaults: { },
            tdClassName: null,
            deleteParameters: { 'delete_line': true },
            inactiveParameters: { 'set_active': false },
            activeParameters: { 'set_active': true },
            hiddenAttributes: new Array(),
            useFormDivs: false,
            skipUpdates: false,
            postSuccessCallback: null,
        }, args || { });

        this.table = $(table);
        this.url = url;
        this.columns = columns;
        this.editElements = $$(this.config.editColumnsSelector);
        this.editElements.each(function(element) {
            this.addEditButtons(element);
        }.bind(this));

        if (this.config.newID) {
            this.newHandler = this.onNewClick.bind(this);
            $(this.config.newID).observe('click', this.newHandler);
        }

        if (this.config.checkAllID) {
            this.checkAllHandler = this.onCheckAllClick.bind(this);
            $(this.config.checkAllID).observe('click', this.checkAllHandler);
        }

        if (this.config.clearAllID) {
            this.clearAllHandler = this.onClearAllClick.bind(this);
            $(this.config.clearAllID).observe('click', this.clearAllHandler);
        }

        this.resizeHandler = this.onResize.bind(this);
        Event.observe(document.onresize ? document : window, "resize", this.resizeHandler);
    },

    addEditButtons: function(element) {
        var newTd = element.cloneNode(false);
        var paramSpan = element.down('span');
        if (paramSpan) {
            var buttonSpan = new Element('span').setStyle({ position: 'absolute' });
            if (paramSpan.hasClassName('roweditor_checkbox')) {
                var selectCheckbox = new Element('input', { type: 'checkbox' }).addClassName('roweditor-checkbox');
                buttonSpan.appendChild(selectCheckbox);
            }
            if (paramSpan.hasClassName('roweditor_edit')) {
                var editLink = new Element('a', { href: '#' }).observe('click', this.onEditClick.bind(this));
                editLink.innerHTML = '<img src="/images/b_edit.png" alt="edit" title="Edit" border="0">';
                buttonSpan.appendChild(editLink);
            }
            if (paramSpan.hasClassName('roweditor_delete')) {
                var spacer = new Element('textNode').update('&nbsp;');
                buttonSpan.appendChild(spacer);
                var deleteLink = new Element('a', { href: '#' }).observe('click', this.onDeleteClick.bind(this));
                deleteLink.innerHTML = '<img src="/images/b_drop.png" alt="delete" title="Delete" border="0">';
                buttonSpan.appendChild(deleteLink);
            }
            if (paramSpan.hasClassName('roweditor_active')) {
                var spacer = new Element('textNode').update('&nbsp;');
                buttonSpan.appendChild(spacer);
                var deleteLink = new Element('a', { href: '#' }).observe('click', this.onActiveClick.bindAsEventListener(this, true));
                deleteLink.innerHTML = '<img src="/images/inactive.png" alt="Mark Active" title="Mark Active" border="0">';
                buttonSpan.appendChild(deleteLink);
            }
            if (paramSpan.hasClassName('roweditor_inactive')) {
                var spacer = new Element('textNode').update('&nbsp;');
                buttonSpan.appendChild(spacer);
                var deleteLink = new Element('a', { href: '#' }).observe('click', this.onActiveClick.bindAsEventListener(this, false));
                deleteLink.innerHTML = '<img src="/images/active.png" alt="Mark Inactive" title="Mark Inactive" border="0">';
                buttonSpan.appendChild(deleteLink);
            }
            newTd.appendChild(buttonSpan);
        }
        element.parentNode.replaceChild(newTd, element);
    },

    cleanup: function() {
        if (this.config.newID)
            $(this.config.newID).stopObserving('click', this.newHandler);
        if (this.config.checkAllID)
            $(this.config.checkAllID).stopObserving('click', this.checkAllHandler);
        if (this.config.clearAllID)
            $(this.config.clearAllID).stopObserving('click', this.clearAllHandler);
        Event.stopObserving(document.onresize ? document : window, "resize", this.resizeHandler);
    },

    createRow: function() {
        if (this.active) { return; }

        // Create new row
        this.newRow = true;
        var row = new Element('tr');
        var lastRow = $$('#' + this.table.id + ' > tbody > tr:last-of-type').first();
        if (lastRow && lastRow.hasClassName('odd')) {
            row.addClassName('even');
        }
        else {
            row.addClassName('odd');
        }

        lastRow.getElementsBySelector('td,th').each(function(col, i) {
            var newEl = new Element('td');
            if (this.config.tdClassName)
                newEl.addClassName(this.config.tdClassName);
            if (this.columns.length > i) {
                if (this.config.columnDefaults[this.columns[i]] != undefined)
                    newEl.update(this.config.columnDefaults[this.columns[i]])
                else if (this.columns[i] == this.config.editColumnName)
                    newEl.update('&nbsp;');
            }
            row.appendChild(newEl);
        }.bind(this));

        this.table.down('tbody').appendChild(row);

        this.startEditing(row);
    },

    _createEditingBar: function(row) {
        // Create editing bar
        this.editingBar = new Element('div');
        this.editingBar.addClassName('roweditor-editing');
        this.editingBar.setStyle({
            position: 'absolute'
        });
        this.editingBarTag = new Element('span').update('&nbsp;&nbsp;>>');
        this.editingBar.appendChild(this.editingBarTag);
    },

    startEditing: function(row) {
        if (this.active || !row) { return; }

        this.active = 'edit';
        this.editingRow = row;

        this._createEditingBar(row);

        // Create input boxes or other widgets
        var form = this.form = new Element('form', { 'action': this.url, 'onsubmit': 'return false;' });
        this.editingBar.appendChild(this.form);

        var firstInput;
        row.getElementsBySelector('td').each(function (el, i) {
            if (!i) { return; } // XXX hack for now to stop editing the first el

            /* Stop creating inputs at the end of this.columns */
            if (i >= this.columns.length)
                return;

            if (this.config.useFormDivs) {
                var field = $('re_' + this.config.parameters.prefix + this.columns[i]);
                this.parentForm = field.parentNode;
                field.setStyle({ display: 'inline' });
                var input = $(this.config.parameters.prefix + this.columns[i]);
            }
            else {
                var field = new Element('input', { name: this.columns[i] });
                var input = field;
            }

            field.setStyle({
                position: 'absolute'
            });

            input.setStyle({
                border: '1px solid black'
            });

            if (el.getAttribute("data-editvalue")) {
                input.value = el.getAttribute("data-editvalue");
            } else {
                if (input.nodeName == "SELECT") {
                    input.originalValue = input.selectedIndex;
                    $A(input.options).each(function (option, i) {
                        if (el.getText() == Element.getText(option)) {
                            input.selectedIndex = i;
                        }
                    });
                }
                else {
                    input.originalValue = input.value;
                    if (input.type == 'checkbox') {
                        var checkbox = el.down('input[type=checkbox]');
                        if (checkbox) {
                            input.checked = checkbox.checked;
                            input.disabled = checkbox.readAttribute('enabled') == '1' ? '' : 'DISABLED';
                        }
                        else {
                            input.checked = '';
                            input.disabled = '';
                        }
                    }
                    if (el.getText()) {
                        input.value = el.getText();
                    }
                }
            }

            field.parentTd = el;

            if (input.onEdit)
                input.onEdit();

            form.appendChild(field);
            if (input.keyPressListener)
                input.stopObserving('keypress', input.keyPressListener);
            input.keyPressListener = input.observe('keypress', this.onKeypress.bind(this));
            if (input.nodeName == "SELECT") {
                if (input.onChangeListener)
                    input.stopObserving('change', input.onChangeListener);
                input.onChangeListener = input.observe('change', this.onSelectChange.bind(this));
            }
            if (!firstInput) { firstInput = input; }
        }.bind(this));

        // Create for hidden attrs
        // XXX configurable
        this.config.hiddenAttributes.each(function(attr) {
            if (row.getAttribute("data-" + attr.key)) {
                var input = new Element('input', { type: 'hidden', name: attr.value, value: row.getAttribute("data-" + attr.key) });
                form.appendChild(input);
            }
        });

        // Editing tag (will contain save and cancel)
        this.editingTag = new Element('div');
        this.editingTag.addClassName('roweditor-editing');
        this.editingTag.setStyle({
            position: 'absolute',
            backgroundColor: 'rgb(225, 202, 47)',
            paddingLeft: '10px',
            paddingRight: '10px',
            paddingTop: '4px',
            paddingBottom: '4px',
            borderRadius: '0px 0px 5px 5px',
            MozBorderRadius: '0px 0px 5px 5px'
        });

        // Save and Cancel
        var button = new Element('input', { type: 'button', value: 'Save' });
        button.observe('click', this.onSave.bind(this));
        this.editingTag.appendChild(button);

        this.editingTag.appendChild(document.createTextNode(' '));

        var cancel = new Element('a', { href: '#' });
        cancel.innerHTML = 'Cancel';
        cancel.observe('click', this.onCancel.bind(this));
        this.editingTag.appendChild(cancel);

        // Position elements
        this.onResize();

        $('page').appendChild(this.editingBar);
        $('page').appendChild(this.editingTag);

        firstInput.select();

        // Handle weird tr positioning delay
        setTimeout(this.onResize.bind(this),10);
    },

    updateRow: function(response) {
        if (!this.editingRow)
            return;

        var data = response.update;

        // XXX hacked + needs refactoring love
        if (data) {
            this.editingRow.getElementsBySelector('td').each(function (el, i) {
                el.update(data[i]);
                if (i == 0) {
                    this.addEditButtons(el);
                }
            }.bind(this));
        }

        if (response.attrs) {
            this.config.hiddenAttributes.each(function(attr) {
                if (typeof response.attrs[attr.value] != 'undefined') {
                    this.editingRow.setAttribute("data-" + attr.key, response.attrs[attr.key]);
                }
            }.bind(this));
        }
    },

    recolorizeRows: function() {
        var oddeven = null;
        $$('#' + this.table.id + ' > tbody > tr').each(function(row) {
            if (oddeven == null) {
                if (row.hasClassName('even'))
                    oddeven = 'odd';
                else
                    oddeven = 'even';
            }
            else {
                if (oddeven == 'odd') {
                    row.removeClassName('odd');
                    oddeven = 'even';
                }
                else {
                    row.removeClassName('even');
                    oddeven = 'odd';
                }
                row.addClassName(oddeven);
            }
        });
    },

    _showAjaxWait: function () {
        this.wait = new Element('img', {src: '/images/ajax-loader.gif'})
        this.wait.setStyle({
            paddingTop: '6px',
            paddingLeft: '5px'
        });
        this.editingBarTag.update(this.wait);
    },

    confirmDelete: function(row) {
        // XXX fix the handling of delete failures
        // XXX this activate and editing bar stuff needs... cute refactoring love
        // XXX Also the AND hiddenattr/parameter stuff. Instead of converting them to inputs
        //     we should just pass it as parameters so at least that is consistent
        if (this.active || !row) { return; }

        if (confirm('Are you sure you want to delete this row?')) {
            this.active = 'delete';
            this.editingRow = row;

            this._createEditingBar(row);
            this.onResize();
            this._showAjaxWait();
            $('page').appendChild(this.editingBar);

            var hiddenParameters = {};
            this.config.hiddenAttributes.each(function(attr) {
                if (row.getAttribute("data-" + attr.key)) {
                    hiddenParameters[attr.key] = row.getAttribute("data-" + attr.key);
                }
            });

            new Ajax.Request(this.url, {
                method: 'post',
                parameters: Object.extend(this.config.deleteParameters, Object.extend(hiddenParameters, this.config.parameters)),
                onSuccess: this.onAjaxSuccess.bind(this),
                onFailure: this.onAjaxFailure.bind(this)
            });
        }
    },

    confirmActive: function(row, active) {
        if (this.active || !row) { return; }

        if (confirm('Are you sure you want to mark this row ' + (active ? 'active' : 'inactive') + '?')) {
            this.active = 'active';
            this.editingRow = row;

            this._createEditingBar(row);
            this.onResize();
            this._showAjaxWait();
            $('page').appendChild(this.editingBar);

            var hiddenParameters = {};
            this.config.hiddenAttributes.each(function(attr) {
                if (row.getAttribute("data-" + attr.key)) {
                    hiddenParameters[attr.key] = row.getAttribute("data-" + attr.key);
                }
            });

            new Ajax.Request(this.url, {
                method: 'post',
                parameters: Object.extend(active ? this.config.activeParameters : this.config.inactiveParameters, Object.extend(hiddenParameters, this.config.parameters)),
                onSuccess: this.onAjaxSuccess.bind(this),
                onFailure: this.onAjaxFailure.bind(this)
            });
        }
    },

    save: function() {
        this.editingTag.hide();
        this._showAjaxWait();

        this.form.request({
            method: 'post',
            parameters: this.config.parameters,
            asynchronous: true,
            onSuccess: this.onAjaxSuccess.bind(this),
            onFailure: this.onAjaxFailure.bind(this)
        });
    },

    abort: function() {
        if (!this.active) { return; }

        if (this.editingTag)
            this.editingTag.remove();
        if (this.active == 'edit' && this.config.useFormDivs) {
            this.form.getElementsBySelector('div').each(function (child) {
                child.setStyle({ display: 'none' });
                // Restore orignal input values
                var input = child.firstDescendant();
                if (input.nodeName == "SELECT") {
                    input.selectedIndex = input.originalValue;
                }
                else {
                    input.value = input.originalValue;
                }
                if (input.onAbort)
                    input.onAbort();
                this.parentForm.appendChild(child);
            }.bind(this));
        }
        this.clearBubble();
        this.editingBar.remove();
        this.editingRow.removeClassName('roweditor-editing');

        if (this.newRow) {
            this.editingRow.remove();
        }

        this.editingTag = false;
        this.editingRow = false;
        this.active = false;
        this.newRow = false;
    },

    getCheckboxes: function() {
        return $$(this.config.editColumnsSelector + ' input[type="checkbox"]');
    },

    getSelectedRows: function() {
        return this.getCheckboxes().grep(this.checkboxInspector, function(checkbox) {
            return checkbox.up('tr');
        });
    },

    checkboxInspector: new Object({
        match: function(checkbox) { return checkbox.checked; }
    }),

    onCheckAllClick: function(e) {
        this.getCheckboxes().each(function(checkbox) { checkbox.checked = true; });
        e.stop();
    },

    onClearAllClick: function(e) {
        this.getCheckboxes().each(function(checkbox) { checkbox.checked = false; });
        e.stop();
    },

    onResize: function(e) {
        if (!this.editingRow)
            return;

        var pos = this.editingRow.cumulativeOffset();
        var height = this.editingRow.getHeight();
        var width = this.editingRow.getWidth();

        if (this.editingBar) {
            this.editingBar.setStyle({
                left: (pos['left']) + 'px',
                top: (pos['top']) + 'px',
                width: width + 'px',
                height: height + 'px'
            });

            if (this.config.useFormDivs) {
                var elementType = 'div';
            }
            else {
                var elementType = 'input';
            }
            this.editingBar.getElementsBySelector(elementType).each(function (field) {
                if (!field.parentTd)
                    return;
                var input = this.config.useFormDivs ? field.firstDescendant() : field;
                var siblingWidth = 0;
                if (input != field) {
                    field.childElements().each(function (element) {
                        if (element == input || element.nodeName == 'SCRIPT' || !element.visible())
                            return;
                        siblingWidth += element.getWidth();
                    });
                }
                if (siblingWidth) siblingWidth += 8;
                var tdWidth = field.parentTd.getWidth();
                field.setStyle({
                    left: (field.parentTd.offsetLeft + 2) + 'px',
                    top: (height - field.getHeight())/2 + 'px',
                    width: (tdWidth - 8) + 'px'
                });
                input.setStyle({
                    width: field.getWidth() - siblingWidth + 'px'
                });
            }.bind(this));
        }

        if (this.editingTag) {
            this.editingTag.setStyle({
                left: (pos['left'] + 20) + 'px',
                top: (pos['top'] + height) + 'px'
            });
        }

        if (this.bubble) {

        }
    },

    onError: function(errors) {
        // XXX hacked + needs refactoring love
        if (errors) {
            this.editingBar.getElementsBySelector('input,select').each(function (el) {
                if (!errors[el.name])
                    return;

                this.bubble(el, errors[el.name]);

                el.setStyle({
                    backgroundColor: 'red'
                });
            }.bind(this));
        }

        if (this.active == 'edit') {
            this.editingBarTag.update('&nbsp;&nbsp;>>');
        } else if (this.active == 'delete' || this.active == 'active') {
            this.abort();
        }

        if (this.editingTag)
            this.editingTag.show();
    },

    onCancel: function(e) {
        this.abort();
        e.stop();
    },

    onSave: function(e) {
        this.save();
        e.stop();
    },

    onEditClick: function(e) {
        var row = e.findElement().up('tr');

        this.startEditing(row);
        e.stop();
    },

    onDeleteClick: function(e) {
        var row = e.findElement().up('tr');

        this.confirmDelete(row);
        e.stop();
    },

    onNewClick: function(e) {
        this.createRow();
        e.stop();
    },

    onActiveClick: function(e, active) {
        this.confirmActive(e.findElement().up('tr'), active);
        e.stop();
    },

    onKeypress: function(e) {
        this.clearBubble(e.findElement());

        if (e.keyCode == Event.KEY_RETURN) {
            this.save();

        } else if (e.keyCode == Event.KEY_ESC) {
            this.abort();
        }
    },

    onSelectChange: function(e) {
        this.clearBubble(e.findElement());
    },

    onAjaxSuccess: function(transport) {
        var response;
        try {
            response = transport.responseText.evalJSON();
        } catch (e) { }

        if (response && response.result == 'ok') {
            if (!this.config.skipUpdates) {
                if (this.active == 'edit') {
                    if (response.update) {
                        this.updateRow(response);
                    } else {
                        // Shouldn't happen. We should always get a set of updated values back.
                        alert('The save was successful but an error prevented updating the values displayed to you. Refresh the page to update your display.');
                    }
                } else { // active = delete
                    this.editingRow.remove();
                    this.recolorizeRows();
                }
            }

            this.newRow = false;
            this.abort();

            if (this.config.postSuccessCallback) {
                this.config.postSuccessCallback();
            }
        } else {
            // XXX maybe replace the >> with a red ! icon, and indicate what is wrong (if we know)
            if (response && response.message) {
                alert(response.message);
                this.onError();

            } else if (response && response.errors) {
                this.onError(response.errors);

            } else {
                alert('An unknown issue occurred while updating.');
                this.onError();
            }
        }
    },

    onAjaxFailure: function() {
        alert('Oops! A problem prevented saving your update. Sorry.');

        this.onError();
    },

    clearBubble: function(el) {
        if (!this.editingBar)
            return;

        this.editingBar.getElementsBySelector('.roweditor_bubble').each(function (bubble) {
            if (!el || (bubble.parentEl == el)) {
                bubble.parentEl.setStyle({
                    backgroundColor: ''
                });
                bubble.parentEl.stopObserving('mouseover');
                bubble.parentEl.stopObserving('mouseout');
                bubble.remove();
            }
        }.bind(this));
    },

    bubble: function(el, text) {
        if (!this.editingBar)
            return;

        if (this.config.useFormDivs)
            var targetEl = el.up();
        else
            var targetEl = el;

        // XXX this needs to position it based on the height of the bubble
        // XXX which should then be hooked/moved into the on resize handler
        var container = new Element('div').addClassName('roweditor_bubble').setStyle({ display: 'none' });
        el.observe('mouseover', function(event) { container.setStyle({ display: 'inline' }); });
        el.observe('mouseout', function(event) { container.setStyle({ display: 'none' }); });
        container.setStyle({
            position: 'absolute',
            left: (targetEl.offsetLeft - 50) + 'px',
            top: '-45px'
        });

        var bubble = new Element('div').update(text);
        bubble.setStyle({
            border: '0.2em solid black',
            backgroundColor: 'white',
            borderRadius: '1em 1em 1em 1em',
            MozBorderRadius: '1em 1em 1em 1em',
            padding: '0.4em 0.6em 0.4em 0.6em'
        });

        var arrowa = new Element('div');
        arrowa.setStyle({
            borderLeft: '12px dotted transparent',
            borderRight: '12px dotted transparent',
            borderTop: '12px solid black',
            width: 0,
            height: 0,
            marginLeft: '55px'
        });
        var arrowb = new Element('div');
        arrowb.setStyle({
            borderLeft: '12px dotted transparent',
            borderRight: '12px dotted transparent',
            borderTop: '12px solid white',
            width: 0,
            height: 0,
            marginTop: '-15px',
            marginLeft: '55px'
        });

        container.appendChild(bubble);
        container.appendChild(arrowa);
        container.appendChild(arrowb);

        this.editingBar.appendChild(container);
        container.parentEl = el;
    }
});
