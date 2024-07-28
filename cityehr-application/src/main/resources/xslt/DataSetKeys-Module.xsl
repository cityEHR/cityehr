<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    DataSetKeys-Module.xsl
    Included as a module in DataSet2Spreadsheet, DataSet2SpreadsheetFile.xsl
    Generates the XSLT keys for looking up entries in a cross-patient data set
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Keys for ClassAssertion
        <data patientId="1234567890">
            <cda:observation>
            ...
            </cda:observation>
        </data>
        
        entryList returns entry (cda:observation) for patientId and entryId
    -->
    <xsl:key name="entryList" match="/cityEHR:dataSet/cityEHR:data/cda:observation" use="concat(../@patientId,cda:id/@extension)"/>
   

</xsl:stylesheet>
