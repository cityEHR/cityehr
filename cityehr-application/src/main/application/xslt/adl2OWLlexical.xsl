<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    adl2OWLlexical.xsl
    Input is an ADL document defining an information model.
    Output is the basic structure of the ADL, split into sections
    Comments are removed from cADL sections
    
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
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions" exclude-result-prefixes="xs" version="2.0">

    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Keywords for ADL syntax.
         Sequence of comma separated strings for each archetype type.
         Each string is a set of comma separated patterns for the sequence of keywords denoting sections in that type of archetype. -->
    <xsl:variable name="adlStructure"
        select="('archetype:
                  declaration/specialize|specialise|concept|language,
                  specialize/concept|language,
                  specialise/concept|language,
                  concept/language,
                  language/description|definition,
                  description/definition,
                  definition/rules|terminology|ontology,
                  rules/terminology|ontology,
                  terminology/,
                  ontology/',
                  
                  'template:
                  declaration/specialize|specialise|concept|language,
                  specialize/concept|language,
                  specialise/concept|language,
                  concept/language,
                  language/description,
                  description/definition,
                  definition/rules|terminology|ontology,
                  rules/terminology|ontology,
                  terminology/end-of-file,
                  ontology/end-of-file',
                  
                  'template_overlay:
                  declaration/specialize|specialise|concept|language,
                  specialize/concept|language,
                  specialise/concept|language,
                  concept/language,
                  language/description,
                  description/definition,
                  definition/rules|terminology|ontology,
                  rules/terminology|ontology,
                  terminology/end-of-file,
                  ontology/end-of-file',
                  
                  'operational_template:
                  declaration/specialize|specialise|concept|language,
                  specialize/concept|language,
                  specialise/concept|language,
                  concept/language,
                  language/description,
                  description/definition,
                  definition/rules|terminology|ontology,
                  rules/terminology|ontology,
                  terminology/end-of-file,
                  ontology/end-of-file'
                  
                  )"/>

    <!-- Match document element.
         This should be the only node -->
    <xsl:template match="/document">

        <!-- Strip the BOM, if present -->
        <xsl:variable name="bom" select="concat('&#xEF;','&#xBB;','&#xBF;')"/>
        <xsl:variable name="adlDocument" select="if (starts-with(.,$bom)) then substring-after(.,$bom) else ."/>

        <!-- Get the archetype type (needed as a global variable).
             The ADL should start with ^(flat)?\s*(archetype|template|template_overlay|operational_archetype)\s+\(
             So get the string before the first '(', strip trailing whitespace and get the last token -->
        <xsl:variable name="adlType" select="tokenize(normalize-space(substring-before($adlDocument,'(')),'\s')[last()]"/>

        <!-- Get the adlKeywords for the archetype type.
             First get the structure for the adlType, then form the set of structure kweywords -->
        <xsl:variable name="adlTypeStructure" select="normalize-space($adlStructure[substring-before(.,':')=$adlType])"/>
        <xsl:variable name="adlKeywords" select="tokenize(normalize-space(substring-after($adlTypeStructure,':')),'\s*,\s*')"/>

        <document type="{$adlType}" stage="lexical">
            <!-- Not a valid archetype type 
                 This shouldn't happen, since the type is checked before this transformation is made, but just in case -->
            <xsl:if test="empty($adlKeywords)">
                <error type="adl-invalid-archetype-type" parameter="{$adlType}"/>
            </xsl:if>

            <!-- Process valid archetype type -->
            <xsl:if test="exists($adlKeywords)">
                <!-- Get ADL text after the type declaration -->
                <xsl:variable name="sourceString" select="substring-after($adlDocument,$adlType)"/>

                <!-- First split into individual lines -->
                <xsl:variable name="sourceTokens" select="tokenize($sourceString,'^','m')"/>

                <!-- Set up first call to parseSections -->
                <xsl:variable name="currentSection" select="'declaration'"/>
                <xsl:variable name="currentSectionStructure" select="$adlKeywords[starts-with(.,$currentSection)]"/>
                <xsl:variable name="currentSectionTerminators" select="tokenize(substring-after($currentSectionStructure,'/'),'\|')"/>

                <!-- Call recursive parseSections template to split source into sections -->
                <xsl:call-template name="parseSections">
                    <xsl:with-param name="sourceTokens" select="$sourceTokens"/>
                    <xsl:with-param name="adlKeywords" select="$adlKeywords"/>
                    <xsl:with-param name="currentSection" select="$currentSection"/>
                    <xsl:with-param name="currentSectionText" select="''"/>
                    <xsl:with-param name="currentSectionTerminators" select="$currentSectionTerminators"/>
                </xsl:call-template>

            </xsl:if>
        </document>
    </xsl:template>

    <!-- Recursive template to parse ADL into sections -->
    <xsl:template name="parseSections">
        <xsl:param name="sourceTokens"/>
        <xsl:param name="adlKeywords"/>
        <xsl:param name="currentSection"/>
        <xsl:param name="currentSectionText"/>
        <xsl:param name="currentSectionTerminators"/>

        <!-- Check for terminator of current section -->
        <xsl:variable name="token" select="normalize-space($sourceTokens[1])"/>
        <xsl:variable name="unparsedSourceTokens" select="$sourceTokens[position() gt 1]"/>

        <!-- Output section on terminator, or if source tokens are exhausted.
             Then set up for next section -->
        <xsl:if test="($token!='' and $token=$currentSectionTerminators) or empty($unparsedSourceTokens)">
            <!-- Generate section -->
            <section type="{$currentSection}">
                <xsl:value-of select="$currentSectionText"/>
            </section>

            <!-- Set up next section and continue parsing.
            But only if there are tokens left to parse -->
            <xsl:if test="exists($unparsedSourceTokens)">
                <xsl:variable name="nextSection" select="$token"/>
                <xsl:variable name="nextSectionTerminators" select="tokenize(substring-after($adlKeywords[starts-with(.,$nextSection)][1],'/'),'\|')"/>
                <xsl:call-template name="parseSections">
                    <xsl:with-param name="sourceTokens" select="$unparsedSourceTokens"/>
                    <xsl:with-param name="adlKeywords" select="$adlKeywords"/>
                    <xsl:with-param name="currentSection" select="$nextSection"/>
                    <xsl:with-param name="currentSectionText" select="''"/>
                    <xsl:with-param name="currentSectionTerminators" select="$nextSectionTerminators"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:if>

        <!-- No terminator - continue current section -->
        <xsl:if test="not($token=$currentSectionTerminators) and exists($unparsedSourceTokens)">
            <xsl:call-template name="parseSections">
                <xsl:with-param name="sourceTokens" select="$unparsedSourceTokens"/>
                <xsl:with-param name="adlKeywords" select="$adlKeywords"/>
                <xsl:with-param name="currentSection" select="$currentSection"/>
                <xsl:with-param name="currentSectionText"
                    select="if ($token='') then $currentSectionText else concat($currentSectionText,cityEHRFunction:stripComments($token),'&#10;')"/>
                <xsl:with-param name="currentSectionTerminators" select="$currentSectionTerminators"/>
            </xsl:call-template>
        </xsl:if>

    </xsl:template>

    <!-- Function to strip comments.
         Just remove the comment from the delimiter to the end of the line -->
    <xsl:function name="cityEHRFunction:stripComments">
        <xsl:param name="token"/>

        <xsl:value-of select="if (contains($token,'--')) then substring-before($token,'--') else $token"/>
    </xsl:function>



    <!-- Use analyze-string to find the Archetype Declaration and then process the other sections.-->
    <!--
    <xsl:analyze-string select="$adlDocument" regex="^(flat)?\s*(archetype|template|template_overlay|operational_archetype)\s+\(([^)]*)\)">
        <xsl:matching-substring>
            <declaration> / <xsl:value-of select="regex-group(1)"/> / <xsl:value-of select="regex-group(2)"/> / <xsl:value-of
                select="regex-group(3)"/> / </declaration>
        </xsl:matching-substring>
        
        <xsl:non-matching-substring></xsl:non-matching-substring>
        
    </xsl:analyze-string>
    -->




    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


</xsl:stylesheet>
