<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    checkAPIParameters.xsl
    Check the parameters passed to a cityEHR APY command
    
    Input is view-parameters with the command and other API parameters set (or not)
    
    Check that all parameters for the command have been set.
    If they have, then return <validParameters/>
    
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

    <!-- Cet the command -->
    <xsl:variable name="command" select="/parameters/command"/>

    <xsl:template match="/">
        <xsl:variable name="commandDefinition" select="parameters/cityEHRapi/command[@name = $command]"/>

        <xsl:if test="exists($commandDefinition)">
            <!-- Get the names of all command paramsters -->
            <xsl:variable name="commandParameterNames" select="$commandDefinition/parameters/parameter/@name"/>

            <!-- Get the parameters for the API call.
                 These are the parameters in view-parameters that match the API command-->
            <xsl:variable name="commandParameters" select="parameters/*[name() = $commandParameterNames]"/>

            <!-- The output depends on whether any of the paramsters are not set -->
            <xsl:if test="$commandParameters = ''">
                <invalidParameters>
                    <xsl:copy-of select="$commandDefinition"/>
                </invalidParameters>
            </xsl:if>
            <xsl:if test="not($commandParameters = '')">
                <validParameters>
                    <xsl:value-of select="string-join($commandParameters, '-')"/>
                </validParameters>
            </xsl:if>

        </xsl:if>

        <!-- The command not found should not happen.
             If it does, then its because view-parameters does not contain an entry for a command that does have a pipeline defined -->
        <xsl:if test="not(exists($commandDefinition))">
            <commandNotFound/>
        </xsl:if>

    </xsl:template>

    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>

</xsl:stylesheet>
