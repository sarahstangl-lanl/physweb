var DirectoryBulkAddLookup = new Class.create();

DirectoryBulkAddLookup.prototype = {

    initialize: function(options) {
        this.options = Object.extend({
            textboxid:          'autodir_search',
            lookupmessagesid:   'autodir_lookup_messages',
            lookupbuttonid:     'autodir_lookup',
            lookupurl:          '/include/lookup_emplid.html',
            lookupoptions:      { },
            addmessagesid:      'autodir_add_messages',
            addbuttonid:        'autodir_add',
            addurl:             'quickadd.html',
            addoptions:         { },
            requestmessagesid:  'autodir_request_messages',
            requestbuttonid:    'autodir_request',
            requesturl:         'physidrequest.html',
            requestoptions:     { },
            usersdivid:         'div_newusers',
        }, options);
        this.textbox = $(this.options.textboxid);
        /* Setup look up section */
        this.lookupmessagesbox = $(this.options.lookupmessagesid);
        this.lookupbutton = $(this.options.lookupbuttonid);
        this.lookupstatusbox = this.lookupbutton.up();
        this.lookupRequestsPending = 0;
        /* Setup verify section */
        this.usersdiv = $(this.options.usersdivid);
        this.users = $A();
        /* Setup add section */
        this.addmessagesbox = $(this.options.addmessagesid);
        this.addbutton = $(this.options.addbuttonid).disable();
        this.addstatusbox = this.addbutton.up();
        this.addRequestsPending = 0;
        /* Setup request section */
        this.requestmessagesbox = $(this.options.requestmessagesid);
        this.requestbutton = $(this.options.requestbuttonid).disable();
        this.requeststatusbox = this.requestbutton.up();
        this.requestRequestsPending = 0;
        /* Setup fields */
        this.fields = $H({
            first_name: "First Name",
            last_name:  "Last Name",
            x500:       "X.500",
            emplid:     "Employee ID",
            dw_position:   "Position",
            email:      "Email",
            ucard:      "UCard #"
        });
        /* Create busy messages */
        this.busyimg = new Element('img', { src: "/images/ajax-loader.gif" });
        this.lookupbusy = new Element('span');
        this.lookupbusy.appendChild(this.busyimg);
        this.lookupbusy.appendChild(document.createTextNode("Looking Up..."));
        this.addbusy = new Element('span');
        this.addbusy.appendChild(this.busyimg.cloneNode(true));
        this.addbusy.appendChild(document.createTextNode("Adding Entries..."));
        this.requestbusy = new Element('span');
        this.requestbusy.appendChild(this.busyimg.cloneNode(true));
        this.requestbusy.appendChild(document.createTextNode("Requesting Accounts..."));
        /* Create new users table header row */
        tr = new Element('tr');
        this.fields.each(function(field) {
            tr.appendChild(new Element('th', { style: 'white-space: nowrap; text-align: left;' }).update(field.value));
        });
        this.userstableheader = tr;
        /* Create check/clear all physid request links */
        this.bulkcheck = new Element('td', { colspan: 3 });
        checkall = new Element('span', { style: 'padding-right: 5px;' });
        this.checkalllink = new Element('a', { href: '#' }).update('Check All');
        checkall.appendChild(this.checkalllink);
        this.bulkcheck.appendChild(checkall);
        this.bulkcheck.appendChild(new Element('span').update('|'));
        clearall = new Element('span', { style: 'padding-left: 5px;' });
        this.clearalllink = new Element('a', { href: '#' }).update('Clear All');
        clearall.appendChild(this.clearalllink);
        this.bulkcheck.appendChild(clearall);
        /* Setup event handlers */
        Event.observe(this.lookupbutton, 'click', this.lookupAccounts.bind(this));
        Event.observe(this.addbutton, 'click', this.submitAdditions.bind(this));
        Event.observe(this.requestbutton, 'click', this.submitRequests.bind(this));
        Event.observe(this.checkalllink, 'click', this.checkAllRequests.bind(this));
        Event.observe(this.clearalllink, 'click', this.clearAllRequests.bind(this));
    },

    /* Methods for toggling status sections/buttons */
    toggleLoading: function() {
        if (this.lookupRequestsPending)
            this.lookupstatusbox.update(this.lookupbusy);
        else
            this.lookupstatusbox.update(this.lookupbutton);
    },

    toggleAdding: function() {
        if (this.addRequestsPending)
            this.addstatusbox.update(this.addbusy);
        else
            this.addstatusbox.update(this.addbutton);
    },

    toggleRequesting: function() {
        if (this.requestRequestsPending)
            this.requeststatusbox.update(this.requestbusy);
        else
            this.requeststatusbox.update(this.requestbutton);
    },

    getRequestCheckboxes: function() {
        return $$('input[type=checkbox][class=physid_request]');
    },

    /* Enable/disable request button */
    requestButtonCheck: function (event) {
        if (event)
            event.stop();

        if (this.getRequestCheckboxes().any(function (checkbox) {
            return checkbox.checked;
        }))
            this.requestbutton.enable();
        else
            this.requestbutton.disable();
    },

    /* Methods for checking/clearing account request checkboxes */
    checkAllRequests: function(event) {
        if (event)
            event.stop();

        this.getRequestCheckboxes().each(function (checkbox) {
            checkbox.checked = true;
        });
        this.checkalllink.blur();
        this.requestButtonCheck();
    },

    clearAllRequests: function(event) {
        if (event)
            event.stop();

        this.getRequestCheckboxes().each(function (checkbox) {
            checkbox.checked = false;
        });
        this.clearalllink.blur();
        this.requestButtonCheck();
    },

    /* Start a lookup on the entered values */
    lookupAccounts: function(event) {
        if (event)
            event.stop();

        if (this.lookupmessagestable)
            this.lookupmessagestable.remove();
        this.bulkcheck.isvisible = false;
        this.addbutton.disable();
        this.lookupmessagestable = new Element('table', { cellpadding: 3, cellspacing: 0 });
        this.lookupmessagesbox.appendChild(this.lookupmessagestable);
        this.userstable = new Element('table', { cellpadding: 3, cellspacing: 0 });
        this.userstable.appendChild(this.userstableheader);
        this.usersdiv.update(this.userstable);
        this.users.clear();

        this.textbox.value.split('\n').each(function(person) {
            if (person == '')
                return;
            this.lookupRequestsPending++;
            options = Object.extend({
                parameters: { search: person },
                onSuccess: this.onLookupSuccess.bindAsEventListener(this, person),
                onFailure: this.onLookupFailure.bindAsEventListener(this, person)
            }, this.options.lookupoptions);
            new Ajax.Request(this.options.lookupurl, options);
        }.bind(this));
        this.toggleLoading();
    },

    /* Submit entry creation request(s) */
    submitAdditions: function(event) {
        if (event)
            event.stop();

        this.addbutton.disable();
        if (this.addmessagestable)
            this.addmessagestable.remove();
        this.addmessagestable = new Element('table', { cellpadding: 3, cellspacing: 0 });
        this.addmessagesbox.appendChild(this.addmessagestable);
        globalparams = { ajax: 1, 'confirm': 1 };
        $$('input[type=checkbox][id^=autodir_]').each(function(checkbox) {
            globalparams[checkbox.name] = checkbox.checked ? checkbox.value : null;
        });
        this.users.each(function (user) {
            options = Object.extend({
                parameters: Object.extend(user.toObject(), globalparams),
                onSuccess: this.onAddSuccess.bindAsEventListener(this, user),
                onFailure: this.onAddFailure.bindAsEventListener(this, user)
            }, this.options.addoptions);
            this.addRequestsPending++;
            new Ajax.Request(this.options.addurl, options);
        }, this);
        this.toggleAdding();
    },

    /* Submit account creation request(s) */
    submitRequests: function(event) {
        if (event)
            event.stop();

        this.requestbutton.disable();
        if (this.requestmessagestable)
            this.requestmessagestable.remove();
        this.requestmessagestable = new Element('table', { cellpadding: 3, cellspacing: 0 });
        this.requestmessagesbox.appendChild(this.requestmessagestable);
        this.getRequestCheckboxes().findAll(function (checkbox) { return checkbox.checked }).each(function (checkbox) {
            this.requestRequestsPending++;
            options = Object.extend({
                parameters: { uid: checkbox.name, ajax: 1 },
                onSuccess: this.onRequestSuccess.bindAsEventListener(this, checkbox.name),
                onFailure: this.onRequestFailure.bindAsEventListener(this, checkbox.name)
            }, this.options.addoptions);
            new Ajax.Request(this.options.requesturl, options);
        }, this);
        this.toggleRequesting();
    },

    /* Methods for adding result messages */
    addLookupMessage: function(message, uid, physid, acctreq) {
        tr = new Element('tr');
        colspan = 3
        message = '<b>' + message + '</b>';
        if (uid != null) {
            colspan -= 2;
            if (physid != null || acctreq != null)
                tr.insert(new Element('td').update('Physid: <i>' + ( physid || 'Request pending' ) + '</i>'));
            else {
                if (!this.bulkcheck.isvisible) {
                    this.lookupmessagestable.appendChild(new Element('tr').update(this.bulkcheck));
                    this.bulkcheck.isvisible = true;
                }
                checkbox = new Element('input', { name: uid, type: 'checkbox' }).addClassName('physid_request');
                Event.observe(checkbox, 'change', this.requestButtonCheck.bind(this));
                tr.insert(new Element('td').insert(checkbox).insert('Request Physics Account Creation'));
            }
            tr.insert({ top: new Element('td').update('<a target="_blank" href="edit_entry_form.html?uid=' + uid + '">Edit directory entry</a>') });
            tr.insert({ top: new Element('td').update(message) });
        }
        else
            tr.insert(new Element('td', { colspan: colspan }).update(message));
        if (this.bulkcheck.isvisible)
            this.lookupmessagestable.insertBefore(tr, this.bulkcheck.up());
        else
            this.lookupmessagestable.appendChild(tr);
    },

    addAddMessage: function(message, uid) {
        message = '<b>' + message + '</b>';
        if (uid != null)
            messageHTML = '<td>' + message + '</td><td><a target="_blank" href="edit_entry_form.html?uid=' + uid + '">Edit directory entry</a></td>';
        else
            messageHTML = '<td colspan="2">' + message + '</td>';
        this.addmessagestable.appendChild(new Element('tr').update(messageHTML));
    },

    addRequestMessage: function(message) {
        message = '<b>' + message + '</b>';
        messageHTML = '<td>' + message + '</td>';
        this.requestmessagestable.appendChild(new Element('tr').update(messageHTML));
    },

    /* Adds a row to the verify results section */
    addUserRow: function(user) {
        tr = new Element('tr');
        this.users.push($H(user).clone());
        this.fields.each(function(field) {
            tr.appendChild(new Element('td', { style: 'padding-right: 10px;' }).update(user[field.key]));
        });
        this.userstable.appendChild(tr);
        this.addbutton.enable();
    },

    /* AJAX Callbacks */
    onLookupSuccess: function(request, person) {
        try {
            result = request.responseText.evalJSON();
            if (result['found'] == 'directory')
                this.addLookupMessage('Existing directory entry for ' + person, result['uid'], result['physid'], result['acctreq']);
            else if (result['err'])
                this.addLookupMessage('There was a problem looking up ' + person + ': ' + result['err']);
            else
                this.addUserRow(result);
        } catch (e) {
            this.addLookupMessage('No match found for ' + person);
        }
        this.lookupRequestsPending--;
        if (!this.lookupRequestsPending) {
            this.toggleLoading();
        }
    },

    onLookupFailure: function(request, person) {
        try {
            result = request.responseText.evalJSON();
            this.addLookupMessage('There was a problem looking up ' + person + ': ' + result['err']);
        } catch (e) {
            this.addLookupMessage('There was a problem looking up ' + person);
        }
        this.lookupRequestsPending--;
        if (!this.lookupRequestsPending) {
            this.toggleLoading();
        }
    },

    onAddSuccess: function(request, user) {
        try {
            result = request.responseText.evalJSON();
            if (result['err'])
                this.addAddMessage('There was a problem adding ' + user.get('x500') + ': ' + result['err']);
            else
                this.addAddMessage('Successfully added ' + user.get('x500') + ': ' + result['message'], result['uid']);
        } catch (e) {
            this.addAddMessage('Failed to parse JSON for ' + user.get('x500'));
        }
        this.addRequestsPending--;
        if (!this.addRequestsPending) {
            this.toggleAdding();
        }
    },

    onAddFailure: function(request, user) {
        try {
            result = request.responseText.evalJSON();
            this.addAddMessage('There was a problem adding ' + user.get('x500') + ': ' + result['err']);
        } catch (e) {
            this.addAddMessage('There was a problem adding ' + user.get('x500'));
        }
        this.addRequestsPending--;
        if (!this.addRequestsPending) {
            this.toggleAdding();
        }
    },

    onRequestSuccess: function(request, user) {
        try {
            result = request.responseText.evalJSON();
            if (result['err'])
                this.addRequestMessage('There was a problem requesting an account for ' + user + ': ' + result['err']);
            else
                this.addRequestMessage('Successfully requested ' + user + ': ' + result['message']);
        } catch (e) {
            this.addRequestMessage('Failed to parse JSON for ' + user);
        }
        this.requestRequestsPending--;
        if (!this.requestRequestsPending) {
            this.toggleRequesting();
        }
    },

    onRequestFailure: function(request, user) {
        try {
            result = request.responseText.evalJSON();
            this.addRequestMessage('There was a problem requesting ' + user + ': ' + result['err']);
        } catch (e) {
            this.addRequestMessage('There was a problem requesting ' + user);
        }
        this.requestRequestsPending--;
        if (!this.requestRequestsPending) {
            this.toggleRequesting();
        }
    }
};
