<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRGetUploadedBinary.xpl
    
    Pipeline to get binary content from a file uploaded by the user.
    Input is the view-paraemters, with sourceHandle set.
    Can be an image, zip file (e.g. office document), etc
    Returns an XML element of the form:
    
    <document xsi:type="xs:base64Binary" content-type="image/jpeg">
     /9j/4AAQSkZJRgABAQEBygHKAAD/2wBDAAQDAwQDAwQEBAQFBQQFBwsHBwYGBw4KCggLEA4R
     KKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooA//2Q==
    </document>
    
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
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Input to pipeline is view-parameters.xml -->
    <p:param name="parameters" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>

    <!-- Get the binary data.
         The location of the binary data is set in parameters/sourceHandle. -->
    <p:processor name="oxf:url-generator">
        <p:input name="config" transform="oxf:xslt" href="#parameters">
            <config xsl:version="2.0">
                <url>
                    <xsl:value-of select="parameters/sourceHandle"/>
                </url>
                <content-type>
                    <xsl:value-of select="parameters/sourceType"/>
                </content-type>
            </config>
        </p:input>
        <p:output name="data" id="binaryData"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#binaryData"/>
        <p:output name="data" ref="data"/>
    </p:processor>

</p:pipeline>
