<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    ODFSpreadsheet2OWL-Module.xsl
    Input is a spreadsheet (content.xml file from the ODF .ods zip) with data dictionary and forms for a specialty
    Plus the static ontology shell passed in on the cityEHRarchitecture input
    Generates an OWl/XML ontology as per the City EHR architecture.
    
    Any errors found are reported in OWL annotations as follows:
    <Annotation>
        <AnnotationProperty abbreviatedIRI=":error"/>
        <Literal> Error description</Literal>
        </Annotation>
    <Annotation>
    
    This module is designed to be called from ODFSpreadsheet2OWL.xsl or ODFSpreadsheet2OWLFile.xsl.
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<!-- === Note: This version uses &amp;rdf;PlainLiteral with a character map to output &rdf;PlainLiteral.
    2016-04-21 Could change to output &amp;rdf;PlainLiteral - this seems to be more normal, even though Protege uses &rdf;PlainLiteral
    &rdf; is an entity and only works if the entity is declared in the document prologue. 
    
    So we now use: datatypeIRI="&amp;rdf;PlainLiteral"
    To put back to the Protege way, make a global replace on datatypeIRI="&amp;rdf;PlainLiteral"
-->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:cda="urn:hl7-org:v3" xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:html="http://www.w3.org/TR/REC-html40" xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
    xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0"
    xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:presentation="urn:oasis:names:tc:opendocument:xmlns:presentation:1.0"
    xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0"
    xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0" xmlns:math="http://www.w3.org/1998/Math/MathML"
    xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0" xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0"
    xmlns:ooo="http://openoffice.org/2004/office" xmlns:ooow="http://openoffice.org/2004/writer" xmlns:oooc="http://openoffice.org/2004/calc"
    xmlns:dom="http://www.w3.org/2001/xml-events" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rpt="http://openoffice.org/2005/report"
    xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:grddl="http://www.w3.org/2003/g/data-view#" xmlns:tableooo="http://openoffice.org/2009/table"
    xmlns:field="urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">

    <!-- Output formatted XML -->
    <xsl:output method="xml" indent="yes" name="xml" use-character-maps="entityOutput"/>

    <!-- Import OWL Utilities -->
    <xsl:include href="OWLUtilities.xsl"/>

    <!-- === 
        Character maps - allows the output of &rdf; in data property attributes       
        === -->
    <xsl:character-map name="entityOutput">
        <xsl:output-character character="&amp;" string="&amp;"/>
    </xsl:character-map>


    <!-- ==============================================
        Global variables 
        ============================================== -->

    <!-- Set the root node -->
    <xsl:variable name="rootNode" select="/"/>

    <!-- The startRow for the spreadsheet being processed is determined by the row of the Application property on the Configuration sheet.
         But just set it to 1, since that's what it is. -->
    <xsl:variable name="startRow" as="xs:integer" select="1"/>
    
    <!-- Set the prefix used for propertyIRIs (for properties defined on the sheet named 'Properties' -->
    <xsl:variable name="propertyIRI" select="'#CityEHR:Property'"/>

    <!-- Set the configuration sheet -->
    <xsl:variable name="configurationSheet" select="office:document-content/office:body/office:spreadsheet/table:table[@table:name='Configuration']"/>

    <!-- Set the Application for this Information Model -->
    <xsl:variable name="applicationId"
        select="$configurationSheet/table:table-row[table:table-cell[1]/text:p='ApplicationId']/table:table-cell[2]/text:p"/>
    <xsl:variable name="modelOwner"
        select="$configurationSheet/table:table-row[table:table-cell[1]/text:p='ModelOwner']/table:table-cell[2]/text:p"/>


    <!-- Set the Specialty for this Information Model -->
    <xsl:variable name="specialtyId" select="$configurationSheet/table:table-row[table:table-cell[1]/text:p='SpecialtyId']/table:table-cell[2]/text:p"/>
    <xsl:variable name="specialtyDisplayName"
        select="$configurationSheet/table:table-row[table:table-cell[1]/text:p='SpecialtyDisplayName']/table:table-cell[2]/text:p"/>

    <!-- Set the Class for this Information Model.
        This will only get set for a class model - specialty model will leave these blank-->
    <xsl:variable name="classId"
        select="if (exists($configurationSheet/table:table-row[table:table-cell[1]/text:p='classId'])) then $configurationSheet/table:table-row[table:table-cell[1]/text:p='classId']/table:table-cell[2]/text:p else ()"/>
    <xsl:variable name="classDisplayName"
        select="if (exists($configurationSheet/table:table-row[table:table-cell[1]/text:p='classDisplayName'])) then $configurationSheet/table:table-row[table:table-cell[1]/text:p='classDisplayName']/table:table-cell[2]/text:p else ()"/>

    <!-- Set the Base Language for this Information Model - this should be in OETF language code format ll-cc -->
    <xsl:variable name="specifiedLanguageCode"
        select="$configurationSheet/table:table-row[table:table-cell[1]/text:p='LanguageCode']/table:table-cell[2]/text:p"/>
    <xsl:variable name="baseLanguageCode" select="if ($specifiedLanguageCode!='') then $specifiedLanguageCode else 'en-gb'"/>

    <!-- Set the pathSeparator for this Information Model -->
    <xsl:variable name="specifiedPathSeparator"
        select="$configurationSheet/table:table-row[table:table-cell[1]/text:p='PathSeparator']/table:table-cell[2]/text:p"/>
    <xsl:variable name="pathSeparator" select="if ($specifiedPathSeparator!='') then $specifiedPathSeparator else '/'"/>

    <!-- Can only process spreadsheet if applicationId and specialtyId are defined -->
    <xsl:variable name="processError" as="xs:string" select="if ($applicationId !='' and $specialtyId !='') then 'false' else 'true'"/>

    <!-- ==============================================
         Variables for displayNames
         ============================================== -->

    <!-- Specialty and class have display names -->
    <xsl:variable name="specialtyTerms" select="$specialtyDisplayName | $classDisplayName"/>

    <!-- On all sheets except Configuration, Properties and Contents
         The displayName is in cell position 2, only for rows where there is an Identifier in the first cell
         And if the Identifier is the same as the DisplayName, then the value is from cell position 1, with table:number-columns-repeated
         And not on the first row, which has the column headers -->
    <xsl:variable name="modelComponentSheets"
        select="office:document-content/office:body/office:spreadsheet/table:table[not(@table:name=('Configuration','Properties','Contents'))]"/>
    <xsl:variable name="displayNameTerms"
        select="$modelComponentSheets/table:table-row[position() gt 1][table:table-cell[1]/text:p!='']/table:table-cell[2][text:p!=''] | $modelComponentSheets/table:table-row[position() gt 1]/table:table-cell[1][@table:number-columns-repeated][text:p!='']"/>

    <!-- Element value displayNames are in the Values of the Element sheet.
         But only for elements with an Id and of enumeratedValue or enumeratedDirectory type -->
    <xsl:variable name="elementSheet" select="office:document-content/office:body/office:spreadsheet/table:table[@table:name='Element']"/>
    <xsl:variable name="elementSheetRows"
        select="$elementSheet/table:table-row[position() gt 1][table:table-cell[1]/text:p!=''][table:table-cell/text:p=('enumeratedValue','enumeratedDirectory')]"/>
    <xsl:variable name="valuePosition" select="$elementSheet/table:table-row[1]/table:table-cell[text:p='Values']/count(preceding-sibling::*) +1"/>
    <xsl:variable name="elementValueTerms" select="cityEHRFunction:GetValueDisplayNames($elementSheetRows,$valuePosition)"/>

    <xsl:variable name="allTerms" select="$specialtyTerms/normalize-space(.), $displayNameTerms/normalize-space(text:p), $elementValueTerms"/>


    <!-- ==============================================
        Define Keys  
        ============================================== -->

    <!-- Key for Properties    
         propertySetCells returns set of cells for a cityEHR property.
         The properties are dfined on the sheet named 'Properties'
    -->
    <xsl:key name="propertySetCells"
        match="/office:document-content/office:body/office:spreadsheet/table:table[@table:name='Properties']/table:table-row[position() gt 1][table:table-cell[1]/normalize-space(text:p)!='']/table:table-cell"
        use="normalize-space(../table:table-cell[1]/text:p)"/>



    <!-- === 
         Generate OWL/XML with the full cityEHR ontology for this information model       
         === -->
    <xsl:template match="office:document-content">

        <!-- === Output the DOCTYPE and document type declaration subset with entity definitions.
            Plus the root document node for the Ontology -->

        <!-- This would be required to make identical to the format Protege uses.
            Then use &rdf;PlainLiteral
            But xforms processing doesn't like document prologue, so we are not using it -->
        <!--
            <xsl:text disable-output-escaping="yes"><![CDATA[
            <!DOCTYPE Ontology [
            <!ENTITY xsd "http://www.w3.org/2001/XMLSchema#" >
            <!ENTITY xml "http://www.w3.org/XML/1998/namespace" >
            <!ENTITY rdfs "http://www.w3.org/2000/01/rdf-schema#" >
            <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#" >
            ]> 
            ]]></xsl:text>
        -->

        <Ontology xmlns="http://www.w3.org/2002/07/owl#">
            <!-- Copy attributes (including namespace declarations) from template -->
            <xsl:copy-of select="$cityEHRarchitecture/owl:Ontology/@*"/>

            <!-- === The City EHR ontology architecture - static XML === 
                Copy the assertions from cityEHRarchitecture.xml
                This includes the necessary prefix declarations and some standard annotations
                plus all assertions for the cityEHR architecture
                ============================================================== -->
            <xsl:copy-of select="$cityEHRarchitecture/owl:Ontology/*"/>


            <!-- Process the sheets to build the model -->
            <xsl:apply-templates/>

        </Ontology>
    </xsl:template>

    <!-- Top level elements in the spreadsheet - just process children -->
    <xsl:template match="office:body">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="office:spreadsheet">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- Sheet for configuration
         The parameters on this sheet are recorded as annotations in the ontology
         -->
    <xsl:template match="table:table[@table:name='Configuration']">
        <xsl:call-template name="generateAnnotations"/>
        <xsl:call-template name="generateApplicationDeclarations"/>
    </xsl:template>

    <!-- Sheet for properties.
         The cityEHR properties for this ontology
         These are cityEHR specific properties applied to the model components
        -->
    <xsl:template match="table:table[@table:name='Properties']">
        <!-- Each property on a separate row, except for the header row -->
        <xsl:for-each select="table:table-row[position() gt 1][table:table-cell[1]/text:p!='']">
            <xsl:variable name="rowCells" select="table:table-cell"/>
            <xsl:variable name="rowValues" select="cityEHRFunction:GetODFRowData($rowCells)[. !='']"/>

            <xsl:variable name="propertyType" select="normalize-space($rowValues[1])"/>
            <xsl:variable name="propertyValues" select="$rowValues[position() gt 1]"/>

            <xsl:call-template name="generatePropertySet">
                <xsl:with-param name="propertyType" select="$propertyType"/>
                <xsl:with-param name="propertyValues" select="$propertyValues"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template>

    <!-- Sheet for contents - does not need to be processed
         But use it to output the declarations for value, displayName and term -->
    <xsl:template match="table:table[@table:name='Contents']">
        <!-- Generate assertions for the terms -->
        <xsl:call-template name="generateTerms">
            <xsl:with-param name="terms" select="distinct-values($allTerms)"/>
        </xsl:call-template>

    </xsl:template>

    <!-- All other sheets are for components in the model.
         Output the property assertions for each component (row) -->
    <xsl:template match="table:table">
        <xsl:variable name="componentType" select="@table:name"/>

        <!-- Only output for sheets that have a name -->
        <xsl:if test="$componentType !=''">
            <!-- Set the IRI for the component - prefix is either ISO-13606 or CityEHR-->
            <xsl:variable name="componentTypeIRI" select="cityEHRFunction:GetComponentTypeIRI($componentType)"/>

            <!-- The set of properties is in the first row.
                 May contain blank cells after the final property -->
            <xsl:variable name="propertySet" select="cityEHRFunction:GetODFRowData(table:table-row[1]/table:table-cell)[.!='']"/>
            <xsl:variable name="identifierProperty" select="$propertySet[1]"/>

            <!-- Generate an error if identifier property is bad -->
            <xsl:if test="$identifierProperty != 'Identifier'"> </xsl:if>

            <!-- Only continue if the sheet has an identifier property -->
            <xsl:if test="$identifierProperty = 'Identifier'">

                <!-- Check that the identifiers are unique -->
                <xsl:variable name="identifierSet" select="table:table-row[position() gt 1][table:table-cell[1]/text:p!='']/text:p"/>
                <xsl:variable name="repeatIdentifiers" select="cityEHRFunction:getRepeatIdentifiers($identifierSet)"/>

                <!-- Output assertions for each identified component (row)
                     But only if identifiers are OK -->
                <xsl:if test="empty($repeatIdentifiers)">
                    <xsl:for-each select="table:table-row[position() gt 1][table:table-cell[1]/text:p!='']">
                        <xsl:variable name="rowCells" select="table:table-cell"/>

                        <xsl:variable name="propertyValues" select="cityEHRFunction:GetODFRowData($rowCells)"/>

                        <xsl:call-template name="generateComponentAssertions">
                            <xsl:with-param name="componentTypeIRI" select="$componentTypeIRI"/>
                            <xsl:with-param name="propertySet" select="$propertySet"/>
                            <xsl:with-param name="propertyValues" select="$propertyValues"/>
                        </xsl:call-template>

                    </xsl:for-each>
                </xsl:if>

                <!-- Output errors for any repeat identifiers -->
                <xsl:for-each select="$repeatIdentifiers">
                    <xsl:variable name="identifier" select="."/>
                    <xsl:call-template name="generateError">
                        <xsl:with-param name="node" select="$identifier"/>
                        <xsl:with-param name="context" select="$componentType"/>
                        <xsl:with-param name="message" select="'Identifier not unique'"/>
                    </xsl:call-template>
                </xsl:for-each>

            </xsl:if>
        </xsl:if>
    </xsl:template>


    <!-- ====================================================================
         cityEHRFunction:GetODFRowData
         Get the set of data values in a row of the spreadsheet as a set of normalized-space strings.
         The cellSet is the set of table:table-cell elements in the row.
         Empty cells in the row give a value of '' (empty string)
         The set extends to the last cell with a value.
         
         Cells in the row are:
         <table:table-row table:style-name="ro1">
            <table:table-cell table:number-columns-repeated="3"/>
            <table:table-cell office:value-type="string">
                <text:p>-</text:p>
            </table:table-cell>
         </table:table-row>
         
         This is a tail recursive function that builds the return sequence
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:GetODFRowData">
        <xsl:param name="cellSet"/>
        <xsl:variable name="cell" select="$cellSet[1]"/>

        <!-- The value is made up of all child text:p -->
        <xsl:variable name="value" as="xs:string" select="if (exists($cell/text:p)) then normalize-space(string-join($cell/text:p,' ')) else ''"/>
        <xsl:variable name="occurenceCount"
            select="if (exists($cell/@table:number-columns-repeated)) then $cell/@table:number-columns-repeated else 1"/>

        <xsl:variable name="nextCellSet" select="$cellSet[position() gt 1]"/>

        <!-- Output sequence of cell values.
             But if the last cell is has no value, then don't output.
             Most rows have a last cell with no value, repeated many times - so this avoid outputting hundreds of empty values -->
        <xsl:if test="not(empty($nextCellSet) and $value='')">
            <xsl:sequence select="cityEHRFunction:getSequence($value,$occurenceCount)"/>
        </xsl:if>

        <xsl:if test="not(empty($nextCellSet))">
            <xsl:sequence select="cityEHRFunction:GetODFRowData($nextCellSet)"/>
        </xsl:if>

    </xsl:function>

    <!-- ====================================================================
        cityEHRFunction:GetValueDisplayNames
        Get the set of displayNames for the Values on the Element sheet
        Finds displayNames for all the rows
        
        Starting from valuePosition, each row has pairs of displayName,value - this is the valueSet
        Need to return all the displayNames from valueSet, which is all elements at odd-numbered positions.
        But not the blank ones.
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:GetValueDisplayNames">
        <xsl:param name="elementSheetRows"/>
        <xsl:param name="valuePosition"/>

        <xsl:for-each select="$elementSheetRows">
            <xsl:variable name="cellSet" select="table:table-cell"/>
            <xsl:variable name="valueSet" select="cityEHRFunction:GetODFRowData($cellSet)[position() ge $valuePosition]"/>
            <xsl:sequence select="cityEHRFunction:GetDisplayNames($valueSet)[.!='']"/>
        </xsl:for-each>

    </xsl:function>

    <!-- ====================================================================
        cityEHRFunction:GetValues
        Get the set of Values from the set of cells with dsiplayName,value pairs
        Each dsiplayName,value pair must have a displayName, but may not have a value
        
        Starting from valuePosition, each row has pairs of displayName,value - this is the valueSet
        Need to return all the values from valueSet, which is all elements at even-numbered positions.
        If the value is not set, then it defaults to the displaName (even if displayName is blank)
       
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:GetValues">
        <xsl:param name="valueSet"/>

        <!-- Iterate through all displayNames (these are in odd-numbered positions)
             The iteration must be through displayNames, since these always exist -->
        <xsl:for-each select="$valueSet">
            <xsl:variable name="position" select="position()"/>
            <xsl:variable name="displayName" select="normalize-space(.)"/>
            <xsl:if test="cityEHRFunction:isOdd($position)">
                <xsl:variable name="value" select="normalize-space($valueSet[position()= $position +1])"/>
                <xsl:sequence select="if (exists($value) and $value!='') then $value else $displayName"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:function>


    <!-- ====================================================================
        cityEHRFunction:GetDisplayNames
        Get the set of displayNames from the set of values with dsiplayName,value pairs
        
        Starting from valuePosition, each row has pairs of displayName,value - this is the valueSet
        Need to return all the displayNames from valueSet, which is all elements at odd-numbered positions.
        Always returns the displaName (even if it is blank)
        
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:GetDisplayNames">
        <xsl:param name="valueSet"/>

        <!-- Iterate through all displayNames (these are in odd-numbered positions) -->
        <xsl:for-each select="$valueSet">
            <xsl:variable name="position" select="position()"/>
            <xsl:variable name="displayName" select="normalize-space(.)"/>
            <xsl:if test="cityEHRFunction:isOdd($position)">
                <xsl:sequence select="$displayName"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:function>


    <!-- ====================================================================
        cityEHRFunction:isOdd
        Returns true() if the number is odd, false if it is even
        (mod 2 is either 1 or 0, if odd/even, which correspond to true/false)
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:isOdd" as="xs:boolean">
        <xsl:param name="number"/>
        <xsl:value-of select="if ($number castable as xs:integer) then ($number mod 2) else false()"/>
    </xsl:function>

    <!-- ====================================================================
        cityEHRFunction:isEven
        Returns true() if the number is even, false if it is odd
        (mod 2 is either 1 or 0, if odd/even, which correspond to true/false)
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:isEven" as="xs:boolean">
        <xsl:param name="number"/>
        <xsl:value-of select="if ($number castable as xs:integer) then not(($number mod 2)) else false()"/>
    </xsl:function>



    <!-- ====================================================================
         cityEHRFunction:getSequence
         Get sequence of $value, repeated $occurenceCount times.
         This is a tail recursive function.
        -->
    <xsl:function name="cityEHRFunction:getSequence">
        <xsl:param name="value" as="xs:string"/>
        <xsl:param name="occurenceCount"/>

        <xsl:sequence select="$value"/>

        <xsl:variable name="nextOccurenceCount" select="$occurenceCount - 1"/>
        <xsl:if test="$nextOccurenceCount gt 0">
            <xsl:sequence select="cityEHRFunction:getSequence($value,$nextOccurenceCount)"/>
        </xsl:if>

    </xsl:function>

    <!-- === 
        cityEHRFunction:getRepeatIdentifiers
        Check that a set of identifiers is unique  
        Returns the set of non-unique identifiers (so empty sequence if all are unique).
        This is a tail recursive function.
        === -->
    <xsl:function name="cityEHRFunction:getRepeatIdentifiers">
        <xsl:param name="identifierSet"/>

        <xsl:variable name="identifier" select="$identifierSet[1]"/>
        <xsl:variable name="nextIdentifierSet" select="$identifierSet[position() gt 1]"/>

        <!-- Return repeat, if it exists -->
        <xsl:if test="$identifier = $nextIdentifierSet">
            <xsl:sequence select="$identifier"/>
        </xsl:if>

        <!-- Process rest of the identifiers -->
        <xsl:if test="not(empty($nextIdentifierSet))">
            <xsl:sequence select="cityEHRFunction:getRepeatIdentifiers($nextIdentifierSet)"/>
        </xsl:if>

    </xsl:function>


    <!-- === 
        cityEHRFunction:GetComponentTypeIRI
        Get the IRI for a component type (append either ISO-13606: or CityEHR:)
        
        Could just compare componentType with the set of ISO-13606 components (Folder,Composition,Section,Entry,Cluster,Element) 
        === -->
    <xsl:function name="cityEHRFunction:GetComponentTypeIRI">
        <xsl:param name="componentType"/>

        <!-- Component is either ISO-13606 or CityEHR -->
        <xsl:variable name="componentTypeIRI-ISO-13606" select="concat('#ISO-13606:',$componentType)"/>
        <xsl:variable name="componentTypeIRI-CityEHR" select="concat('#CityEHR:',$componentType)"/>

        <!-- Find a declaration for ISO-13606 in the cityEHRarchitecture -->
        <xsl:variable name="ISO-13606Declaration"
            select="$cityEHRarchitecture/owl:Ontology/owl:Declaration/owl:Class[@IRI=$componentTypeIRI-ISO-13606]"/>

        <!-- Return either componentTypeIRI-ISO-13606 or componentTypeIRI-CityEHR -->
        <xsl:variable name="componentTypeIRI"
            select="if (exists($ISO-13606Declaration)) then $componentTypeIRI-ISO-13606 else $componentTypeIRI-CityEHR"/>
        <xsl:value-of select="$componentTypeIRI"/>
    </xsl:function>

    <!-- === 
        cityEHRFunction:GetComponentIRI
        Get the IRI for a component, 
        given a componentId of the form type:id (append either ISO-13606: or CityEHR:)

        === -->
    <xsl:function name="cityEHRFunction:GetComponentIRI">
        <xsl:param name="componentId"/>

        <xsl:variable name="componentType" select="substring-before($componentId,':')"/>
        <xsl:variable name="componentTypeIRI" select="cityEHRFunction:GetComponentTypeIRI($componentType)"/>

        <xsl:value-of select="concat($componentTypeIRI,':',$componentId)"/>

    </xsl:function>

    <!-- === 
        cityEHRFunction:GetComponentIRIList
        Get list of componentIRI for a list of componentId, 
        given componentIds of the form type:id (append either ISO-13606: or CityEHR:)
        The componentIdList may contain blanks ('') so these need to be ignored
        === -->
    <xsl:function name="cityEHRFunction:GetComponentIRIList">
        <xsl:param name="componentIdList"/>

        <xsl:for-each select="$componentIdList[.!='']">
            <xsl:variable name="componentId" select="."/>
            <xsl:variable name="componentType" select="substring-before($componentId,':')"/>
            <xsl:variable name="componentTypeIRI" select="cityEHRFunction:GetComponentTypeIRI($componentType)"/>

            <xsl:sequence select="concat($componentTypeIRI,':',substring-after($componentId,':'))"/>
        </xsl:for-each>
    </xsl:function>

    <!-- === 
        Generate Application Declarations
        Application, Specialty, Class (for a class model)
        === -->
    <xsl:template name="generateApplicationDeclarations" xmlns="http://www.w3.org/2002/07/owl#">
        <!--The application for this ontology
            Corresponds to a top-level ISO-13606:EHR_Extract.
            
            The application must be present on the Configuration sheet.                
            $applicationId and $applicationDisplayName are set in the XSL that calls this module.
            
            Assert the individual
            Set its class to ISO-13606:EHR_Extract
            Set its displayName
            
        -->
        <Declaration>
            <NamedIndividual IRI="{$applicationIRI}"/>
        </Declaration>
        
        <ClassAssertion>
            <Class IRI="#ISO-13606:EHR_Extract"/>
            <NamedIndividual IRI="{$applicationIRI}"/>
        </ClassAssertion>
        
        <!-- The Language for this ontology -->
        <DataPropertyAssertion>
            <DataProperty IRI="#hasBaseLanguage"/>
            <NamedIndividual IRI="{$applicationIRI}"/>
            <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="&amp;rdf;PlainLiteral">
                <xsl:value-of select="$baseLanguageCode"/>
            </Literal>
        </DataPropertyAssertion>
        
        <!-- The specialty for this ontology
            Corresponds to a top-level ISO-13606:Folder
            
            The specialty must be present on the Configuration sheet.                
            $specialtyId and $specialtyDisplayName are set in the XSL that calls this module.
            
            Assert the individual
            Set its class to ISO-13606:EHR_Folder
            Set the Folder as content of the EHR_Extract
            Set its displayName
        -->
        <Declaration>
            <Class IRI="{$specialtyIRI}"/>
        </Declaration>
        
        <SubClassOf>
            <Class IRI="{$specialtyIRI}"/>
            <Class IRI="#ISO-13606:Folder"/>
        </SubClassOf>
        
        <Declaration>
            <NamedIndividual IRI="{$specialtyIRI}"/>
        </Declaration>
        
        <ClassAssertion>
            <Class IRI="#ISO-13606:Folder"/>
            <NamedIndividual IRI="{$specialtyIRI}"/>
        </ClassAssertion>
        
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasContent"/>
            <NamedIndividual IRI="{$applicationIRI}"/>
            <NamedIndividual IRI="{$specialtyIRI}"/>
        </ObjectPropertyAssertion>
        
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasDisplayName"/>
            <NamedIndividual IRI="{$specialtyIRI}"/>
            <NamedIndividual IRI="{$specialtyTermIRI}"/>
        </ObjectPropertyAssertion>
        
        <!-- No need to declare the term, as it is picked up in the general declarations later on -->
        
    </xsl:template>
    

    <!-- === 
        Generate Property Set
        $propertyIRI is defined as a global variable
        === -->
    <xsl:template name="generatePropertySet" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="propertyType"/>
        <xsl:param name="propertyValues"/>

        <xsl:variable name="propertyTypeIRI" select="concat($propertyIRI,':',$propertyType)"/>

        <!-- Declaration of subclass for propertyType -->
        <Declaration>
            <Class IRI="{$propertyTypeIRI}"/>
        </Declaration>
        <SubClassOf>
            <Class IRI="{$propertyTypeIRI}"/>
            <Class IRI="{$propertyIRI}"/>
        </SubClassOf>

        <!-- Declaration and assertion for each property value -->
        <xsl:for-each select="$propertyValues">
            <xsl:variable name="propertyValue" select="normalize-space(.)"/>
            <xsl:variable name="propertyValueIRI" select="concat($propertyTypeIRI,':',$propertyValue)"/>

            <Declaration>
                <NamedIndividual IRI="{$propertyValueIRI}"/>
            </Declaration>
            <ClassAssertion>
                <Class IRI="{$propertyTypeIRI}"/>
                <NamedIndividual IRI="{$propertyValueIRI}"/>
            </ClassAssertion>
        </xsl:for-each>
    </xsl:template>


    <!-- === 
         generateComponentAssertions
         Generate assertions for a component of specified componentTypeIRI
         The propertySet and propertyValues are matching sets of property/value normalized-space strings
         Uses global variables $rootNode and $propertyIRI
         
         Iterate through propertySet - assertions then depend on the property
         
         'Identifier'       is the unique Id for the component
         'DisplayName'      is a displayName for which a term has already been asserted - just needs an objectProperty assertion 
         '-'                is a spacer that is ignored
         'Content'          the remaining values in propertyValues are references to the content of the component
         'Values'           the remaining values in propertyValues are displayName/value pairs (the component is an element)        
          Anything else     is an object property assertion or data property assertion for the corresponding value
          
          For these other properties:
            Get the type of property from the $cityEHRarchitecture
            If a dataProperty assertion, then just use the value
            If an objectProperty assertion, then the value is either
                A property as defined in the propertySet key
                Or a reference to an ISO-13606 or cityEHR component 
         
        === -->
    <xsl:template name="generateComponentAssertions" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="componentTypeIRI"/>
        <xsl:param name="propertySet"/>
        <xsl:param name="propertyValues"/>

        <!-- The first property must be the identifier -->
        <xsl:if test="$propertySet[1]='Identifier' and $propertyValues[1] !=''">
            <!-- Set the componentId and componentIRI-->
            <xsl:variable name="componentId" select="$propertyValues[1]"/>
            <xsl:variable name="componentIRI" select="cityEHRFunction:getIRI($componentTypeIRI,$componentId)"/>

            <!-- Iterate through the properties -->
            <xsl:for-each select="$propertySet">
                <xsl:variable name="propertyTypeId" select="."/>
                <xsl:variable name="propertyPosition" select="position()"/>
                <xsl:variable name="propertyValueRecorded" select="$propertyValues[position()=$propertyPosition]"/>

                <!-- There may be no cell in the spreadsheet recorded for the propertyType.
                     This can happen at the end of the row -->
                <xsl:variable name="propertyValue" select="if (exists($propertyValueRecorded)) then $propertyValueRecorded else ''"/>

                <!-- Assertions depend on the type of property -->
                <xsl:choose>
                    <!-- Identifier - the unique Id for the component -->
                    <xsl:when test="$propertyTypeId='Identifier'">
                        <Declaration>
                            <NamedIndividual IRI="{$componentIRI}"/>
                        </Declaration>
                        <ClassAssertion>
                            <Class IRI="{$componentTypeIRI}"/>
                            <NamedIndividual IRI="{$componentIRI}"/>
                        </ClassAssertion>
                    </xsl:when>

                    <!-- DisplayName for which a term has already been asserted -->
                    <xsl:when test="$propertyTypeId='DisplayName'">
                        <!-- Only if there is a displayName -->
                        <xsl:if test="$propertyValue!=''">
                            <xsl:variable name="termIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:',$propertyValue)"/>

                            <ObjectPropertyAssertion>
                                <ObjectProperty IRI="#hasDisplayName"/>
                                <NamedIndividual IRI="{$componentIRI}"/>
                                <NamedIndividual IRI="{$termIRI}"/>
                            </ObjectPropertyAssertion>
                        </xsl:if>
                    </xsl:when>

                    <!-- spacer that is ignored -->
                    <xsl:when test="$propertyTypeId='-'"/>

                    <!-- references to the content of the component -->
                    <xsl:when test="$propertyTypeId='Content'">
                        <!-- The contents list is all the remaining property values in the set -->
                        <xsl:variable name="contentsList" select="$propertyValues[position() ge $propertyPosition]"/>
                        <xsl:call-template name="generateComponentContents">
                            <xsl:with-param name="componentIRI" select="$componentIRI"/>
                            <xsl:with-param name="contentsList" select="$contentsList"/>
                        </xsl:call-template>
                    </xsl:when>

                    <!-- displayName/value pairs (the component is an element) -->
                    <xsl:when test="$propertyTypeId='Values'">
                        <!-- The values list (pairs of displayName/value) is all the remaining property values in the set -->
                        <xsl:variable name="valuesList" select="$propertyValues[position() ge $propertyPosition]"/>

                        <!-- Get the list of element values and displayNames -->
                        <xsl:variable name="elementValues" select="cityEHRFunction:GetValues($valuesList)"/>
                        <xsl:variable name="elementDisplayNames" select="cityEHRFunction:GetDisplayNames($valuesList)"/>

                        <!-- Generate assertions for the values, but only if they are distinct -->
                        <xsl:if test="count($elementValues) = count(distinct-values($elementValues))">
                            <xsl:for-each select="$elementValues">
                                <xsl:variable name="elementValue" select="."/>
                                <xsl:variable name="position" select="position()"/>

                                <!-- Only need assertions for values that are not blank -->
                                <xsl:if test="$elementValue != ''">
                                    <xsl:variable name="elementValueIRI"
                                        select="cityEHRFunction:getIRI('#ISO-13606:Data',concat($componentId,$elementValue))"/>
                                    <xsl:variable name="elementValueDisplayName" select="$elementDisplayNames[position()=$position]"/>

                                    <xsl:call-template name="generateValueAssertions">
                                        <xsl:with-param name="elementIRI" select="$componentIRI"/>
                                        <xsl:with-param name="elementValueIRI" select="$elementValueIRI"/>
                                        <xsl:with-param name="elementValue" select="$elementValue"/>
                                        <xsl:with-param name="elementValueDisplayName" select="$elementValueDisplayName"/>
                                    </xsl:call-template>
                                </xsl:if>
                            </xsl:for-each>
                        </xsl:if>
                    </xsl:when>

                    <!-- Anything else is an object property assertion or data property assertion -->
                    <xsl:otherwise>
                        <!-- The OWL/XML property -->
                        <xsl:variable name="owlPropertyIRI" select="concat('#has',$propertyTypeId)"/>

                        <!-- Get the type of the property in the cityEHRarchitecture -->
                        <xsl:variable name="propertyDeclarationType"
                            select="$cityEHRarchitecture/owl:Ontology/owl:Declaration/(owl:ObjectProperty|owl:DataProperty)[@IRI=$owlPropertyIRI]/name()"/>

                        <!-- Data property - just make the assertion, unless the value is blank -->
                        <xsl:if test="$propertyDeclarationType='DataProperty' and $propertyValue !=''">
                            <DataPropertyAssertion>
                                <DataProperty IRI="{$owlPropertyIRI}"/>
                                <NamedIndividual IRI="{$componentIRI}"/>
                                <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="&amp;rdf;PlainLiteral">
                                    <xsl:value-of select="$propertyValue"/>
                                </Literal>
                            </DataPropertyAssertion>
                        </xsl:if>

                        <!-- Object property - is either a property or reference to a component -->
                        <xsl:if test="$propertyDeclarationType='ObjectProperty'">
                            <xsl:variable name="propertySetCells" select="key('propertySetCells',$propertyTypeId,$rootNode)"/>

                            <!-- A cityEHR property will have a key with the set of value options -->
                            <xsl:if test="exists($propertySetCells)">
                                <!-- Get the property values - the value for this component should be one of them.
                                     If not, assert an error -->
                                <xsl:variable name="propertyValueSet"
                                    select="cityEHRFunction:GetODFRowData($propertySetCells)[. !=''][position() gt 1]"/>

                                <!-- Property is valid or is not set (blank) -->
                                <xsl:if test="$propertyValue = $propertyValueSet or $propertyValue = ''">
                                    <!-- If property value is not set, then use default (first value in propertyValueSet) -->
                                    <xsl:variable name="assertedPropertyValue"
                                    select="if ($propertyValue='') then $propertyValueSet[1] else $propertyValue"/>
                                    <xsl:variable name="propertyTypeIRI" select="concat($propertyIRI,':',$propertyTypeId)"/>
                                    <xsl:variable name="propertyIRI" select="concat($propertyTypeIRI,':',$assertedPropertyValue)"/>
                                    <ObjectPropertyAssertion>
                                        <ObjectProperty IRI="{$owlPropertyIRI}"/>
                                        <NamedIndividual IRI="{$componentIRI}"/>
                                        <NamedIndividual IRI="{$propertyIRI}"/>
                                    </ObjectPropertyAssertion>
                                </xsl:if>

                                <!-- Property not valid -->
                                <xsl:if test="not($propertyValue = $propertyValueSet or $propertyValue = '')">
                                    <xsl:call-template name="generateError">
                                        <xsl:with-param name="node" select="$rootNode"/>
                                        <xsl:with-param name="context" select="concat($componentIRI,' / ',$owlPropertyIRI)"/>
                                        <xsl:with-param name="message" select="'Property value (defined cityEHR property) not valid'"/>
                                    </xsl:call-template>
                                </xsl:if>

                            </xsl:if>

                            <!-- Other object properties must be references to model components.
                                 Don't assert anything if the property is blank
                                 Need then to get the type of the component - either ISO-13606 or CityEHR.
                                 The propertyValue is of the form ComponentType:ComponentId (if not, assert an error) -->
                            <xsl:if test="not(exists($propertySetCells))">
                                <!-- Only if there is a value -->
                                <xsl:if test="$propertyValue!=''">
                                    <xsl:variable name="referencedComponentType" select="tokenize($propertyValue,':')[1]"/>
                                    <xsl:variable name="referencedComponentId" select="tokenize($propertyValue,':')[2]"/>

                                    <!-- Referenced component value must be valid -->
                                    <xsl:if test="$referencedComponentType!='' and $referencedComponentId!=''">
                                        <!-- Set the IRI for the referenced component -->
                                        <xsl:variable name="referencedComponentTypeIRI"
                                            select="cityEHRFunction:GetComponentTypeIRI($referencedComponentType)"/>
                                        <!-- Form the referenced component IRI -->
                                        <xsl:variable name="referencedComponentIRI"
                                            select="concat($referencedComponentTypeIRI,':',$referencedComponentId)"/>

                                        <ObjectPropertyAssertion>
                                            <ObjectProperty IRI="{$owlPropertyIRI}"/>
                                            <NamedIndividual IRI="{$componentIRI}"/>
                                            <NamedIndividual IRI="{$referencedComponentIRI}"/>
                                        </ObjectPropertyAssertion>
                                    </xsl:if>

                                    <!-- Error if referenced component value not valid. -->
                                    <xsl:if test="$referencedComponentType ='' or $referencedComponentId =''">
                                        <xsl:call-template name="generateError">
                                            <xsl:with-param name="node" select="$propertyValue"/>
                                            <xsl:with-param name="context" select="$owlPropertyIRI"/>
                                            <xsl:with-param name="message" select="'Property value (component reference) not valid'"/>
                                        </xsl:call-template>
                                    </xsl:if>
                                </xsl:if>
                            </xsl:if>
                        </xsl:if>


                    </xsl:otherwise>
                </xsl:choose>

            </xsl:for-each>


        </xsl:if>

    </xsl:template>

    <!-- === 
        generateComponentContents
        Generate assertions for the contentsList for a component of specified componentIRI
        The components in the contentsList are strings of the form type:id
        They need to be prefixed by #cityEHR: or #ISO-13606: to create their componentIRI
        === -->
    <xsl:template name="generateComponentContents" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="componentIRI"/>
        <xsl:param name="contentsList"/>

        <xsl:variable name="contentsIRIList" select="cityEHRFunction:GetComponentIRIList($contentsList)"/>
        <!-- #hasContentsList assertion is a literal with the componentIRIs for each component in the contentsList, separated by spaces -->
        <DataPropertyAssertion>
            <DataProperty IRI="#hasContentsList"/>
            <NamedIndividual IRI="{$componentIRI}"/>
            <Literal xml:lang="en-gb" datatypeIRI="&amp;rdf;PlainLiteral">
                <xsl:value-of select="string-join($contentsIRIList,' ')"/>
            </Literal>
        </DataPropertyAssertion>

        <!-- #hasContent assertion is made of each component in the contentsList -->
        <xsl:for-each select="$contentsIRIList">
            <xsl:variable name="contentsComponentIRI" select="."/>

            <ObjectPropertyAssertion>
                <ObjectProperty IRI="#hasContent"/>
                <NamedIndividual IRI="{$componentIRI}"/>
                <NamedIndividual IRI="{$contentsComponentIRI}"/>
            </ObjectPropertyAssertion>

        </xsl:for-each>
    </xsl:template>


    <!-- === 
        generateValueAssertions
        Generate assertions for the value of an element of specified elementIRI
        The parameters for the assertions are elementValueIRI, elementValue and elementValueDisplayName
        === -->
    <xsl:template name="generateValueAssertions" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="elementIRI"/>
        <xsl:param name="elementValueIRI"/>
        <xsl:param name="elementValue"/>
        <xsl:param name="elementValueDisplayName"/>

        <Declaration>
            <NamedIndividual IRI="{$elementValueIRI}"/>
        </Declaration>

        <ClassAssertion>
            <Class IRI="#ISO-13606:Data"/>
            <NamedIndividual IRI="{$elementValueIRI}"/>
        </ClassAssertion>

        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasValue"/>
            <NamedIndividual IRI="{$elementIRI}"/>
            <NamedIndividual IRI="{$elementValueIRI}"/>
        </ObjectPropertyAssertion>

        <DataPropertyAssertion>
            <DataProperty IRI="#hasValue"/>
            <NamedIndividual IRI="{$elementValueIRI}"/>
            <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="&amp;rdf;PlainLiteral">
                <xsl:value-of select="$elementValue"/>
            </Literal>
        </DataPropertyAssertion>

        <!-- Declare the displayName, if there is one.
            No need to declare the term, as it is picked up in the general declarations above-->
        <xsl:if test="$elementValueDisplayName!=''">
            <xsl:variable name="termIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:',$elementValueDisplayName)"/>
            <ObjectPropertyAssertion>
                <ObjectProperty IRI="#hasDisplayName"/>
                <NamedIndividual IRI="{$elementValueIRI}"/>
                <NamedIndividual IRI="{$termIRI}"/>
            </ObjectPropertyAssertion>
        </xsl:if>
    </xsl:template>


</xsl:stylesheet>
