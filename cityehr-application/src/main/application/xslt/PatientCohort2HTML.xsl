<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    PatientCohort2HTML.xsl
    Input is a patient cohort of patientInfo elements
    The header information is specified in a single 
    
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet version="2.0" 
    xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xxi="http://orbeon.org/oxf/xml/xinclude" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:cda="urn:hl7-org:v3" 
    xmlns:iso-13606="http://www.iso.org/iso-13606"
    xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    
    <!-- Need the indent="no" to make sure no white space is output between elements -->
    <xsl:output method="xml" indent="no" name="xml"/>

    <!-- Main templates for CDA to HTML conversion -->
    <xsl:include href="PatientCohort2HTML-Module.xsl"/>

    <!-- ===  Match the document node (should be patientSet, but don't assume this) to output an HTML document ====
              Creates the shell HTML document, then applies templates to output table with cohort list
         ========================================================================================================== -->
    <xsl:template match="/">
        <xsl:call-template name="generateHTML"/>
    </xsl:template>


</xsl:stylesheet>
