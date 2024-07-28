<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    Spreadsheet2CDA-Module.xsl
    Input is a spreadsheet (MS Office 2003 XML format) with data for a cohort of patients
    Generates an HL7 CDA document as per the City EHR architecture.
    
    The template for the CDA document is found from the worksheet name in the spreadsheet.
    
    There is also a look up of the patientId vs recordId which may be different
    
    This module is designed to be called from Spreadsheet2CDA.xsl or Spreadsheet2CDAFile.xsl.
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:cda="urn:hl7-org:v3" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:c="urn:schemas-microsoft-com:office:component:spreadsheet" xmlns:html="http://www.w3.org/TR/REC-html40" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:office2003Spreadsheet="urn:schemas-microsoft-com:office:spreadsheet" xmlns:x2="http://schemas.microsoft.com/office/excel/2003/xml" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns:cityEHR="http://openhealthinformatics.org/ehr" xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions" >
    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- Set the root node -->
    <xsl:variable name="rootNode" select="/"/>
    
    <!-- Set the start row for processing the spreadsheet.
         Originally the startRow was 2, when each sheet just had a header for each column
         Later an additional row was added to the top of each sheet with notes about how each column should be filled out.
         This shifted the startRow to row 3
         
         The startRow for the spreadsheet being processed is determined by the row of the Applicatiom property on the Configuration sheet -->
    <xsl:variable name="startRow" as="xs:integer" select="1"/>   

    <!-- Key for Contents
        
        <ss:Worksheet ss:Name="Contents">
            <Table ss:StyleID="ta2">
                <Row ss:Height="12.8409">
                    <Cell>
                        <Data ss:Type="String">Type:Act</Data>
                    
        contentsList returns data element of ISO-13606 component for matched id.
        Used to check that contents list refer to defined ISO-13606 components
    -->
    <xsl:key name="contentsList" match="/office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Contents']/office2003Spreadsheet:Table/office2003Spreadsheet:Row/office2003Spreadsheet:Cell[office2003Spreadsheet:Data!='']" use="office2003Spreadsheet:Data"/>


    <!-- Create key on the ID of sectionList.
        There are two sheets that contain sections - 'Sections' and 'Sections (Tasks)' -->
    <xsl:key name="sectionListKey" match="/office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Sections' or @ss:Name='Sections (Tasks)']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[position()>$startRow][exists(office2003Spreadsheet:Cell)][empty(office2003Spreadsheet:Cell[1]/@ss:Index)][office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data!='']" use="cityEHRFunction:CreateID(office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data)"/>


    <!-- Create key on the ID of entryList.
         There are two sheets that contain entries - 'Entries' and 'Entries (Actions)' -->
    <xsl:key name="entryListKey" match="/office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Entries' or @ss:Name='Entries (Actions)']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[position()>$startRow][exists(office2003Spreadsheet:Cell)][empty(office2003Spreadsheet:Cell[1]/@ss:Index)]" use="cityEHRFunction:CreateID(office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data)"/>

    <!-- Create key on the ID of clusterList.
        Elements are on the sheet named 'Clusters' -->
    <xsl:key name="clusterListKey" match="/office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Clusters']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[position()>$startRow][exists(office2003Spreadsheet:Cell)][empty(office2003Spreadsheet:Cell[1]/@ss:Index)]" use="cityEHRFunction:CreateID(office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data)"/>

    <!-- Create key on the ID of elementList.
         Elements are on the sheet named 'Elements' -->
    <xsl:key name="elementListKey" match="/office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Elements']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[position()>$startRow][exists(office2003Spreadsheet:Cell)][empty(office2003Spreadsheet:Cell[1]/@ss:Index)]" use="cityEHRFunction:CreateID(office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data)"/>


    <!-- === 
        Generate an error as output      
        === -->
    <xsl:template name="generateCDAError">
        
        
    </xsl:template>
    
    <!-- === 
        Generate HL7 CDA document set from the spreadsheet       
        === -->
    <xsl:template name="generateCityEHRCDA">
        
        
    </xsl:template>
    








    <!-- === 
         Generate OWL/XML with the full cityEHR ontology for this information model       
         === -->
    <xsl:template name="generateCityEHROWL">

        <!-- === Output the DOCTYPE and document type declaration subset with entity definitions.
        Plus the root document node for the Ontology -->

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

        <Ontology xmlns="http://www.w3.org/2002/07/owl#" xml:base="http://www.elevenllp.com/owl/2011/2/16/Ontology1300280377354.owl" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:xsd="http://www.w3.org/2001/XMLSchema#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:xml="http://www.w3.org/XML/1998/namespace" ontologyIRI="http://www.elevenllp.com/owl/2011/2/16/Ontology1300280377354.owl">

            <!-- === The City EHR ontology architecture - static XML === 
                 Copy the assertions from cityEHRarchitecture.xml
                 This includes the necessary prefix declarations and some standard annotations
                 plus all assertions for the cityEHR architecture
                 ============================================================== -->

            <xsl:copy-of select="$cityEHRarchitecture/owl:Ontology/*"/>

            <!-- === Annotations for the Information Model being processed.
                ============================================================== -->

            <Annotation>
                <AnnotationProperty abbreviatedIRI="rdfs:applicationId"/>
                <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                    <xsl:value-of select="$applicationId"/>
                </Literal>
            </Annotation>
            <Annotation>
                <AnnotationProperty abbreviatedIRI="rdfs:specialtyId"/>
                <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                    <xsl:value-of select="$specialtyId"/>
                </Literal>
            </Annotation>
            <Annotation>
                <AnnotationProperty abbreviatedIRI="rdfs:copyright"/>
                <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">Copyright (c) <xsl:value-of select="year-from-date(current-date())"/>
                    <xsl:value-of select="$applicationOwner"/>
                </Literal>
            </Annotation>
            <!-- The pathSeparator is used in expressions - usually / but was hisyorically : -->
            <Annotation>
                <AnnotationProperty abbreviatedIRI="rdfs:pathSeparator"/>
                <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                    <xsl:value-of select="$pathSeparator"/>
                </Literal>
            </Annotation>           
            

            <!-- === Process the Configuration sheet ============== 
                ===================================================== -->

            <!-- === The application for this ontology === 
                Corresponds to a top-level ISO-13606:EHR_Extract.
                
                The application must be present on the Configuration sheet.                
                $applicationId and $applicationDisplayName are set in the XSL that calls this module.
                
                Assert the individual
                Set its class to ISO-13606:EHR_Extract
                Set its displayName
                
            -->

            <xsl:variable name="applicationIRI" select="cityEHRFunction:getIRI('#ISO-13606:EHR_Extract:',$applicationId)"/>
            <xsl:variable name="applicationTermIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:',$applicationDisplayName)"/>

            <Declaration>
                <NamedIndividual IRI="{$applicationIRI}"/>
            </Declaration>

            <ClassAssertion>
                <Class IRI="#ISO-13606:EHR_Extract"/>
                <NamedIndividual IRI="{$applicationIRI}"/>
            </ClassAssertion>

            <ObjectPropertyAssertion>
                <ObjectProperty IRI="#hasDisplayName"/>
                <NamedIndividual IRI="{$applicationIRI}"/>
                <NamedIndividual IRI="{$applicationTermIRI}"/>
            </ObjectPropertyAssertion>

            <!-- No need to declare the term, as it is picked up in the general declarations later on -->


            <!-- === The specialty for this ontology === 
                 Corresponds to a top-level ISO-13606:Folder
                 
                 The specialty must be present on the Configuration sheet.                
                 $specialtyId and $specialtyDisplayName are set in the XSL that calls this module.
                 
                 Assert the individual
                 Set its class to ISO-13606:EHR_Folder
                 Set the Folder as content of the EHR_Extract
                 Set its displayName
                 -->

            <xsl:variable name="specialtyIRI" select="cityEHRFunction:getIRI('#ISO-13606:Folder:',$specialtyId)"/>
            <xsl:variable name="specialtyTermIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:',$specialtyDisplayName)"/>

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


            <!-- === The data types for this ontology === -->
            <xsl:for-each select="office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Configuration']/office2003Spreadsheet:Table/office2003Spreadsheet:Row/office2003Spreadsheet:Cell[1][office2003Spreadsheet:Data='DataType']/../office2003Spreadsheet:Cell[position()>1]">
                <!-- Only process cells that contain some data -->
                <xsl:if test="exists(office2003Spreadsheet:Data)">
                    <xsl:variable name="dataType" select="office2003Spreadsheet:Data"/>
                    <xsl:variable name="dataTypeIRI" select="cityEHRFunction:getIRI('#CityEHR:DataType:',$dataType)"/>

                    <Declaration>
                        <NamedIndividual IRI="{$dataTypeIRI}"/>
                    </Declaration>

                    <ClassAssertion>
                        <Class IRI="#CityEHR:DataType"/>
                        <NamedIndividual IRI="{$dataTypeIRI}"/>
                    </ClassAssertion>

                </xsl:if>
            </xsl:for-each>

            <!-- === The entry properties for this ontology
                     These are cityEHR specific properties applied to the ISO-13606 Entry individuals
                     Picked up from rows on the Configuration sheet
                     Can be CRUD, Occurrence, InitialValue, Layout or Rendition 
                 === -->
            <xsl:for-each select="office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Configuration']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data=('CRUD','Occurrence','InitialValue','Layout','Rendition','CohortSearch','Scope')]/office2003Spreadsheet:Cell[position()>1]">
                <!-- Only process cells that contain some data -->
                <xsl:if test="exists(office2003Spreadsheet:Data)">
                    <xsl:variable name="entryProperty" select="office2003Spreadsheet:Data"/>
                    <xsl:variable name="entryPropertyIRI" select="cityEHRFunction:getIRI('#CityEHR:EntryProperty:',$entryProperty)"/>

                    <Declaration>
                        <NamedIndividual IRI="{$entryPropertyIRI}"/>
                    </Declaration>

                    <ClassAssertion>
                        <Class IRI="#CityEHR:EntryProperty"/>
                        <NamedIndividual IRI="{$entryPropertyIRI}"/>
                    </ClassAssertion>
                </xsl:if>
            </xsl:for-each>

            <!-- Entry property for InitialValue of 'Built-in' (is not in the list on Configuration sheet) -->
            <Declaration>
                <NamedIndividual IRI="#CityEHR:EntryProperty:Built-in"/>
            </Declaration>

            <ClassAssertion>
                <Class IRI="#CityEHR:EntryProperty"/>
                <NamedIndividual IRI="#CityEHR:EntryProperty:Built-in"/>
            </ClassAssertion>


            <!-- === The element properties for this ontology
                These are cityEHR specific properties applied to the ISO-13606 Element individuals
                Can be ValueRequired, ElementType 
                === -->
            <xsl:for-each select="office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Configuration']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data=('ValueRequired','ElementType','Scope')]/office2003Spreadsheet:Cell[position()>1]">
                <!-- Only process cells that contain some data -->
                <xsl:if test="exists(office2003Spreadsheet:Data)">
                    <xsl:variable name="elementProperty" select="office2003Spreadsheet:Data"/>
                    <xsl:variable name="elementPropertyIRI" select="cityEHRFunction:getIRI('#CityEHR:ElementProperty:',$elementProperty)"/>

                    <Declaration>
                        <NamedIndividual IRI="{$elementPropertyIRI}"/>
                    </Declaration>

                    <ClassAssertion>
                        <Class IRI="#CityEHR:ElementProperty"/>
                        <NamedIndividual IRI="{$elementPropertyIRI}"/>
                    </ClassAssertion>

                </xsl:if>
            </xsl:for-each>


            <!-- === Declare all terms used in the ontology === 
                ============================================== -->
            <!-- Named individuals for each term 
                Only want one unique individual for each term, so need to test that there aren't duplicates.
                $allTerms will contain all term nodes, including any duplicates
                As we step through each term, output the declaration of a Named Individual only if there are no duplicates 
                for that term left in the sequence.
                
                The terms are formed from the displayNames which are all in the 2nd column of sheets with a DisplayName column defined.                   
                Only other terms are the specialty names and enumerated values (including for classes) for elements.
            -->

            <!-- Application and specialty have display names -->
            <xsl:variable name="specialtyTerms" select="$applicationDisplayName | $specialtyDisplayName"/>

            <!-- The displayName is in cell position 2, only for rows where there is an Id in the first cell -->
            <xsl:variable name="displayNameTerms" select="office2003Spreadsheet:Workbook/ss:Worksheet/office2003Spreadsheet:Table[office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[2]/office2003Spreadsheet:Data='DisplayName']/office2003Spreadsheet:Row[position()>$startRow][office2003Spreadsheet:Cell[1][not(@ss:Index)]]/office2003Spreadsheet:Cell[2][not(@ss:Index)]/office2003Spreadsheet:Data"/>

            <!-- List of element values starts after the second [-] cell in the Elements sheet for elements of type enumeratedValue, url or range only.
                 Also now add calculatedValue since these may contain a list of allowed values that can be calculated
                 We have to use the second [-] to find the values, rather than the cell position of the Values column because this would need to be calculated for each row separately -->
            <xsl:variable name="elementTypes" select="('enumeratedValue','enumeratedClass','calculatedValue','url','range')"/>
            <xsl:variable name="elementValueTerms" select="office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Elements']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[position()>$startRow]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data=$elementTypes]/following-sibling::office2003Spreadsheet:Cell[office2003Spreadsheet:Data='-']/following-sibling::office2003Spreadsheet:Cell/office2003Spreadsheet:Data[normalize-space(.) != '']"/>

            <xsl:variable name="allTerms" select="$displayNameTerms/normalize-space(.) , $specialtyTerms/normalize-space(.)  , $elementValueTerms/normalize-space(.)"/>

            <xsl:for-each select="distinct-values($allTerms)">
                <xsl:variable name="term" as="xs:string" select="normalize-space(.)"/>
                <xsl:variable name="termIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:',$term)"/>
                <Declaration>
                    <NamedIndividual IRI="{$termIRI}"/>
                </Declaration>
                <ClassAssertion>
                    <Class IRI="#CityEHR:Term"/>
                    <NamedIndividual IRI="{$termIRI}"/>
                </ClassAssertion>
                <DataPropertyAssertion>
                    <DataProperty IRI="#hasValue"/>
                    <NamedIndividual IRI="{$termIRI}"/>
                    <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                        <xsl:value-of select="$term"/>
                    </Literal>
                </DataPropertyAssertion>
            </xsl:for-each>


            <!-- === The Folders for this ontology === 
                
                For each Folder we need to:
                
                Declare an individual
                Assert the individual as a member of the ISO-13606:Folder class
                Assert the individual as content of the specialty folder using the hasContent object property
                Set the display name for the folder using the hasDisplayName object property
                Set the contents for the folder using the hasContent object property
                
                In the spreadhseet, each row represents a folder, with the following cells:
                
                [1] The folderId
                [2] Display Name for the folder
                [-]
                [4] The rank for the folder (used to order them in selection lists
                [5] The contents for the folder (which is a set of forms and views)
                
                ==================================== -->

            <xsl:variable name="folderList" select="office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Folders']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[position()>$startRow]"/>
            <xsl:for-each select="$folderList">
                <!-- FolderId is in the first column - must not have a ss:Index attribute -->
                <xsl:variable name="folder" select="."/>
                <xsl:variable name="folderNumber" select="position()"/>
                <xsl:variable name="folderId" select="if ($folder/office2003Spreadsheet:Cell[1]/@ss:Index) then '' else cityEHRFunction:CreateID($folder/office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data)"/>


                <!-- Only process rows that have a folderId which is unique. -->

                <!-- If folderId is not unique then generate an error -->
                <xsl:if test="$folderId != '' and exists($folderList[position() > $folderNumber][cityEHRFunction:CreateID(office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data) = $folderId])">
                    <xsl:variable name="context" select="concat('Position: ',$folderNumber,' Folder: ',$folderId)"/>
                    <xsl:variable name="message" select="'Folder id is not unique'"/>
                    <xsl:call-template name="generateError">
                        <xsl:with-param name="node" select="$folder"/>
                        <xsl:with-param name="context" select="$context"/>
                        <xsl:with-param name="message" select="$message"/>
                    </xsl:call-template>
                </xsl:if>

                <!-- If folderId is unique then process it -->
                <xsl:if test="$folderId != '' and empty($folderList[position() > $folderNumber][normalize-space(office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data) = $folderId])">
                    <xsl:variable name="folderIRI" select="cityEHRFunction:getIRI('#ISO-13606:Folder:',$folderId)"/>
                    <xsl:variable name="folderDisplayName" select="$folder/office2003Spreadsheet:Cell[2]/office2003Spreadsheet:Data"/>
                    <xsl:variable name="termIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:',$folderDisplayName)"/>

                    <Declaration>
                        <NamedIndividual IRI="{$folderIRI}"/>
                    </Declaration>

                    <ClassAssertion>
                        <Class IRI="#ISO-13606:Folder"/>
                        <NamedIndividual IRI="{$folderIRI}"/>
                    </ClassAssertion>

                    <ObjectPropertyAssertion>
                        <ObjectProperty IRI="#hasContent"/>
                        <NamedIndividual IRI="{$specialtyIRI}"/>
                        <NamedIndividual IRI="{$folderIRI}"/>
                    </ObjectPropertyAssertion>

                    <ObjectPropertyAssertion>
                        <ObjectProperty IRI="#hasDisplayName"/>
                        <NamedIndividual IRI="{$folderIRI}"/>
                        <NamedIndividual IRI="{$termIRI}"/>
                    </ObjectPropertyAssertion>

                    <!-- The rank property is set in the cell position with first row title 'Rank' -->
                    <xsl:variable name="activeCellPositionRank" as="xs:integer" select="count(/office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Folders']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Rank']/preceding-sibling::*) +1"/>

                    <xsl:variable name="rankSet">
                        <xsl:call-template name="getCellValue">
                            <xsl:with-param name="row" select="$folder"/>
                            <xsl:with-param name="cellPosition" select="$activeCellPositionRank"/>
                        </xsl:call-template>
                    </xsl:variable>

                    <!-- rank takes default value of '1' if it has not been set in the spreadsheet -->
                    <xsl:variable name="rank" select="if ($rankSet='') then '1' else $rankSet"/>
                    <xsl:if test="$rankSet=''">
                        <xsl:variable name="context" select="concat('Folder: ',$folderId)"/>
                        <xsl:variable name="message" select="'Rank not defined - set default of 1'"/>
                        <xsl:call-template name="generateWarning">
                            <xsl:with-param name="node" select="$folder"/>
                            <xsl:with-param name="context" select="$context"/>
                            <xsl:with-param name="message" select="$message"/>
                        </xsl:call-template>
                    </xsl:if>

                    <DataPropertyAssertion>
                        <DataProperty IRI="#hasRank"/>
                        <NamedIndividual IRI="{$folderIRI}"/>
                        <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                            <xsl:value-of select="$rank"/>
                        </Literal>
                    </DataPropertyAssertion>

                    <!-- The list of Contents for the folder (views and forms)  starts at cell position with first row title 'Contents' (activeCellPosition) -->
                    <xsl:variable name="activeCellPositionContents" as="xs:integer" select="count(/office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Folders']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Contents']/preceding-sibling::*) +1"/>

                    <!-- Get actual position of the cell where contents list starts -->
                    <xsl:variable name="contentsListPosition">
                        <xsl:call-template name="getCellPosition">
                            <xsl:with-param name="row" select="."/>
                            <xsl:with-param name="cellPosition" select="$activeCellPositionContents"/>
                        </xsl:call-template>
                    </xsl:variable>

                    <!-- Iterate through the contents list -->
                    <xsl:for-each select="./office2003Spreadsheet:Cell[position()>=$contentsListPosition]/office2003Spreadsheet:Data[normalize-space(.) != '']">
                        <xsl:variable name="contentId" select="."/>
                        <xsl:variable name="contentIRI" select="concat('#CityEHR:',$contentId)"/>

                        <xsl:if test="exists(key('contentsList',$contentId))">
                            <ObjectPropertyAssertion>
                                <ObjectProperty IRI="#hasContent"/>
                                <NamedIndividual IRI="{$folderIRI}"/>
                                <NamedIndividual IRI="{$contentIRI}"/>
                            </ObjectPropertyAssertion>
                        </xsl:if>


                        <xsl:if test="empty(key('contentsList',$contentId))">
                            <xsl:variable name="context" select="concat('Folder content: ',$folderId)"/>
                            <xsl:variable name="message" select="concat('Content node: ',$contentId,' not defined')"/>
                            <xsl:call-template name="generateWarning">
                                <xsl:with-param name="node" select="$contentId"/>
                                <xsl:with-param name="context" select="$context"/>
                                <xsl:with-param name="message" select="$message"/>
                            </xsl:call-template>
                        </xsl:if>

                    </xsl:for-each>

                </xsl:if>
            </xsl:for-each>


            <!-- === The Views for this ontology === 
                
                For each View we need to:
                
                Declare an individual
                Assert the individual as a member of the CityEHR:View class
                Set the display name for the view using the hasDisplayName object property
                Set the contents for the view using the hasContent object property
                
                In the spreadhseet, each row represents a view, with the following cells:
                
                [1] The viewId
                [2] Display Name for the view
                [-]
                [4] The view type (folder or composition)
                [-]
                [6] The contents for the view (which is a list of forms)
                
                ==================================== -->

            <xsl:for-each select="office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Views']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[position()>$startRow]">
                <xsl:variable name="view" select="."/>
                <!-- ViewId is in the first column - must not have a ss:Index attribute -->
                <xsl:variable name="viewId" select="if ($view/office2003Spreadsheet:Cell[1]/@ss:Index) then '' else normalize-space($view/office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data)"/>
                <!-- Only process rows that have a ViewId -->
                <xsl:if test="$viewId != ''">
                    <xsl:variable name="viewIRI" select="cityEHRFunction:getIRI('#CityEHR:View:',$viewId)"/>
                    <xsl:variable name="viewDisplayName" select="$view/office2003Spreadsheet:Cell[2]/office2003Spreadsheet:Data"/>
                    <xsl:variable name="termIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:',$viewDisplayName)"/>

                    <Declaration>
                        <NamedIndividual IRI="{$viewIRI}"/>
                    </Declaration>

                    <ClassAssertion>
                        <Class IRI="#CityEHR:View"/>
                        <NamedIndividual IRI="{$viewIRI}"/>
                    </ClassAssertion>

                    <ObjectPropertyAssertion>
                        <ObjectProperty IRI="#hasDisplayName"/>
                        <NamedIndividual IRI="{$viewIRI}"/>
                        <NamedIndividual IRI="{$termIRI}"/>
                    </ObjectPropertyAssertion>

                    <!-- The viewType property is set in the cell position with first row title 'View Type' -->
                    <xsl:variable name="activeCellPositionViewType" as="xs:integer" select="count(/office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Views']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='View Type']/preceding-sibling::*) +1"/>

                    <xsl:variable name="viewTypeSet">
                        <xsl:call-template name="getCellValue">
                            <xsl:with-param name="row" select="$view"/>
                            <xsl:with-param name="cellPosition" select="$activeCellPositionViewType"/>
                        </xsl:call-template>
                    </xsl:variable>

                    <!-- viewType takes default value of 'Folder' if it has not been set in the spreadsheet -->
                    <xsl:variable name="viewType" select="if ($viewTypeSet='') then 'Folder' else $viewTypeSet"/>

                    <DataPropertyAssertion>
                        <DataProperty IRI="#hasType"/>
                        <NamedIndividual IRI="{$viewIRI}"/>
                        <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                            <xsl:value-of select="$viewType"/>
                        </Literal>
                    </DataPropertyAssertion>

                    <!-- The rank property is set in the cell position with first row title 'Rank' -->
                    <xsl:variable name="activeCellPositionRank" as="xs:integer" select="count(/office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Views']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Rank']/preceding-sibling::*) +1"/>

                    <xsl:variable name="rankSet">
                        <xsl:call-template name="getCellValue">
                            <xsl:with-param name="row" select="$view"/>
                            <xsl:with-param name="cellPosition" select="$activeCellPositionRank"/>
                        </xsl:call-template>
                    </xsl:variable>

                    <!-- rank takes default value of '1' if it has not been set in the spreadsheet -->
                    <xsl:variable name="rank" select="if ($rankSet='') then '1' else $rankSet"/>
                    <xsl:if test="$rankSet=''">
                        <xsl:variable name="context" select="concat('View: ',$viewId)"/>
                        <xsl:variable name="message" select="'Rank not defined - set default of 1'"/>
                        <xsl:call-template name="generateWarning">
                            <xsl:with-param name="node" select="$view"/>
                            <xsl:with-param name="context" select="$context"/>
                            <xsl:with-param name="message" select="$message"/>
                        </xsl:call-template>
                    </xsl:if>

                    <DataPropertyAssertion>
                        <DataProperty IRI="#hasRank"/>
                        <NamedIndividual IRI="{$viewIRI}"/>
                        <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                            <xsl:value-of select="$rank"/>
                        </Literal>
                    </DataPropertyAssertion>


                    <!-- The contents (form) starts in the cell position with first row title 'Content' -->
                    <xsl:variable name="activeCellPositionContents" as="xs:integer" select="count(/office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Views']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Contents']/preceding-sibling::*) +1"/>

                    <!-- Get actual position of the cell where contents list starts -->
                    <xsl:variable name="contentsListPosition">
                        <xsl:call-template name="getCellPosition">
                            <xsl:with-param name="row" select="$view"/>
                            <xsl:with-param name="cellPosition" select="$activeCellPositionContents"/>
                        </xsl:call-template>
                    </xsl:variable>

                    <!-- Iterate through the contents list.
                         Note that contentId is a node -->
                    <xsl:for-each select="$view/office2003Spreadsheet:Cell[position()>=$contentsListPosition]/office2003Spreadsheet:Data[normalize-space(.) != '']">
                        <xsl:variable name="contentId" select="."/>
                        <xsl:variable name="contentIRI" select="concat('#CityEHR:',$contentId)"/>

                        <xsl:if test="exists(key('contentsList',$contentId))">
                            <ObjectPropertyAssertion>
                                <ObjectProperty IRI="#hasContent"/>
                                <NamedIndividual IRI="{$viewIRI}"/>
                                <NamedIndividual IRI="{$contentIRI}"/>
                            </ObjectPropertyAssertion>
                        </xsl:if>


                        <xsl:if test="empty(key('contentsList',$contentId))">
                            <xsl:variable name="context" select="concat('View content: ',$viewId)"/>
                            <xsl:variable name="message" select="concat('Content node: ',$contentId,' not defined')"/>
                            <xsl:call-template name="generateWarning">
                                <xsl:with-param name="node" select="$contentId"/>
                                <xsl:with-param name="context" select="$context"/>
                                <xsl:with-param name="message" select="$message"/>
                            </xsl:call-template>
                        </xsl:if>
                    </xsl:for-each>

                </xsl:if>
            </xsl:for-each>


            <!-- Tester -->
            <!--
            <xsl:variable name="testSequence" select="((1,2),(3,4),(5,6))"/>
            
            <xsl:for-each select="StestSequence/*">
                <xsl:variable name="innerSequence" select="."/>
                <sequence>
                    <xsl:for-each select="SinnerSequence/*">
                        <sequence>
                            <xsl:value-of select="."/>
                        </sequence>               
                    </xsl:for-each>
                </sequence>               
            </xsl:for-each>
            -->


            <!-- === The Letters for this ontology === 
                
                For each Letter we need to:
                
                Declare an individual
                Assert the individual as a member of the CityEHR:Letter class
                Set the display name for the letter using the hasDisplayName object property
                Set the header for the letter using the hasHeader object property
                Set the contents for the letter using the hasContent object property
                
                In the spreadhseet, each row represents a letter, with the following cells:
                
                [1] The letterId
                [2] Display Name for the letter
                [3] Hint
                [-]
                [5] The rank
                [6] The header
                [-]
                [7] The contents for the letter (which is a list of sections)
                
                ==================================== -->

            <xsl:variable name="lettersWorksheet" select="office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Letters']/office2003Spreadsheet:Table"/>

            <xsl:for-each select="$lettersWorksheet/office2003Spreadsheet:Row[position()>$startRow]">

                <xsl:variable name="row" select="."/>

                <!-- letterId is in the first column - must not have a ss:Index attribute -->
                <xsl:variable name="letterId" select="if ($row/office2003Spreadsheet:Cell[1]/@ss:Index) then '' else normalize-space($row/office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data)"/>
                <!-- Only process rows that have a letterId -->
                <xsl:if test="$letterId != ''">

                    <xsl:variable name="compositionTypeIRI" select="'#CityEHR:Letter'"/>
                    <xsl:variable name="letterIRI" select="cityEHRFunction:getIRI($compositionTypeIRI,$letterId)"/>

                    <xsl:call-template name="generateComposition">
                        <xsl:with-param name="worksheet" select="$lettersWorksheet"/>
                        <xsl:with-param name="row" select="$row"/>
                        <xsl:with-param name="compositionId" select="$letterId"/>
                        <xsl:with-param name="compositionTypeIRI" select="$compositionTypeIRI"/>
                        <xsl:with-param name="compositionIRI" select="$letterIRI"/>
                    </xsl:call-template>


                    <!-- The header property is set in the cell position with first row title 'Header' -->
                    <xsl:variable name="activeCellPositionHeader" as="xs:integer" select="count($lettersWorksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Header']/preceding-sibling::*) +1"/>

                    <xsl:variable name="headerId">
                        <xsl:call-template name="getCellValue">
                            <xsl:with-param name="row" select="$row"/>
                            <xsl:with-param name="cellPosition" select="$activeCellPositionHeader"/>
                        </xsl:call-template>
                    </xsl:variable>

                    <xsl:variable name="headerIRI" select="concat('#ISO-13606:',$headerId)"/>

                    <xsl:if test="exists(key('contentsList',$headerId))">
                        <ObjectPropertyAssertion>
                            <ObjectProperty IRI="#hasHeader"/>
                            <NamedIndividual IRI="{$letterIRI}"/>
                            <NamedIndividual IRI="{$headerIRI}"/>
                        </ObjectPropertyAssertion>
                    </xsl:if>

                </xsl:if>
            </xsl:for-each>


            <!-- === The Messages for this ontology === 
                                    
                    For each Message we need to:
                    
                    Declare an individual
                    Assert the individual as a member of the CityEHR:Message class
                    Set the display name for the message using the hasDisplayName object property
                    Set the sections for the message using the hasContent object property
                    
                    In the spreadsheet, each row represents a message, with the following cells:
                    
                    [1] The messageId
                    [2] Display Name for the message
                    [-]
                    [>3] The sections for the message
                    
                    ==================================== -->

            <xsl:variable name="messagesWorksheet" select="office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Messages']/office2003Spreadsheet:Table"/>
            <!-- Process each row in the sheet -->
            <xsl:for-each select="$messagesWorksheet/office2003Spreadsheet:Row[position()>$startRow]">

                <xsl:variable name="row" select="."/>

                <!-- MessageId is in the first column - must not have a ss:Index attribute -->
                <xsl:variable name="messageId" select="if ($row/office2003Spreadsheet:Cell[1]/@ss:Index) then '' else normalize-space($row/office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data)"/>

                <!-- Only process rows that have a MessageId -->
                <xsl:if test="$messageId != ''">

                    <xsl:variable name="compositionTypeIRI" select="'#CityEHR:Message'"/>
                    <xsl:variable name="messageIRI" select="cityEHRFunction:getIRI($compositionTypeIRI,$messageId)"/>

                    <xsl:call-template name="generateComposition">
                        <xsl:with-param name="worksheet" select="$messagesWorksheet"/>
                        <xsl:with-param name="row" select="$row"/>
                        <xsl:with-param name="compositionId" select="$messageId"/>
                        <xsl:with-param name="compositionTypeIRI" select="$compositionTypeIRI"/>
                        <xsl:with-param name="compositionIRI" select="$messageIRI"/>
                    </xsl:call-template>

                </xsl:if>
            </xsl:for-each>


            <!-- === The Forms for this ontology === 
                
                For each Form we need to:
                
                Declare an individual
                Assert the individual as a member of the CityEHR:Form class
                Set the display name for the form using the hasDisplayName object property
                Set the sections for the form using the hasContent object property
                
                In the spreadhseet, each row represents a form, with the following cells:
                
                [1] The formId
                [2] Display Name for the form
                [3] Hint
                [-]
                [>4] The sections for the form
                
                ==================================== -->

            <xsl:variable name="formsWorksheet" select="office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Forms']/office2003Spreadsheet:Table"/>
            <xsl:for-each select="$formsWorksheet/office2003Spreadsheet:Row[position()>$startRow]">

                <xsl:variable name="row" select="."/>

                <!-- FormId is in the first column - must not have a ss:Index attribute -->
                <xsl:variable name="formId" select="if ($row/office2003Spreadsheet:Cell[1]/@ss:Index) then '' else cityEHRFunction:CreateID($row/office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data)"/>

                <!-- Only process rows that have a FormId -->
                <xsl:if test="$formId != ''">

                    <xsl:variable name="compositionTypeIRI" select="'#CityEHR:Form'"/>
                    <xsl:variable name="formIRI" select="cityEHRFunction:getIRI($compositionTypeIRI,$formId)"/>

                    <xsl:call-template name="generateComposition">
                        <xsl:with-param name="worksheet" select="$formsWorksheet"/>
                        <xsl:with-param name="row" select="$row"/>
                        <xsl:with-param name="compositionId" select="$formId"/>
                        <xsl:with-param name="compositionTypeIRI" select="$compositionTypeIRI"/>
                        <xsl:with-param name="compositionIRI" select="$formIRI"/>
                    </xsl:call-template>

                </xsl:if>
            </xsl:for-each>


            <!-- === The Order Templates for this ontology === 
                               
                For each Order we need to:
                
                Declare an individual
                Assert the individual as a member of the CityEHR:Order class
                Set the display name for the order template using the hasDisplayName object property
                Set the sections for the order using the hasContent object property
                
                In the spreadhseet, each row represents an order template, with the following cells:
                
                [1] The orderId
                [2] Display Name for the order template
                [3] Hint
                [-]
                [>4] The sections for the order template
                
                ==================================== -->

            <xsl:variable name="ordersWorksheet" select="office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Orders']/office2003Spreadsheet:Table"/>
            <xsl:for-each select="$ordersWorksheet/office2003Spreadsheet:Row[position()>$startRow]">

                <xsl:variable name="row" select="."/>

                <!-- OrderId is in the first column - must not have a ss:Index attribute -->
                <xsl:variable name="orderId" select="if ($row/office2003Spreadsheet:Cell[1]/@ss:Index) then '' else cityEHRFunction:CreateID($row/office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data)"/>

                <!-- Only process rows that have an OrderId -->
                <xsl:if test="$orderId != ''">

                    <xsl:variable name="compositionTypeIRI" select="'#CityEHR:Order'"/>
                    <xsl:variable name="orderIRI" select="cityEHRFunction:getIRI($compositionTypeIRI,$orderId)"/>

                    <xsl:call-template name="generateComposition">
                        <xsl:with-param name="worksheet" select="$ordersWorksheet"/>
                        <xsl:with-param name="row" select="$row"/>
                        <xsl:with-param name="compositionId" select="$orderId"/>
                        <xsl:with-param name="compositionTypeIRI" select="$compositionTypeIRI"/>
                        <xsl:with-param name="compositionIRI" select="$orderIRI"/>
                    </xsl:call-template>

                </xsl:if>
            </xsl:for-each>


            <!-- === The Care Pathway Templates for this ontology === 
                
                For each Pathway we need to:
                
                Declare an individual
                Assert the individual as a member of the CityEHR:Pathway class
                Set the display name for the pathway template using the hasDisplayName object property
                Set the sections for the pathway using the hasContent object property
                
                In the spreadhseet, each row represents a pathway template, with the following cells:
                
                [1] The pathwayId
                [2] Display Name for the pathway template
                [3] Hint
                [-]
                [>4] The sections for the pathway template
                
                ==================================== -->

            <xsl:variable name="pathwaysWorksheet" select="office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Pathways']/office2003Spreadsheet:Table"/>
            <xsl:for-each select="$pathwaysWorksheet/office2003Spreadsheet:Row[position()>$startRow]">

                <xsl:variable name="row" select="."/>

                <!-- pathwayId is in the first column - must not have a ss:Index attribute -->
                <xsl:variable name="pathwayId" select="if ($row/office2003Spreadsheet:Cell[1]/@ss:Index) then '' else cityEHRFunction:CreateID($row/office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data)"/>

                <!-- Only process rows that have an pathwayId -->
                <xsl:if test="$pathwayId != ''">

                    <xsl:variable name="compositionTypeIRI" select="'#CityEHR:Pathway'"/>
                    <xsl:variable name="pathwayIRI" select="cityEHRFunction:getIRI($compositionTypeIRI,$pathwayId)"/>

                    <xsl:call-template name="generateComposition">
                        <xsl:with-param name="worksheet" select="$pathwaysWorksheet"/>
                        <xsl:with-param name="row" select="$row"/>
                        <xsl:with-param name="compositionId" select="$pathwayId"/>
                        <xsl:with-param name="compositionTypeIRI" select="$compositionTypeIRI"/>
                        <xsl:with-param name="compositionIRI" select="$pathwayIRI"/>
                    </xsl:call-template>

                </xsl:if>
            </xsl:for-each>




            <!-- === The Sections for this ontology === 
                
                    Can be for sections on a form, etc or tasks in a pathway.
                    So match the sheets of 'Sections' and 'Sections (Tasks)'
                    
                    For each Section we need to:
                    
                    Declare an individual
                    Assert the individual as a member of the ISO-13606:Section class
                    Set the display name for the Section using the hasDisplayName object property
                    Set the contents for the section using the hasContent object properties
                    Set the layout for the section using the hasLayout data property
                    
                    In the spreadsheet, each row represents a section, with the following cells:
                    
                    [1] The sectionID
                    [2] Display Name for the Section (may be blank)
                    [3-5] Various setings for the section
                    [>5] The contents for the Section
                    
                    ==================================== -->

            <!-- sectionList is rows on the sheet from row 2 onwards that do not have an empty first cell -->
            <xsl:variable name="sectionList" select="office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Sections' or @ss:Name='Sections (Tasks)']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[position()>$startRow][empty(office2003Spreadsheet:Cell[1]/@ss:Index)]"/>

            <xsl:variable name="sectionIdList" select="$sectionList/cityEHRFunction:CreateID(office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data)"/>
            <xsl:variable name="distinctSectionIdList" select="distinct-values($sectionIdList)"/>


            <!-- Generate error for any non-unique sectionId -->
            <xsl:for-each select="$distinctSectionIdList">
                <xsl:variable name="sectionId" select="."/>

                <xsl:variable name="repeatedSection" select="key('sectionListKey',$sectionId,$rootNode)[2]"/>

                <xsl:if test="exists($repeatedSection)">
                    <xsl:variable name="context" select="concat('Section: ',$sectionId)"/>
                    <xsl:variable name="message" select="'Section id is not unique'"/>
                    <xsl:call-template name="generateError">
                        <xsl:with-param name="node" select="$repeatedSection"/>
                        <xsl:with-param name="context" select="$context"/>
                        <xsl:with-param name="message" select="$message"/>
                    </xsl:call-template>
                </xsl:if>

            </xsl:for-each>

            <!-- Process each section -->
            <xsl:for-each select="$distinctSectionIdList">
                <xsl:variable name="sectionId" select="."/>
                <xsl:variable name="section" select="key('sectionListKey',$sectionId,$rootNode)[1]"/>

                <!-- Section is a row in the worksheet - now need to get which worksheet that is (the parent of the row, which is a office2003Spreadsheet:Table element -->
                <xsl:variable name="worksheet" select="$section/.."/>

                <!-- Only process rows that have a SectionId -->
                <xsl:if test="$sectionId != ''">
                    <xsl:variable name="sectionIRI" select="cityEHRFunction:getIRI('#ISO-13606:Section:',$sectionId)"/>

                    <xsl:call-template name="generateSection">
                        <xsl:with-param name="worksheet" select="$worksheet"/>
                        <xsl:with-param name="row" select="$section"/>
                        <xsl:with-param name="sectionId" select="$sectionId"/>
                        <xsl:with-param name="sectionIRI" select="$sectionIRI"/>
                    </xsl:call-template>

                </xsl:if>
            </xsl:for-each>


            <!-- === The Entries for this ontology === 
                    
                    For each Entry we need to:
                    
                    Declare an individual
                    Assert the individual as a member of the appropriate ISO-13606:Entry sub-class:
                            HL7-CDA:Act
                            HL7-CDA:Encounter
                            HL7-CDA:Observation
                            HL7-CDA:Procedure
                            HL7-CDA:RegionOfInterest
                            HL7-CDA:SubstanceAdministration
                            HL7-CDA:Supply
                            
                    Set the display name for the Entry using the hasDisplayName object property
                    Set the Elements for the Entry using the hasContent object property
                    
                    In the spreadhsheet, each row represents an entry, with the following cells:
                    
                    [1] The entryId
                    [2] Display Name for the Entry
                    [3] SNOMED Code for the Entry
                    [-]
                    [5-12] Various setings for the Entry
                    [>12] The Contents for the Entry (Elements and/or Clusters)
                    
                    ==================================== -->

            <!-- entryList is rows on the sheet from row 2 onwards that do not have an empty first cell -->
            <xsl:variable name="entryList" select="office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Entries' or @ss:Name='Entries (Actions)']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[position()>$startRow][empty(office2003Spreadsheet:Cell[1]/@ss:Index)]"/>

            <xsl:variable name="entryIdList" select="$entryList/cityEHRFunction:CreateID(office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data)"/>
            <xsl:variable name="distinctEntryIdList" select="distinct-values($entryIdList)"/>

            <!-- Generate error for any non-unique entryId -->
            <!--
            <xsl:for-each select="$distinctEntryIdList">
                <xsl:variable name="entryId" select="."/>

                <xsl:variable name="repeatedEntry" select="key('entryListKey',$entryId,$rootNode)[2]"/>

                <xsl:if test="exists($repeatedEntry)">
                    <xsl:variable name="context" select="concat('Entry: ',$entryId)"/>
                    <xsl:variable name="message" select="'Entry id is not unique'"/>
                    <xsl:call-template name="generateError">
                        <xsl:with-param name="node" select="$repeatedEntry"/>
                        <xsl:with-param name="context" select="$context"/>
                        <xsl:with-param name="message" select="$message"/>
                    </xsl:call-template>
                </xsl:if>

            </xsl:for-each>
            -->

            <!-- Process each entry -->
            <xsl:for-each select="$distinctEntryIdList">
                <xsl:variable name="entryId" select="."/>

                <!-- Generate error for any non-unique entryId -->
                <xsl:variable name="repeatedEntry" select="key('entryListKey',$entryId,$rootNode)[2]"/>

                <xsl:if test="exists($repeatedEntry)">
                    <xsl:variable name="context" select="concat('Entry: ',$entryId)"/>
                    <xsl:variable name="message" select="'Entry id is not unique'"/>
                    <xsl:call-template name="generateError">
                        <xsl:with-param name="node" select="$repeatedEntry"/>
                        <xsl:with-param name="context" select="$context"/>
                        <xsl:with-param name="message" select="$message"/>
                    </xsl:call-template>
                </xsl:if>

                <xsl:variable name="entry" select="key('entryListKey',$entryId,$rootNode)[1]"/>

                <!-- Entry is a row in the worksheet - now need to get which worksheet that is (the parent of the row, which is a office2003Spreadsheet:Table element -->
                <xsl:variable name="worksheet" select="$entry/.."/>

                <xsl:variable name="entryIRI" select="cityEHRFunction:getIRI('#ISO-13606:Entry:',$entryId)"/>

                <!-- The entry class (type) is set in the cell position with first row title 'Entry Type' -->
                <xsl:variable name="activeCellPositionEntryType" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Entry Type']/preceding-sibling::*) +1"/>

                <xsl:variable name="entryType">
                    <xsl:call-template name="getCellValue">
                        <xsl:with-param name="row" select="$entry"/>
                        <xsl:with-param name="cellPosition" select="$activeCellPositionEntryType"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:variable name="entryClassIRI" select="concat('#HL7-CDA:',substring-after($entryType,':'))"/>

                <Declaration>
                    <NamedIndividual IRI="{$entryIRI}"/>
                </Declaration>

                <ClassAssertion>
                    <Class IRI="{$entryClassIRI}"/>
                    <NamedIndividual IRI="{$entryIRI}"/>
                </ClassAssertion>

                <!-- The displayName is set in the cell position with first row title 'DisplayName' -->
                <xsl:variable name="activeCellPositionDisplayName" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='DisplayName']/preceding-sibling::*) +1"/>

                <xsl:variable name="displayName">
                    <xsl:call-template name="getCellValue">
                        <xsl:with-param name="row" select="$entry"/>
                        <xsl:with-param name="cellPosition" select="$activeCellPositionDisplayName"/>
                    </xsl:call-template>
                </xsl:variable>

                <!-- Set the assertion of the displayName for the entry -->
                <xsl:if test="$displayName != ''">
                    <xsl:variable name="termIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:',$displayName)"/>

                    <ObjectPropertyAssertion>
                        <ObjectProperty IRI="#hasDisplayName"/>
                        <NamedIndividual IRI="{$entryIRI}"/>
                        <NamedIndividual IRI="{$termIRI}"/>
                    </ObjectPropertyAssertion>

                </xsl:if>
                
                <!-- The hint is set in the cell position with first row title 'Hint' -->
                <xsl:variable name="activeCellPositionHint" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Hint']/preceding-sibling::*) +1"/>
                
                <xsl:variable name="hint">
                    <xsl:call-template name="getCellValue">
                        <xsl:with-param name="row" select="$entry"/>
                        <xsl:with-param name="cellPosition" select="$activeCellPositionHint"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <!-- Set the assertion of the hint for the section, if it has one -->
                <xsl:if test="$hint != ''">
                    <DataPropertyAssertion>
                        <DataProperty IRI="#hasHint"/>
                        <NamedIndividual IRI="{$entryIRI}"/>
                        <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                            <xsl:value-of select="$hint"/>
                        </Literal>
                    </DataPropertyAssertion>
                </xsl:if>
                
                
                <!-- The alert is set in the cell position with first row title 'Alert' -->
                <xsl:variable name="activeCellPositionAlert" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Alert']/preceding-sibling::*) +1"/>
                
                <xsl:variable name="alert">
                    <xsl:call-template name="getCellValue">
                        <xsl:with-param name="row" select="$entry"/>
                        <xsl:with-param name="cellPosition" select="$activeCellPositionAlert"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <!-- Set the assertion of the alert for the section, if it has one -->
                <xsl:if test="$alert != ''">
                    <DataPropertyAssertion>
                        <DataProperty IRI="#hasAlert"/>
                        <NamedIndividual IRI="{$entryIRI}"/>
                        <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                            <xsl:value-of select="$alert"/>
                        </Literal>
                    </DataPropertyAssertion>
                </xsl:if>
                
                
                <!-- The list of Contents (Elements and Clusters) starts at cell position with first row value of 'Contents' (activeCellPosition) -->
                <xsl:variable name="activeCellPositionContents" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Contents']/preceding-sibling::*) +1"/>

                <!-- Get actual position of the cell we want -->
                <xsl:variable name="contentsListPosition">
                    <xsl:call-template name="getCellPosition">
                        <xsl:with-param name="row" select="$entry"/>
                        <xsl:with-param name="cellPosition" select="$activeCellPositionContents"/>
                    </xsl:call-template>
                </xsl:variable>

                <!-- Set the contents list -->
                <xsl:variable name="contentsList" select="$entry/office2003Spreadsheet:Cell[position() >= $contentsListPosition]/office2003Spreadsheet:Data[normalize-space(.) != '']"/>

                <!-- Data property assertion for the contents list -->
                <xsl:if test="exists($contentsList)">
                    <DataPropertyAssertion>
                        <DataProperty IRI="#hasContentsList"/>
                        <NamedIndividual IRI="{$entryIRI}"/>
                        <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                            <xsl:value-of select="cityEHRFunction:generateContentsList($entryIRI,$contentsList)"/>
                        </Literal>
                    </DataPropertyAssertion>
                </xsl:if>

                <!-- Iterate through the contents list -->
                <xsl:for-each select="$contentsList">
                    <xsl:variable name="contentId" select="."/>
                    <xsl:variable name="contentIRI" select="concat('#ISO-13606:',$contentId)"/>

                    <xsl:if test="exists(key('contentsList',$contentId))">
                        <ObjectPropertyAssertion>
                            <ObjectProperty IRI="#hasContent"/>
                            <NamedIndividual IRI="{$entryIRI}"/>
                            <NamedIndividual IRI="{$contentIRI}"/>
                        </ObjectPropertyAssertion>
                    </xsl:if>

                    <xsl:if test="empty(key('contentsList',$contentId))">
                        <xsl:variable name="context" select="concat('Entry content: ',$entryId)"/>
                        <xsl:variable name="message" select="concat('Content node: ',$contentId,' not defined')"/>
                        <xsl:call-template name="generateWarning">
                            <xsl:with-param name="node" select="$contentId"/>
                            <xsl:with-param name="context" select="$context"/>
                            <xsl:with-param name="message" select="$message"/>
                        </xsl:call-template>
                    </xsl:if>
                </xsl:for-each>

                <!-- The remaining properties may not be present in the spreadsheet, 
                     so need to check the activeCellPosition before making the assertion.
                     If activeCellPosition is 1 then the property does not exist -->

                <!-- This entry can be the root of another (i.e. a proxy entry). -->
                <xsl:variable name="activeCellPositionRootOf" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Root Of']/preceding-sibling::*) +1"/>

                <xsl:variable name="rootOf">
                    <xsl:call-template name="getCellValue">
                        <xsl:with-param name="row" select="$entry"/>
                        <xsl:with-param name="cellPosition" select="$activeCellPositionRootOf"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:variable name="rootOfEntryIRI" select="if ($rootOf ='' or $activeCellPositionRootOf = 1) then '' else concat('#ISO-13606:',$rootOf)"/>

                <!-- Set the assertion of the rootOf property for the entry, but only if one is specified -->
                <xsl:if test="$rootOfEntryIRI != ''">
                    <ObjectPropertyAssertion>
                        <ObjectProperty IRI="#isRootOf"/>
                        <NamedIndividual IRI="{$entryIRI}"/>
                        <NamedIndividual IRI="{$rootOfEntryIRI}"/>
                    </ObjectPropertyAssertion>
                </xsl:if>


                <!-- The layout property is set in the cell position with first row title 'Layout' -->
                <xsl:variable name="activeCellPositionLayout" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Layout']/preceding-sibling::*) +1"/>

                <xsl:variable name="layoutSet">
                    <xsl:call-template name="getCellValue">
                        <xsl:with-param name="row" select="$entry"/>
                        <xsl:with-param name="cellPosition" select="$activeCellPositionLayout"/>
                    </xsl:call-template>
                </xsl:variable>

                <!-- layout takes default value of 'Ranked' if it has not been set in the spreadsheet -->
                <xsl:variable name="layout" select="if ($layoutSet='' or $activeCellPositionLayout=1) then 'Ranked' else $layoutSet"/>

                <DataPropertyAssertion>
                    <DataProperty IRI="#hasLayout"/>
                    <NamedIndividual IRI="{$entryIRI}"/>
                    <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                        <xsl:value-of select="$layout"/>
                    </Literal>
                </DataPropertyAssertion>

                <!-- The rendition property is set in the cell position with first row title 'Rendition' -->
                <xsl:variable name="activeCellPositionRendition" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Rendition']/preceding-sibling::*) +1"/>

                <xsl:variable name="renditionSet">
                    <xsl:call-template name="getCellValue">
                        <xsl:with-param name="row" select="$entry"/>
                        <xsl:with-param name="cellPosition" select="$activeCellPositionRendition"/>
                    </xsl:call-template>
                </xsl:variable>

                <!-- rendition takes default value of 'Form' if it has not been set in the spreadsheet -->
                <xsl:variable name="renditionIRI" select="if ($renditionSet='' or $activeCellPositionRendition=1) then '#CityEHR:EntryProperty:Form' else cityEHRFunction:getIRI('#CityEHR:EntryProperty:',$renditionSet)"/>

                <!-- Set the assertion of the Rendition property for the entry -->
                <ObjectPropertyAssertion>
                    <ObjectProperty IRI="#hasRendition"/>
                    <NamedIndividual IRI="{$entryIRI}"/>
                    <NamedIndividual IRI="{$renditionIRI}"/>
                </ObjectPropertyAssertion>


                <!-- The CRUD Entry Property is set in the cell position with first row title 'CRUD' -->
                <xsl:variable name="activeCellPositionCRUD" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='CRUD']/preceding-sibling::*) +1"/>

                <xsl:variable name="crudSet">
                    <xsl:call-template name="getCellValue">
                        <xsl:with-param name="row" select="$entry"/>
                        <xsl:with-param name="cellPosition" select="$activeCellPositionCRUD"/>
                    </xsl:call-template>
                </xsl:variable>

                <!-- Takes value of 'R' if not set -->
                <xsl:variable name="crudIRI" select="if ($crudSet='' or $activeCellPositionCRUD=1) then '#CityEHR:EntryProperty:R' else cityEHRFunction:getIRI('#CityEHR:EntryProperty:',$crudSet)"/>

                <!-- Set the assertion of the CRUD property for the entry -->
                <ObjectPropertyAssertion>
                    <ObjectProperty IRI="#hasCRUD"/>
                    <NamedIndividual IRI="{$entryIRI}"/>
                    <NamedIndividual IRI="{$crudIRI}"/>
                </ObjectPropertyAssertion>


                <!-- The occurrence property is set in the cell position with first row title 'Occurrence' -->
                <xsl:variable name="activeCellPositionOccurrence" as="xs:integer" select="count($rootNode/office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Entries']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Occurrence']/preceding-sibling::*) +1"/>

                <xsl:variable name="occurrenceSet">
                    <xsl:call-template name="getCellValue">
                        <xsl:with-param name="row" select="$entry"/>
                        <xsl:with-param name="cellPosition" select="$activeCellPositionOccurrence"/>
                    </xsl:call-template>
                </xsl:variable>

                <!-- occurrence takes default value of 'Single' if it has not been set in the spreadsheet -->
                <xsl:variable name="occurrenceIRI" select="if ($occurrenceSet='' or $activeCellPositionOccurrence=1) then '#CityEHR:EntryProperty:Single' else cityEHRFunction:getIRI('#CityEHR:EntryProperty:',$occurrenceSet)"/>

                <!-- Set the assertion of the Occurrence property for the entry -->
                <ObjectPropertyAssertion>
                    <ObjectProperty IRI="#hasOccurrence"/>
                    <NamedIndividual IRI="{$entryIRI}"/>
                    <NamedIndividual IRI="{$occurrenceIRI}"/>
                </ObjectPropertyAssertion>


                <!-- This entry can be sorted by an element, but only if its a MultipleEntry. -->
                <xsl:if test="$occurrenceIRI = '#CityEHR:EntryProperty:MultipleEntry'">

                    <xsl:variable name="activeCellPositionSortCriteria" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Sort Criteria']/preceding-sibling::*) +1"/>

                    <xsl:variable name="sortElementId">
                        <xsl:call-template name="getCellValue">
                            <xsl:with-param name="row" select="$entry"/>
                            <xsl:with-param name="cellPosition" select="$activeCellPositionSortCriteria"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:variable name="sortElementIRI" select="if ($sortElementId ='' or $activeCellPositionSortCriteria = 1) then '' else concat('#ISO-13606:',$sortElementId)"/>

                    <xsl:if test="$sortElementIRI != ''">
                        <ObjectPropertyAssertion>
                            <ObjectProperty IRI="#hasSortCriteria"/>
                            <NamedIndividual IRI="{$entryIRI}"/>
                            <NamedIndividual IRI="{$sortElementIRI}"/>
                        </ObjectPropertyAssertion>
                    </xsl:if>
                </xsl:if>


                <!-- The InitialValue Entry Property is set in the cell position with first row title 'Initial Value' -->
                <xsl:variable name="activeCellPositionInitialValue" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Initial Value']/preceding-sibling::*) +1"/>

                <xsl:variable name="initialValueSet">
                    <xsl:call-template name="getCellValue">
                        <xsl:with-param name="row" select="$entry"/>
                        <xsl:with-param name="cellPosition" select="$activeCellPositionInitialValue"/>
                    </xsl:call-template>
                </xsl:variable>

                <!-- Takes value of 'Default' if not set -->
                <xsl:variable name="initialValueIRI" select="if ($initialValueSet='' or $activeCellPositionInitialValue=1) then '#CityEHR:EntryProperty:Default' else cityEHRFunction:getIRI('#CityEHR:EntryProperty:',$initialValueSet)"/>

                <!-- Set the assertion of the initial value property for the entry -->
                <ObjectPropertyAssertion>
                    <ObjectProperty IRI="#hasInitialValue"/>
                    <NamedIndividual IRI="{$entryIRI}"/>
                    <NamedIndividual IRI="{$initialValueIRI}"/>
                </ObjectPropertyAssertion>


                <!-- The conditions property is set in the cell position with first row title 'Conditions'. -->
                <xsl:variable name="activeCellPositionConditions" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Conditions']/preceding-sibling::*) +1"/>

                <xsl:variable name="conditions">
                    <xsl:call-template name="getCellValue">
                        <xsl:with-param name="row" select="$entry"/>
                        <xsl:with-param name="cellPosition" select="$activeCellPositionConditions"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:if test="$conditions != ''">
                    <DataPropertyAssertion>
                        <DataProperty IRI="#hasConditions"/>
                        <NamedIndividual IRI="{$entryIRI}"/>
                        <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                            <xsl:value-of select="$conditions"/>
                        </Literal>
                    </DataPropertyAssertion>
                </xsl:if>


                <!-- The pre-conditions property is set in the cell position with first row title 'Pre-conditions'. -->
                <xsl:variable name="activeCellPositionPreConditions" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Pre-conditions']/preceding-sibling::*) +1"/>

                <xsl:variable name="preConditions">
                    <xsl:call-template name="getCellValue">
                        <xsl:with-param name="row" select="$entry"/>
                        <xsl:with-param name="cellPosition" select="$activeCellPositionPreConditions"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:if test="$preConditions != ''">
                    <DataPropertyAssertion>
                        <DataProperty IRI="#hasPreConditions"/>
                        <NamedIndividual IRI="{$entryIRI}"/>
                        <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                            <xsl:value-of select="$preConditions"/>
                        </Literal>
                    </DataPropertyAssertion>
                </xsl:if>



                <!-- The cohortSearch property is set in the cell position with first row title 'Cohort Search' -->
                <xsl:variable name="activeCellPositionCohortSearch" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Cohort Search']/preceding-sibling::*) +1"/>

                <xsl:variable name="cohortSearchSet">
                    <xsl:call-template name="getCellValue">
                        <xsl:with-param name="row" select="$entry"/>
                        <xsl:with-param name="cellPosition" select="$activeCellPositionCohortSearch"/>
                    </xsl:call-template>
                </xsl:variable>

                <!-- cohortSearch takes default value of 'NotSearchable' if it has not been set in the spreadsheet -->
                <xsl:variable name="cohortSearch" select="if ($cohortSearchSet='') then 'Searchable' else $cohortSearchSet"/>

                <xsl:variable name="cohortSearchIRI" select="if ($cohortSearchSet='' or $activeCellPositionCohortSearch=1) then '#CityEHR:EntryProperty:NotSearchable' else cityEHRFunction:getIRI('#CityEHR:EntryProperty:',$cohortSearchSet)"/>

                <!-- Set the assertion of the cohortSearch property for the entry -->
                <ObjectPropertyAssertion>
                    <ObjectProperty IRI="#hasCohortSearch"/>
                    <NamedIndividual IRI="{$entryIRI}"/>
                    <NamedIndividual IRI="{$cohortSearchIRI}"/>
                </ObjectPropertyAssertion>


            </xsl:for-each>
            <!-- Iteration through Entries -->


            <!-- === The Clusters for this ontology === 
                
                For each Cluster we need to:
                
                Declare an individual
                Assert the individual as a member of the ISO-13606:Cluster class
                Set the display name for the Cluster using the hasDisplayName object property
                Set the Elements for the Cluster using the hasContent object property
                
                In the spreadhsheet, each row represents a cluster, with the following cells:
                
                [1] The clusterId
                [2] Display Name for the Cluster
                [3] SMOMED Code
                [-] 
                [5] Conditions
                [-]
                [>7] The Elements for the Cluster
                
                ==================================== -->

            <!-- clusterList is rows on the sheet from row 2 onwards that do not have an empty first cell -->
            <!-- Cluster is a row in the worksheet - now need to get which worksheet that is (the parent of the row, which is a office2003Spreadsheet:Table element -->
            <xsl:variable name="clusterWorksheet" select="office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Clusters']/office2003Spreadsheet:Table"/>
            <xsl:variable name="clusterList" select="$clusterWorksheet/office2003Spreadsheet:Row[position()>$startRow][empty(office2003Spreadsheet:Cell[1]/@ss:Index)]"/>

            <xsl:variable name="clusterIdList" select="$clusterList/cityEHRFunction:CreateID(office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data)"/>
            <xsl:variable name="distinctClusterIdList" select="distinct-values($clusterIdList)"/>


            <xsl:for-each select="$distinctClusterIdList">
                <xsl:variable name="clusterId" select="."/>

                <!-- **jc put repeated entry check in here -->

                <xsl:variable name="cluster" select="key('clusterListKey',$clusterId,$rootNode)[1]"/>

                <xsl:variable name="clusterIRI" select="cityEHRFunction:getIRI('#ISO-13606:Cluster:',$clusterId)"/>

                <!-- Only process rows that have a ClusterId -->
                <xsl:if test="$clusterId != ''">

                    <Declaration>
                        <NamedIndividual IRI="{$clusterIRI}"/>
                    </Declaration>

                    <ClassAssertion>
                        <Class IRI="#ISO-13606:Cluster"/>
                        <NamedIndividual IRI="{$clusterIRI}"/>
                    </ClassAssertion>

                    <!-- The displayName is set in the cell position with first row title 'DisplayName' -->
                    <xsl:variable name="activeCellPositionDisplayName" as="xs:integer" select="count($clusterWorksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='DisplayName']/preceding-sibling::*) +1"/>

                    <xsl:variable name="displayName">
                        <xsl:call-template name="getCellValue">
                            <xsl:with-param name="row" select="$cluster"/>
                            <xsl:with-param name="cellPosition" select="$activeCellPositionDisplayName"/>
                        </xsl:call-template>
                    </xsl:variable>

                    <!-- Set the assertion of the displayName for the cluster -->
                    <xsl:if test="$displayName != ''">
                        <xsl:variable name="termIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:',$displayName)"/>
                        <ObjectPropertyAssertion>
                            <ObjectProperty IRI="#hasDisplayName"/>
                            <NamedIndividual IRI="{$clusterIRI}"/>
                            <NamedIndividual IRI="{$termIRI}"/>
                        </ObjectPropertyAssertion>
                    </xsl:if>


                    <!-- The list of Contents (Elements and Clusters) starts at cell position with first row value of 'Contents' (activeCellPosition) -->
                    <xsl:variable name="activeCellPositionContents" as="xs:integer" select="count($clusterWorksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Contents']/preceding-sibling::*) +1"/>

                    <!-- Get actual position of the cell we want -->
                    <xsl:variable name="contentsListPosition">
                        <xsl:call-template name="getCellPosition">
                            <xsl:with-param name="row" select="$cluster"/>
                            <xsl:with-param name="cellPosition" select="$activeCellPositionContents"/>
                        </xsl:call-template>
                    </xsl:variable>

                    <!-- Set the contents list -->
                    <xsl:variable name="contentsList" select="$cluster/office2003Spreadsheet:Cell[position() >= $contentsListPosition]/office2003Spreadsheet:Data[normalize-space(.) != '']"/>

                    <!-- Data property assertion for the contents list -->
                    <xsl:if test="exists($contentsList)">
                        <DataPropertyAssertion>
                            <DataProperty IRI="#hasContentsList"/>
                            <NamedIndividual IRI="{$clusterIRI}"/>
                            <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                                <xsl:value-of select="cityEHRFunction:generateContentsList($clusterIRI,$contentsList)"/>
                            </Literal>
                        </DataPropertyAssertion>
                    </xsl:if>

                    <!-- Iterate through the contents list.
                         Contents of the cluster must exist as ids and must not be the same as the container cluster -->
                    <xsl:for-each select="$contentsList">
                        <xsl:variable name="contentId" select="."/>
                        <xsl:variable name="contentIRI" select="concat('#ISO-13606:',$contentId)"/>

                        <xsl:if test="exists(key('contentsList',$contentId)) and $contentIRI!=$clusterIRI">
                            <ObjectPropertyAssertion>
                                <ObjectProperty IRI="#hasContent"/>
                                <NamedIndividual IRI="{$clusterIRI}"/>
                                <NamedIndividual IRI="{$contentIRI}"/>
                            </ObjectPropertyAssertion>
                        </xsl:if>

                        <!-- Warning if content does not exist -->
                        <xsl:if test="empty(key('contentsList',$contentId))">
                            <xsl:variable name="context" select="concat('Cluster content: ',$clusterId)"/>
                            <xsl:variable name="message" select="concat('Content node: ',$contentId,' not defined')"/>
                            <xsl:call-template name="generateWarning">
                                <xsl:with-param name="node" select="$contentId"/>
                                <xsl:with-param name="context" select="$context"/>
                                <xsl:with-param name="message" select="$message"/>
                            </xsl:call-template>
                        </xsl:if>

                        <!-- Warning if cluster contains itself -->
                        <xsl:if test="$contentIRI=$clusterIRI">
                            <xsl:variable name="context" select="concat('Cluster content: ',$clusterId)"/>
                            <xsl:variable name="message" select="concat('Content node: ',$contentId,' not defined')"/>
                            <xsl:call-template name="generateWarning">
                                <xsl:with-param name="node" select="$contentId"/>
                                <xsl:with-param name="context" select="$context"/>
                                <xsl:with-param name="message" select="$message"/>
                            </xsl:call-template>
                        </xsl:if>
                    </xsl:for-each>

                </xsl:if>
                <!-- End of processing for Cluster with ClusterId set -->

            </xsl:for-each>
            <!-- Iteration through Clusters -->


            <!-- === The Elements for this ontology === 
                    
                    For each Element we need to:
                    
                    Declare an individual
                    Assert the individual as a member of the ISO-13606:Element class
                    Set the display name for the Element using the hasDisplayName object property
                    Set the values for the Element using the hasValue object property
                    
                    In the spreadhseet, each row represents an element, with the following cells:
                    
                    [1] The elementID
                    [2] Display Name for the Element
                    [3] SNOMED code for the Element
                    [-]
                    [5] the element type (cityEHR specific) 
                    [6] the data type for the element (an xs data type)
                    [7-11] Various other settings for the Element
                    [-]
                    [>12] The values for the Element
                    
                    Values for enumeratedValue type are specified in pairs of cells, the first with the displayName, the second with the value.
                    If no value is specified, then the displayName is used for both.
                    The pairs of cells have different format styles and this is used to differentiate them in the processing
                                       
                    ==================================== -->

            <xsl:variable name="elementsWorksheet" select="office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Elements']/office2003Spreadsheet:Table[1]"/>

            <!-- Get the list of headers on the sheet. Use Cell rather than is Data child so that blank cells are also included -->
            <xsl:variable name="elementsWorksheetHeaders" select="$elementsWorksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell"/>


            <!-- This is not really an iteration, since there is only one elements sheet.
                 But is necessary to contain the scope of the variables declared below.
                -->
            <xsl:for-each select="$elementsWorksheet">

                <xsl:variable name="activeCellPositionDisplayName" as="xs:integer" select="count($elementsWorksheetHeaders[office2003Spreadsheet:Data='DisplayName']/preceding-sibling::*)+1"/>
                <xsl:variable name="activeCellPositionRootOf" as="xs:integer" select="count($elementsWorksheetHeaders[office2003Spreadsheet:Data='Root Of']/preceding-sibling::*)+1"/>
                <xsl:variable name="activeCellPositionDataType" as="xs:integer" select="count($elementsWorksheetHeaders[office2003Spreadsheet:Data='Data Type']/preceding-sibling::*)+1"/>
                <xsl:variable name="activeCellPositionElementType" as="xs:integer" select="count($elementsWorksheetHeaders[office2003Spreadsheet:Data='Element Type']/preceding-sibling::*)+1"/>
                <xsl:variable name="activeCellPositionValueRequired" as="xs:integer" select="count($elementsWorksheetHeaders[office2003Spreadsheet:Data='Value Required']/preceding-sibling::*)+1"/>
                <xsl:variable name="activeCellPositionScope" as="xs:integer" select="count($elementsWorksheetHeaders[office2003Spreadsheet:Data='Scope']/preceding-sibling::*)+1"/>
                <xsl:variable name="activeCellPositionUnit" as="xs:integer" select="count($elementsWorksheetHeaders[office2003Spreadsheet:Data='Units']/preceding-sibling::*)+1"/>
                <xsl:variable name="activeCellPositionFieldLength" as="xs:integer" select="count($elementsWorksheetHeaders[office2003Spreadsheet:Data='Field Length']/preceding-sibling::*)+1"/>
                <xsl:variable name="activeCellPositionDefaultValue" as="xs:integer" select="count($elementsWorksheetHeaders[office2003Spreadsheet:Data='Default Value']/preceding-sibling::*)+1"/>
                <xsl:variable name="activeCellPositionExpression" as="xs:integer" select="count($elementsWorksheetHeaders[office2003Spreadsheet:Data='Calculated Value']/preceding-sibling::*)+1"/>
                <xsl:variable name="activeCellPositionConstraints" as="xs:integer" select="count($elementsWorksheetHeaders[office2003Spreadsheet:Data='Constraints']/preceding-sibling::*)+1"/>
                <xsl:variable name="activeCellPositionConditions" as="xs:integer" select="count($elementsWorksheetHeaders[office2003Spreadsheet:Data='Conditions']/preceding-sibling::*)+1"/>
                <xsl:variable name="activeCellPositionElements" as="xs:integer" select="count($elementsWorksheetHeaders[office2003Spreadsheet:Data='Values']/preceding-sibling::*)+1"/>

                <!-- Get styles for displayName and value which are set in the top row -->
                <xsl:variable name="displayNameStyle" select="$elementsWorksheetHeaders[position() gt $activeCellPositionElements][office2003Spreadsheet:Data='displayName']/@ss:StyleID"/>
                <xsl:variable name="valueStyle" select="$elementsWorksheetHeaders[position() gt $activeCellPositionElements][office2003Spreadsheet:Data='value']/@ss:StyleID"/>

                <!-- elementList is rows on the sheet from row 2 onwards that do not have an empty first cell -->
                <xsl:variable name="elementList" select="$elementsWorksheet/office2003Spreadsheet:Row[position()>$startRow][empty(office2003Spreadsheet:Cell[1]/@ss:Index)]"/>

                <xsl:variable name="elementIdList" select="$elementList/cityEHRFunction:CreateID(office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data)"/>
                <xsl:variable name="distinctElementIdList" select="distinct-values($elementIdList)"/>


                <!-- === The CityEHR classes used in this ontology -->
                <!-- List of element classes is found from the first value cell after the $activeCellPositionElements for elements of type enumeratedClass only 
                     The list of displayName/xalue pairs should contain values of class:node or just class.
                     The value has @ss:StyleID = $valueStyle
                     tokenize splits the valuae into class:node - just need [1] of yjem to get the class -->

                <xsl:variable name="enumeratedClassElementList" select="$elementList[position() gt 1][office2003Spreadsheet:Cell/office2003Spreadsheet:Data = 'enumeratedClass']"/>
                <xsl:variable name="elementValueClasses" select="$enumeratedClassElementList/office2003Spreadsheet:Cell[@ss:StyleID = $valueStyle]/tokenize(office2003Spreadsheet:Data,':')[1]"/>

                <!-- elementValueClasses may contain repeats, so we need to filter those out before asserting each class -->
                <xsl:for-each select="distinct-values($elementValueClasses)">
                    <xsl:variable name="class" select="."/>

                    <xsl:variable name="classIRI" select="cityEHRFunction:getIRI('#CityEHR:Class:',$class)"/>
                    <Declaration>
                        <NamedIndividual IRI="{$classIRI}"/>
                    </Declaration>

                    <ClassAssertion>
                        <Class IRI="#CityEHR:Class"/>
                        <NamedIndividual IRI="{$classIRI}"/>
                    </ClassAssertion>
                </xsl:for-each>


                <!-- === Iterate through the list of elements, asserting properties for each one -->
                <xsl:for-each select="$distinctElementIdList">
                    <xsl:variable name="elementId" select="."/>
                    <xsl:variable name="element" select="key('elementListKey',$elementId,$rootNode)[1]"/>
                    <xsl:variable name="elementIRI" select="cityEHRFunction:getIRI('#ISO-13606:Element:',$elementId)"/>

                    <!-- Generate error for any non-unique elementId -->
                    <xsl:variable name="repeatedElement" select="key('elementListKey',$elementId,$rootNode)[2]"/>
                    <xsl:if test="exists($repeatedElement) and $elementId!=''">
                        <xsl:variable name="repeatedElementCount" select="count(key('elementListKey',$elementId,$rootNode))"/>
                        <xsl:variable name="context" select="concat('Element: ',$elementId)"/>
                        <xsl:variable name="message" select="concat('Element id is not unique: ',$repeatedElementCount,' instances')"/>
                        <xsl:call-template name="generateError">
                            <xsl:with-param name="node" select="$repeatedElement"/>
                            <xsl:with-param name="context" select="$context"/>
                            <xsl:with-param name="message" select="$message"/>
                        </xsl:call-template>
                    </xsl:if>

                    <!-- Only process rows which have an elementId -->
                    <xsl:if test="$elementId!=''">
                        <!-- Declaration of the element -->
                        <Declaration>
                            <NamedIndividual IRI="{$elementIRI}"/>
                        </Declaration>

                        <ClassAssertion>
                            <Class IRI="#ISO-13606:Element"/>
                            <NamedIndividual IRI="{$elementIRI}"/>
                        </ClassAssertion>

                        <!-- The displayName is set in the cell position with first row title 'DisplayName' -->
                        <!--
                    <xsl:variable name="activeCellPositionDisplayName" as="xs:integer" select="count($elementsWorksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='DisplayName']/preceding-sibling::*) +1"/>
                    -->

                        <xsl:variable name="displayName">
                            <xsl:call-template name="getCellValue">
                                <xsl:with-param name="row" select="$element"/>
                                <xsl:with-param name="cellPosition" select="$activeCellPositionDisplayName"/>
                            </xsl:call-template>
                        </xsl:variable>

                        <!-- Set the assertion of the displayName for the element -->
                        <xsl:if test="$displayName != ''">

                            <xsl:variable name="termIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:',$displayName)"/>

                            <ObjectPropertyAssertion>
                                <ObjectProperty IRI="#hasDisplayName"/>
                                <NamedIndividual IRI="{$elementIRI}"/>
                                <NamedIndividual IRI="{$termIRI}"/>
                            </ObjectPropertyAssertion>

                        </xsl:if>

                        <!-- This element can be the root of another (i.e. a proxy element). -->

                        <xsl:variable name="rootOf">
                            <xsl:call-template name="getCellValue">
                                <xsl:with-param name="row" select="$element"/>
                                <xsl:with-param name="cellPosition" select="$activeCellPositionRootOf"/>
                            </xsl:call-template>
                        </xsl:variable>

                        <xsl:variable name="rootOfElementIRI" select="if ($rootOf ='' or $activeCellPositionRootOf = 1) then '' else concat('#ISO-13606:',$rootOf)"/>

                        <!-- Set the assertion of the rootOf property for the entry, but only if one is specified -->
                        <xsl:if test="$rootOfElementIRI != ''">
                            <ObjectPropertyAssertion>
                                <ObjectProperty IRI="#isRootOf"/>
                                <NamedIndividual IRI="{$elementIRI}"/>
                                <NamedIndividual IRI="{$rootOfElementIRI}"/>
                            </ObjectPropertyAssertion>
                        </xsl:if>


                        <!-- The dataType is set in the cell position with first row title 'Data Type' -->
                        <!--
                    <xsl:variable name="activeCellPositionDataType" as="xs:integer" select="count($elementsWorksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Data Type']/preceding-sibling::*) +1"/>
                    -->

                        <xsl:variable name="dataTypeSet">
                            <xsl:call-template name="getCellValue">
                                <xsl:with-param name="row" select="$element"/>
                                <xsl:with-param name="cellPosition" select="$activeCellPositionDataType"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <!-- dataType takes default value of 'string' if it has not been set in the spreadsheet -->
                        <xsl:variable name="dataType" select="if ($dataTypeSet='') then 'string' else $dataTypeSet"/>
                        <xsl:variable name="dataTypeIRI" select="cityEHRFunction:getIRI('#CityEHR:DataType:',$dataType)"/>

                        <!-- Set the assertion of the data type for the element -->

                        <ObjectPropertyAssertion>
                            <ObjectProperty IRI="#hasDataType"/>
                            <NamedIndividual IRI="{$elementIRI}"/>
                            <NamedIndividual IRI="{$dataTypeIRI}"/>
                        </ObjectPropertyAssertion>

                        <!-- The ElementType is set in the cell position with first row title 'Element Type' -->
                        <!--
                    <xsl:variable name="activeCellPositionElementType" as="xs:integer" select="count($elementsWorksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Element Type']/preceding-sibling::*) +1"/>
                    -->

                        <xsl:variable name="elementTypeSet">
                            <xsl:call-template name="getCellValue">
                                <xsl:with-param name="row" select="$element"/>
                                <xsl:with-param name="cellPosition" select="$activeCellPositionElementType"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <!-- ElementType takes default value of 'simpleType' if it has not been set in the spreadsheet -->
                        <xsl:variable name="elementTypeIRI" select="if ($elementTypeSet='') then '#CityEHR:ElementProperty:simpleType' else cityEHRFunction:getIRI('#CityEHR:ElementProperty:',$elementTypeSet)"/>

                        <ObjectPropertyAssertion>
                            <ObjectProperty IRI="#hasElementType"/>
                            <NamedIndividual IRI="{$elementIRI}"/>
                            <NamedIndividual IRI="{$elementTypeIRI}"/>
                        </ObjectPropertyAssertion>


                        <!-- The valueRequired is set in the cell position with first row title 'Value Required' -->
                        <!--
                    <xsl:variable name="activeCellPositionValueRequired" as="xs:integer" select="count($elementsWorksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Value Required']/preceding-sibling::*) +1"/>
                    -->

                        <xsl:variable name="valueRequiredSet">
                            <xsl:call-template name="getCellValue">
                                <xsl:with-param name="row" select="$element"/>
                                <xsl:with-param name="cellPosition" select="$activeCellPositionValueRequired"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <!-- valueRequired takes default value of 'Optional' if it has not been set in the spreadsheet -->
                        <xsl:variable name="valueRequiredIRI" select="if ($valueRequiredSet='') then '#CityEHR:ElementProperty:Optional' else cityEHRFunction:getIRI('#CityEHR:ElementProperty:',$valueRequiredSet)"/>

                        <ObjectPropertyAssertion>
                            <ObjectProperty IRI="#hasValueRequired"/>
                            <NamedIndividual IRI="{$elementIRI}"/>
                            <NamedIndividual IRI="{$valueRequiredIRI}"/>
                        </ObjectPropertyAssertion>


                        <!-- The Scope is set in the cell position with first row title 'Scope' -->
                        <!--
                    <xsl:variable name="activeCellPositionScope" as="xs:integer" select="count($elementsWorksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Scope']/preceding-sibling::*) +1"/>
                    -->

                        <xsl:variable name="scopeSet">
                            <xsl:call-template name="getCellValue">
                                <xsl:with-param name="row" select="$element"/>
                                <xsl:with-param name="cellPosition" select="$activeCellPositionScope"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <!-- scope takes default value of 'Defined' if it has not been set in the spreadsheet -->
                        <xsl:variable name="scopeIRI" select="if ($scopeSet='') then '#CityEHR:ElementProperty:Defined' else cityEHRFunction:getIRI('#CityEHR:ElementProperty:',$scopeSet)"/>

                        <ObjectPropertyAssertion>
                            <ObjectProperty IRI="#hasScope"/>
                            <NamedIndividual IRI="{$elementIRI}"/>
                            <NamedIndividual IRI="{$scopeIRI}"/>
                        </ObjectPropertyAssertion>



                        <!-- The units are set in the cell position with first row title 'Units' -->
                        <!--
                    <xsl:variable name="activeCellPositionUnit" as="xs:integer" select="count($elementsWorksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Units']/preceding-sibling::*) +1"/>
                    -->

                        <xsl:variable name="unit">
                            <xsl:call-template name="getCellValue">
                                <xsl:with-param name="row" select="$element"/>
                                <xsl:with-param name="cellPosition" select="$activeCellPositionUnit"/>
                            </xsl:call-template>
                        </xsl:variable>

                        <!-- Set the assertion of the units for the element.
                         The units are either a Unit:Id or Element:Id (taking the units of the specified element) -->
                        <xsl:if test="$unit != ''">
                            <xsl:variable name="unitPrefix" select="if (starts-with($unit,'Unit:')) then '#CityEHR:' else '#ISO-13606:'"/>
                            <xsl:variable name="unitIRI" select="concat($unitPrefix,$unit)"/>

                            <ObjectPropertyAssertion>
                                <ObjectProperty IRI="#hasUnit"/>
                                <NamedIndividual IRI="{$elementIRI}"/>
                                <NamedIndividual IRI="{$unitIRI}"/>
                            </ObjectPropertyAssertion>
                        </xsl:if>

                        <!-- The field length is set in the cell position with first row title 'Field Length' -->
                        <!--
                    <xsl:variable name="activeCellPositionFieldLength" as="xs:integer" select="count($elementsWorksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Field Length']/preceding-sibling::*) +1"/>
                    -->

                        <xsl:variable name="fieldLength">
                            <xsl:call-template name="getCellValue">
                                <xsl:with-param name="row" select="$element"/>
                                <xsl:with-param name="cellPosition" select="$activeCellPositionFieldLength"/>
                            </xsl:call-template>
                        </xsl:variable>

                        <xsl:if test="$fieldLength != ''">
                            <DataPropertyAssertion>
                                <DataProperty IRI="#hasFieldLength"/>
                                <NamedIndividual IRI="{$elementIRI}"/>
                                <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                                    <xsl:value-of select="$fieldLength"/>
                                </Literal>
                            </DataPropertyAssertion>
                        </xsl:if>

                        <!-- The value for default values is set in the cell position with first row title 'Default Value'.
                         This can be an experssion for calculation if just a value then it needs to be quoted. -->
                        <!--
                    <xsl:variable name="activeCellPositionDefaultValue" as="xs:integer" select="count($elementsWorksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Default Value']/preceding-sibling::*) +1"/>
                    -->

                        <xsl:variable name="defaultValue">
                            <xsl:call-template name="getCellValue">
                                <xsl:with-param name="row" select="$element"/>
                                <xsl:with-param name="cellPosition" select="$activeCellPositionDefaultValue"/>
                            </xsl:call-template>
                        </xsl:variable>

                        <xsl:if test="exists($defaultValue) and $defaultValue != ''">
                            <DataPropertyAssertion>
                                <DataProperty IRI="#hasDefaultValue"/>
                                <NamedIndividual IRI="{$elementIRI}"/>
                                <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                                    <xsl:value-of select="$defaultValue"/>
                                </Literal>
                            </DataPropertyAssertion>
                        </xsl:if>


                        <!-- The expression for calculated values is set in the cell position with first row title 'Calculated Value' -->
                        <!--
                    <xsl:variable name="activeCellPositionExpression" as="xs:integer" select="count($elementsWorksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Calculated Value']/preceding-sibling::*) +1"/>
                    -->

                        <xsl:variable name="expression">
                            <xsl:call-template name="getCellValue">
                                <xsl:with-param name="row" select="$element"/>
                                <xsl:with-param name="cellPosition" select="$activeCellPositionExpression"/>
                            </xsl:call-template>
                        </xsl:variable>

                        <xsl:if test="$expression != ''">
                            <DataPropertyAssertion>
                                <DataProperty IRI="#hasCalculatedValue"/>
                                <NamedIndividual IRI="{$elementIRI}"/>
                                <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                                    <xsl:value-of select="$expression"/>
                                </Literal>
                            </DataPropertyAssertion>
                        </xsl:if>


                        <!-- The expression for constraints on values is set in the cell position with first row title 'Constraints' -->
                        <!--
                    <xsl:variable name="activeCellPositionConstraints" as="xs:integer" select="count($elementsWorksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Constraints']/preceding-sibling::*) +1"/>
                    -->

                        <xsl:variable name="constraints">
                            <xsl:call-template name="getCellValue">
                                <xsl:with-param name="row" select="$element"/>
                                <xsl:with-param name="cellPosition" select="$activeCellPositionConstraints"/>
                            </xsl:call-template>
                        </xsl:variable>

                        <xsl:if test="$constraints != ''">
                            <DataPropertyAssertion>
                                <DataProperty IRI="#hasConstraints"/>
                                <NamedIndividual IRI="{$elementIRI}"/>
                                <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                                    <xsl:value-of select="$constraints"/>
                                </Literal>
                            </DataPropertyAssertion>
                        </xsl:if>


                        <!-- The conditions property is set in the cell position with first row title 'Conditions'. -->
                        <!--
                    <xsl:variable name="activeCellPositionConditions" as="xs:integer" select="count($elementsWorksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Conditions']/preceding-sibling::*) +1"/>
                    -->

                        <xsl:variable name="conditions">
                            <xsl:call-template name="getCellValue">
                                <xsl:with-param name="row" select="$element"/>
                                <xsl:with-param name="cellPosition" select="$activeCellPositionConditions"/>
                            </xsl:call-template>
                        </xsl:variable>

                        <xsl:if test="$conditions != ''">
                            <DataPropertyAssertion>
                                <DataProperty IRI="#hasConditions"/>
                                <NamedIndividual IRI="{$elementIRI}"/>
                                <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                                    <xsl:value-of select="$conditions"/>
                                </Literal>
                            </DataPropertyAssertion>
                        </xsl:if>


                        <!-- The list of enumerated values for the element starts at cell position with first row value 'Values' (activeCellPosition) 
                         Only need to process elements that are of type enumeratedValue, calculatedValue and enumeratedClass -->
                        <!--
                    <xsl:variable name="activeCellPositionElements" as="xs:integer" select="count($elementsWorksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Values']/preceding-sibling::*) +1"/>
                    -->

                        <!-- Get actual position of the cell we want -->
                        <xsl:variable name="valueListPosition">
                            <xsl:call-template name="getCellPosition">
                                <xsl:with-param name="row" select="$element"/>
                                <xsl:with-param name="cellPosition" select="$activeCellPositionElements"/>
                            </xsl:call-template>
                        </xsl:variable>

                        <!-- Get the style used in the first enumerated cell (will be used to differentiate displayNames from values).
                         The first (in fact all) values in the spreadhseet must have a displayName
                         If the first cell has an ss:Index element then it means the first displyaName was empty, so raise a warning (later) -->

                        <xsl:variable name="displayNameDefined" select="exists($element/office2003Spreadsheet:Cell[position() = $valueListPosition][not(@ss:Index)])"/>
                        <xsl:variable name="thisDisplayNameStyle" select="if ($displayNameDefined) then $element/office2003Spreadsheet:Cell[position() = $valueListPosition][not(@ss:Index)]/@ss:StyleID else ''"/>

                        <!-- First Value (not displayName) is used to set CityEHR:Class if the Element Type is enumeratedClass.
                         The first value is at $activeCellPositionExpression+1
                         The value must be of the form Class or Class:Node
                         
                         Note that these variables are set here for all elements but are only used for enumeratedClass elements.
                         This is because they heed to be used in the general processing below.
                    -->
                        <xsl:variable name="firstValuePosition" as="xs:integer" select="xs:integer($activeCellPositionElements + 1)"/>
                        <xsl:variable name="firstValue">
                            <xsl:call-template name="getCellValue">
                                <xsl:with-param name="row" select="$element"/>
                                <xsl:with-param name="cellPosition" select="$firstValuePosition"/>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:variable name="firstValueClass" select="tokenize($firstValue,':')[1]"/>


                        <!-- For enumeratedClass, assert the class value, if present (which it should be) -->
                        <xsl:if test="$elementTypeSet = 'enumeratedClass'">
                            <xsl:if test="$firstValueClass!=''">
                                <xsl:variable name="classIRI" select="cityEHRFunction:getIRI('#CityEHR:Class:',$firstValueClass)"/>
                                <ObjectPropertyAssertion>
                                    <ObjectProperty IRI="#hasValueClass"/>
                                    <NamedIndividual IRI="{$elementIRI}"/>
                                    <NamedIndividual IRI="{$classIRI}"/>
                                </ObjectPropertyAssertion>
                            </xsl:if>
                            <xsl:if test="$firstValueClass=''">
                                <xsl:variable name="context" select="concat('Element: ',$elementId)"/>
                                <xsl:variable name="message" select="'No class set for enumeratedClass element'"/>
                                <xsl:call-template name="generateWarning">
                                    <xsl:with-param name="node" select="$element"/>
                                    <xsl:with-param name="context" select="$context"/>
                                    <xsl:with-param name="message" select="$message"/>
                                </xsl:call-template>
                            </xsl:if>
                        </xsl:if>


                        <!-- Process the element values -->

                        <!-- Value is a CityEHR:Value if the Element Type is enumeratedValue, enumeratedClass
                         Enumerate only through cells with displayNameStyle so that each pair of cells of processed together.
                         
                         For enumeratedValue
                         Must have an elementValueDisplayName - elementValue is optional (and defaults to elementValueDisplayName if not set)
                         
                         For enumeratedClass
                         Must have an elementValue - elementValueDisplayName is optional
                         elementValue is of the form class:entryNode or just class if there is no entry node
                         
                    -->
                        <!-- Must have display names on values of these types -->
                        <xsl:if test="$elementTypeSet = ('enumeratedValue','enumeratedClass','range','url') and not($displayNameDefined)">
                            <xsl:variable name="context" select="concat('Element: ',$elementId)"/>
                            <xsl:variable name="message" select="concat('Display names must be set for all values of elements of type ',$elementTypeSet)"/>
                            <xsl:call-template name="generateWarning">
                                <xsl:with-param name="node" select="$element"/>
                                <xsl:with-param name="context" select="$context"/>
                                <xsl:with-param name="message" select="$message"/>
                            </xsl:call-template>
                        </xsl:if>


                        <!-- The style for the first value displayName in the row must be the same as the one defined in the sheet header row
                         If not, then warn that there is a format problem -->
                        <xsl:if test="$elementTypeSet = ('enumeratedValue','enumeratedClass','range','url') and not($thisDisplayNameStyle = $displayNameStyle)">
                            <xsl:variable name="context" select="concat('Element: ',$elementId)"/>
                            <xsl:variable name="message" select="'First displayname style (',$thisDisplayNameStyle,') is not set correctly. Check spreadsheet formatting.'"/>
                            <xsl:call-template name="generateWarning">
                                <xsl:with-param name="node" select="$element"/>
                                <xsl:with-param name="context" select="$context"/>
                                <xsl:with-param name="message" select="$message"/>
                            </xsl:call-template>
                        </xsl:if>

                        <!-- Set values for these specific element types, but only if formatting is correct -->
                        <xsl:if test="$elementTypeSet = ('enumeratedValue','enumeratedClass','calculatedValue','range','url') and $thisDisplayNameStyle=$displayNameStyle">
                            <xsl:for-each select="$element/office2003Spreadsheet:Cell[position() >= $valueListPosition][@ss:StyleID=$thisDisplayNameStyle]">
                                <xsl:variable name="elementValueCell" select="."/>

                                <xsl:variable name="elementValueDisplayName" select="normalize-space(./office2003Spreadsheet:Data)"/>

                                <!-- The declared value is the one entered in the spreadsheet, which may be blank -->
                                <xsl:variable name="elementValueDeclared" select="if (following-sibling::office2003Spreadsheet:Cell[1][@ss:StyleID != $thisDisplayNameStyle][normalize-space(office2003Spreadsheet:Data) != '']) then following-sibling::office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data else ''"/>

                                <!-- Only process cases where either displayName or value is not blank -->
                                <xsl:if test="concat($elementValueDisplayName,$elementValueDeclared) !=''">

                                    <!-- For enumeratedClass, range, url must have a value, for enumeratedValue must have a displayName -->
                                    <xsl:variable name="elementValueSuffix" select="if ($elementTypeSet='enumeratedValue') then $elementValueDisplayName else $elementValueDeclared"/>

                                    <!-- And now check that the element suffix is not blank before processing, otherwise raise a warning -->
                                    <xsl:if test="$elementValueSuffix!=''">

                                        <!-- For enumeratedValue with no value declared, the value is set to the displayName.
                                         For enumeratedClass the value is the node in the class hierarchy - note that this requires the value to be of the form class:node which is not checked here -->
                                        <xsl:variable name="elementValue" select="if ($elementTypeSet='enumeratedValue' and $elementValueDeclared='') then $elementValueDisplayName else if ($elementTypeSet='enumeratedClass') then concat('#CityEHR:Class:',$elementValueDeclared) else $elementValueDeclared"/>

                                        <xsl:variable name="elementValueId" select="concat($elementId,':',$elementValueSuffix)"/>
                                        <xsl:variable name="elementValueIRI" select="cityEHRFunction:getIRI('#ISO-13606:Data:',$elementValueId)"/>

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
                                            <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
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

                                    </xsl:if>

                                    <!-- Output warning if elementSuffix was blank -->
                                    <xsl:if test="$elementValueSuffix = ''">
                                        <xsl:variable name="context" select="concat('Element: ',$elementId)"/>
                                        <xsl:variable name="message" select="if ($elementTypeSet='enumeratedValue') then 'A display name must be set for all values of this enumeratedValue element' else ' A value must be set for all values of this element'"/>
                                        <xsl:call-template name="generateWarning">
                                            <xsl:with-param name="node" select="$elementValueCell"/>
                                            <xsl:with-param name="context" select="$context"/>
                                            <xsl:with-param name="message" select="$message"/>
                                        </xsl:call-template>
                                    </xsl:if>

                                </xsl:if>
                                <!-- End processing of element value -->
                            </xsl:for-each>
                            <!-- End iteration through values -->
                        </xsl:if>


                        <!-- === NOT DOING THIS ANY MORE 15/07/2013 -->
                        <!-- First Value is an CityEHR:Class if the Element Type is enumeratedClass 
                         Second value (if present) is the entry node for the class -->
                        <xsl:if test="$elementTypeSet = 'enumeratedClassX'">
                            <!-- Assert the class value, if present (which it should be) -->
                            <xsl:variable name="class" select="normalize-space($element/office2003Spreadsheet:Cell[position() = $valueListPosition]/office2003Spreadsheet:Data)"/>
                            <xsl:variable name="classIRI" select="cityEHRFunction:getIRI('#CityEHR:Class:',$class)"/>
                            <xsl:if test="$class!=''">
                                <ObjectPropertyAssertion>
                                    <ObjectProperty IRI="#hasValueClass"/>
                                    <NamedIndividual IRI="{$elementIRI}"/>
                                    <NamedIndividual IRI="{$classIRI}"/>
                                </ObjectPropertyAssertion>
                                <xsl:variable name="node" select="normalize-space($element/office2003Spreadsheet:Cell[position() = $valueListPosition +1]/office2003Spreadsheet:Data)"/>
                                <xsl:variable name="nodeIRI" select="concat('#CityEHR:Class:',cityEHRFunction:CreateID($class),':',cityEHRFunction:CreateID($node))"/>
                                <!-- Assert the node within the class, if present (which it may or may not be) -->
                                <xsl:if test="$node!=''">
                                    <DataPropertyAssertion>
                                        <DataProperty IRI="#hasValue"/>
                                        <NamedIndividual IRI="{$elementIRI}"/>
                                        <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                                            <xsl:value-of select="$nodeIRI"/>
                                        </Literal>
                                    </DataPropertyAssertion>
                                </xsl:if>
                            </xsl:if>
                        </xsl:if>
                    </xsl:if>
                </xsl:for-each>

                <!-- Iteration through Elements -->
            </xsl:for-each>
            <!-- Finished processing the Elements sheet-->



            <!-- === The Units for this ontology === 
                
                For each Unit we need to:
                
                Declare an individual
                Assert the individual as a member of the CityEHR:Unit class
                Set the display name for the Unit using the hasDisplayName object property
                Set the values for the Unit using the hasValue object property
                
                In the spreadhseet, each row represents a unit, with the following cells:
                
                [1] The unitId
                [2] Display Name for the Unit
                [-]
                
                ==================================== -->


            <xsl:for-each select="office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Units']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[position()>$startRow]">
                <!-- UnitId is in the first column - must not have a ss:Index attribute -->
                <xsl:variable name="unitId" select="if (./office2003Spreadsheet:Cell[1]/@ss:Index) then '' else cityEHRFunction:CreateID(./office2003Spreadsheet:Cell[1]/office2003Spreadsheet:Data)"/>
                <!-- Only process rows that have a UnitId -->
                <xsl:if test="$unitId != ''">
                    <xsl:variable name="unitIRI" select="cityEHRFunction:getIRI('#CityEHR:Unit:',$unitId)"/>

                    <Declaration>
                        <NamedIndividual IRI="{$unitIRI}"/>
                    </Declaration>

                    <ClassAssertion>
                        <Class IRI="#CityEHR:Unit"/>
                        <NamedIndividual IRI="{$unitIRI}"/>
                    </ClassAssertion>

                    <!-- The displayName is set in the cell position with first row title 'DisplayName' -->
                    <xsl:variable name="activeCellPositionDisplayName" as="xs:integer" select="count(/office2003Spreadsheet:Workbook/ss:Worksheet[@ss:Name='Units']/office2003Spreadsheet:Table/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='DisplayName']/preceding-sibling::*) +1"/>

                    <xsl:variable name="displayName">
                        <xsl:call-template name="getCellValue">
                            <xsl:with-param name="row" select="."/>
                            <xsl:with-param name="cellPosition" select="$activeCellPositionDisplayName"/>
                        </xsl:call-template>
                    </xsl:variable>

                    <!-- Set the assertion of the displayName for the element -->
                    <xsl:if test="$displayName != ''">
                        <xsl:variable name="termIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:',$displayName)"/>
                        <ObjectPropertyAssertion>
                            <ObjectProperty IRI="#hasDisplayName"/>
                            <NamedIndividual IRI="{$unitIRI}"/>
                            <NamedIndividual IRI="{$termIRI}"/>
                        </ObjectPropertyAssertion>
                    </xsl:if>

                </xsl:if>
                <!-- End of processing for Unit with UnitId set -->

            </xsl:for-each>
            <!-- Iteration through Units -->


        </Ontology>

    </xsl:template>


    <!-- ====================================================================
        Generate assertions for a Composition.
        This covers the common assertions for the following types of composition:
        
            Form
            Letter
            Message
            Order
            Booking
            Prescription
            Pathway
        
        ==================================================================== -->
    <xsl:template name="generateComposition" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="worksheet"/>
        <xsl:param name="row"/>
        <xsl:param name="compositionId"/>
        <xsl:param name="compositionTypeIRI"/>
        <xsl:param name="compositionIRI"/>

        <xsl:variable name="compositionDisplayName" select="$row/office2003Spreadsheet:Cell[2]/office2003Spreadsheet:Data"/>
        <xsl:variable name="termIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:',$compositionDisplayName)"/>

        <Declaration>
            <NamedIndividual IRI="{$compositionIRI}"/>
        </Declaration>

        <ClassAssertion>
            <Class IRI="{$compositionTypeIRI}"/>
            <NamedIndividual IRI="{$compositionIRI}"/>
        </ClassAssertion>

        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasDisplayName"/>
            <NamedIndividual IRI="{$compositionIRI}"/>
            <NamedIndividual IRI="{$termIRI}"/>
        </ObjectPropertyAssertion>


        <!-- The rank property is set in the cell position with first row title 'Rank' -->
        <xsl:variable name="activeCellPositionRank" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Rank']/preceding-sibling::*) +1"/>

        <!-- If the Rank property does not exist, then activeCellPositionRank will be 1.
        Don't assert the Rank property if it doesn;t exist -->

        <xsl:if test="$activeCellPositionRank > 1">
            <xsl:variable name="rankSet">
                <xsl:call-template name="getCellValue">
                    <xsl:with-param name="row" select="$row"/>
                    <xsl:with-param name="cellPosition" select="$activeCellPositionRank"/>
                </xsl:call-template>
            </xsl:variable>

            <!-- rank takes default value of '1' if it has not been set in the spreadsheet -->
            <xsl:variable name="rank" select="if ($rankSet='') then '1' else $rankSet"/>
            <xsl:if test="$rankSet=''">
                <xsl:variable name="context" select="concat('Composition: ',$compositionId)"/>
                <xsl:variable name="message" select="'Rank not defined - set default of 1'"/>
                <xsl:call-template name="generateWarning">
                    <xsl:with-param name="node" select="$compositionId"/>
                    <xsl:with-param name="context" select="$context"/>
                    <xsl:with-param name="message" select="$message"/>
                </xsl:call-template>
            </xsl:if>

            <DataPropertyAssertion>
                <DataProperty IRI="#hasRank"/>
                <NamedIndividual IRI="{$compositionIRI}"/>
                <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                    <xsl:value-of select="$rank"/>
                </Literal>
            </DataPropertyAssertion>
        </xsl:if>


        <!-- The list of Sections starts at cell position with first row title 'Sections' (activeCellPosition) -->
        <xsl:variable name="activeCellPositionSections" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Sections']/preceding-sibling::*) +1"/>

        <!-- Get actual position of the cell where sections list starts -->
        <xsl:variable name="sectionsListPosition">
            <xsl:call-template name="getCellPosition">
                <xsl:with-param name="row" select="$row"/>
                <xsl:with-param name="cellPosition" select="$activeCellPositionSections"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- Set the contents list -->
        <xsl:variable name="contentsList" select="$row/office2003Spreadsheet:Cell[position()>=$sectionsListPosition]/office2003Spreadsheet:Data[normalize-space(.) != '']"/>

        <!-- Data property assertion for the contents list -->
        <xsl:if test="exists($contentsList)">
            <DataPropertyAssertion>
                <DataProperty IRI="#hasContentsList"/>
                <NamedIndividual IRI="{$compositionIRI}"/>
                <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                    <xsl:value-of select="cityEHRFunction:generateContentsList($compositionIRI,$contentsList)"/>
                </Literal>
            </DataPropertyAssertion>
        </xsl:if>


        <!-- Iterate through the contents list -->
        <xsl:for-each select="$contentsList">

            <xsl:variable name="sectionId" select="."/>
            <xsl:variable name="sectionIRI" select="concat('#ISO-13606:',$sectionId)"/>

            <xsl:if test="exists(key('contentsList',$sectionId))">
                <ObjectPropertyAssertion>
                    <ObjectProperty IRI="#hasContent"/>
                    <NamedIndividual IRI="{$compositionIRI}"/>
                    <NamedIndividual IRI="{$sectionIRI}"/>
                </ObjectPropertyAssertion>
            </xsl:if>

            <xsl:if test="empty(key('contentsList',$sectionId))">
                <xsl:variable name="context" select="concat('Composition content: ',$compositionId)"/>
                <xsl:variable name="message" select="concat('Content node: ',$sectionId,' not defined')"/>
                <xsl:call-template name="generateWarning">
                    <xsl:with-param name="node" select="$sectionId"/>
                    <xsl:with-param name="context" select="$context"/>
                    <xsl:with-param name="message" select="$message"/>
                </xsl:call-template>
            </xsl:if>

        </xsl:for-each>

    </xsl:template>


    <!-- ====================================================================
        Generate assertions for a Section.
        This covers the common assertions for the following types of section:
        
        Sections
        Sections (Tasks)
        
        
        ==================================================================== -->
    <xsl:template name="generateSection" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="worksheet"/>
        <xsl:param name="row"/>
        <xsl:param name="sectionId"/>
        <xsl:param name="sectionIRI"/>

        <Declaration>
            <NamedIndividual IRI="{$sectionIRI}"/>
        </Declaration>

        <ClassAssertion>
            <Class IRI="#ISO-13606:Section"/>
            <NamedIndividual IRI="{$sectionIRI}"/>
        </ClassAssertion>

        <!-- The displayName is set in the cell position with first row title 'DisplayName' -->
        <xsl:variable name="activeCellPositionDisplayName" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='DisplayName']/preceding-sibling::*) +1"/>

        <xsl:variable name="displayName">
            <xsl:call-template name="getCellValue">
                <xsl:with-param name="row" select="$row"/>
                <xsl:with-param name="cellPosition" select="$activeCellPositionDisplayName"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- Set the assertion of the displayName for the section, if it has one -->
        <xsl:if test="$displayName != ''">
            <xsl:variable name="termIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:',$displayName)"/>
            <ObjectPropertyAssertion>
                <ObjectProperty IRI="#hasDisplayName"/>
                <NamedIndividual IRI="{$sectionIRI}"/>
                <NamedIndividual IRI="{$termIRI}"/>
            </ObjectPropertyAssertion>
        </xsl:if>
        
        
        <!-- The hint is set in the cell position with first row title 'Hint' -->
        <xsl:variable name="activeCellPositionHint" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Hint']/preceding-sibling::*) +1"/>
        
        <xsl:variable name="hint">
            <xsl:call-template name="getCellValue">
                <xsl:with-param name="row" select="$row"/>
                <xsl:with-param name="cellPosition" select="$activeCellPositionHint"/>
            </xsl:call-template>
        </xsl:variable>
        
        <!-- Set the assertion of the hint for the section, if it has one -->
        <xsl:if test="$hint != ''">
            <DataPropertyAssertion>
                <DataProperty IRI="#hasHint"/>
                <NamedIndividual IRI="{$sectionIRI}"/>
                <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                    <xsl:value-of select="$hint"/>
                </Literal>
            </DataPropertyAssertion>
        </xsl:if>
        
 
        <!-- The alert is set in the cell position with first row title 'Alert' -->
        <xsl:variable name="activeCellPositionAlert" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Alert']/preceding-sibling::*) +1"/>
        
        <xsl:variable name="alert">
            <xsl:call-template name="getCellValue">
                <xsl:with-param name="row" select="$row"/>
                <xsl:with-param name="cellPosition" select="$activeCellPositionAlert"/>
            </xsl:call-template>
        </xsl:variable>
        
        <!-- Set the assertion of the alert for the section, if it has one -->
        <xsl:if test="$alert != ''">
            <DataPropertyAssertion>
                <DataProperty IRI="#hasAlert"/>
                <NamedIndividual IRI="{$sectionIRI}"/>
                <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                    <xsl:value-of select="$alert"/>
                </Literal>
            </DataPropertyAssertion>
        </xsl:if>
        
        

        <!-- The list of Contents (Sections and Entries) starts at cell position with first row title 'Contents' (activeCellPosition)
            Each content item is either a section or an entry, as determined by the start of its ID being Section: or Entry:
        -->

        <xsl:variable name="activeCellPositionContents" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Contents']/preceding-sibling::*) +1"/>

        <!-- Get actual position of the cell where contents list starts -->
        <xsl:variable name="contentsListPosition">
            <xsl:call-template name="getCellPosition">
                <xsl:with-param name="row" select="$row"/>
                <xsl:with-param name="cellPosition" select="$activeCellPositionContents"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- Set the contents list -->
        <xsl:variable name="contentsList" select="$row/office2003Spreadsheet:Cell[position() >= $contentsListPosition]/office2003Spreadsheet:Data[normalize-space(.) != '']"/>


        <!-- Data property assertion for the contents list -->
        <xsl:if test="exists($contentsList)">
            <DataPropertyAssertion>
                <DataProperty IRI="#hasContentsList"/>
                <NamedIndividual IRI="{$sectionIRI}"/>
                <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                    <xsl:value-of select="cityEHRFunction:generateContentsList($sectionIRI,$contentsList)"/>
                </Literal>
            </DataPropertyAssertion>
        </xsl:if>

        <!-- Iterate through the contents list -->
        <xsl:for-each select="$contentsList">
            <xsl:variable name="contentId" select="."/>
            <xsl:variable name="contentIRI" select="concat('#ISO-13606:',$contentId)"/>

            <xsl:if test="exists(key('contentsList',$contentId)) and $contentIRI!=$sectionIRI">
                <ObjectPropertyAssertion>
                    <ObjectProperty IRI="#hasContent"/>
                    <NamedIndividual IRI="{$sectionIRI}"/>
                    <NamedIndividual IRI="{$contentIRI}"/>
                </ObjectPropertyAssertion>
            </xsl:if>

            <xsl:if test="empty(key('contentsList',$contentId))">
                <xsl:variable name="context" select="concat('Section content: ',$sectionId)"/>
                <xsl:variable name="message" select="concat('Content node: ',$contentId,' not defined')"/>
                <xsl:call-template name="generateWarning">
                    <xsl:with-param name="node" select="$contentId"/>
                    <xsl:with-param name="context" select="$context"/>
                    <xsl:with-param name="message" select="$message"/>
                </xsl:call-template>
            </xsl:if>

            <!-- Warning if section contains itself -->
            <xsl:if test="$contentIRI=$sectionIRI">
                <xsl:variable name="context" select="concat('Section content: ',$sectionId)"/>
                <xsl:variable name="message" select="concat('Content node: ',$sectionId,' cannot contain itself')"/>
                <xsl:call-template name="generateWarning">
                    <xsl:with-param name="node" select="$contentId"/>
                    <xsl:with-param name="context" select="$context"/>
                    <xsl:with-param name="message" select="$message"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>

        <!-- The layout property is set in the cell position with first row title 'Layout'.
             If the property doesn't exist then activeCellPosition will be 1 -->
        <xsl:variable name="activeCellPositionLayout" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Layout']/preceding-sibling::*) +1"/>

        <xsl:variable name="layoutSet">
            <xsl:call-template name="getCellValue">
                <xsl:with-param name="row" select="$row"/>
                <xsl:with-param name="cellPosition" select="$activeCellPositionLayout"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- layout takes default value of 'Ranked' if it has not been set in the spreadsheet -->
        <xsl:variable name="layout" select="if ($layoutSet='' or $activeCellPositionLayout=1) then 'Ranked' else $layoutSet"/>

        <DataPropertyAssertion>
            <DataProperty IRI="#hasLayout"/>
            <NamedIndividual IRI="{$sectionIRI}"/>
            <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                <xsl:value-of select="$layout"/>
            </Literal>
        </DataPropertyAssertion>


        <!-- The rendition property is set in the cell position with first row title 'Rendition' -->
        <xsl:variable name="activeCellPositionRendition" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Rendition']/preceding-sibling::*) +1"/>

        <xsl:variable name="renditionSet">
            <xsl:call-template name="getCellValue">
                <xsl:with-param name="row" select="$row"/>
                <xsl:with-param name="cellPosition" select="$activeCellPositionRendition"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- rendition takes default value of '' if it has not been set in the spreadsheet -->
        <!--
        <xsl:variable name="renditionIRI" select="if ($renditionSet='' or $activeCellPositionRendition=1) then '#CityEHR:EntryProperty:Form' else cityEHRFunction:getIRI('#CityEHR:EntryProperty:',$renditionSet)"/>
        -->
        <xsl:variable name="renditionIRI" select="if ($renditionSet='' or $activeCellPositionRendition=1) then '' else cityEHRFunction:getIRI('#CityEHR:EntryProperty:',$renditionSet)"/>

        <!-- Set the assertion of the Rendition property for the section.
        Only assert if it has been set in the spreadsheet -->

        <xsl:if test="$renditionIRI != ''">
            <ObjectPropertyAssertion>
                <ObjectProperty IRI="#hasRendition"/>
                <NamedIndividual IRI="{$sectionIRI}"/>
                <NamedIndividual IRI="{$renditionIRI}"/>
            </ObjectPropertyAssertion>
        </xsl:if>


        <!-- The conditions property is set in the cell position with first row title 'Conditions'. -->
        <xsl:variable name="activeCellPositionConditions" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Conditions']/preceding-sibling::*) +1"/>

        <xsl:variable name="conditions">
            <xsl:call-template name="getCellValue">
                <xsl:with-param name="row" select="$row"/>
                <xsl:with-param name="cellPosition" select="$activeCellPositionConditions"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:if test="$conditions != ''">
            <DataPropertyAssertion>
                <DataProperty IRI="#hasConditions"/>
                <NamedIndividual IRI="{$sectionIRI}"/>
                <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                    <xsl:value-of select="$conditions"/>
                </Literal>
            </DataPropertyAssertion>
        </xsl:if>


        <!-- The pre-conditions property is set in the cell position with first row title 'Pre-conditions'. -->
        <xsl:variable name="activeCellPositionPreConditions" as="xs:integer" select="count($worksheet/office2003Spreadsheet:Row[1]/office2003Spreadsheet:Cell[office2003Spreadsheet:Data='Pre-conditions']/preceding-sibling::*) +1"/>

        <xsl:variable name="preConditions">
            <xsl:call-template name="getCellValue">
                <xsl:with-param name="row" select="$row"/>
                <xsl:with-param name="cellPosition" select="$activeCellPositionPreConditions"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:if test="$preConditions != ''">
            <DataPropertyAssertion>
                <DataProperty IRI="#hasPreConditions"/>
                <NamedIndividual IRI="{$sectionIRI}"/>
                <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral">
                    <xsl:value-of select="$preConditions"/>
                </Literal>
            </DataPropertyAssertion>
        </xsl:if>

    </xsl:template>



    <!-- ===============================================================
         Generate assertions for an element
         =============================================================== -->



    <!-- ====================================================================
         Get the value from a row contained in cell at the specified position 
         Input is the row and the cell position.
               
         If the cell we are looking for contains a blank value, or is not present, then either there will be another ss:Index="X" (X > cellPosition) cell before we have stepped forward the
         required number of cells, or we will run out of cells in the row.
         
         If the actual cell position returned is '1' then the value we are looking for does not exist on the spreadhseet.
         ==================================================================== -->
    <xsl:template name="getCellValue">
        <xsl:param name="row"/>
        <xsl:param name="cellPosition"/>

        <!-- Get actual position of the cell we want -->
        <xsl:variable name="actualCellPosition">
            <xsl:call-template name="getCellPosition">
                <xsl:with-param name="row" select="$row"/>
                <xsl:with-param name="cellPosition" select="$cellPosition"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- Cell is blank if actualCellPosition is '1' or there is another skipped cell before the one we are lookng for -->
        <xsl:variable name="blankCell" select="if ($actualCellPosition='1' or  $row/office2003Spreadsheet:Cell[position() &lt;= $actualCellPosition][@ss:Index &gt; $cellPosition]) then 'true' else 'false'"/>

        <!-- Get value of cell at position - will be blank if there are not enough cells in the row -->
        <xsl:if test="$blankCell = 'false'">
            <xsl:value-of select="normalize-space($row/office2003Spreadsheet:Cell[position() = $actualCellPosition]/office2003Spreadsheet:Data)"/>
        </xsl:if>

    </xsl:template>


    <!-- ====================================================================
        Get the actual position of a cell in a row, given the cell position in the spreadsheet 
        Input is the row and the cell position.
        
        The cell we want is at cellPosition in the spreadsheet, but there may be cells missing in the XML which uses the attribute ss:Index="X" to 
        indicate the cell number when some have been missed out. So to get the actual position of the cell in the row we need to get the position of the greatest
        X < cellPosition with ss:Index="X", then step forward cellPosition-X cells to get to the acutal position. If X=0 (i.e. no ss:Index="X" attributes on cells before 
        position cellPosition) then we just need the cellPosition cell in the XML. 

        ==================================================================== -->
    <xsl:template name="getCellPosition">
        <xsl:param name="row"/>
        <xsl:param name="cellPosition"/>

        <!-- Get the positon value of the last skipped cell before the one we are looking for -->
        <xsl:variable name="lastSkippedCellValue" as="xs:integer" select="if ($row/office2003Spreadsheet:Cell[@ss:Index &lt;= $cellPosition]) then ($row/office2003Spreadsheet:Cell[@ss:Index &lt;= $cellPosition])[last()]/@ss:Index else 0"/>

        <!-- Get the position in the row of the last skipped cell -->
        <xsl:variable name="lastSkippedCellPosition" as="xs:integer" select="if ($lastSkippedCellValue>0) then count($row/office2003Spreadsheet:Cell[@ss:Index=$lastSkippedCellValue]/preceding-sibling::*) +1 else 0"/>

        <!-- Get the position in the row of the cell we are looking for, assuming it is not blank -->
        <xsl:variable name="actualPosition" as="xs:integer" select="if ($lastSkippedCellValue=0) then xs:integer($cellPosition) else xs:integer($lastSkippedCellPosition + $cellPosition - $lastSkippedCellValue)"/>

        <!-- Output the actual position -->
        <xsl:value-of select="$actualPosition"/>

    </xsl:template>


    <!-- ====================================================================
         Generate the contents list from a list of contentIds (of the form Section:SectionId). 
         The container (specified by the containerIRI of the form #ISO-13606:Section:SectionId) must not contain itself.
         It should only be necessary to check this for folders, sections and clusters which can have contents of the same type
         ==================================================================== -->

    <xsl:function name="cityEHRFunction:generateContentsList">
        <xsl:param name="containerIRI"/>
        <xsl:param name="contentsList"/>

        <xsl:variable name="containerId" select="substring-after($containerIRI,'#ISO-13606:')"/>

        <!-- Output the contents list -->
        <xsl:for-each select="$contentsList">
            <xsl:variable name="contentId" select="."/>
            <xsl:if test="$containerId!=$contentId">
                <xsl:variable name="contentIRI" select="concat('#ISO-13606:',$contentId)"/>
                <xsl:value-of select="$contentIRI"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:function>



</xsl:stylesheet>
