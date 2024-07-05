<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    HTML2WordML.xsl
    Input is an HTML document
    Root of the HTML document is html
    Generates wordML that forms the document.xml component of the .docx zip
        
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions" xmlns:ve="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml">
    <!-- Need the indent="no" to make sure no white space is output between elements -->
    <xsl:output method="xml" indent="no" name="xml"/>

    <!-- Images files sizes are passed in from directory scan -->
    <!--
    <xsl:variable name="image-file-info" select="document('input:image-file-info')/parameters"/>
    -->
    <xsl:variable name="image-file-info">
        <directory name="initialization" path="initialization">
            <file last-modified-ms="1120343217984" last-modified-date="2005-07-03T00:26:57.984" size="961130" path="letterhead.png" name="letterhead.png">
                <image-metadata>
                    <basic-info>
                        <content-type>image/jpeg</content-type>
                        <width>2272</width>
                        <height>1704</height>
                    </basic-info>
                </image-metadata>
            </file>
        </directory>
    </xsl:variable>


    <!-- Set global variable for view-parameters.xml passed in as input-->
    <!--
        <xsl:variable name="parameters" select="document('input:parameters')/parameters"/>
    -->
    <xsl:variable name="parameters" select="document('../view-parameters.xml')/parameters"/>

    <!-- Get the template XML content for the MS Word document
         This has already been extracted from the .docx template and placed in the templates directory in the standard configuration.
         Only used for testing purposes -->
        <xsl:variable name="wordTemplate" select="document('../resources/templates/letterTemplate-document.xml')/w:document"/>

    <!-- ==== Set global variables for data extracted from the CDA Header ===
         ===================================================================== -->

    <!-- Patient demographics found in meta elements in the HTML head -->
    <xsl:variable name="patientId" select="//head/meta[@name='patientId']/@content"/>
    <xsl:variable name="patientFamily" select="//head/meta[@name='patientFamily']/@content"/>
    <xsl:variable name="patientGiven" select="//head/meta[@name='patientGiven']/@content"/>
    <xsl:variable name="patientPrefix" select="//head/meta[@name='patientPrefix']/@content"/>
    <xsl:variable name="patientAdministrativeGenderCode" select="//head/meta[@name='patientAdministrativeGenderCode']/@content"/>
    <xsl:variable name="patientBirthTime" select="//head/meta[@name='patientBirthTime']/@content"/>


    <!-- Set the Application, Specialty and Composition for this HTML Document.
        These are found in the meta elements.
        Which are children of the html/head element -->
    <xsl:variable name="applicationIRI" select="//head/meta[@name='applicationIRI']/@content"/>
    <xsl:variable name="specialtyIRI" select="//head/meta[@name='specialtyIRI']/@content"/>
    <xsl:variable name="compositionIRI" select="//head/meta[@name='compositionIRI']/@content"/>

    <!-- Set locations to mirror the exist database collections -->
    <xsl:variable name="applicationLocation" select="replace(substring($applicationIRI,2),':','-')"/>
    <xsl:variable name="specialtyLocation" select="replace(substring($specialtyIRI,2),':','-')"/>
    <xsl:variable name="compositionLocation" select="replace(substring($compositionIRI,2),':','-')"/>

    <!-- Main templates for HTML to XSL-FO conversion -->
    <xsl:include href="HTML2WordML-Module.xsl"/>


    <!-- ===  Match the root node to output a WordML document =========================================
        Creates the shell WordML document, then applies templates to output each HTML document found in the source
        ===================================================================================================== -->
    <xsl:template match="/">
        <!-- Redirect output to file, based on the application and specialty -->
        <xsl:variable name="filename" as="xs:string" select="concat('../existSandBox/',$applicationLocation,'/wordML/',$specialtyLocation,'/',$compositionLocation,'.xml')"/>
        <!-- Needed if results are output to a file -->
        <xsl:result-document href="{$filename}" format="xml">
            <xsl:apply-templates/>
        </xsl:result-document>
    </xsl:template>

</xsl:stylesheet>
