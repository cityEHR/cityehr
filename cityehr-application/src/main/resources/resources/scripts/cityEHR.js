/*
*********************************************************************************************************
cityEHR
cityEHR.js

Javascript functions for cityEHR user interface control

Copyright (C) 2013-2021 John Chelsom.

This program is free software; you can redistribute it and/or modify it under the terms of the
GNU Lesser General Public License as published by the Free Software Foundation; either version
2.1 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Lesser General Public License for more details.

The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
**********************************************************************************************************
*/

/* === Control the size of viewDisplay
and Set up maphilight if jQuery is loaded
================================== */

window.onload = function () {
    /* IE7 bug doesn't offsetHeight during pageload as can be seen with this alert
    alert(document.getElementById('viewDisplay').offsetHeight);
    Adding a slight delay as below fixes this
    setTimeout('code()', 1);
    */
    setTimeout('sizeViewDisplay();', 10);
    
    // jQuery present
    /* Set up the maphilight here so that it works on IE7 */
    setTimeout('if (typeof (window.jQuery) !== "undefined") {$(function () {$(".map").maphilight();});};', 10);
};


/* === Resize viewDisplay when window is resized
================================== */
window.onresize = function () {
    sizeViewDisplay();
};


/* === Get the client IP address
================================== */

function getIPAddress() {
    window.RTCPeerConnection = window.RTCPeerConnection || window.mozRTCPeerConnection || window.webkitRTCPeerConnection;
    //compatibility for firefox and chrome
    var pc = new RTCPeerConnection({
        iceServers:[]
    }), noop = function () {
    };
    pc.createDataChannel("");
    //create a bogus data channel
    pc.createOffer(pc.setLocalDescription.bind(pc), noop);
    // create offer and set local description
    pc.onicecandidate = function (ice) {
        //listen for candidate events
        if (! ice || ! ice.candidate || ! ice.candidate.candidate) return;
        var myIP = /([0-9]{1,3}(\.[0-9]{1,3}){3}|[a-f0-9]{1,4}(:[a-f0-9]{1,4}){7})/.exec(ice.candidate.candidate)[1];
        alert('my IP: ', myIP);
        pc.onicecandidate = noop;
    };
}

function hello() {
    alert('hello');
}



/* === Override the error handler
================================== */
/*
window.onerror = function() {
alert("Error caught");
};
*/
/*
var gOldOnError = window.onerror;
window.onerror = function myErrorHandler(errorMsg, url, lineNumber) {
alert('An error has been handled');

// Call previous handler.
//if (gOldOnError)
//return gOldOnError(errorMsg, url, lineNumber);

// Just let default handler run.
return false;
}
*/
/*
ORBEON.xforms.Events.errorEvent.subscribe(function(eventName, eventData) {
window.location.href = "http://localhost:8080/orbeon/ehr/";
});
*/

/* === Size the viewDisplay and associated panes at level 2 and 3
================================== */
function sizeViewDisplay() {
    if (document.getElementById("patientLabel") !== 'null') {
        document.getElementById("systemNavigation").style.left = document.getElementById("patientLabel").offsetWidth + "px";
    }
    
    document.getElementById("navigationDisplay").style.height = document.getElementById("ehrNavigation").offsetHeight - document.getElementById("navigationType").offsetHeight + "px";
    document.getElementById("ehrView").style.left = document.getElementById("ehrNavigation").offsetWidth + "px";
    document.getElementById("ehrView").style.width = document.getElementById("ehrContent").offsetWidth - document.getElementById("ehrNavigation").offsetWidth - document.getElementById("ehrInfo").offsetWidth + "px";
    
    document.getElementById("viewDisplay").style.height = document.getElementById("ehrView").offsetHeight - document.getElementById("viewType").offsetHeight - document.getElementById("viewControls").offsetHeight + "px";
    document.getElementById("infoDisplay").style.height = document.getElementById("ehrInfo").offsetHeight - document.getElementById("infoType").offsetHeight + "px";
}

/* === Control display/size of ehrNanigation and ehrInfo
================================== */

function expandNavigation() {
    var ehrNavigation = document.getElementById("ehrNavigation");
    var collapseNavigation = document.getElementById("collapseNavigation");
    var expandNavigation = document.getElementById("expandNavigation");
    
    ehrNavigation.style.display = "block";
    
    collapseNavigation.style.display = "inline";
    expandNavigation.style.display = "none";
    
    sizeViewDisplay();
}

function collapseNavigation() {
    var ehrNavigation = document.getElementById("ehrNavigation");
    var collapseNavigation = document.getElementById("collapseNavigation");
    var expandNavigation = document.getElementById("expandNavigation");
    
    ehrNavigation.style.display = "none";
    
    collapseNavigation.style.display = "none";
    expandNavigation.style.display = "inline";
    
    sizeViewDisplay();
}

function maximiseView() {
    var ehrInfo = document.getElementById("ehrInfo");
    var maximiseView = document.getElementById("maximiseView");
    var minimiseView = document.getElementById("minimiseView");
    var collapseInfo = document.getElementById("collapseInfo");
    var expandInfo = document.getElementById("expandInfo");
    
    ehrInfo.style.width = "400px";
    ehrInfo.style.display = "block";
    
    maximiseView.style.display = "none";
    minimiseView.style.display = "inline";
    collapseInfo.style.display = "inline";
    expandInfo.style.display = "none";
    
    sizeViewDisplay();
}

function minimiseView() {
    var ehrInfo = document.getElementById("ehrInfo");
    var maximiseView = document.getElementById("maximiseView");
    var minimiseView = document.getElementById("minimiseView");
    var collapseInfo = document.getElementById("collapseInfo");
    var expandInfo = document.getElementById("expandInfo");
    
    ehrInfo.style.width = "250px";
    ehrInfo.style.display = "block";
    
    maximiseView.style.display = "inline";
    minimiseView.style.display = "none";
    collapseInfo.style.display = "inline";
    expandInfo.style.display = "none";
    
    sizeViewDisplay();
}

function expandInfo() {
    var ehrInfo = document.getElementById("ehrInfo");
    var maximiseView = document.getElementById("maximiseView");
    var minimiseView = document.getElementById("minimiseView");
    var collapseInfo = document.getElementById("collapseInfo");
    var expandInfo = document.getElementById("expandInfo");
    
    
    ehrInfo.style.width = "250px";
    ehrInfo.style.display = "block";
    
    maximiseView.style.display = "inline";
    minimiseView.style.display = "none";
    collapseInfo.style.display = "inline";
    expandInfo.style.display = "none";
    
    sizeViewDisplay();
}

function collapseInfo() {
    var ehrInfo = document.getElementById("ehrInfo");
    var maximiseView = document.getElementById("maximiseView");
    var minimiseView = document.getElementById("minimiseView");
    var collapseInfo = document.getElementById("collapseInfo");
    var expandInfo = document.getElementById("expandInfo");
    
    ehrInfo.style.display = "none";
    
    maximiseView.style.display = "none";
    minimiseView.style.display = "none";
    collapseInfo.style.display = "none";
    expandInfo.style.display = "inline";
    
    sizeViewDisplay();
}


/* === Scroll window to show specified element
The elements are specified using the id attribute.
Was using name, but can now use id to identify the element.
============================================== */

function scrollToElement(id) {
    
    var element = document.getElementById(id);
    if (element === null) {
        return;
    }
    element.scrollIntoView(true);
}


/* === Turn sequence (as obtained from getelementsbyname) into an array
============================================== */
/*
function arrayFromSequence(seq) {
var arr = new Array(seq.length);
for (var i = seq.length; i > 0; i--) {
if (i in seq) {
arr[i] = seq[i];
return arr;
}
}
}
*/


/* === Call Orbeon action.
First argument is the id of the target model
Second argument is the eventName associated with the action
============================================== */
function callXformsAction(targetId, eventName) {
    ORBEON.xforms.Document.dispatchEvent(targetId, eventName);
}


/* === Set value of Orbeon xforms control.
First argument is the controlId
Concatenates any additional arguments to value.
============================================== */
function setXformsControl(controlId) {
    var value = "";
    for (var i = 1; i < arguments.length; i++) {
        value += String(arguments[i]);
    }
    // Set the control value, but only if using Orbeon
    try {
        ORBEON.xforms.Document.setValue(controlId, value);
    }
    catch (err) {
        value = err;
    }
}


/* === Get value of Orbeon xforms control.
But set default if not using Orbeon
============================================== */
function getXformsControl(controlId) {
    var value = "";
    try {
        value = ORBEON.xforms.Document.getValue(controlId);
    }
    catch (err) {
        value = err;
    }
    return value;
}


/* === Toggle value of Orbeon xforms control.
Toggles the value between 1 and 0
Called onclick in the image map area
Note that mapControlId must be prefixed by #
This works with or without Orbeon.
ORBEON.xforms.Document.getValue gets the value of the control, but can only be called if using Orbeon
============================================== */
function toggleXformsControl(controlId) {
    // Get the maphilight data
    var mapControlId = '#Map-' + controlId;
    
    // Get the Orbeon control value, but set default if not using Orbeon
    var value = getXformsControl(controlId);
    
    // Set the new value for the Orbeon control and set the maphilight
    // Note that === comparison does not work in Firefox on Windows 8
    var newValue;
    if (value == 1) {
        newValue = 0;
        setMapHilight(mapControlId, newValue);
    } else if (value == 0) {
        newValue = 1;
        setMapHilight(mapControlId, newValue);
    } else {
        newValue = 1;
        setMapHilight(mapControlId, 'toggle');
    }
    
    // Set the control value, but only if using Orbeon
    setXformsControl(controlId, newValue);
}


/* === Set hilight of specified area on imagemap.
The 'toggle' version is for when running outside Orbeon.
Note that this relies on the equivalence of 1 and true, 0 and false
=== */
function setMapHilight(mapControlId, value) {
    var data = $(mapControlId).data('maphilight') || {
    };
    if (value == 'toggle') {
        data.alwaysOn = ! data.alwaysOn;
    } else {
        data.alwaysOn = value;
    }
    $(mapControlId).data('maphilight', data).trigger('alwaysOn.maphilight');
}

/* === Set the maphighlight
================================== */
function setMapHilightX() {
    if (typeof (window.jQuery) !== 'undefined') {
        // jQuery present
        /* Set up the maphilight here so that it works on IE7 */
        $(function () {
            $(".map").maphilight();
        });
    }
}

/* === Set hilight of all areas on imagemap.
The nade passed is to the img element - then need to get the associated map and iterate through its area children.
Get the associated map by moving up two ancestors in the DOM tree and getting its contained 'area' nodes
Need two levels of ancestor to cope for browsers inserting an extra div to holf the img element
=== */
function setImageMap(imageNode) {
    var mapAreas = imageNode.parentNode.parentNode.getElementsByTagName('area');
    var idPrefix = "#Map-";
    var idPrefixLength = idPrefix.length;
    
    /*
    var tester = mapAreas[1].getAttribute("id").substring(idPrefixLength - 1);
    alert(tester);
    alert(getXformsControl(tester));
    */
    
    for (var i = 0; i < mapAreas.length; i++) {
        var mapControl = mapAreas[i];
        var mapControlId = '#' + mapControl.getAttribute("id");
        var controlId = mapControlId.substring(idPrefixLength);
        
        var setValue = getXformsControl(controlId);
        
        /*
        alert(controlId);
        alert(mapControlId);
        alert(getXformsControl(controlId));
        */
        
        if (setValue == 1) {
            setMapHilight(mapControlId, setValue);
        }
    }
}

/* === Call setImageMap on all maps on the page.
=== */
function setAllImageMaps() {
    var imageMapList = document.getElementsByClassName('map');
    
    for (var i = 0; i < imageMapList.length; i++) {
        setImageMap(imageMapList[i]);
    }
}


/* === Set state of all checkboxes with specified name
Passes in the current state (class is checked/unchecked) and toggles the class
============================================== */
function setCheckboxes(name, state) {
    var input_list = document.getElementsByName(name);
    if (input_list === null) {
        return state;
    }
    
    if (state == 'checked') {
        state = 'unchecked';
    } else {
        state = 'checked';
    }
    
    for (var i = 0; i < input_list.length; i++) {
        input_list[i].className = state;
    }
    
    return state;
}

/* === Set state of all checkboxes
Passes in the current state (class is checked/unchecked) sets class of all check boxes
============================================== */
function resetAllCheckboxes() {
    
    var input_list = document.getElementsByClassName('checked');
    
    for (var i = 0; i < input_list.length; i++) {
        
        if (input_list[i].hasAttribute('name')) {
            input_list[i].className = 'unchecked';
        } else {
        }
    }
    
    return;
}


/* === Call trigger on Enter key press
============================================== */

function searchKeyPress(e) {
    // look for window.event in case event isn't passed in
    if (window.event) {
        e = window.event;
    }
    if (e.keyCode == 13) {
        document.getElementById('btnSearch').click();
    }
}