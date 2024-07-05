<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    AnonymiseDataSet-Module.xsl
    Input is a patient cohort with patientInfo and patientData elements
    Generates anonymised XML with same structure
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:cda="urn:hl7-org:v3" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">

    <!-- ========================
         Global variables
         ======================== -->
    <!-- Set parameters -->
    <xsl:variable name="sessionId" select="$parameters/sessionId"/>    
    <xsl:variable name="anonymisationType" select="$parameters/exportPipeline/anonymisation/anonymisationType"/>
    <xsl:variable name="allowableCharacterString"
        select="$parameters/exportPipeline/anonymisation/allowableCharacterString"/>
    <xsl:variable name="seedKey"
        select="$parameters/exportPipeline/anonymisation/seedKey"/>
    <xsl:variable name="anonymiseElements" select="$parameters/exportPipeline/anonymisation/anonymiseElements"/>
   
    <!-- Set the characterSelectionKey as an integer from the seedKey -->
    <xsl:variable name="randomNumberSet" select="translate(substring-after(xs:string(current-dateTime()),'.'),'Z','')"/>
    <xsl:variable name="randomNumber" select="if ($randomNumberSet castable as xs:integer) then $randomNumberSet else '8464292'"/>
    <xsl:variable name="sessionNumberSet" select="translate($sessionId,'123456789','123456789')"/> 
    <xsl:variable name="sessionNumber" select="if ($sessionNumberSet castable as xs:integer) then $sessionNumberSet else '9647272'"/>   
    <xsl:variable name="seedNumberSet" select="sum(string-to-codepoints($seedKey))"/>
    <xsl:variable name="seedNumber" select="if ($seedNumberSet castable as xs:integer) then $seedNumberSet else '4672372'"/>   
    
    <xsl:variable name="characterSelectionKey"
        select="if ($anonymisationType='anonymised') then xs:integer($randomNumber)*xs:integer($sessionNumber)*xs:integer($seedNumber) else xs:integer($seedNumber)"/>
    
    <!-- Set the root node -->
    <xsl:variable name="rootNode" select="//patientSet"/>

    <!-- Set entry lists for patientInfo (demographics) and data sets -->
    <xsl:variable name="entryList" select="tokenize($rootNode/@entryList,' ')"/>
    <xsl:variable name="entryListCount" select="count($entryList)+2"/>
    <xsl:variable name="dataSetEntryList" select="tokenize($rootNode/@dataSetEntryList,' ')"/>


    <!-- ========================
         Anonymise data set
         ======================== -->

    <!-- Process the base patientSet element -->
    <xsl:template match="patientSet">
        <patientSet>
            <!-- Copy attributes -->
            <xsl:copy-of select="@*"/>

            <!-- Process children.
                 If no anonymisation, then just copy straight through -->
            <xsl:if test="not($anonymisationType=('pseudoAnonymised','anonymised'))">
                <xsl:copy-of select="*"/>
            </xsl:if>
            <!-- Process children.
            If anonymisation is required, then apply templates -->
            <xsl:if test="$anonymisationType=('pseudoAnonymised','anonymised')">
                <xsl:apply-templates/>
            </xsl:if>
        </patientSet>
    </xsl:template>



    <!-- patientInfo -->
    <xsl:template match="patientInfo">
        <xsl:variable name="patientId" select="./@patientId"/>

        <!-- Anonymise patientId -->
        <xsl:variable name="anonymisedPatientId"
            select="cityEHRFunction:anonymiseString($patientId,$allowableCharacterString,$characterSelectionKey)"/>

        <patientInfo patientId="{$anonymisedPatientId}">
            <xsl:apply-templates/>
        </patientInfo>
    </xsl:template>
    
    <!-- patientData -->
    <xsl:template match="patientData">
        <xsl:variable name="patientId" select="./@patientId"/>
        
        <!-- Anonymise patientId -->
        <xsl:variable name="anonymisedPatientId"
            select="cityEHRFunction:anonymiseString($patientId,$allowableCharacterString,$characterSelectionKey)"/>
        
        <patientData patientId="{$anonymisedPatientId}">
            <xsl:apply-templates/>
        </patientData>
    </xsl:template>


    <!-- cda:value - anonymise @value and @displayName -->
    <xsl:template match="cda:value">
        <cda:value>
            <xsl:copy-of select="@*[not(name()=('value','displayName'))]"/>

            <xsl:variable name="entryIRI"
                select="ancestor::cda:entry[1]/descendant::cda:id[1]/@extension"/>
            <xsl:variable name="elementIRI" select="@extension"/>

            <xsl:variable name="value" select="@value"/>
            <xsl:variable name="displayName" select="@displayName"/>

            <xsl:variable name="anonymiseElement"
                select="if (exists($anonymiseElements/anonymise[@entry=$entryIRI][@element=$elementIRI])) then 'true' else 'false'"/>
            <!-- If this entry/element is anonymised -->
            <xsl:if test="$anonymiseElement='true'">
                <xsl:attribute name="value"
                    select="cityEHRFunction:anonymiseString($value,$allowableCharacterString,$characterSelectionKey)"/>
                <xsl:attribute name="displayName"
                    select="cityEHRFunction:anonymiseString($displayName,$allowableCharacterString,$characterSelectionKey)"
                />
            </xsl:if>
            <!-- Not anonymised -->
            <xsl:if test="not($anonymiseElement='true')">
                <xsl:attribute name="value" select="$value"/>
                <xsl:attribute name="displayName" select="$displayName"/>
            </xsl:if>
            <xsl:apply-templates/>
        </cda:value>
    </xsl:template>

    
    <!-- Copy everything else -->
    <xsl:template match="*">
        <xsl:element name="{name(.)}" namespace="urn:hl7-org:v3">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="text()">
        <xsl:value-of select="."/>
    </xsl:template>


    <!-- ===================================================================
         Utility Functions
         =================================================================== -->

    <!-- Function to anonymise a string.
         Convert the string to code points.
         Iterate through codepoints, generating character position in allowableCharacterString for output
         Build up anonymised string from the characters selected. 
         Always gives the same result for any repeat of the three parameters.
         So result is anonymised if characterSelectionKey is randomly generated, 
         or pseudo-anonymised if characterSelectionKey is predicably generated (e.g. from a set key)-->

    <xsl:function name="cityEHRFunction:anonymiseString">
        <xsl:param name="string"/>
        <xsl:param name="allowableCharacterString"/>
        <xsl:param name="characterSelectionKey"/>

        <xsl:variable name="stringCodePoints" select="string-to-codepoints($string)"/>
        <xsl:variable name="stringKey" select="sum($stringCodePoints)"/>

        <xsl:variable name="allowableCharacterCodePoints"
            select="string-to-codepoints($allowableCharacterString)"/>
        <xsl:variable name="allowableCharacterCount" select="count($allowableCharacterCodePoints)"/>

        <!-- Get list of character positions, based on stringCodePoints -->
        <xsl:variable name="characterPositions"
            select="for $c in $stringCodePoints return xs:integer(xs:integer($c) * xs:integer($characterSelectionKey) * xs:integer($stringKey)) mod xs:integer($allowableCharacterCount) + 1"/>

        <!-- Get list of characters from allowableCharacterString. based on character positions -->
        <xsl:variable name="anonymisedStringCodePoints"
            select="for $p in $characterPositions return $allowableCharacterCodePoints[position() = $p]"/>

        <xsl:value-of select="codepoints-to-string($anonymisedStringCodePoints)"/>
    </xsl:function>


</xsl:stylesheet>
