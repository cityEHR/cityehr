<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    Database2OWL.xsl
    Input is a cityEHR database (converted from a spreadsheet) with information model for the specialty or class
    Generates an OWL/XML ontology as per the City EHR architecture.
    
    <database>
        <table id="name1">
            <record>
                <field>r1c1</field>
                ...
            </record>
            ...
        </table>
        <table id="name2">
            <record>
                <field>r1c1</field>
                ...
            </record>
            ...
        </table>
        ...
    </database>
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">

    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Import module that generates OWL ontology from spreadsheet -->
    <xsl:include href="Database2OWL-Module.xsl"/>

    <!-- Get the cityEHR architecture OWL/XML for inclusion in the generated ontology
         This is the new 2018 version - V2.
         There is a full version of the architecture for specialty models
         and a cut-down version (with only the required properties declared) for class models.
         The classId is set in Database2OWL-Module.xsl - it is a node, not a string -->
    <xsl:variable name="cityEHRarchitecture"
        select="if ($classId) then document('../resources/templates/cityEHRarchitecture-2018-class.xml') else document('../resources/templates/cityEHRarchitecture-2018.xml')"/>


    <!-- Match root and call template to generate the ontology -->
    <xsl:template match="/">
        <xsl:if test="$processError='false'">
            <xsl:apply-templates/>
        </xsl:if>
        <xsl:if test="$processError='true'">
            <xsl:call-template name="generateOWLError">
                <xsl:with-param name="context">cityEHR Information Model cannot be
                    processed.</xsl:with-param>
                <xsl:with-param name="message">applicationId and specialtyId must be defined in the
                    model.</xsl:with-param>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
