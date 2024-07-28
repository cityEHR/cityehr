<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    depthCount.xsl
    Output count of XML tree depth
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:iso-13606="http://www.iso.org/iso-13606" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3" exclude-result-prefixes="xs" version="2.0">

    <!-- reportMode can be:
            full        report depth on avery element
            parameters  only report depth of parameters, not control element (from cityEHR: namespace) -->
    <xsl:variable name="reportMode" select="'parameters'"/>

    <!-- depthLimit is the threshold at which depth is reported.
         e.g. depthLimit = 3 means only report elements at depth greater than 3-->
    <xsl:variable name="depthLimit" select="3"/>

    <xsl:template match="/">
        <treeInfo>
            <xsl:apply-templates/>
        </treeInfo>
    </xsl:template>

    <xsl:template match="element()">
        <xsl:variable name="name" select="name()"/>
        <xsl:variable name="path" select="string-join(ancestor::*/name(),'/')"/>
        <xsl:variable name="depth" select="count(ancestor::*)"/>

        <!-- Apply reportMode restrictions, if configured -->
        <xsl:if test="$reportMode = 'full' or not(starts-with($name,'cityEHR:'))">

            <!-- Only report to depthLimit -->
            <xsl:if test="$depthLimit castable as xs:integer and $depth gt $depthLimit">
                <node name="{$name}" path="{$path}" depth="{$depth}"/>
            </xsl:if>

            <!-- Processing only continues within restrictions of reportMode -->
            <xsl:apply-templates/>

        </xsl:if>
    </xsl:template>

    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>

</xsl:stylesheet>
