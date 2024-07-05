<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    HTML2FO.xsl
    Adapted from http://catcode.com/cis97yt/xslfo.html
    J. David Eisenberg
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions" >
    <xsl:output method="xml" indent="yes" name="xml"/>
    
    <!-- view-parameters.xml is read from the file system -->
    <xsl:variable name="parameters" select="document('../view-parameters.xml')/parameters"/>

    <!-- Main templates for HTML to XSL-FO conversion -->
    <xsl:include href="HTML2FO-Module.xsl"/>
    
    <!-- Set locations to mirror the exist database collections -->
    <xsl:variable name="applicationLocation" select="replace(substring($applicationIRI,2),':','-')"/>
    <xsl:variable name="specialtyLocation" select="replace(substring($specialtyIRI,2),':','-')"/>
    <xsl:variable name="compositionLocation" select="replace(substring($compositionIRI,2),':','-')"/>
    
    <!-- ===  Match the root node to output an XSL-FO document =========================================
         Creates the shell FO document, then applies templates to output each HTML document found in the source
        ===================================================================================================== -->
    <xsl:template match="/">
        <!-- Redirect output to file, based on the application and specialty -->
        <xsl:variable name="filename" as="xs:string" select="concat('../existSandBox/',$applicationLocation,'/xsl-fo/',$specialtyLocation,'/',$compositionLocation,'.xml')"/>
        <!-- Needed if results are output to a file -->
        <xsl:result-document href="{$filename}" format="xml">
            <fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format">
                <xsl:apply-templates/>
            </fo:root>
        </xsl:result-document>
    </xsl:template>

</xsl:stylesheet>
