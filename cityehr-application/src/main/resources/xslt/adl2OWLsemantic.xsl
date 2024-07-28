<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    adl2OWLsemantic.xsl
    Input is an XML document with sections of ADL.
    Output is XML representing parsed syntax of the declaration, ODIN, cADL and rules
    
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
    version="2.0">

    <xsl:output method="xml" indent="yes" name="xml"/>
    
    <!-- Match exceptions element.
         This is needed if the previous stage in the translation generated an exception -->
    <xsl:template match="exceptions">
        <exceptions stage="{if (@stage) then @stage else 'semantic'}">
            <xsl:copy-of select="*"/>
        </exceptions>
    </xsl:template>


    <!-- Match document element.
         This should be the only node -->
    <xsl:template match="/document">
        <document type="{@type}" stage="semantic">
            <xsl:copy-of select="*"/>
        </document>
    </xsl:template>



    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
