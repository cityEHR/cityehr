<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    HTML2WordML.xsl
    Input is an HTML document
    Root of the HTML document is html
    Generates ODF that forms the content.xml component of the .odt zip
        
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:cda="urn:hl7-org:v3" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions" xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
    xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0"
    xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
    xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0" xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0"
    xmlns:math="http://www.w3.org/1998/Math/MathML" xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0"
    xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0" xmlns:ooo="http://openoffice.org/2004/office"
    xmlns:ooow="http://openoffice.org/2004/writer" xmlns:oooc="http://openoffice.org/2004/calc" xmlns:dom="http://www.w3.org/2001/xml-events"
    xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:rpt="http://openoffice.org/2005/report" xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:grddl="http://www.w3.org/2003/g/data-view#" xmlns:officeooo="http://openoffice.org/2009/office"
    xmlns:tableooo="http://openoffice.org/2009/table" xmlns:drawooo="http://openoffice.org/2010/draw"
    xmlns:calcext="urn:org:documentfoundation:names:experimental:calc:xmlns:calcext:1.0"
    xmlns:loext="urn:org:documentfoundation:names:experimental:office:xmlns:loext:1.0"
    xmlns:field="urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0"
    xmlns:formx="urn:openoffice:names:experimental:ooxml-odf-interop:xmlns:form:1.0" xmlns:css3t="http://www.w3.org/TR/css3-text/">   
    
    <!-- Need the indent="no" to make sure no white space is output between elements -->
    <xsl:output method="xml" indent="no" name="xml"/>

    <!-- The combined parameters are passed in on parameters input -->
    <xsl:variable name="view-parameters" select="document('input:parameters')//parameters[@type='view']"/>
    <xsl:variable name="system-parameters" select="document('input:parameters')//parameters[@type='system']"/>
    <xsl:variable name="session-parameters" select="document('input:parameters')//parameters[@type='session']"/>
    
    <!-- Get the template XML content for the ODFdocument
         This has already been extracted from the .odt template in the cityEHRWordProcessorCDA pipeline 
         and is passed in as the odfTemplate input -->

    <xsl:variable name="odfTemplate" select="document('input:odfTemplate')/office:document-content"/>
        
    <!-- Patient demographics found in meta elements in the HTML head -->
    <xsl:variable name="patientId" select="//head/meta[@name='patientId']/@content"/>
    <xsl:variable name="patientFamily" select="//head/meta[@name='patientFamily']/@content"/>
    <xsl:variable name="patientGiven" select="//head/meta[@name='patientGiven']/@content"/>
    <xsl:variable name="patientPrefix" select="//head/meta[@name='patientPrefix']/@content"/>
    <xsl:variable name="patientAdministrativeGenderCode" select="//head/meta[@name='patientAdministrativeGenderCode']/@content"/>
    <xsl:variable name="patientBirthTime" select="//head/meta[@name='patientBirthTime']/@content"/>


    <!-- Set the Application, Specialty and Composition for this HTML Document.
        These are found in the meta elements  
        Which are children of the html/head element -->
    <xsl:variable name="applicationIRI" select="//head/meta[@name='applicationIRI']/@content"/>
    <xsl:variable name="specialtyIRI" select="//head/meta[@name='specialtyIRI']/@content"/>
    <xsl:variable name="compositionIRI" select="//head/meta[@name='compositionIRI']/@content"/>

    <!-- Main templates for HTML to XSL-FO conversion -->
    <xsl:include href="HTML2ODF-Module.xsl"/>


    <!-- ===  Match the root node to output a WordML document =========================================
        Creates the shell PDF document, then applies templates to output each HTML document found in the source
        ===================================================================================================== -->
    <xsl:template match="/">
            <xsl:apply-templates/>
    </xsl:template>

</xsl:stylesheet>
