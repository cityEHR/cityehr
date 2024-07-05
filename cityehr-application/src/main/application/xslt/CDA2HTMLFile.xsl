<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    CDA2HTMLFile.xsl
    Input is a CDA document or container (such as a formDefinition)
    PLUS view-parameters.xml is passed in on parameters input
    
    Produces HTML file that can be displayed using the cityEHR.css stylesheet.
       
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0"
    xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3" 
    xmlns:iso-13606="http://www.iso.org/iso-13606"
    xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    
    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Set global variable for view-parameters.xml passed in as input-->
    <!--
    <xsl:variable name="parameters" select="document('input:parameters')/parameters"/>
    -->
    <xsl:variable name="parameters" select="document('../view-parameters.xml')/parameters"/>

    <!-- Main templates for CDA to HTML conversion -->
    <xsl:include href="CDA2HTML-Module.xsl"/>


    <!-- ===  Match the root node to output an HTML document =========================================
        Creates the shell HTML document, then applies templates to output each CDA document found in the source
        ===================================================================================================== -->
    <xsl:template match="/">
        <!-- Redirect output to file, based on the application and specialty -->
        <xsl:variable name="filename" as="xs:string"
            select="concat('../existSandBox/',$applicationLocation,'/html/',$specialtyLocation,'/',$compositionLocation,'.html')"/>
        <!-- Needed if results are output to a file -->
        <xsl:result-document href="{$filename}" format="xml">
            <html>
                <!-- Head -->
                <xsl:call-template name="renderHTMLHead"/>
                <!-- Body -->    
                <body>
                    <xsl:apply-templates/>
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>




</xsl:stylesheet>
