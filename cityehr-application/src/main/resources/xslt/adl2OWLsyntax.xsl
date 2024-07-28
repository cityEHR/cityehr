<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    adl2OWLsyntax.xsl
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

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions" exclude-result-prefixes="xs cityEHRFunction" version="2.0">

    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Match exceptions element.
        This is needed if the previous stage in the translation generated an exception -->
    <xsl:template match="/exceptions">
        <exceptions stage="{if (@stage) then @stage else 'syntax'}">
            <xsl:copy-of select="*"/>
        </exceptions>
    </xsl:template>

    <!-- Match document element -->
    <xsl:template match="/document">
        <document type="{@type}" stage="syntax">
            <xsl:apply-templates/>
        </document>
    </xsl:template>

    <!-- Declaration section has its own syntax -->
    <xsl:template match="section[@type='declaration']">
        <section type="{@type}">
            <xsl:call-template name="parseDeclaration">
                <xsl:with-param name="sourceString" select="."/>
            </xsl:call-template>
        </section>
    </xsl:template>

    <!-- Sections in ODIN syntax -->
    <xsl:template match="section[@type=('language','description','terminology','annotations','revision-history')]">
        <section type="{@type}" syntax="ODIN">
            <xsl:call-template name="parseODIN">
                <xsl:with-param name="sourceString" select="."/>
            </xsl:call-template>
        </section>
    </xsl:template>

    <!-- Definition sections in cADL syntax -->
    <xsl:template match="section[@type='definition']">
        <section type="{@type}" syntax="cADL">
            <xsl:call-template name="parseADL">
                <xsl:with-param name="syntax" select="'cADL'"/>
                <xsl:with-param name="sourceString" select="."/>
                <xsl:with-param name="position" as="xs:integer" select="1"/>
            </xsl:call-template>
        </section>
    </xsl:template>

    <!-- Rules section in FOPL syntax -->
    <xsl:template match="section[@type='rules']">
        <section type="{@type}">
            <xsl:call-template name="parseFOPL">
                <xsl:with-param name="sourceString" select="."/>
            </xsl:call-template>
        </section>
    </xsl:template>


    <!-- Mop up unmatched text nodes -->
    <xsl:template match="text()"/>


    <!-- Template to parse ADL Declaration -->
    <xsl:template name="parseDeclaration">
        <xsl:param name="sourceString"/>
        <xsl:value-of select="$sourceString"/>
    </xsl:template>


    <!-- Template to parse ADL ODIN -->
    <xsl:template name="parseODIN">
        <xsl:param name="sourceString"/>
        <xsl:value-of select="$sourceString"/>
    </xsl:template>

    <!-- Template to parse ADL cADL.
         This is a recursive template which identifies each cADL block in the sourceString -->
    <xsl:template name="parseADL">
        <xsl:param name="syntax"/>
        <xsl:param name="sourceString"/>
        <xsl:param name="position"/>

        <!-- Only process sourceString if there's something in it -->
        <xsl:if test="$sourceString!=''">
            <!-- Regex for the block prefix.
             Must match the block at start of the sourceString, then to the end of the string.
             blockId type[id] -->
            <xsl:variable name="blockType" select="'^([^\[\s]+)'"/>
            <xsl:variable name="blockId" select="'(\[[a-zA-Z0-9_]+\])?'"/>
            <xsl:variable name="constraints" select="'((occurrences|existence|cardinality)\s+(matches|is_in)\s*\{[^}]+\}\s*)*'"/>
            <xsl:variable name="matchOperator" select="'(matches|~matches|is_in|~is_in)'"/>
            <xsl:variable name="unparsedSource" select="'([^$]*)'"/>

            <xsl:variable name="regex" select="concat($blockType,'\s*',$blockId,'\s*',$constraints,'\s*',$matchOperator,'\s*',$unparsedSource)"/>

            <xsl:analyze-string select="$sourceString" regex="{$regex}">
                <!-- The whole string should match the regex -->
                <xsl:matching-substring>
                    <xsl:variable name="blockType" as="xs:string" select="regex-group(1)"/>
                    <xsl:variable name="blockId" as="xs:string" select="regex-group(2)"/>
                    <xsl:variable name="constraints" as="xs:string" select="regex-group(3)"/>
                    <xsl:variable name="matchOperator" as="xs:string" select="regex-group(6)"/>
                    <xsl:variable name="unparsedSource" as="xs:string" select="regex-group(7)"/>

                    <!-- extractBlockContent returns a sequence of the block content and the remaining unparsed source string -->
                    <xsl:variable name="blockContentExtraction" select="cityEHRFunction:extractBlockContent('',$unparsedSource,0)"/>

                    <xsl:variable name="blockContent" select="$blockContentExtraction[1]"/>
                    <xsl:variable name="remainingUnparsedSource" select="$blockContentExtraction[2]"/>

                    <block type="{$blockType}" id="{$blockId}">
                        <!-- Parse the contents of the block to find nested blocks. -->
                        <xsl:call-template name="parseADL">
                            <xsl:with-param name="syntax" select="$syntax"/>
                            <xsl:with-param name="sourceString" select="normalize-space($blockContent)"/>
                            <xsl:with-param name="position" as="xs:integer" select="1"/>
                        </xsl:call-template>
                    </block>

                    <!-- Parse the remaining source -->
                    <xsl:call-template name="parseADL">
                        <xsl:with-param name="syntax" select="$syntax"/>
                        <xsl:with-param name="sourceString" select="normalize-space($remainingUnparsedSource)"/>
                        <xsl:with-param name="position" as="xs:integer" select="1"/>
                    </xsl:call-template>

                </xsl:matching-substring>

                <!-- If the regex doesn't match the string, then this is leaf content of the { } block -->
                <xsl:non-matching-substring>
                    <xsl:value-of select="."/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>

        </xsl:if>
    </xsl:template>


    <!-- Function to separate block content from start of string.
     Reads the body until brackets {..} are balanced
     Then returns a sequence of two strings: the body and the remaining unparsed string -->

    <xsl:function name="cityEHRFunction:extractBlockContent">
        <xsl:param name="blockContent"/>
        <xsl:param name="unparsedSource"/>
        <xsl:param name="balance" as="xs:integer"/>

        <!-- Get next character to parse and remaining unparsed string-->
        <xsl:variable name="character" select="substring($unparsedSource, 1, 1)"/>
        <xsl:variable name="remainingUnparsedSource" select="substring-after($unparsedSource, $character)"/>
        
        <!-- Set the nextBlockCOntent.
             Don't want the leading { in the block content 
             This will be the first character found, when the function is called with blockContent = '' -->
        <xsl:variable name="nextBlockContent" select="if ($character='{' and $blockContent='') then '' else concat($blockContent,$character)"/>

        <!-- Check balance of the brackets -->
        <xsl:variable name="nextBalance" as="xs:integer"
            select="if ($character='{') then $balance + 1 else if ($character='}') then $balance - 1 else $balance"/>

        <!-- If brackets are balanced, or unparedString is exhausted, return the result.
             Don't need to add the training } here -->
        <xsl:if test="$nextBalance = 0 or $remainingUnparsedSource=''">
            <xsl:sequence select="($blockContent,$remainingUnparsedSource)"/>
        </xsl:if>

        <!-- Brackets not balanced - recursive call -->
        <xsl:if test="$nextBalance != 0 and $remainingUnparsedSource!=''">
            <xsl:sequence select="cityEHRFunction:extractBlockContent($nextBlockContent,$remainingUnparsedSource,$nextBalance)"/>
        </xsl:if>

    </xsl:function>


    <xsl:function name="cityEHRFunction:getSequence">
        <xsl:param name="input"/>
        <xsl:param name="count" as="xs:integer"/>

        <xsl:if test="$count = 0">
            <xsl:sequence select="$input"/>
        </xsl:if>

        <xsl:if test="$count = 0">
            <xsl:sequence select="$input"/>
        </xsl:if>

        <xsl:if test="$count gt 0">
            <xsl:sequence select="cityEHRFunction:getSequence(concat($input,' / ',$count),$count - 1)"/>
        </xsl:if>
    </xsl:function>


    <!-- Template to parse ADL FOPL -->
    <xsl:template name="parseFOPL">
        <xsl:param name="sourceString"/>
        <xsl:value-of select="$sourceString"/>
    </xsl:template>

</xsl:stylesheet>
