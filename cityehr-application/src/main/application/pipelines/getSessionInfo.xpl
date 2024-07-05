<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    getSessionInfo.xpl
    
    Pipeline to get information about the current Orbeon session.
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    **********************************************************************************************************
-->

<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline"
    xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms">

    <!-- Standard pipeline output -->
    <p:param name="info" type="output"/>

    <!-- Execute standard Obeon request processor.
         -->    
    <p:processor name="oxf:request">
        <p:input name="config">
            <config>
                <include>/request/method</include>
            </config>
        </p:input>
        <p:output name="data" ref="info"/>
    </p:processor>
    

</p:pipeline>
