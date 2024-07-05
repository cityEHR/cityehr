<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    ODFSpreadsheet2PatientSetFile.xsl
    Input is a ODF spreadsheet (content.xml file from the ODF .ods zip) with clinical data for a set of patients
    Generates an ISO-13606 xml representation of the patient data, suitable for import to cityEHR.
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs"
    version="2.0" xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:html="http://www.w3.org/TR/REC-html40"
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
    xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
    xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0"
    xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:presentation="urn:oasis:names:tc:opendocument:xmlns:presentation:1.0"
    xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0"
    xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0" xmlns:math="http://www.w3.org/1998/Math/MathML"
    xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0" xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0"
    xmlns:ooo="http://openoffice.org/2004/office" xmlns:ooow="http://openoffice.org/2004/writer" xmlns:oooc="http://openoffice.org/2004/calc"
    xmlns:dom="http://www.w3.org/2001/xml-events" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rpt="http://openoffice.org/2005/report"
    xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:grddl="http://www.w3.org/2003/g/data-view#" xmlns:tableooo="http://openoffice.org/2009/table"
    xmlns:field="urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">

    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Import module that generates ISO-13606 XML from spreadsheet -->
    <xsl:include href="ODFSpreadsheet2PatientSet-Module.xsl"/>

    <!-- Can only process spreadsheet if applicationId and specialtyId are defined -->
    <xsl:variable name="processError" as="xs:string" select="if ($applicationId !='' and $specialtyId !='') then 'false' else 'true'"/>

    <!-- Set locations to mirror the exist database collections -->
    <xsl:variable name="applicationLocation" select="concat('ISO-13606-EHR_Extract-',$applicationId)"/>
    <xsl:variable name="specialtyLocation" select="concat('ISO-13606-Folder-',$specialtyId)"/>

    <!-- Match root node - set up output file and call template to generate the ontology -->
    <xsl:template match="/">
        <!-- Redirect output to file, based on the application and specialty -->
        <xsl:variable name="filename" as="xs:string"
            select="concat('../existSandBox/',$applicationLocation,'/patientSet/',$specialtyLocation,'/',$specialtyLocation,'.xml')"/>
        <!-- Needed if results are output to a file -->
        <xsl:result-document href="{$filename}" format="xml">
            <xsl:if test="$processError='false'">
                <xsl:call-template name="generatePatientSetData"/>
            </xsl:if>
            <!-- Note that if applicationId and/or specialtyId are not defined then the filename will be different from when valid -->
            <xsl:if test="$processError='true'">
                <error/>
            </xsl:if>
        </xsl:result-document>
    </xsl:template>

    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>
</xsl:stylesheet>
