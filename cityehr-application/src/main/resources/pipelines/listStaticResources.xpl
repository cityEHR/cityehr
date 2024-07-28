<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    listStaticResources.xpl
    
    Pipeline to return a list of files in the server directory specified in parameters/resourceDirectory
    Input is session-parameters with resourceDirectory and resourcePattern set
    
    Returns directory information in the form:
    
    <directory name="address-book" path="c:\Documents and Settings\John Doe\OPS\src\examples\web\examples\address-book">
        <file last-modified-ms="1120343217984" last-modified-date="2005-07-03T00:26:57.984" size="961130" path="image0001.jpg" name="image0001.jpg">
            <image-metadata>
                <basic-info>
                    <content-type>image/jpeg</content-type>
                    <width>2272</width>
                    <height>1704</height>
                </basic-info>
            </image-metadata>
        </file>
    </directory>
    
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

    <!-- Input to pipeline is xml/patient-view-parameters.xml as set in the page-flow.xml file 
         with parameters set in the page element -->
    <p:param name="instance" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>

    <!-- Get list of files/folders in resourceDirectory folder -->
    <p:processor name="oxf:directory-scanner">
        <p:input name="config" transform="oxf:xslt" href="#instance">
            <config xsl:version="2.0">
                <base-directory>
                    <xsl:value-of select="parameters/resourceDirectory"/>
                </base-directory>
                <include>
                    <xsl:value-of select="parameters/resourcePattern"/>
                </include>
                <!--
                <include> */*.* </include>
                -->
                <case-sensitive>false</case-sensitive>
                <image-metadata>
                    <basic-info>true</basic-info>
                </image-metadata>
            </config>
        </p:input>
        <p:output name="data" id="fileInfo"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#fileInfo"/>
        <p:output name="data" ref="data"/>
    </p:processor>


</p:pipeline>
