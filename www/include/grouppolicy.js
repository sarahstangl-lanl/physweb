/* Configuration variables */
var policyDivName = 'policypane';
var url = '/resources/admin/network/grouppolicy_update.html';
var defaultClusterName = 'Default Cluster';
var droppableOptions = {
		policy: {
            accept: ['policyset'],
            groupings: $H({regkey: 'Registry Keys', policyset: 'Policy Sets', cluster: 'Computer Clusters', computer: 'Computers'}),
            prefix: 'policy'
		},
		policyset: {
			accept: ['policy','cluster','computer'],
			groupings: $H({policy: 'Group Policies', cluster: 'Computer Clusters', computer: 'Computers'}),
			prefix: 'policyset'
		},
		computer: {
            accept: ['policyset', 'cluster'],
            groupings: $H({policy: 'Group Policies', policyset: 'Policy Sets', cluster: 'Computer Clusters'}),
            prefix: 'computer'
		},
		cluster: {
            accept: ['policyset', 'computer'],
            groupings: $H({policy: 'Group Policies', policyset: 'Policy Sets', computer: 'Computers'}),
            prefix: 'cluster'
		},
		trash: {
            accept: [
                     'policy', 'policy_policyset',
                     'policyset', 'policyset_policy', 'policyset_computer', 'policyset_cluster',
                     'computer_policyset', 'computer_cluster',
                     'cluster_policyset', 'cluster_computer'
                    ]
		}
};
var POLICY = 0, POLICYSET = 1, COMPUTER = 2, CLUSTER = 3, REGKEY = 4;
var processOrder = [ POLICYSET, CLUSTER, POLICY, COMPUTER ];
var enableHighlight = false;
var enableExpand = false;

/* Global variables/event listeners */
window.addEventListener('load', init, false);

var typeNums = { policy: POLICY, policyset: POLICYSET, computer: COMPUTER, cluster: CLUSTER, regkey: REGKEY };
var int;
var pendingCalls = 0;
var pendingProcess = 0;
var treeDivs = new Array();
var treeChildren = new Array();
var rootClones = new Array();
var undospans = new Array();
var trashspans = new Array();
var undoItems = new Array();
var oldHighlight = enableHighlight;
var policyDiv;
var loadingDiv = document.createElement('div');
var menuDiv = document.createElement('div');
var defaultClusterNode;
var consoleObj = new Object();
consoleObj.content = "";
consoleObj.log = function () {
	if (arguments.length) {
		document.getElementById('consoleLink').style.color = 'red';
		this.content += this.getText(arguments[0]);
		for (var i = 1; i < arguments.length; i++) {
			this.content += ' | ' + this.getText(arguments[i]);
		}
		this.content += '<BR>\n';
	}
}
consoleObj.getText = function(object) {
	if (typeof(object) == "string") return object;
	else if (typeof(object) == "object" && object.id) return object.id;
	else return object;
}
var bb = document.createElement('div');

/* Creates tree structures and initiates population */
function init() { try {
	// Use consoleObj for logging if FireBug 'console' isn't defined
	setDefault("console", consoleObj);
	setDefault("treeClass","mktree");
	setDefault("nodeClosedClass","liClosed");
	setDefault("nodeOpenClass","liOpen");
	setDefault("nodeBulletClass","liBullet");
	setDefault("nodeLinkClass","bullet");
    policyDiv = document.getElementById(policyDivName);
    if (!policyDiv) {
        alert("Could not find policyDiv");
        return;
    }
    policyDiv.appendChild(menuDiv);
    policyDiv.parentNode.appendChild(loadingDiv);
    menuDiv.id = 'menuDiv';
    menuDiv.innerHTML = '<img id="console" src="/images/console.png"><a id="consoleLink" href="#" onclick="launchConsole()">Console</a>';
    menuDiv.innerHTML += '<img id="help" src="/images/help.gif"><a href="#" onclick="launchHelp()">Help</a>';
    loadingDiv.id = 'loading';
	loadingDiv.style.paddingTop = ((document.documentElement.clientHeight - loadingDiv.offsetTop - 90)/2).round() + 'px';
	loadingDiv.style.paddingLeft = ((document.documentElement.clientWidth - loadingDiv.offsetLeft - 150)/2).round() + 'px';
	loadingDiv.style.height = document.documentElement.clientHeight - loadingDiv.offsetTop + 'px';
    loadingDiv.style.fontSize = '16pt';
	loadingDiv.innerHTML = "Loading";
    loadingDiv.zIndex = 1001;
	int = setInterval(function () {
		loadingDiv.innerHTML += '.';
		if (loadingDiv.innerHTML == 'Loading....') loadingDiv.innerHTML = 'Loading';
	}, 200);
    enableHighlight = false;
    policyDiv.appendChild(bb);
    var bbchild = bb.appendChild(document.createElement("div"));
    bbchild.style.backgroundColor = '#33C';
    bbchild.style.opacity = 0.3;
    bbchild.style.width = '100%';
    bbchild.style.height = '100%';
    bb.style.display = 'none';
    bb.style.position = 'relative';
    bb.style.border = '1px solid #33C';
    bb._drags = new Array();
    bb._offsetsSet = false;
    bb._scrollSensitivity = 20;
    bb._defaultScrollSpeed = 15;
    bb.stopScrolling = function () {
    	if (this._scrollInterval) {
    		clearInterval(this._scrollInterval);
    		this._scrollInterval = null;
    	}
    }
    bb.startScrolling = function (speed) {
        if (!(speed[0] || speed[1])) return;
        this._scrollSpeed = [speed[0]*this._defaultScrollSpeed,speed[1]*this._defaultScrollSpeed];
        this._lastScrolled = new Date();
        this._scrollInterval = setInterval(this.scroll.bind(this), 10);

    }
    bb.scroll = function () {
    	var current = new Date();
    	var delta = current - this._lastScrolled;
    	this._lastScrolled = current;
   		this._scroll.scrollLeft += this._scrollSpeed[0] * delta / 1000;
   		this._scroll.scrollTop  += this._scrollSpeed[1] * delta / 1000;
    	Position.prepare();
    }
    bb.reset = function () {
        this._drags.clear();
        toggleRemove(false);
        this._constraint = null;
        this._drops = null;
        this._lastscroll = null;
        this._dragsSelected = false;
        this._offsetsSet = false;
    }
    bb.activateDrop = activateDrop;
    bb.processMouseMove = processMouseMove;
    bb.processMouseUp = processMouseUp;
    window.addEventListener('resize', setHeight, false);
    document.addEventListener('mousemove', function (event) { bb.processMouseMove(event); }, false);
    document.addEventListener('mouseup', function (event) { bb.processMouseUp(event); }, false);
    Draggables.dragTypes = new Hash();
    Droppables.dropTypes = new Hash();
    Droppables.dropTypes.set('trash', new Array());
    var image = new Image(), image2 = new Image(), image3 = new Image();
    image.src = "/images/trashIcon.png";
    image2.src = "/images/undo.png";
    image3.src = "/images/delete_icon.png"
    createTree('policy', 'Group Policies', 'Group Policy', true);
    createTree('policyset', 'Group Policy Sets', 'Group Policy Set', true);
    createTree('computer', 'Computers', 'Computer', false);
    createTree('cluster', 'Computer Clusters', 'Computer Cluster', false);
    populateTreeRoots();
} catch (e) { console.log("init", e); } }

/* Displays trees after population is complete */
function showTrees() { try {
    clearInterval(int);
	policyDiv.style.display = 'block';
    loadingDiv.style.display = 'none';
    loadingDiv.style.opacity = 0.5;
    loadingDiv.style.backgroundColor = '#000';
	setHeight();
    enableHighlight = oldHighlight;
} catch (e) { console.log("showTrees", e); } }

/* Creates the base structure of a tree */
function createTree(type, name, itemname, create) { try {
	var treepane = createNode('div', policyDiv, null, 'treepane');
    createNode('h4', treepane, null, null, null, null, name);
    var treelinks = createNode('div', treepane, null, 'treelinks');
    createNode('span', treelinks, 'expand'+type, 'expand', 'Expand all', function () { expandCollapseTree(type+'tree', true); });
    createNode('span', treelinks, 'collapse'+type, 'collapse', 'Collapse all', function () { expandCollapseTree(type+'tree', false); });
    if (create) createNode('span', treelinks, 'new'+type, 'new', 'Add new '+itemname, function () { newItem(type, itemname); });
    var trash = createNode('span', treelinks, 'trash'+type, 'trash', 'Trash');
    var undo = createNode('span', treelinks, 'undo'+type, 'undodisabled', 'Undo');
	var treediv = createNode('div', treepane, type+'div', 'treediv', null, function (event) { processMouseDown.apply(treediv, [event]); });
	treediv._type = type;
    treediv._typeNum = typeNums[type];
	var ul = createNode('ul', treediv, type+'tree', 'mktree');
    Draggables.dragTypes.set(type, new Array());
    Droppables.dropTypes.set(type, new Array());
    createTrash('trash'+type);
    treeDivs.push(treediv);
    trashspans.push(trash);
    undospans.push(undo);
} catch (e) { console.log("createTree", e); } }

/* Helper function to create new DOM element */
function createNode(type, root, id, className, title, fcn, innerHTML) {
    var node = document.createElement(type);
    if (root) root.appendChild(node);
    if (id) node.id = id;
    if (className) node.className = className;
    if (title) node.setAttribute('title', title);
    if (fcn) node.addEventListener('mousedown', fcn, false);
    if (innerHTML) node.innerHTML = innerHTML;
    return node;
}

/* Creates a root element of a tree */
function createItem(type, id, name, sort) { try {
    sort = sort == null ? true : sort;
	var ul = document.getElementById(type+'tree');
	if (!ul) return;
	var li = createNode('li', null, null, nodeClosedClass);
    var bullet = createNode('span', li, null, nodeLinkClass, null, null, '\u00A0');
    bullet.toggle = toggleList;
    bullet.addEventListener('mousedown', bullet.toggle, false);
	var span = createNode('span', li, type+id, type, name, null, name);
	li.nameNode = span;
	span._type = type;
    span._typeNum = typeNums[type];
    span._draggable = createDraggable(span);
    span._chunked = chunkify(name);
    if (type == 'computer')
    	span.addClassName('nocluster');
    rootClones[span.id] = new Array();
    //Find insert position if sort requested else insert at top of tree
    if (sort) insertNode(ul, li);
    else if (ul.childNodes.length)
        ul.insertBefore(li, ul.childNodes[0]);
    else
        ul.appendChild(li);
    createDroppable(span.id, type, $H(droppableOptions).get(type));
    return span;
} catch (e) { console.log("createItem", e); } }

/* Creates a droppable object - used for trash and root elements */
function createDroppable(id, type, options) { try {
    var ul, node = document.getElementById(id), parentNode = node.parentNode;
    if (Object.isHash(options.groupings)) {
        options.typeNodes = $H({ });
        if (node.nextSibling && node.nextSibling.nodeName == "UL")
            ul = node.nextSibling;
        else
            ul = parentNode.appendChild(document.createElement('ul'));
        var keys = options.groupings.keys();
        for (var i = 0; i < keys.length; i++) {
            var li = createNode('li', ul, null, nodeBulletClass);
            li._type = keys[i];
            li._typeNum = typeNums[keys[i]];
            options.typeNodes.set(typeNums[keys[i]],li);
            createNode('span', li, null, nodeLinkClass, null, null, '\u00A0'+options.groupings.get(keys[i]));
        }
    }
    var defaults = {
        greedy: false,
        accept: null,
        hoverclass: 'hover',
        onDrop: function(element) {
            toggleLoading(true);
            toggleUndo(false);
            pendingCalls++;
            var type, target, item;
            var dropType = node._typeNum;
            var elementType = element._typeNum;
            switch(dropType) {
                case POLICY:    type = 'policy'; target = id; item = element.id; break;
                case POLICYSET: if (elementType == POLICY) { type = 'policy'; target = element.id; item = id; }
                                else { type = 'policyset'; target = id; item = element.id; } break;
                case CLUSTER:   if (elementType == COMPUTER) { type = 'cluster'; target = id; item = element.id; }
                                else { type = 'policyset'; target = element.id; item = id; } break;
                case COMPUTER:  if (elementType == CLUSTER) type = 'cluster';
                                else type = 'policyset'; target = element.id; item = id; break;
            }
            new Ajax.Request(url, {
                method: 'get',
                onSuccess: function(transport) {
                    if (transport.responseText.match(/^OK/)) {
                        addItem(this, element, null, enableExpand, true);
                    }
                    else if (!transport.responseText.match(/Duplicate/)) alert("Failure: "+transport.responseText);
                    pendingCalls--;
                    if (!pendingCalls) toggleLoading(false);
                }.bind(this),
                parameters: { action: 'add', type: type, target: target, id: item }
            });
            return true;
        },
        typeNodes: null,
        prefix: null,
        propagate: null
    }
    Object.extend(defaults, options);
    Droppables.add(node, defaults);
    node._droppable = Droppables.drops[Droppables.drops.length-1];
    var drops = Droppables.dropTypes.get(type);
    drops.push(node._droppable);
    Droppables.dropTypes.set(type, drops);
} catch (e) { console.log("createDroppable", e); } }

/* Creates a draggable object - used for root elements and non-inherited child elements */
function createDraggable(element) { try {
    var defaults = {
        	quiet: true,
            revert: true,
            ghosting: true,
            starteffect: function(element) {
                element.style.opacity = 0.5;
            },
            endeffect: function(element) {
                element.style.opacity = 1;
            },
            reverteffect: function(element) {
                element.style.top = 0;
                element.style.left = 0;
                element.style.position = 'relative';
            },
            onDrag: function (drag, event) {
                if (event && !bb._dragsSelected) drag.activateDrop([Event.pointerX(event), Event.pointerY(event)], drag);
            },
            onStart: function (drag) {
                if (drag.element._parent) drag.element.innerHTML = drag.element._parent.innerHTML;
            },
            onEnd: function (drag) {
                if (drag.element._parent) drag.element.updateDisplay();
                drag._lastscroll = null;
                drag._drops = null;
            },
            scrolls: treeDivs
    }
    var options = Object.extend(defaults, arguments[1] || { });
    var draggable = new Draggable(element, options);
    draggable.activateDrop = activateDrop;
    //Create observer to watch for double-clicks
    draggable.handle.addEventListener('mousedown', function (event) { processDoubleClick.apply(draggable, [event]); }, false);
    var type = element._root ? element._root._type : element._type;
    //Set cursor
    element.style.cursor = 'pointer';
    var drags = Draggables.dragTypes.get(type);
    drags.push(draggable);
    Draggables.dragTypes.set(type, drags);
    return draggable;
} catch (e) { console.log("createDraggable", e); } }

/* Creates a trash droppable object by calling createDroppable with special parameters */
function createTrash(id) { try {
	var options = $H(droppableOptions).get('trash');
	var defaults = {
            hoverclass: 'trashhover',
            onDrop: function(element) {
                toggleLoading(true);
                if (!bb._dragsSelected) {
                	undoItems.clear();
                }
                if (element._parent) removeItem(element, true, true);
                else {
                    if (confirm("WARNING: Deleting a root node cannot be undone! Continue?")) {
                    	var drop = element._droppable;
                        var types = drop.typeNodes.keys();
                        var childNodes = new Array();
                        for (var i = 0, len = types.length; i < len; ++i) {
                        	if (types[i] == REGKEY) continue;
                            var typeNode = drop.typeNodes.get(types[i]);
                            if (typeNode.nodeName != "UL") continue;
                            for (var j = 0, len2 = typeNode.childNodes.length; j < len2; ++j) {
                                var childNode = typeNode.childNodes[j];
                                if (!childNode.nameNode._isInherited)
                                    childNodes.push(childNode.nameNode);
                            }
                        }
                        for (var i = 0, len = childNodes.length; i < len; ++i)
                        	removeItem(childNodes[i], false, false);
                        pendingCalls++;
                        new Ajax.Request(url, {
                            method: 'get',
                            onSuccess: function(transport) {
                                if (transport.responseText.match(/^OK/)) { try {
                                    var type = element.className.split(' ')[0];
                                    var drops = Droppables.dropTypes.get(type);
                                    var drop = element._droppable;
                                    var dropPos = drops.indexOf(drop);
                                    drops.splice(dropPos, 1);
                                    Droppables.dropTypes.set(type, drops);
                                    Droppables.remove(element);
                                    element.parentNode.parentNode.removeChild(element.parentNode);
                                } catch (e) { console.log("createTrash", e); }
                                } else alert("Failure: "+transport.responseText);
                                pendingCalls--;
                                if (!pendingCalls) toggleLoading(false);
                            },
                            parameters: { action: 'delete', id: element.id }
                        })
                    } else {
                    	toggleLoading(false);
                    	return false;
                    }
                }
                return true;
            }
	}
    Object.extend(defaults, options);	
    createDroppable(id, 'trash', defaults);
    return Droppables.drops[Droppables.drops.length-1];
} catch (e) { console.log("createTrash", e); } }

/* Populates the root elements of each tree */
function populateTreeRoots() { try {
    for (var i = 0; i < treeDivs.length; i++) {
		pendingCalls++;
	    new Ajax.Request(url, {
	        method: 'get',
	        onSuccess: function(transport) {
                if (transport.responseText.match(/^OK/)) {
                  var results = transport.responseText.split('\n');
                  for (var j = 1; j < results.length; j++) {
                      var parts = results[j].split(':');
                      createItem(this._type, parts[0], parts[1], true);
                  }
                }
                pendingCalls--;
                if (!pendingCalls) {
            	    defaultClusterNode = createItem('cluster', 0, defaultClusterName, false);
                	populateTreeChildren();
                }
	        }.bind(treeDivs[i]),
	        onFailure: function(transport) {
	        	showTrees();
	        	console.log("Failed to retrieve tree data: " + transport.responseText);
	        },
	        parameters: { action: 'get', type: treeDivs[i]._type }
	    });
	}
} catch (e) { console.log("populateTreeRoots", e); } }

/* Populates the child elements of each tree */
function populateTreeChildren() { try {
    for (var i = 0; i < treeDivs.length; i++) {
		pendingCalls++;
	    new Ajax.Request(url, {
	        method: 'get',
	        onSuccess: function(transport) {
                processResults.call(this, transport.responseText.split('\n'));
	        }.bind(treeDivs[i]),
	        parameters: { action: 'getitems', type: treeDivs[i]._type }
	      });
	}
} catch (e) { console.log("populateTreeChildren", e); } }

/* Processes the result of an AJAX request */
function processResults(results) {
    var typeNum = this._typeNum;
    if (typeNum != processOrder[pendingProcess]) {
        setTimeout(function (obj, results) { processResults.call(obj, results); }, 10, this, results);
        return;
    }
    if (results[0] == "OK") {
        var targetType;
        if (typeNum == POLICY) targetType = 'policyset';
        else if (typeNum == CLUSTER) targetType = 'computer';
        for (var j = 1; j < results.length; j++) {
            var result = results[j];
            var parts = result.split(':');
            if (typeNum == POLICYSET) targetType = parts[2] ? 'cluster' : 'computer';
            if (!targetType) return;
            var element = document.getElementById(this._type+parts[1]);
            var target = document.getElementById(targetType+(parts[2] ? parts[2] : parts[3]));
            if (element == null || target == null) {
            	if (targetType == 'cluster') {
            		createItem('cluster', parts[2], parts[2], true);
            		addItem(document.getElementById(targetType+(parts[2]))._droppable, element, null, false, true);
            	}
            	else if (targetType == 'computer') {
            		createItem('computer', parts[3], '??hostid'+parts[3]+'??', true);
            		addItem(document.getElementById(targetType+(parts[3]))._droppable, element, null, false, true);
            	}
            	else console.log("processResults: element or target null", element, this._type+parts[1], target, targetType+(parts[2] ? parts[2] : parts[3]));
            }
            else addItem(target._droppable, element, null, false, true);
        }
    }
    pendingProcess++;
    pendingCalls--;
    if (!pendingCalls) populateRegKeys();
}

/* Populates the registry key elements in the Policies tree */
function populateRegKeys() { try {
	new Ajax.Request(url, {
		method: 'get',
		onSuccess: function(transport) {
			if (transport.responseText.match(/^OK/)) {
                var results = transport.responseText.split('\n');
                for (var i = 0; i < results.length; i++) {
                    var result = results[i];
					if (result == "OK") continue;
					var parts = result.split(':');
					var drop = document.getElementById('policy'+parts[0])._droppable;
					if (!drop) return;
					var typeNode = drop.typeNodes.get(REGKEY);
					var ul, span;
					if (typeNode.nodeName != "UL") {
						typeNode.className = nodeClosedClass;
	                    ul = createNode('ul', typeNode, null, null, null, null, unescape(parts[1]));
						drop.typeNodes.set(REGKEY, ul);
	                    span = ul.previousSibling;
	                    span.toggle = toggleList;
	                    span.addEventListener('mousedown', span.toggle, false);
					} else {
						typeNode.innerHTML += unescape(parts[1]);
					}
                    for (var j = 0; j < ul.childNodes.length; j++) {
                        span = ul.childNodes[j].firstChild;
                        if (span.toggle != toggleList) {
                        	span.toggle = toggleList;
                            span.addEventListener('mousedown', span.toggle, false);
                        }
                    }
				}
                populateDefaultCluster();
			}
		},
		parameters: { action: 'getregkeys' }
	});
} catch (e) { console.log("populateRegKeys", e); } }

/* Adds machines without a cluster to the default cluster */
function populateDefaultCluster() {
	for (var i = 0; i < treeDivs.length; i++) {
		if (treeDivs[i]._type == 'computer') {
			for (var j = 0; j < treeDivs[i].firstChild.childNodes.length; j++) {
				var childNode = treeDivs[i].firstChild.childNodes[j];
				if (childNode.nameNode.className.match(/nocluster/)) {
					addItem(childNode.nameNode._droppable, defaultClusterNode, null, false, true, false);
				}
			}
			break;
		}
	}
    showTrees();
}

/* Adds a copy of a root element to another tree */
function addItem(drop, element, source, expand, propagate, sourceIsArray) { try {
    var id = drop.element.id+'_'+element.id, target = document.getElementById(id);
    var span,ul;
    if (!target) {
        // Find typeNode
        var sourceClassName = element._type;
        var typeNode = drop.typeNodes.get(element._typeNum);
        if (!typeNode) {
            return false;
        }
        // Remove old cluster if changing computer cluster
        if (element._typeNum == CLUSTER && drop.element._typeNum == COMPUTER) {
        	if (typeNode.nodeName == "UL") {
            	typeNode.firstChild.nameNode.removeSource(typeNode.firstChild.nameNode._rootName, true, false);
            	typeNode = drop.typeNodes.get(CLUSTER);
        	}
        }
        if (typeNode.nodeName == "UL")
            ul = typeNode;
        else {
            typeNode.className = nodeClosedClass;
            typeNode.firstChild.toggle = toggleList;
            typeNode.firstChild.addEventListener('mousedown', typeNode.firstChild.toggle, false);
            ul = typeNode.appendChild(document.createElement('ul'));
            drop.typeNodes.set(element._typeNum, ul);
        }
        // Set new element attributes
        var li = createNode('li', null, id, nodeBulletClass);
        li._root = drop.element;
        li._parent = element;
        li._rootCloneNum = rootClones[element.id].length;
        rootClones[element.id].push(li);
        var bullet = createNode('span', li, null, nodeLinkClass, null, null, '\u00A0');
        span = element.cloneNode(true);
        span.style.position = 'relative';
        span.style.top = 0;
        span.style.left = 0;
        span.style.opacity = 1.0;
        span.id = '';
        span.className = drop.prefix + '_'+ sourceClassName;
        span._sources = new Array();
        span._root = drop.element;
        span._rootName = drop.element.id;
        span._parent = element;
        span._parentName = element.id;
        span._type = sourceClassName;
        span._typeNum = typeNums[sourceClassName];
        span._typeNode = ul;
        span._isChild = 1;
        span.updateDisplay = function(nameChange) {
                var root = this._rootName;
                var uniqueSources = new Array();
                var displaySources = new Array();
                var hasRootSource = false;
                for (var i = 0; i < this._sources.length; i++) {
                    var source = this._sources[i];
                    if (uniqueSources.indexOf(source) == -1) {
                        uniqueSources.push(source);
                        if (source == root) hasRootSource = true;
                        else displaySources.push(source);
                    }
                }
                this._sources = uniqueSources;
                if (this._isInherited) {
                    // Create draggable if no longer inherited
                    if (hasRootSource) {
                        this.className = this.className.replace(' inherit', '');
                        this._isInherited = false;
                        this.style.cursor = '';
                        this._draggable = createDraggable(this);
                    }
                } else if (!hasRootSource && this._draggable) {
                    // Remove draggable if only inherited
                    this.className += ' inherit';
                    this._isInherited = true;
                    this.style.cursor = 'default';
                    var drags = Draggables.dragTypes.get(this._type);
                    var drag = this._draggable;
                    var dragPos = drags.indexOf(drag);
                    drags.splice(dragPos, 1);
                    Draggables.dragTypes.set(this._type, drags);
                    this._draggable.destroy();
                    this._draggable = null;
                }
                var text = this._parent.innerHTML;
                if (displaySources.length) {
                    var names = new Array();
                    for (var i = 0; i < displaySources.length; i++)
                        names.push(document.getElementById(displaySources[i]).innerHTML);
                    text += " ("+names.sort().join(', ')+")";
                }
                this.innerHTML = text;
                this.setAttribute('title',text);
                if (nameChange)
                    insertNode(this.parentNode.parentNode, this.parentNode);
        }
        span.addSource = function (source, sourceIsArray) {
                if (sourceIsArray) {
                    for (var i = 0, len = source.length; i < len; ++i) {
                        this._sources.push(source[i]);
                    }
                }
                else {
                    this._sources.push(source);
                }
                if (!this._typeNode.parentNode) {
                	console.log("No parentNode!", this);
                }
                if (this._typeNode.parentNode._isExpanded) {
                	this.updateDisplay(false);
                } else {
                	this.parentNode._isUpdated = true;
                	this._typeNode._isUpdated = true;
                }
        }
        span.removeSource = function (source, propagate, checkCluster) { try {
                var parentName = this._parentName;
                var rootName = this._rootName;
                var sourcePos = this._sources.indexOf(source);
                if (sourcePos != -1) this._sources.splice(sourcePos, 1);
                else return;
                if (propagate) {
                    var targetNodes = new Array();
                    var childNodes = rootClones[parentName];
                    for (var i = 0, len = childNodes.length; i < len; ++i) {
                        var childNode = childNodes[i];
                		if (childNode.nameNode._sources.indexOf(source) != -1)
                            targetNodes.push(childNode);
                    }
                    for (var i = 0, len = targetNodes.length; i < len; ++i)
                        targetNodes[i].nameNode.removeSource(source, false, true);
                    childNodes = rootClones[source];
                    for (var i = 0, len = childNodes.length; i < len; ++i) {
                        childNode = childNodes[i];
                		if (childNode.nameNode._sources.indexOf(parentName) != -1)
                            targetNodes.push(childNode);
                	}
                    for (var i = 0, len = targetNodes.length; i < len; ++i)
                        targetNodes[i].nameNode.removeSource(parentName, false, true);
                }
                if (!this._sources.length) {
                    var targetNode = this.parentNode;
                    var drop = this._root._droppable;
                    // Remove draggable
                    if (this._draggable) {
                    	var drags = Draggables.dragTypes.get(this._type);
                        var drag = this._draggable;
                        var dragPos = drags.indexOf(drag);
                        drags.splice(dragPos, 1);
                    	Draggables.dragTypes.set(this._type, drags);
                    	this._draggable.destroy();
                    }
                    // Update treeChildren
                    var childNum = targetNode._childNum;
                    treeChildren[childNum] = treeChildren.pop();
                    treeChildren[childNum]._childNum = childNum;
                    // Update rootClones
                    var rootCloneArray = rootClones[this._parentName];
                    var rootCloneNum = this.parentNode._rootCloneNum;
                    rootCloneArray[rootCloneNum] = rootCloneArray.pop();
                    rootCloneArray[rootCloneNum]._rootCloneNum = rootCloneNum;
                    // Remove UL if soon to be empty and update typeNode
                    if (this._typeNode.childNodes.length == 1) {
                        targetNode = targetNode.parentNode;
                        this._typeNode = targetNode.parentNode;
                        drop.typeNodes.set(this._typeNum, this._typeNode);
                        this._typeNode.className = nodeBulletClass;
                        this._typeNode._isExpanded = false;
                        targetNode.previousSibling.removeEventListener('mousedown', targetNode.previousSibling.toggle, false);
                    }
                    // Remove any inherited children from root
                    var types = drop.typeNodes.keys();
                    var childNodes = new Array();
                    for (var i = 0, len = types.length; i < len; ++i) {
                        if (types[i] == REGKEY) continue;
                        var typeNode = drop.typeNodes.get(types[i]);
                        if (typeNode.nodeName != "UL") continue;
                        for (var j = 0, len2 = typeNode.childNodes.length; j < len2; ++j) {
                            var childNode = typeNode.childNodes[j];
                            if (childNode.nameNode._sources.indexOf(parentName) != -1)
                                childNodes.push(childNode);
                        }
                    }
                    for (var i = 0, len = childNodes.length; i < len; ++i)
                        childNodes[i].nameNode.removeSource(parentName, false, true);
                    // Remove element
                    targetNode.parentNode.removeChild(targetNode);
                	// Check for computer having no clusters and add back to default cluster
                	if (checkCluster && this._root._typeNum == COMPUTER && this._typeNum == CLUSTER && this._typeNode.nodeName == "LI") {
                		this._root.addClassName('nocluster');
                		addItem(drop, defaultClusterNode, null, false, true, false);
                	}
                }
                else {
                    if (this._typeNode.parentNode._isExpanded) {
                        this.updateDisplay(false);
                    } else {
                        this.parentNode._isUpdated = true;
                        this._typeNode._isUpdated = true;
                    }
                }
        } catch (e) { console.log("removeSource", e); } }
        li.nameNode = span;
        li.appendChild(span);
        insertNode(ul, li);
        if (source) {
            span._draggable = null;
            span.addSource(source, sourceIsArray);
            span.style.cursor = 'default';
            span.className += ' inherit';
            span._isInherited = true;
        } else {
            span.addSource(drop.element.id);
            if (element != defaultClusterNode && (drop.element != defaultClusterNode || element._typeNum != COMPUTER)) span._draggable = createDraggable(span);
            else {
                span.style.cursor = 'default';
            }
        }
        if (span._typeNum == CLUSTER && element != defaultClusterNode) drop.element.removeClassName('nocluster');
        li._childNum = treeChildren.length;
        treeChildren.push(li);
    } else {
        span = target.nameNode;
        if (source) span.addSource(source, sourceIsArray);
        else span.addSource(drop.element.id);
        ul = target.parentNode;
    }
    if (propagate) propagateElements(element, drop, expand);
    if (enableHighlight) drop.element.highlight();
    if (expand) {
        ul.parentNode.className = nodeOpenClass;
        ul.parentNode.parentNode.parentNode.className = nodeOpenClass;
    }
    } catch (e) { console.log("addItem", e, element); }
    return true;
}

/* Requests that a new item be created */
function newItem(type, itemname) { try {
	if (type == 'policy') window.location = 'PolicyBuilder.exe';
	else {
	    new Ajax.Request(url, {
	        method: 'get',
	        onSuccess: function(transport) {
	            if (transport.responseText.match(/^OK/)) { 
	                var parts = transport.responseText.split(':');
	                span = createItem(type, parts[1], parts[2], false)
	                editItem(span._draggable);
	            } 
	        },
	        parameters: { action: 'new', type: type, name: itemname }
	    });
	}
} catch (e) { console.log("newItem", e); } }

/* Allows a non-inherited element to be renamed */
function editItem(draggable) { try {
    Draggables._editingDraggable = draggable;
    var span = draggable.element;
    var input = document.createElement('input');
    var origValue = span.innerHTML;
    // Commit change on blur
    input.onblur = function() {
        if (!input.value) {
            alert("The value cannot be empty");
            setTimeout(function() { input.focus(); },250);
        } else {
            if (input.value == origValue) {
                span.innerHTML = origValue;
                insertNode(span.parentNode.parentNode, span.parentNode);
                Draggables._editingDraggable = null;
            } else {
                var id = span.id ? span.id : span._parentName;
                new Ajax.Request(url, {
                    method: 'get',
                    onSuccess: function(transport) {
                        if (transport.responseText.match(/^OK/)) {
                            var node = document.getElementById(id);
                            node.innerHTML = input.value;
                            node._chunked = chunkify(input.value);
                            for (var i = 0, len = treeChildren.length; i < len; ++i) {
                                var li = treeChildren[i];
                                if (li._parent.id == id)
                                    li.nameNode.updateDisplay(true);
                                else if (li.nameNode._sources.indexOf(id) != -1) {
                                    if (li.parentNode.parentNode._isExpanded) {
                                        li.nameNode.updateDisplay(false);
                                    } else {
                                        li._isUpdated = true;
                                        li.parentNode._isUpdated = true;
                                    }
                                }
                            }
                            insertNode(span.parentNode.parentNode, span.parentNode);
                            Draggables._editingDraggable = null;
                        } else {
                            if (transport.responseText.length < 1024)
                                alert(transport.responseText);
                            else
                                alert("Failed to update name. Response text too long to display.");
                            setTimeout(function() { input.select(); input.focus(); },250);
                        }},
                    parameters: { action: 'edit', name: input.value, id: id }
                });
            }
        }
    }
    // Blur focus on [enter] keypress, restore previous value on [esc]
    input.onkeydown = function(event) {
          if (event.keyCode == Event.KEY_RETURN) this.blur();
          else if (event.keyCode == Event.KEY_ESC) {
              event.stop();
              this.value = origValue;
              this.blur();
          }}
    input.type = 'text';
    input.setAttribute('autocomplete','off');
    input.style.margin = '-2px 0 -3px 0';
    input.style.width = '200px';
    input.value = origValue;
    span.innerHTML = '';
    span.appendChild(input);
    input.focus();
    input.select();
} catch (e) { console.log("editItem", e); } }

/* Removes a child element from a tree */
function removeItem(element, enableUndo, showOnComplete) { try {
    var type, target, item;
    var itemParent = element._parent;
    var itemType = itemParent._typeNum;
    var targetType = element._root._typeNum;
    switch(itemType) {
        case POLICY:    type = 'policy'; target = itemParent.id; item = element._rootName; break;
        case POLICYSET: if (targetType == POLICY) { type = 'policy'; target = element._rootName; item = itemParent.id; }
                          else { type = 'policyset'; target = itemParent.id; item = element._rootName; } break;
        case CLUSTER:   if (targetType == COMPUTER) { type = 'cluster'; target = itemParent.id; item = element._rootName; }
                          else { type = 'policyset'; target = element._rootName; item = itemParent.id; } break;
        case COMPUTER:  if (targetType == CLUSTER) type = 'cluster';
                          else type = 'policyset'; target = element._rootName; item = itemParent.id; break;
    }
    pendingCalls++;
    new Ajax.Request(url, {
        method: 'get',
        onSuccess: function(transport) {
            if (transport.responseText.match(/^OK/)) {
                element.removeSource(element._rootName, true, true);
                if (enableUndo) {
                    toggleUndo(true);
                    undoItems.push({ drop: element._root._droppable, element: element._parent });
                }
            }
            else {
                alert("Failure: "+transport.responseText);
            }
            pendingCalls--;
            if (showOnComplete && !pendingCalls) toggleLoading(false);
        },
        parameters: { action: 'remove', type: type, target: target, id: item }
    });
} catch (e) { console.log("removeItem", e); } }

/* Adds the last-removed child element(s) back to the tree */
function undo() { try {
    //TODO Optimize population order
    toggleLoading(true);
    for (var i = 0, len = undoItems.length; i < len; ++i) {
        var undoItem = undoItems[i];
        var type, target, item;
        var id = undoItem.drop.element.id, element = undoItem.element;
        var dropType = undoItem.drop.element._typeNum;
        var elementType = element._typeNum;
        switch(dropType) {
            case POLICY:    type = 'policy'; target = id; item = element.id; break;
            case POLICYSET: if (elementType == POLICY) { type = 'policy'; target = element.id; item = id; }
                              else { type = 'policyset'; target = id; item = element.id; } break;
            case CLUSTER:   if (elementType == COMPUTER) { type = 'cluster'; target = id; item = element.id; }
                              else { type = 'policyset'; target = element.id; item = id; } break;
            case COMPUTER:  if (elementType == CLUSTER) type = 'cluster';
                              else type = 'policyset'; target = element.id; item = id; break;
        }
        pendingCalls++;
        new Ajax.Request(url, {
            method: 'get',
            onSuccess: function(transport) { try {
                if (transport.responseText.match(/^OK/)) {
                    addItem(this.drop, this.element, null, enableExpand, true);
                }
                else alert("Failure: "+transport.responseText);
                pendingCalls--;
                if (!pendingCalls) {
                    toggleUndo(false);
                    undoItems.clear();
                    toggleLoading(false);
                }
            } catch (e) { console.log("undo ajax", e); } }.bind(undoItem),
            parameters: { action: 'add', type: type, target: target, id: item }
        });
    }
} catch (e) { console.log("undo", e); } }

/* Propagates an added child element to any other affected trees */
function propagateElements(element, drop, expand) {
    // Reciprocate element
    addItem(element._droppable, drop.element, null, expand, false);
    // Switch elements if necessary
    switch(element._typeNum) {
        case CLUSTER:
            if (drop.element._typeNum == COMPUTER) break;
        case POLICY:
        case COMPUTER:
            var temp = drop;
            drop = element._droppable;
            element = temp.element;
            temp = null;
    }
    // Propagate elements
    var sourcedrop = element._droppable;
    var sourceType = element._typeNum;
    var dropType = drop.element._typeNum;
    var childNodes, dropNodes;
    switch(sourceType) {
        case POLICYSET:
            switch(dropType) {
                case POLICY:
                	childNodes = getChildNodes(sourcedrop, COMPUTER);
                	for (var i = 0, len = childNodes.length; i < len; ++i) {
                        addItem(childNodes[i]._parent._droppable, drop.element, element.id, expand, false);
                        addItem(drop, childNodes[i]._parent, childNodes[i].nameNode._sources, expand, false, true);
                    }
                	childNodes = getChildNodes(sourcedrop, CLUSTER);
                	for (var i = 0, len = childNodes.length; i < len; ++i) {
                        addItem(childNodes[i]._parent._droppable, drop.element, element.id, expand, false);
                        addItem(drop, childNodes[i]._parent, element.id, expand, false);
                    }
                    break;
                case COMPUTER:
                	childNodes = getChildNodes(sourcedrop, POLICY);
                	for (var i = 0, len = childNodes.length; i < len; ++i) {
                        addItem(childNodes[i]._parent._droppable, drop.element, element.id, expand, false);
                        addItem(drop, childNodes[i]._parent, element.id, expand, false);
                    }
                    break;
                case CLUSTER:
                    dropNodes = getChildNodes(drop, COMPUTER);
                	childNodes = getChildNodes(sourcedrop, POLICY);
                	for (var i = 0, len = childNodes.length; i < len; ++i) {
                        addItem(childNodes[i]._parent._droppable, drop.element, element.id, expand, false);
                        addItem(drop, childNodes[i]._parent, element.id, expand, false);
                    	for (var j = 0, len2 = dropNodes.length; j < len2; ++j) {
                            addItem(childNodes[i]._parent._droppable, dropNodes[j]._parent, drop.element.id, expand, false);
                            addItem(dropNodes[j]._parent._droppable, childNodes[i]._parent, element.id, expand, false);
                        }
                    }
                	for (var j = 0, len2 = dropNodes.length; j < len2; ++j) {
                        addItem(dropNodes[j]._parent._droppable, element, drop.element.id, expand, false);
                        addItem(sourcedrop, dropNodes[j]._parent, drop.element.id, expand, false);
                    }
                    break;
            }
            break;
        case CLUSTER:
        	childNodes = getChildNodes(sourcedrop, POLICY);
        	for (var i = 0, len = childNodes.length; i < len; ++i) {
                addItem(drop, childNodes[i]._parent, childNodes[i].nameNode._sources, expand, false, true);
                addItem(childNodes[i]._parent._droppable, drop.element, element.id, expand, false);
            }
        	childNodes = getChildNodes(sourcedrop, POLICYSET);
        	for (var i = 0, len = childNodes.length; i < len; ++i) {
                addItem(childNodes[i]._parent._droppable, drop.element, element.id, expand, false);
                addItem(drop, childNodes[i]._parent, element.id, expand, false);
            }
            break;
    }
}

/* Returns the LIs from a given Droppable and type */
function getChildNodes(drop, typeNum) { try {
    var typeNode = drop.typeNodes.get(typeNum);
    if (typeNode.nodeName == 'UL')
        return typeNode.childNodes;
    else
        return [ ];
} catch (e) { console.log("getChildNodes", e); } }

/* Used to highlight a droppable on hover - optimized version of the Droppables function */
function activateDrop(pointer, drag) {
    if (!this._lastscroll || (this._lastscroll != 'trash' && drag.options.scroll != this._lastscroll)) {
    	if (drag.element._isChild) {
    		this._lastscroll = 'trash';
    		this._drops = Droppables.dropTypes.get('trash');
    	}
    	else if (drag.options.scroll) {
    		this._lastscroll = drag.options.scroll;
    		if (droppableOptions[drag.options.scroll._type].accept.indexOf(drag.element.className.split(' ')[0]) != -1)
    			this._drops = Droppables.dropTypes.get(drag.options.scroll._type).concat(Droppables.dropTypes.get('trash'));
    		else
    			this._drops = Droppables.dropTypes.get('trash');
    	}
    	else {
    		this._lastscroll = true;
    		this._drops = Droppables.dropTypes.get('trash');
    	}
    }
    if (this._drops) {
		if (Droppables.last_active) Droppables.deactivate(Droppables.last_active);
        for (var i = 0; i < this._drops.length; i++) {
    		if (Droppables.isAffected(pointer, drag.element, this._drops[i])) {
    			Droppables.activate(this._drops[i]);
    			break;
    		}
        }
    }
}

/* Handles selecting multiple elements or dragging selected elements */
function processMouseMove(event) { try {
    if (this._isDragging) {
        var pointer = [event.clientX, event.clientY];
        if (Draggables._lastPointer && (Draggables._lastPointer.inspect() == pointer.inspect())) return;
        Draggables._lastPointer = pointer;
        if (!this._dragsSelected) {
            var top, left, width, height;
            var windowOffset = { left: window.pageXOffset, top: window.pageYOffset };
            var divPos = {
            	left: this._scroll.offsetLeft - windowOffset.left,
            	top: this._scroll.offsetTop - windowOffset.top
            }
            var divScroll = {
                left: this._scroll.scrollLeft,
                top: this._scroll.scrollTop
            }
            var divDim = {
                width: this._scroll.scrollWidth,
                height: this._scroll.scrollHeight
            }
            var bbOffset = {
                left: divScroll.left + windowOffset.left,
                top: divScroll.top + windowOffset.top
            }
            var offset = {
                left: bbOffset.left - this._origOffset.left,
                top: bbOffset.top - this._origOffset.top
            }
            width = pointer[0] - this._clickPos.left + offset.left;
            height = pointer[1] - this._clickPos.top + offset.top;
            if (width >= 0) {
                if (pointer[0] > divPos.left + divDim.width - divScroll.left - 2)
                    width = divPos.left + divDim.width - this._clickPos.left - this._origOffset.left + windowOffset.left - 2;
                left = this._cumPos.left;
            }
            else {
                if (pointer[0] < divPos.left)
                    width = divPos.left - this._clickPos.left + offset.left;
                left = this._cumPos.left + width;
            }
            if (height >= 0) {
                if (pointer[1] > divPos.top + divDim.height - divScroll.top - 3)
                    height = divPos.top + divDim.height - this._clickPos.top - this._origOffset.top + windowOffset.top - 3;
                top = this._cumPos.top;
            }
            else {
                if (pointer[1] < divPos.top)
                    height = divPos.top - this._clickPos.top + offset.top;
                top = this._cumPos.top + height;
            }
            width = Math.abs(width);
            height = Math.abs(height);
            this.style.width = width + 'px';
            this.style.height = height + 'px';
            this.style.marginTop = top + 'px';
            this.style.marginLeft = left + 'px';
            var drags = Draggables.dragTypes.get(this._type);
            for (var i = 0; i < drags.length; i++) {
                var draggable = drags[i];
                var e = draggable.element;
            	//Constrain types to either root nodes or children (0 = root, 1 = child)
                var elementType = (e._isChild ? 1 : 0);
                if ((this._constraint == 1 && !elementType) || (this._constraint == 0 && elementType)) continue;
                if (e.offsetLeft) {
                    var pos = { left: e.offsetLeft - bbOffset.left, top: e.offsetTop - bbOffset.top };
                    var dim = e.getDimensions(); //height, width
                    if (((pos.left > this._origPos.left + left - offset.left + width) || 
                        (pos.left + dim.width < this._origPos.left - offset.left + left) || 
                        (pos.top > this._origPos.top + top - offset.top + height) || 
                        (pos.top + dim.height < this._origPos.top - offset.top + top)))
                    {
                        if (draggable._isSelected) {
                            e.className = e.className.replace('hover', '');
                            draggable._isSelected = false;
                            this._numDrags--;
                            if (!this._numDrags) this._constraint = null;
                        }
                    } else if (!draggable._isSelected) {
                    	if (!this._numDrags) this._constraint = elementType;
                        e.className += ' hover';
                        draggable._isSelected = true;
                        this._numDrags++;
                    }
                }
            }
            //Scroll DIV as necessary
            this.stopScrolling();
            Position.prepare();
            var p;
            p = Position.page(this._scroll);
            p[0] += this._scroll.scrollLeft + Position.deltaX - windowOffset.left;
            p[1] += this._scroll.scrollTop + Position.deltaY - windowOffset.top;
            p.push(p[0]+this._scroll.offsetWidth);
            p.push(p[1]+this._scroll.offsetHeight);
            var speed = [0,0];
            if (pointer[0] < (p[0]+this._scrollSensitivity)) speed[0] = pointer[0]-(p[0]+this._scrollSensitivity);
            if (pointer[1] < (p[1]+this._scrollSensitivity)) speed[1] = pointer[1]-(p[1]+this._scrollSensitivity);
            if (pointer[0] > (p[2]-this._scrollSensitivity)) speed[0] = pointer[0]-(p[2]-this._scrollSensitivity);
            if (pointer[1] > (p[3]-this._scrollSensitivity)) speed[1] = pointer[1]-(p[3]-this._scrollSensitivity);
            this.startScrolling(speed);
        }
        else {
            for (var i = 0; i < this._drags.length; i++) {
                var draggable = this._drags[i];
                if (!this._offsetsSet) {
                    var pos = draggable.element.cumulativeOffset();
                    draggable.offset = [0,1].map( function(i) { return (pointer[i] - pos[i]) });
                    draggable.dragging = true;
                    if(!draggable.delta)
                        draggable.delta = draggable.currentDelta();
                    draggable._clone = draggable.element.cloneNode(true);
                    Element.absolutize(draggable.element);
                    draggable.element.parentNode.insertBefore(draggable._clone, draggable.element);
                    Draggables.notify('onStart', draggable, event);
                    draggable.options.starteffect(draggable.element);
                }
                draggable.updateDrag(event, pointer);
            }
            if (!this._offsetsSet && this._constraint) {
                toggleRemove(false);
            }
            this.activateDrop(pointer, this._drags[0]);
            this._offsetsSet = true;
        }
        Event.stop(event);
    }
} catch (e) { console.log("processMouseMove", e); } }

/* Handles dropping selected elements */
function processMouseUp(event) { try {
    if (this._isDragging) {
        if (this._dragsSelected) {
            toggleLoading(true);
            Position.prepare();
            var pointer = [Event.pointerX(event), Event.pointerY(event)];
            var DroppableIsTrash = Droppables.last_active && Droppables.last_active.hoverclass == 'trashhover';
            var dropItem = true;
            Droppables.last_active = null;
            Droppables.show(pointer, this._drags[0].element);
            if (DroppableIsTrash) {
            	undoItems.clear();
            }
            for (var i = 0; i < this._drags.length; i++) {
                var draggable = this._drags[i];
                draggable.stopScrolling();
                draggable.dragging = false;
                Element.relativize(draggable.element);
                if (draggable._clone) {
                    Element.remove(draggable._clone);
                    draggable._clone = null;
                }
                if (dropItem && Droppables.last_active) {
                    dropItem = Droppables.last_active.onDrop(draggable.element, Droppables.last_active.element, event);
                }
                Draggables.notify('onEnd', draggable, event);
                var revert = draggable.options.revert;
                if(revert && Object.isFunction(revert)) revert = revert(draggable.element);
                    draggable.options.reverteffect(draggable.element);
                if(draggable.options.zindex)
                    draggable.element.style.zIndex = draggable.originalZ;
                if(draggable.options.endeffect)
                    draggable.options.endeffect(draggable.element);
                Draggables.deactivate(draggable);
                draggable.element.className = draggable.element.className.replace(' hover', '');
                draggable._isSelected = false;
            }
            if (!pendingCalls) toggleLoading(false);
            Droppables.reset();
            this.reset();
        }
        else if (this._numDrags) {
            this._dragsSelected = true;
            if (this._constraint) toggleRemove(true);
            var drags = Draggables.dragTypes.get(this._type);
            for (var i = 0; i < drags.length; i++) {
                if (drags[i]._isSelected) this._drags.push(drags[i]);
            }
        }
        this._isDragging = false;
        this.hide();
    } else if (this._dragsSelected && !this._isScrolling) {
        for (var i = 0; i < this._drags.length; i++) {
            this._drags[i].element.className = this._drags[i].element.className.replace(' hover', '');
            this._drags[i]._isSelected = false;
        }
        this.reset();
    } else if (this._isScrolling) this._isScrolling = false;
    if (this._scroll) this.stopScrolling();
} catch (e) { console.log("processMouseUp", e); } }

/* Handles starting element selection and dragging */
function processMouseDown(event) { try {
    this.appendChild(bb);
    //Detect if clicking on scrollbar
    var offsetLeft = this.offsetLeft;
    var offsetTop = this.offsetTop;
	var clientWidth = this.clientWidth;
	var offsetWidth = this.offsetWidth;
	var clientHeight = this.clientHeight;
	var offsetHeight = this.offsetHeight;
	var windowOffset = { left: window.pageXOffset, top: window.pageYOffset };
	if (
        (clientHeight != offsetHeight && event.clientY > offsetTop + clientHeight - windowOffset.top) ||
        (clientWidth != offsetWidth && event.clientX > offsetLeft + clientWidth - windowOffset.left)
       ) {
		bb._isScrolling = true;
		return;
	}
    if (Draggables._editingDraggable) return;
    toggleRemove(false);
    bb._isDragging = true;
    bb._numDrags = 0;
    bb._constraint = null;
    bb._scroll = this;
    bb._type = this._type;
    if (!bb._dragsSelected) {
        bb.style.marginLeft = 0;
        bb.style.marginTop = 0;
        bb.style.width = 0;
        bb.style.height = 0;
        bb.show();
    	bb._origOffset = {
        		left: this.scrollLeft + window.pageXOffset,
        		top: this.scrollTop + window.pageYOffset
        	}
    	bb._origPos = {
    		left: bb.offsetLeft - bb._origOffset.left,
    		top: bb.offsetTop - bb._origOffset.top
    	};
        bb._clickPos = { left: event.clientX, top: event.clientY };
        bb._cumPos = { left: bb._clickPos.left - bb._origPos.left, top: bb._clickPos.top - bb._origPos.top };
        bb.style.marginLeft = bb._cumPos.left + 'px';
        bb.style.marginTop = bb._cumPos.top + 'px';
        bb.style.width = 0;
        bb.style.height = 0;
    }
} catch (e) { console.log("processMouseDown", e); } }

/* Handles mousedown events to watch for double-clicks to edit or single-clicks to expand */
function processDoubleClick(event) { try {
    //Remove focus from active editing draggable
    if (Draggables._editingDraggable) {
        if (Draggables._editingDraggable != this)
            Draggables._editingDraggable.element.firstChild.blur();
        else return;
    }
    //Check for active selection
    if (bb._dragsSelected) {
        bb._isDragging = true;
        Event.stop(event);
        return;
    }
    //Check for double-click
    if (this.clicked == true) {
        //Prevent editing computer and cluster names
        if (this.element.className.split(' ')[0] == 'computer' || this.element.className.indexOf("_computer") != -1 ||
                this.element.className.split(' ')[0] == 'cluster' || this.element.className.indexOf("_cluster") != -1)
            return;
        editItem(this);
    } else {
        this.clicked = true;
        setTimeout( function() {
            this.clicked = false;
            if (Draggables._editingDraggable || this.dragging) return;
            if (!this.element._isChild) this.element.previousSibling.toggle();
        }.bind(this), 250);
    }
} catch (e) { console.log("processDoubleClick", e); } }

/* Sends selected elements to trash */
function removeSelected(event) {
    toggleRemove(false);
    bb._isDragging = true;
    processMouseUp(event);
}

/* Inserts an element in a naturally sorted position */
function insertNode(ul, li) { try {
	if (!ul) return;
    var name = li._parent ? li._parent._chunked : li.nameNode._chunked;
	var pos = binarySearch(ul.childNodes, 0, ul.childNodes.length, name);
	if (pos != null)
        ul.insertBefore(li, ul.childNodes[pos]);
    else
        ul.appendChild(li);
    if (enableHighlight) li.nameNode.highlight();
} catch (e) { console.log("insertNode", e); } }

/* Finds correct place to insert element using binary search and natual comparison */
function binarySearch(a, low, high, key) { try {
    var mid, childli, value, comp = 1;
    if (high == 0) return null;
	while (comp != 0) {
	    if (low == high)
	        return low;
	    mid = parseInt((low + high) / 2);
	    childli = a[mid];
	    value = childli._parent ? childli._parent._chunked : childli.nameNode._chunked;
	    comp = naturalSort(value, key);
	    if (comp < 0)
	    	low = mid + 1;
	    else if (comp > 0)
	    	high = mid;
	}
    return mid;
} catch (e) { console.log("binarySearch", e); } }

/* Calculates natural sorting string */
function chunkify(t) {
    var tz = [], x = 0, y = -1, n = 0, i, j;
    while (i = (j = t.charAt(x++)).charCodeAt(0)) {
        var m = (i == 46 || (i >=48 && i <= 57));
        if (m !== n) {
            tz[++y] = "";
            n = m;
        }
        tz[y] += j;
    }
    return tz;
}

/* Determines natural sorting order of two elements */
function naturalSort(a, b) { try {
	for (x = 0; a[x] && b[x]; x++) {
		if (a[x] !== b[x]) {
			var c = Number(a[x]), d = Number(b[x]);
			if (c == a[x] && d == b[x]) {
				return c - d;
			} else return (a[x] > b[x]) ? 1 : -1;
		}
	}
	return a.length - b.length;
} catch (e) { console.log("naturalSort", e); } }

/* Resizes tree divs and loading box to viewable policydiv area */
function setHeight() { try {
    if (!treeDivs.length) return;
    var width = parseInt(policyDiv.clientWidth/treeDivs.length) - 2 + 'px';
    var height = document.documentElement.clientHeight - treeDivs[0].offsetTop + 'px';
    for (var i = 0; i < treeDivs.length; i++) {
        treeDivs[i].style.width = width;
        treeDivs[i].style.height = height;
    }
//    menuDiv.style.paddingLeft = document.documentElement.clientWidth - policyDiv.offsetLeft - 150 + 'px';
    loadingDiv.style.height = height;
} catch (e) { console.log("setHeight", e); } }

/* Sets a global variable if it is not already set */
function setDefault(name,val) {
	if (typeof(window[name])=="undefined" || window[name]==null)
		window[name]=val;
}

/* Fully expands or collapses a tree with a given ID */
function expandCollapseTree(treeId, expand) {
    var tree = document.getElementById(treeId);
    var types = droppableOptions[tree.parentNode._type].groupings.keys();
    var regkey = (types.indexOf('regkey') == -1) ? false : true;
    for (var i = 0, len = tree.childNodes.length; i < len; ++i) {
        var node = tree.childNodes[i];
        if (expand ? !node._isExpanded : node._isExpanded) node.firstChild.toggle();
        var typeNodes = node.nameNode._droppable.typeNodes;
        for (var j = 0; j < types.length; j++) {
            var typeNode = typeNodes.get(typeNums[types[j]]);
            if (typeNode.nodeName == "UL") {
                if (regkey && types[j] == 'regkey')
                    for (var k = 0; k < typeNode.childNodes.length; k++)
                        if (expand ? !typeNode.childNodes[k]._isExpanded : typeNode.childNodes[k]._isExpanded) typeNode.childNodes[k].firstChild.toggle();
                if (expand ? !typeNode.parentNode._isExpanded : typeNode.parentNode._isExpanded) typeNode.previousSibling.toggle();
            }
        }
    }
}

/* Displays loading div during action processing */
function toggleLoading(show) {
    if (show) {
        loadingDiv.show();
    }
    else {
        loadingDiv.hide();
    }
}

/* Toggles the remove icon when elements are selected */
function toggleRemove(show) {
    if (show) {
        for (var i = 0; i < trashspans.length; i++) {
            trashspans[i].addEventListener('mousedown', removeSelected, false);
            trashspans[i].className = 'remove';
        }
    } else {
        for (var i = 0; i < trashspans.length; i++) {
            trashspans[i].removeEventListener('mousedown', removeSelected, false);
            trashspans[i].className = 'trash';
        }
    }
}

/* Toggles the undo button */
function toggleUndo(show) {
    if (show) {
        for (var i = 0; i < undospans.length; i++) {
           undospans[i].className = 'undo';
           undospans[i].addEventListener('mousedown', undo, false);
        }
    } else {
        for (var i = 0; i < undospans.length; i++) {
            undospans[i].className = 'undodisabled';
            undospans[i].removeEventListener('mousedown', undo, false);
        }
    }
}

/* Toggles visibility of collapsible tree branches and updates modified children */
function toggleList() {
    var node = this.parentNode;
    if (node.lastChild._isUpdated) {
        var childNodes = node.lastChild.childNodes;
        for (var i = 0, len = childNodes.length; i < len; i++) {
            if (childNodes[i]._isUpdated) {
                childNodes[i].nameNode.updateDisplay(false);
                childNodes[i]._isUpdated = false;
            }
        }
        node.lastChild._isUpdated = false;
    }
    if (node.className == nodeOpenClass) {
        node._isExpanded = false;
        node.className = nodeClosedClass;
    } else {
        node._isExpanded = true;
        node.className = nodeOpenClass;
    }
}

/* Launches the help window */
function launchHelp() {
	window.open("gphelp.html", "help", "toolbar=no,menubar=no,width=600,height=600,resizable=yes,scrollbars=yes");
}

/* Launches the console window */
function launchConsole() {
	document.getElementById('consoleLink').style.color = '';
	window.consoleObj.window = window.open("gpconsole.html", "console", "toolbar=no,menubar=no,width=600,height=600,resizable=yes,scrollbars=yes");
}

/* Fills the console window with log data */
function loadConsole() {
	return consoleObj.content;
}