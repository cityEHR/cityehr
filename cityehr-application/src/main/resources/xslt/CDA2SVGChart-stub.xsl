<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    CDA2SVGChart.xsl
    Input is a CDA document representing a generated view
    PLUS a control file which contains the variables that are to be charted
    
    Generates an SVG file that can be consumed by the SVG 2 PNG converter or rendered directly by modern browsers.
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet xmlns:svg="http://www.w3.org/2000/svg"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs" version="2.0" xmlns:cda="urn:hl7-org:v3"
    xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:iso-13606="http://www.iso.org/iso-13606"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">

    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Root document nodes -->

    <xsl:variable name="rootNode" select="/"/>
    <xsl:variable name="controlRootNode" select="document('input:control')"/>
    <xsl:variable name="validInputs"
        select="if (exists($rootNode) and exists($controlRootNode)) then true() else false()"/>

    <xsl:template match="/">
        <xsl:if test="$validInputs or not($validInputs)">
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="300" version="1.1">
                <rect x="0" y="0" width="100" height="100" fill="#E8E8E8"/>
                <text x="50" y="50" font-size="12" text-anchor="middle">
                    <xsl:value-of select="'hello'"/>
                </text>
            </svg>
        </xsl:if>
    </xsl:template>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>
</xsl:stylesheet>
