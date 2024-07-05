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

window.onload = window.onresize = function () {
    /* IE7 bug doesn't offsetHeight during pageload as can be seen with this alert
    alert(document.getElementById('viewDisplay').offsetHeight);
    Adding a slight delay as below fixes this
    setTimeout('code()', 1);
    */
    setTimeout('document.getElementById("viewContent").style.height = document.getElementById("viewDisplay").offsetHeight - document.getElementById("viewControls").offsetHeight + "px";', 1);

if (typeof(window.jQuery) !== 'undefined') {
    // jQuery present
    /* Set up the maplight here so that it works on IE7 */
    setTimeout('$(function() { $(".map").maphilight(); });', 10);
};

function sizeViewDisplay() {
    document.getElementById("systemNavigation").style.left = document.getElementById("label").offsetWidth + "px";
    document.getElementById("viewContent").style.height = document.getElementById("viewDisplay").offsetHeight - document.getElementById("viewControls").offsetHeight + "px";
};


/* === Toggle the size of viewDisplay
================================== */
function toggleViewDisplaySize() {
    var viewDisplay = document.getElementById("viewDisplay");
    var viewNavigation = document.getElementById("viewNavigation");
    
    if (viewNavigation.display === "none") {
        showViewNavigation();
    } else {
        hideViewNavigation();
    }
};

function showViewNavigation() {
    var viewDisplay = document.getElementById("viewDisplay");
    var viewNavigation = document.getElementById("viewNavigation");
    
    viewNavigation.display = "block";
    viewDisplay.style.width = "75%";
    viewNavigation.style.width = "25%";
};

function hideViewNavigation() {
    var viewDisplay = document.getElementById("viewDisplay");
    var viewNavigation = document.getElementById("viewNavigation");
    
    viewNavigation.display = "none";
    viewDisplay.style.width = "100%";
    viewNavigation.style.width = "0%";
};


/* === Scroll window to show specified element
The elements are specified using the id attribute.
Was using name, but can now use id to identify the element.
============================================== */

function scrollToElement(id) {
    
    var element = document.getElementById(id);
    if (element === null) { return; }
    element.scrollIntoView(true);
};


/* === Turn sequence (as obtained from getelementsbyname) into an array
============================================== */

function arrayFromSequence(seq) {
    var arr = new Array(seq.length);
    for (var i = seq.length; i-- > 0;) {
    if (i in seq) {
    arr[i] = seq[i];
    return arr;
    }
    
    }
};


/* === Call Orbeon action.
First argument is the id of the target model
Second argument is the eventName associated with the action
============================================== */
function callXformsAction(targetId, eventName) {
    ORBEON.xforms.Document.dispatchEvent(targetId, eventName);
};


/* === Set value of Orbeon xforms control.
First argument is the controlId
Concatenates any additional arguments to value.
============================================== */
function setXformsControl(controlId) {
    var value = "";
    for (var i = 1; i < arguments.length; i++) {
        value += String(arguments[i]);
    }
    ORBEON.xforms.Document.setValue(controlId, value);
};


/* === Toggle value of Orbeon xforms control.
Toggles the value between 1 and 0
This works with or without Orbeon.
ORBEON.xforms.Document.getValue gets the value of the control, but can only be called if using Orbeon
============================================== */
function toggleXformsControl(controlId) {
    // Get the maphilight data
    var mapControlId = '#Map-' + controlId;
    
    // Get the Orbeon control value, but set default if not using Orbeon
    try {
        var value = ORBEON.xforms.Document.getValue(controlId);
    }
    catch (err) {
        var value = err;
    }
    
    // Set the new value for the Orbeon control and set the maphilight
    var newValue;
    if (value === 1) {
        newValue = 0;
        setMapHilight(mapControlId, newValue);
    } else if (value === 0) {
        newValue = 1;
        setMapHilight(mapControlId, newValue);
    } else {
        setMapHilight(mapControlId, 'toggle')
    };
    
    // Set the control value, but only if using Orbeon
    try {
        ORBEON.xforms.Document.setValue(controlId, newValue);
    }
    catch (err) {
    };
};


/* === Set hilight of specified area on imagemap.
The 'toggle' version is for when running outside Orbeon.
Note that this relies on the equivalence of 1 and true, 0 and false
=== */
function setMapHilight(mapControlId, value) {
    var data = $(mapControlId).data('maphilight') || {
    };
    if (value === 'toggle') {
        data.alwaysOn = ! data.alwaysOn;
    } else {
        data.alwaysOn = value;
    }
    $(mapControlId).data('maphilight', data).trigger('alwaysOn.maphilight');
};


/* === Set hilight of all areas on imagemap.
The nade passed is to the img element - then need to get the associated map and iterate through its area children.
Get the associated map by moving up two ancestors in the DOM tree and getting its contained 'area' nodes
Need two levels of ancestor to cope for browsers inserting an extra div to holf the img element
=== */
function setImageMap(imageNode) {
    var mapAreas = imageNode.parentNode.parentNode.getElementsByTagName('area');
    
        for (var i = 0; i < mapAreas.length; i++) {
        var data = $(mapAreas[i]).data('maphilight') || {
        };
        data.alwaysOn = true;
        $(mapAreas[i]).data('maphilight', data).trigger('alwaysOn.maphilight');
    }
}


/* === Set state of all checkboxes with specified name
============================================== */
function setCheckboxes(name, state) {
    var input_list = document.getElementsByName(name);
    if (input_list === null) { return state; }
    
    if (state === 'checked') {
        state = 'unchecked'
    } else {
        state = 'checked'
    };
    
    for (var i = 0; i < input_list.length; i++) {
        input_list[i].className = state;
    }
    
    return state;
};

/* === Call trigger on Enter key press
============================================== */

function searchKeyPress(e) {
    // look for window.event in case event isn't passed in
    if (window.event) {
        e = window.event;
    }
    if (e.keyCode === 13) {
        document.getElementById('btnSearch').click();
    }
};