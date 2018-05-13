/**
 * Functions for text editing (toolbar stuff)
 *
 * @todo I'm no JS guru please help if you know how to improve
 * @author Andreas Gohr <andi@splitbrain.org>
 */

var DOKU_BASE='/';
var toolbarDisabled = false;

/**
 * Creates a toolbar button through the DOM
 *
 * Style the buttons through the toolbutton class
 *
 * @author Andreas Gohr <andi@splitbrain.org>
 */
function createToolButton(icon,label,key,id){
    var btn = document.createElement('button');
    var ico = document.createElement('img');

    // preapare the basic button stuff
    btn.className = 'toolbutton';
    btn.title = label;
    if(key){
        btn.title += ' [ALT+'+key.toUpperCase()+']';
        btn.accessKey = key;
    }

    // set IDs if given
    if(id){
        btn.id = id;
        ico.id = id+'_ico';
    }

    // create the icon and add it to the button
    ico.src = '/images/wiki_toolbar/'+icon;
    btn.appendChild(ico);

    return btn;
}

/**
 * Creates a picker window for inserting text
 *
 * The given list can be an associative array with text,icon pairs
 * or a simple list of text. Style the picker window through the picker
 * class or the picker buttons with the pickerbutton class. Picker
 * windows are appended to the body and created invisible.
 *
 * @author Andreas Gohr <andi@splitbrain.org>
 */
function createPicker(id,list,icobase,edid){
    var cnt = list.length;

    var picker = document.createElement('div');
    picker.className = 'picker';
    picker.id = id;
    picker.style.position = 'absolute';
    picker.style.display  = 'none';

    for(var key in list){
        var btn = document.createElement('button');

        btn.className = 'pickerbutton';

        // associative array?
        if(isNaN(key)){
            var ico = document.createElement('img');
            ico.src       = DOKU_BASE+'lib/images/'+icobase+'/'+list[key];
            btn.title     = key;
            btn.appendChild(ico);
            eval("btn.onclick = function(){pickerInsert('"+id+"','"+
                                  jsEscape(key)+"','"+
                                  jsEscape(edid)+"');return false;}");
        }else{
            var txt = document.createTextNode(list[key]);
            btn.title     = list[key];
            btn.appendChild(txt);
            eval("btn.onclick = function(){pickerInsert('"+id+"','"+
                                  jsEscape(list[key])+"','"+
                                  jsEscape(edid)+"');return false;}");
        }

        picker.appendChild(btn);
    }
    var body = document.getElementsByTagName('body')[0];
    body.appendChild(picker);
}

/**
 * Called by picker buttons to insert Text and close the picker again
 *
 * @author Andreas Gohr <andi@splitbrain.org>
 */
function pickerInsert(pickerid,text,edid){
    // insert
    insertAtCarret(edid,text);
    // close picker
    pobj = document.getElementById(pickerid);
    pobj.style.display = 'none';
}

/**
 * Show a previosly created picker window
 *
 * @author Andreas Gohr <andi@splitbrain.org>
 */
function showPicker(pickerid,btn){
    var picker = document.getElementById(pickerid);
    var x = findPosX(btn);
    var y = findPosY(btn);
    if(picker.style.display == 'none'){
        picker.style.display = 'block';
        picker.style.left = (x+3)+'px';
        picker.style.top = (y+btn.offsetHeight+3)+'px';
    }else{
        picker.style.display = 'none';
    }
}

/**
 * Create a toolbar
 *
 * @param  string tbid ID of the element where to insert the toolbar
 * @param  string edid ID of the editor textarea
 * @param  array  tb   Associative array defining the buttons
 * @author Andreas Gohr <andi@splitbrain.org>
 */
function initToolbar(tbid,edid,tb) {
    var toolbar = $(tbid);
    if(!toolbar) return;

    //empty the toolbar area:
    toolbar.innerHTML='';

    var cnt = tb.length;
    for(var i=0; i<cnt; i++){
        // create new button
        btn = createToolButton(tb[i]['icon'],
                               tb[i]['title'],
                               tb[i]['key']);

        // add button action dependend on type
        switch(tb[i]['type']){
            case 'format':
                var sample = tb[i]['title'];
                if(tb[i]['sample']){ sample = tb[i]['sample']; }

                eval("btn.onclick = function(){if (toolbarDisabled) {return false;}" +
                						"insertTags('"+
                                        jsEscape(edid)+"','"+
                                        jsEscape(tb[i]['open'])+"','"+
                                        jsEscape(tb[i]['close'])+"','"+
                                        jsEscape(sample)+
                                    "');return false;}");
                toolbar.appendChild(btn);
                break;
            case 'insert':
                eval("btn.onclick = function(){if (toolbarDisabled) {return false;}" +
                						"insertAtCarret('"+
                                        jsEscape(edid)+"','"+
                                        jsEscape(tb[i]['insert'])+
                                    "');return false;}");
                toolbar.appendChild(btn);
                break;
            case 'signature':
                if(typeof(SIG) != 'undefined' && SIG != ''){
                    eval("btn.onclick = function(){if (toolbarDisabled) {return false;}" +
                    						"insertAtCarret('"+
                                            jsEscape(edid)+"','"+
                                            jsEscape(SIG)+
                                        "');return false;}");
                    toolbar.appendChild(btn);
                }
                break;
            case 'picker':
                createPicker('picker'+i,
                             tb[i]['list'],
                             tb[i]['icobase'],
                             edid);
                eval("btn.onclick = function(){if (toolbarDisabled) {return false;}" +
                					"showPicker('picker"+i+
                                    "',this);return false;}");
                toolbar.appendChild(btn);
                break;
            case 'mediapopup':
                eval("btn.onclick = function(){if (toolbarDisabled) {return false;}" +
                						"window.open('"+
                                        jsEscape(tb[i]['url'])+"','"+
                                        jsEscape(tb[i]['name'])+"','"+
                                        jsEscape(tb[i]['options'])+
                                    "');return false;}");
                toolbar.appendChild(btn);
                break;
        } // end switch
    } // end for
}

/**
 * Format selection
 *
 * Apply tagOpen/tagClose to selection in textarea, use sampleText instead
 * of selection if there is none. Copied and adapted from phpBB
 *
 * @author phpBB development team
 * @author MediaWiki development team
 * @author Andreas Gohr <andi@splitbrain.org>
 * @author Jim Raynor <jim_raynor@web.de>
 */
function insertTags(edid,tagOpen, tagClose, sampleText) {
  var txtarea = document.getElementById(edid);
  // IE
  if(document.selection  && !is_gecko) {
    var theSelection = document.selection.createRange().text;
    var replaced = true;
    if(!theSelection){
      replaced = false;
      theSelection=sampleText;
    }
    txtarea.focus();

    // This has change
    var text = theSelection;
    if(theSelection.charAt(theSelection.length - 1) == " "){// exclude ending space char, if any
      theSelection = theSelection.substring(0, theSelection.length - 1);
      r = document.selection.createRange();
      r.text = tagOpen + theSelection + tagClose + " ";
    } else {
      r = document.selection.createRange();
      r.text = tagOpen + theSelection + tagClose;
    }
    if(!replaced){
      r.moveStart('character',-text.length-tagClose.length);
      r.moveEnd('character',-tagClose.length);
    }
    r.select();
  // Mozilla
  } else if(txtarea.selectionStart || txtarea.selectionStart == '0') {
    replaced = false;
    var startPos = txtarea.selectionStart;
    var endPos   = txtarea.selectionEnd;
    if(endPos - startPos){ replaced = true; }
    var scrollTop=txtarea.scrollTop;
    var myText = (txtarea.value).substring(startPos, endPos);
    if(!myText) { myText=sampleText;}
    if(myText.charAt(myText.length - 1) == " "){ // exclude ending space char, if any
      subst = tagOpen + myText.substring(0, (myText.length - 1)) + tagClose + " ";
    } else {
      subst = tagOpen + myText + tagClose;
    }
    txtarea.value = txtarea.value.substring(0, startPos) + subst +
                    txtarea.value.substring(endPos, txtarea.value.length);
    txtarea.focus();

    //set new selection
    if(replaced){
      var cPos=startPos+(tagOpen.length+myText.length+tagClose.length);
      txtarea.selectionStart=cPos;
      txtarea.selectionEnd=cPos;
    }else{
      txtarea.selectionStart=startPos+tagOpen.length;
      txtarea.selectionEnd=startPos+tagOpen.length+myText.length;
    }
    txtarea.scrollTop=scrollTop;
  // All others
  } else {
    var copy_alertText=alertText;
    var re1=new RegExp("\\$1","g");
    var re2=new RegExp("\\$2","g");
    copy_alertText=copy_alertText.replace(re1,sampleText);
    copy_alertText=copy_alertText.replace(re2,tagOpen+sampleText+tagClose);

    if (sampleText) {
      text=prompt(copy_alertText);
    } else {
      text="";
    }
    if(!text) { text=sampleText;}
    text=tagOpen+text+tagClose;
    //append to the end
    txtarea.value += "\n"+text;

    // in Safari this causes scrolling
    if(!is_safari) {
      txtarea.focus();
    }

  }
  // reposition cursor if possible
  if (txtarea.createTextRange){
    txtarea.caretPos = document.selection.createRange().duplicate();
  }
}

/*
 * Insert the given value at the current cursor position
 *
 * @see http://www.alexking.org/index.php?content=software/javascript/content.php
 */
function insertAtCarret(edid,value){
  var field = document.getElementById(edid);

  //IE support
  if (document.selection) {
    field.focus();
    sel = document.selection.createRange();
    sel.text = value;
  //MOZILLA/NETSCAPE support
  }else if (field.selectionStart || field.selectionStart == '0') {
    var startPos  = field.selectionStart;
    var endPos    = field.selectionEnd;
    var scrollTop = field.scrollTop;
    field.value = field.value.substring(0, startPos) +
                  value +
                  field.value.substring(endPos, field.value.length);

    field.focus();
    var cPos=startPos+(value.length);
    field.selectionStart=cPos;
    field.selectionEnd=cPos;
    field.scrollTop=scrollTop;
  } else {
    field.value += "\n"+value;
  }
  // reposition cursor if possible
  if (field.createTextRange){
    field.caretPos = document.selection.createRange().duplicate();
  }
}


/**
 * global var used for not saved yet warning
 */
var textChanged = false;

/**
 * Check for changes before leaving the page
 */
function changeCheck(msg){
  if(textChanged){
    var ok = confirm(msg);
    if(ok){
        // remove a possibly saved draft using ajax
        var dwform = $('dw__editform');
        if(dwform){
            var params = 'call=draftdel';
            params += '&id='+encodeURIComponent(dwform.elements.id.value);

            var sackobj = new sack(DOKU_BASE + 'lib/exe/ajax.php');
            sackobj.AjaxFailedAlert = '';
            sackobj.encodeURIString = false;
            sackobj.runAJAX(params);
            // we send this request blind without waiting for
            // and handling the returned data
        }
    }
    return ok;
  }else{
    return true;
  }
}








/**
 * Setup toolbar
 */



/************************************************************\
*
\************************************************************/
function jsEscape(text){
    var re=new RegExp("\\\\","g");
    text=text.replace(re,"\\\\");
    re=new RegExp("'","g");
    text=text.replace(re,"\\'");
    re=new RegExp('"',"g");
    text=text.replace(re,'"');
    re=new RegExp("\\\\\\\\n","g");
    text=text.replace(re,"\\n");
    return text;
    
}
/************************************************************\
*
\************************************************************/
function escapeQuotes(text){
    var re=new RegExp("'","g");
    text=text.replace(re,"\\'");
    re=new RegExp('"',"g");
    text=text.replace(re,'"');
    re=new RegExp("\\n","g");
    text=text.replace(re,"\\n");
    return text;
    
}

var domLib_userAgent=navigator.userAgent.toLowerCase();
var domLib_isMac=navigator.appVersion.indexOf('Mac')!=-1;
var domLib_isWin=domLib_userAgent.indexOf('windows')!=-1;
var domLib_isOpera=domLib_userAgent.indexOf('opera')!=-1;
var domLib_isOpera7up=domLib_userAgent.match(/opera.(7|8)/i);
var domLib_isSafari=domLib_userAgent.indexOf('safari')!=-1;
var domLib_isKonq=domLib_userAgent.indexOf('konqueror')!=-1;
var domLib_isKHTML=(domLib_isKonq||domLib_isSafari||domLib_userAgent.indexOf('khtml')!=-1);
var domLib_isIE=(!domLib_isKHTML&&!domLib_isOpera&&(domLib_userAgent.indexOf('msie 5')!=-1||domLib_userAgent.indexOf('msie 6')!=-1||domLib_userAgent.indexOf('msie 7')!=-1));
var domLib_isIE5up=domLib_isIE;
var domLib_isIE50=(domLib_isIE&&domLib_userAgent.indexOf('msie 5.0')!=-1);
var domLib_isIE55=(domLib_isIE&&domLib_userAgent.indexOf('msie 5.5')!=-1);
var domLib_isIE5=(domLib_isIE50||domLib_isIE55);
var domLib_isGecko=domLib_userAgent.indexOf('gecko/')!=-1;
var domLib_isMacIE=(domLib_isIE&&domLib_isMac);
var domLib_isIE55up=domLib_isIE5up&&!domLib_isIE50&&!domLib_isMacIE;
var domLib_isIE6up=domLib_isIE55up&&!domLib_isIE55;
var domLib_standardsMode=(document.compatMode&&document.compatMode=='CSS1Compat');
var domLib_useLibrary=(domLib_isOpera7up||domLib_isKHTML||domLib_isIE5up||domLib_isGecko||domLib_isMacIE||document.defaultView);
var domLib_hasBrokenTimeout=(domLib_isMacIE||(domLib_isKonq&&domLib_userAgent.match(/konqueror\/3.([2-9])/)===null));
var domLib_canFade=(domLib_isGecko||domLib_isIE||domLib_isSafari||domLib_isOpera);
var domLib_canDrawOverSelect=(domLib_isMac||domLib_isOpera||domLib_isGecko);
var domLib_canDrawOverFlash=(domLib_isMac||domLib_isWin);
var domLib_eventTarget=domLib_isIE?'srcElement':'currentTarget';
var domLib_eventButton=domLib_isIE?'button':'which';
var domLib_eventTo=domLib_isIE?'toElement':'relatedTarget';
var domLib_stylePointer=domLib_isIE?'hand':'pointer';
var domLib_styleNoMaxWidth=domLib_isOpera?'10000px':'none';
var domLib_hidePosition='-1000px';
var domLib_scrollbarWidth=14;
var domLib_autoId=1;
var domLib_zIndex=100;
var domLib_collisionElements;
var domLib_collisionsCached=false;


var clientPC=navigator.userAgent.toLowerCase();
var is_gecko=((clientPC.indexOf('gecko')!=-1)&&(clientPC.indexOf('spoofer')==-1)&&(clientPC.indexOf('khtml')==-1)&&(clientPC.indexOf('netscape/7.0')==-1));
var is_safari=((clientPC.indexOf('AppleWebKit')!=-1)&&(clientPC.indexOf('spoofer')==-1));
var is_khtml=(navigator.vendor=='KDE'||(document.childNodes&&!document.all&&!navigator.taintEnabled));
if(clientPC.indexOf('opera')!=-1)
{
    var is_opera=true;
    var is_opera_preseven=(window.opera&&!document.childNodes);
    var is_opera_seven=(window.opera&&document.childNodes);
    
}
function updateAccessKeyTooltip()
{
    var tip='ALT+';
    if(domLib_isMac)
    {
        tip='CTRL+';
        
    }
    if(domLib_isOpera)
    {
        tip='SHIFT+ESC ';
        
    }
    if(tip=='ALT+')
    {
        return;
        
    }
    var exp=/\[ALT\+/i;
    var rep='['+tip;
    var elements=domLib_getElementsByTagNames(['a','input','button']);
    for(var i=0; i < elements.length; i++)
    {
        if(elements[i].accessKey.length==1&&elements[i].title.length > 0)
        {
            elements[i].title=elements[i].title.replace(exp,rep);
            
        }
        
    }
    
}












var toolbar=[{
    "type":"format","title":"Bold Text","icon":"bold.png","key":"b","open":"*","close":"*"
}
,{
    "type":"format","title":"Italic Text","icon":"italic.png","key":"i","open":"''","close":"''"
}
,{
    "type":"format","title":"Level 1 Headline","icon":"h1.png","key":"1","open":"= ","close":" =\\n"
}
,{
    "type":"format","title":"Level 2 Headline","icon":"h2.png","key":"2","open":"== ","close":" ==\\n"
}
,{
    "type":"format","title":"Level 3 Headline","icon":"h3.png","key":"3","open":"=== ","close":" ===\\n"
}
,{
    "type":"format","title":"Level 4 Headline","icon":"h4.png","key":"4","open":"==== ","close":" ====\\n"
}
,{
    "type":"format","title":"Level 5 Headline","icon":"h5.png","key":"5","open":"===== ","close":" =====\\n"
}
,{
    "type":"format","title":"Internal Link","icon":"link.png","key":"l","open":"[","close":"]"
}
,{
    "type":"format","title":"External Link","icon":"linkextern.png","open":"[","close":"]","sample":"http:\/\/example.com|External Link"
}
,{
    "type":"format","title":"Ordered List Item","icon":"ol.png","open":"    1. ","close":"\\n"
}
,{
    "type":"format","title":"Unordered List Item","icon":"ul.png","open":"    * ","close":"\\n"
}
,{
    "type":"insert","title":"Horizontal Rule","icon":"hr.png","insert":"----\\n"
}
];

//,{
//    "type":"format","title":"Underlined Text","icon":"underline.png","key":"u","open":"__","close":"__"
//}

//,{
//    "type":"format","title":"Strike-through Text","icon":"strike.png","key":"d","open":"&lt;del&gt;","close":"&lt;\/del&gt;"
//}

//,{
//    "type":"format","title":"Code Text","icon":"mono.png","key":"c","open":"''","close":"''"
//}

//,{  //"type":"picker","title":"Smileys","icon":"smiley.png","list":{"8-)":"icon_cool.gif","8-O":"icon_eek.gif","8-o":"icon_eek.gif",":-(":"icon_sad.gif",":-)":"icon_smile.gif","=)":"icon_smile2.gif",":-\/":"icon_doubt.gif",":-\\":"icon_doubt2.gif",":-?":"icon_confused.gif",":-D":"icon_biggrin.gif",":-P":"icon_razz.gif",":-o":"icon_surprised.gif",":-O":"icon_surprised.gif",":-x":"icon_silenced.gif",":-X":"icon_silenced.gif",":-|":"icon_neutral.gif",";-)":"icon_wink.gif","^_^":"icon_fun.gif",":?:":"icon_question.gif",":!:":"icon_exclaim.gif","LOL":"icon_lol.gif","FIXME":"fixme.gif","DELETEME":"delete.gif"
//    },"icobase":"smileys"
//}

//,{
//    "type":"picker","title":"Special Chars","icon":"chars.png","list":["\u00c0","\u00e0","\u00c1","\u00e1","\u00c2","\u00e2","\u00c3","\u00e3","\u00c4","\u00e4","\u01cd","\u01ce","\u0102","\u0103","\u00c5","\u00e5","\u0100","\u0101","\u0104","\u0105","\u00c6","\u00e6","\u0106","\u0107","\u00c7","\u00e7","\u010c","\u010d","\u0108","\u0109","\u010a","\u010b","\u00d0","\u0111","\u00f0","\u010e","\u010f","\u00c8","\u00e8","\u00c9","\u00e9","\u00ca","\u00ea","\u00cb","\u00eb","\u011a","\u011b","\u0112","\u0113","\u0116","\u0117","\u0118","\u0119","\u0122","\u0123","\u011c","\u011d","\u011e","\u011f","\u0120","\u0121","\u0124","\u0125","\u00cc","\u00ec","\u00cd","\u00ed","\u00ce","\u00ee","\u00cf","\u00ef","\u01cf","\u01d0","\u012a","\u012b","\u0130","\u0131","\u012e","\u012f","\u0134","\u0135","\u0136","\u0137","\u0139","\u013a","\u013b","\u013c","\u013d","\u013e","\u0141","\u0142","\u013f","\u0140","\u0143","\u0144","\u00d1","\u00f1","\u0145","\u0146","\u0147","\u0148","\u00d2","\u00f2","\u00d3","\u00f3","\u00d4","\u00f4","\u00d5","\u00f5","\u00d6","\u00f6","\u01d1","\u01d2","\u014c","\u014d","\u0150","\u0151","\u0152","\u0153","\u00d8","\u00f8","\u0154","\u0155","\u0156","\u0157","\u0158","\u0159","\u015a","\u015b","\u015e","\u015f","\u0160","\u0161","\u015c","\u015d","\u0162","\u0163","\u0164","\u0165","\u00d9","\u00f9","\u00da","\u00fa","\u00db","\u00fb","\u00dc","\u00fc","\u01d3","\u01d4","\u016c","\u016d","\u016a","\u016b","\u016e","\u016f","\u01d6","\u01d8","\u01da","\u01dc","\u0172","\u0173","\u0170","\u0171","\u0174","\u0175","\u00dd","\u00fd","\u0178","\u00ff","\u0176","\u0177","\u0179","\u017a","\u017d","\u017e","\u017b","\u017c","\u00de","\u00fe","\u00df","\u0126","\u0127","\u00bf","\u00a1","\u00a2","\u00a3","\u00a4","\u00a5","\u20ac","\u00a6","\u00a7","\u00aa","\u00ac","\u00af","\u00b0","\u00b1","\u00f7","\u2030","\u00bc","\u00bd","\u00be","\u00b9","\u00b2","\u00b3","\u00b5","\u00b6","\u2020","\u2021","\u00b7","\u2022","\u00ba","\u2200","\u2202","\u2203","\u018f","\u0259","\u2205","\u2207","\u2208","\u2209","\u220b","\u220f","\u2211","\u203e","\u2212","\u2217","\u221a","\u221d","\u221e","\u2220","\u2227","\u2228","\u2229","\u222a","\u222b","\u2234","\u223c","\u2245","\u2248","\u2260","\u2261","\u2264","\u2265","\u2282","\u2283","\u2284","\u2286","\u2287","\u2295","\u2297","\u22a5","\u22c5","\u25ca","\u2118","\u2111","\u211c","\u2135","\u2660","\u2663","\u2665","\u2666","\u03b1","\u03b2","\u0393","\u03b3","\u0394","\u03b4","\u03b5","\u03b6","\u03b7","\u0398","\u03b8","\u03b9","\u03ba","\u039b","\u03bb","\u03bc","\u039e","\u03be","\u03a0","\u03c0","\u03c1","\u03a3","\u03c3","\u03a4","\u03c4","\u03c5","\u03a6","\u03c6","\u03c7","\u03a8","\u03c8","\u03a9","\u03c9","\u2605","\u2606","\u260e","\u261a","\u261b","\u261c","\u261d","\u261e","\u261f","\u2639","\u263a","\u2714","\u2718"]
//}
//,{
//    "type":"signature","title":"Insert Signature","icon":"sig.png","key":"y"
//}

//,{
//    "type":"mediapopup","title":"Add Images and other files","icon":"image.png","url":"\/lib\/exe\/mediamanager.php?ns=","name":"mediaselect","options":"width=750,height=500,left=20,top=20,scrollbars=yes,resizable=yes"
//}
