<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    WordProcessorExtractVariables.xsl
    Input is the content from ODF (content.xml, styles.xml) or MS Word document (word/document.xml)
    Returns a <letterTemplateVariables> element
    Finds variables in the text content of the form #ISO-13606:Entry:letterheadLeft or #ISO-13606:Entry:Demographics/#ISO-13606:Element:Surname 

    Generates a set of <variable/> elements of the form:
        <letterTemplateVariables>
            <variable entryIRI="#ISO-13606:Entry:EntryId/>
            ...
        </letterTemplateVariables>
       
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:cda="urn:hl7-org:v3" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions" 
    
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
    xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
    xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0"
    xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
    xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0" xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0"
    xmlns:math="http://www.w3.org/1998/Math/MathML" xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0"
    xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0" xmlns:ooo="http://openoffice.org/2004/office"
    xmlns:ooow="http://openoffice.org/2004/writer" xmlns:oooc="http://openoffice.org/2004/calc" xmlns:dom="http://www.w3.org/2001/xml-events"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
    xmlns:rpt="http://openoffice.org/2005/report" xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2" 
    xmlns:grddl="http://www.w3.org/2003/g/data-view#" xmlns:tableooo="http://openoffice.org/2009/table"
    xmlns:textooo="http://openoffice.org/2013/office" xmlns:field="urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0"
    
    xmlns:ve="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:v="urn:schemas-microsoft-com:vml"
    xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:w10="urn:schemas-microsoft-com:office:word"
    xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml"
    xmlns:wx="http://schemas.microsoft.com/office/word/2003/auxHint">


    <!-- === ODF document ========================== -->
    
    <!-- The document element is office:document-content  -->
    <xsl:template match="/office:document-content">
        <letterTemplateVariables content-type="application/vnd.oasis.opendocument.text">
            <xsl:apply-templates/>
        </letterTemplateVariables>    
    </xsl:template>
    
    <!-- Variables are found in text:p elements -->
    <!--
    <xsl:template match="text:p">
        
    </xsl:template>
    -->
    
    <!-- === MS Word document ========================== -->   

    <!-- MS Word document - the document element is w:document  -->
    <xsl:template match="/w:document">
        <letterTemplateVariables content-type="application/vnd.openxmlformats-officedocument.wordprocessingml.document">
            <xsl:apply-templates/>
        </letterTemplateVariables>         
    </xsl:template>
    
    
    <!-- === Anything else ========================== -->  
    
    <!-- Just output the name of the document element  -->
    <xsl:template match="/*[not(name()=('office:document-content','w:document'))]">
        <letterTemplateVariables content-type="unknown"/>     
    </xsl:template>   
    
   
    <!-- === Text Nodes - Look for Variables ========================== -->      
    <xsl:template match="text()">
        <xsl:variable name="regex" select="'(#ISO-13606:[^\s]*)'"/>
        
        <xsl:analyze-string select="." regex="{$regex}">
            <xsl:matching-substring>
                <xsl:variable name="variable" as="xs:string" select="regex-group(1)"/>
                <variable ref="{$variable}"/>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:template>
   
   
    <!-- === Functions ========================== --> 
    <!--
    <xsl:function name="cityEHRFunction:tokenizeExpressionEntries">
        <xsl:param name="content"/>
        <xsl:variable name="variablePrefix" select="'cityEHR:Variable:'"/>
        <xsl:variable name="pathSeparator" select="'/'"/>
        <xsl:variable name="regex" select="concat($variablePrefix,'([-a-zA-Z0-9_]+)',$pathSeparator)"/>
        
        <xsl:analyze-string select="$content" regex="{$regex}">
            <xsl:matching-substring>
                <xsl:variable name="entryId" as="xs:string" select="regex-group(1)"/>
                <xsl:if test="$entryId != 'math'">
                    <xsl:value-of select="concat('#ISO-13606:Entry:',$entryId)"/>
                </xsl:if>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    -->

</xsl:stylesheet>
