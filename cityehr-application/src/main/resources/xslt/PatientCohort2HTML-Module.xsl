<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    PatientCohort2HTML-Module.xsl
    Input is a cohort set
    Set of patientInfo elements
    Generates HTML table with the cohort list
        
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet version="2.0" xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xxi="http://orbeon.org/oxf/xml/xinclude" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:cda="urn:hl7-org:v3" xmlns:iso-13606="http://www.iso.org/iso-13606"
    xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">

    <!-- Variables.
         Base document element is exist:result when this is returned from a query.
    -->

    <!-- There may be one or more description elements at the top level -->
    <xsl:variable name="descriptionList" select="//description"/>
    <!-- The connector for description elements is in the item element -->
    <xsl:variable name="descriptionConnector" select="//item[1]/@displayName"/>
    <!-- The patientInfo elements are wrapped by a single patientSet -->
    <xsl:variable name="patientSet" select="//patientSet"/>
    <!-- Table header is in the (single) patientInfo with items specified (comes from configuration parameters) -->
    <xsl:variable name="patientInfoHeader" select="$patientSet/patientInfo[item][1]"/>


    <!-- Generate HTML from set of patientInfo elements.
     patientInfoHeader variable must already be set. -->
    <xsl:template name="generateHTML">
        <html>
            <head>
                <link rel="stylesheet" type="text/css" href="../styles/cityEHR.css" media="screen"/>
                <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
                <meta name="headerText" content="{$patientSet/@headerText}"/>
                <meta name="footerText" content="{$patientSet/@footerText}"/>
            </head>
            <body>

                <!-- Table to display a description of the cohort -->
                <xsl:if test="exists($descriptionList)">
                    <table>
                        <thead>
                            <xsl:for-each select="$descriptionList">
                                <tr>
                                    <td>
                                        <xsl:value-of select="if (preceding-sibling::*) then $descriptionConnector else ''"/>
                                        <xsl:value-of select="."/>
                                    </td>
                                </tr>
                            </xsl:for-each>
                        </thead>
                        <tbody/>
                    </table>
                    
                    <!-- Bit of space and a line before the table of patients -->
                    <br/>
                    <hr/>
                    <br/>
                </xsl:if>


                <!-- Table displays list of patients in the patientSet
                 Table header is in the (single) patientInfo with items specified.
                 The table can't be generated without this or if there are no cohorts in the list -->
                <xsl:if
                    test="exists($patientInfoHeader/item) and exists($patientSet/patientInfo[not(item)])">
                    <table>
                        <thead>
                            <tr>
                                <xsl:for-each select="$patientInfoHeader/item">
                                    <th>
                                        <xsl:value-of select="./@displayName"/>
                                    </th>
                                </xsl:for-each>
                            </tr>
                        </thead>
                        <tbody>
                            <xsl:apply-templates select="$patientSet/patientInfo[not(item)]"/>
                        </tbody>
                    </table>
                </xsl:if>
            </body>
        </html>
    </xsl:template>

    <!-- patientInfo - one row in the table.
         Use $patientInfoHeader as the template for each value-->
    <xsl:template match="patientInfo[not(item)]">
        <xsl:variable name="patientInfo" select="."/>
        <tr>
            <xsl:for-each select="$patientInfoHeader/item">
                <xsl:variable name="item" select="."/>
                <!-- patientInfo may contain multiple entries, in descending order of effective time.
                     So we need the first one -->
                <xsl:variable name="cdaValue"
                    select="($patientInfo/descendant::cda:value[@extension=$item/@element][ancestor::cda:entry/descendant::cda:id/@extension=$item/@entry])[1]"/>
                <xsl:variable name="calculatedValue"
                    select="if (exists($patientInfo/@*[./name()=$item/@calculated])) then $patientInfo/@*[./name()=$item/@calculated] else $patientInfo/*[./name()=$item/@calculated]"/>
                <td>
                    <xsl:value-of
                        select="if (exists($cdaValue) and $cdaValue/@displayName!='') then $cdaValue/@displayName else if (exists($cdaValue)) then $cdaValue/@value else if (exists($calculatedValue)) then $calculatedValue else ''"
                    />
                </td>
            </xsl:for-each>
        </tr>
    </xsl:template>


</xsl:stylesheet>
