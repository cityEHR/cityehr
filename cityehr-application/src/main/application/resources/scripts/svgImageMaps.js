/*
 *********************************************************************************************************
cityEHR
svgImageMaps.js

Javascript functions for cityEHR SVG image map control

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

/* === Control the image maps
Set up event listener for user clicking on the image map
For nested shapes with id attributes, multiple calls will be invoked but the target.id is always the shape that was clicked on.
Sets the XForms input with id 'imageMapCommandAndClass' to the value of the id and class attributes of the shape
================================== */

window.onload = function () {
    const hotspotSet = document.querySelectorAll("g[id]");
    //const hotspotSet = document.getElementsByTagNameNS("http://www.w3.org/2000/svg",*);
    
    hotspotSet.forEach(addHotspotListener);
}

function addHotspotListener (hotspot) {
    hotspot.addEventListener('click', handleHotspotClick);
    
    /*
    if (
    hotspot.namespaceURI === "http://www.w3.org/2000/svg") {
    hotspot.addEventListener('click', handleHotspotClick);
    }
     */
}

function handleHotspotClick (event) {
    
    var hotspot = event.target.parentNode;
    var hotspotId = hotspot.id;
    
    //Set XForms control
    ORBEON.xforms.Document.setValue('imageMapCommand', hotspotId);
}



/* === Set value of the class attrbute an SVG element.
 * Called from Xforms
 * Uses the parameters set in javascriptParameters control
 * Multiple commands are split using @@@
 * The parameters are hotspotId///classValue
 * ============================================== */
function setClassOnElement() {
    var parameters = ORBEON.xforms.Document.getValue("javascriptParameters");
    var commandArray = parameters.split("@@@");
    
    // Iterate thriugh the commands
    for (var i = 0; i < commandArray.length; i++) {
        var command = commandArray[i];
        
        if (typeof command !== 'undefined') {
            
            var parametersArray = command.split("///");
            
            var hotspotId = parametersArray[0];
            var hotspot = document.getElementById(hotspotId);
            
            if (hotspot !== null) {
                var classValue = parametersArray[1];
                
                if (typeof classValue !== 'undefined') {
                    hotspot.setAttribute("class", classValue);
                } else {
                    hotspot.setAttribute("class", '');
                }
            }
        }
    }
}