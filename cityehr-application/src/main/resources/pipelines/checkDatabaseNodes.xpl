<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    checkDatabaseNodes.xpl
    
    Pipeline to check configured and accessible database nodes
    Returns the results set in the form:
    
    <queryResults>
        <total value="1"/>
        <category displayName="Offline" value="1"/>
        <category displayName="Unconfigured" value="0"/>
        <category displayName="Available" value="0"/>
    </queryResults>
    
    Calls the custom processor cityEHR:pingURL which is set up in WEB-INF/resources/config/custom-processors.xml
    And implemanted in 
        
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

<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:xdb="http://orbeon.org/oxf/xml/xmldb"
    xmlns:cityEHR="http://openhealthinformatics.org/ehr">

    <!-- Input to pipeline is view-parameters.xml -->
    <p:param name="instance" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="response" type="output"/>
    
    <p:processor name="oxf:identity">
        <p:input name="data">
            <node host="localhost" port="8080"/>
        </p:input>
        <p:output name="data" id="node"/>
    </p:processor>    

    <p:processor name="cityEHR:pingURL">
        <p:input name="data" href="#node"/>
        <p:output name="data" id="pingReturn"/>
    </p:processor>

    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#pingReturn"/>
        <p:output name="data" id="pingReturnChecked"/>
    </p:processor>

    <p:processor name="oxf:identity">
        <p:input name="data" transform="oxf:xslt" href="#pingReturnChecked">
            <queryResults xsl:version="2.0">
                <total value="1"/>
                <category displayName="Configured" value="1"/>
                <category displayName="Offline" value="0"/>
                <category displayName="Available" value="{count(node[.!=''])}"/>
            </queryResults>
        </p:input>
        <p:output name="data" id="nodeCheckResults"/>
    </p:processor>

    <!-- Return response -->
    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#nodeCheckResults"/>
        <p:output name="data" ref="response"/>
    </p:processor>

</p:pipeline>
