<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    MindMap2OWL-Module.xsl
    Input is a mind map (.mm XML format) with class hierarchy.
    Generates an OWl/XML ontology as per the cityEHR architecture.
    
    This module is designed to be called from MindMap2OWL.xsl or MindMap2OWLFile.xsl.
    Assumes that the variables applicationId, specialtyId and classId have been set.
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<!DOCTYPE stylesheet [
<!ENTITY rdf 
"&amp;rdf;">
]>

<!-- === Note: This version has &amp;rdf; replaced by rdf: -->
<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:cda="urn:hl7-org:v3"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:c="urn:schemas-microsoft-com:office:component:spreadsheet"
    xmlns:html="http://www.w3.org/TR/REC-html40" xmlns:o="urn:schemas-microsoft-com:office:office"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:office2003Spreadsheet="urn:schemas-microsoft-com:office:spreadsheet"
    xmlns:x2="http://schemas.microsoft.com/office/excel/2003/xml"
    xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
    xmlns:x="urn:schemas-microsoft-com:office:excel"
    xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">

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
    
    <!-- The root node of the Mind Map must be labelled as:
        
        cityEHR Base Application : cityEHR :: cityEHR Feature Demo : FeatureDemo :: Diagnosis : Diagnosis :: English : en-gb
        
        with Application, Specialty and Class as the three elements separated by :: -->

    <xsl:variable name="rootNode" select="/map[1]/node[1]"/>
    <xsl:variable name="rootLabel" select="$rootNode/@TEXT"/>
    <xsl:variable name="rootLabelTokens" select="tokenize($rootLabel,'::')"/>
    <xsl:variable name="applicationToken" select="normalize-space($rootLabelTokens[1])"/>
    <xsl:variable name="specialtyToken" select="normalize-space($rootLabelTokens[2])"/>
    <xsl:variable name="classToken" select="normalize-space($rootLabelTokens[3])"/>
    <xsl:variable name="languageToken" select="normalize-space($rootLabelTokens[4])"/>

    <!-- Set baseLanguageCode -->
    <xsl:variable name="baseLanguageCode"
        select="if ($languageToken) then normalize-space(substring-after($languageToken,':')) else 'en-gb'"/>

    <!-- Set the Application for this Information Model -->
    <xsl:variable name="applicationId"
        select="if ($applicationToken) then cityEHRFunction:CreateID(substring-after($applicationToken,':')) else ''"/>
    <xsl:variable name="applicationDisplayName"
        select="if ($applicationToken) then normalize-space(substring-before($applicationToken,':')) else ''"/>
    <xsl:variable name="modelOwner" select="'cityEHR'"/>

    <!-- Set the Specialty for this Information Model -->
    <xsl:variable name="specialtyId" select="if ($specialtyToken) then cityEHRFunction:CreateID(substring-after($specialtyToken,':')) else ''"/>
    <xsl:variable name="specialtyDisplayName"
        select="if ($specialtyToken) then normalize-space(substring-before($specialtyToken,':')) else ''"/>

    <!-- Set the Class for this Information Model -->
    <xsl:variable name="classId" select="if ($classToken) then cityEHRFunction:CreateID(substring-after($classToken,':')) else ''"/>
    <xsl:variable name="classDisplayName"
        select="if ($classToken) then normalize-space(substring-before($classToken,':')) else ''"/>
    <xsl:variable name="classIRI" select="concat('#CityEHR:Class:',$classId)"/>
    
    <!-- Set the pathSeparator for this Information Model -->
    <xsl:variable name="pathSeparator"
        select="'/'"/>

    <!-- Can only process spreadsheet if applicationId, specialtyId and classId are defined -->
    <xsl:variable name="processError" as="xs:string"
    select="if ($applicationId !='' and $specialtyId !='' and $classId !='' and $baseLanguageCode != '') then 'false' else 'true'"/>
    

    <xsl:template name="generateOWL">

        <!-- Output the DOCTYPE and document type declaration subset with entity definitions -->
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

        <xsl:comment> ===== cityEHR Ontology <xsl:value-of select="$classIRI"/> Contains class
            hierarchy and associated supplementary data sets. This OWL/XML file is generated by
            Spreadsheet2OWL.xsl which is part of the cityEHR. Copyright (C) 2013-2015 cityEHR
            Limited.
            ========================================================================================= </xsl:comment>
        <xsl:text disable-output-escaping="yes">           
        </xsl:text>

        <Ontology xmlns="http://www.w3.org/2002/07/owl#">            
            <!-- Copy attributes (including namespace declarations) from template -->
            <xsl:copy-of select="$cityEHRarchitecture/owl:Ontology/@*" copy-namespaces="no"/>
            
            <!-- Copy assertions from template -->
            <xsl:copy-of select="$cityEHRarchitecture/owl:Ontology/*" copy-namespaces="no"/>


            <!-- Annotations contain meta data about the ontology -->
            <xsl:comment> ===== Annotations contain meta data about the ontology
                =================================================== </xsl:comment>
            <xsl:text disable-output-escaping="yes">           
            </xsl:text>

            <Annotation>
                <AnnotationProperty abbreviatedIRI=":versionInfo"/>
                <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="rdf:PlainLiteral"> 1.0
                </Literal>
            </Annotation>
            <Annotation>
                <AnnotationProperty abbreviatedIRI="rdfs:label"/>
                <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="rdf:PlainLiteral"> cityEHR
                    Ontology - <xsl:value-of select="$classId"/>
                </Literal>
            </Annotation>

            <!-- === Declare Application, Specialty, Class and Language ============== 
                 ===================================================================== -->

            <!-- === The application for this ontology === 
                Corresponds to a top-level ISO-13606:EHR_Extract.
                
                The application must be present on the Configuration sheet.                
                $applicationId and $applicationDisplayName are set in the XSL that calls this module.
                
                Assert the individual
                Set its class to ISO-13606:EHR_Extract
                Set its displayName
                
            -->

            <xsl:comment> ===== Assertions related to the application for this ontology ===== </xsl:comment>
            <xsl:text disable-output-escaping="yes">           
            </xsl:text>

            <Declaration>
                <NamedIndividual IRI="{$applicationIRI}"/>
            </Declaration>

            <ClassAssertion>
                <Class IRI="#ISO-13606:EHR_Extract"/>
                <NamedIndividual IRI="{$applicationIRI}"/>
            </ClassAssertion>

            <DataPropertyAssertion>
                <DataProperty IRI="#hasOwner"/>
                <NamedIndividual IRI="{$applicationIRI}"/>
                <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="rdf:PlainLiteral">
                    <xsl:value-of select="$modelOwner"/>
                </Literal>
            </DataPropertyAssertion>

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

            <xsl:comment> ===== Assertions related to the clinical specialty for this ontology ===== </xsl:comment>
            <xsl:text disable-output-escaping="yes">           
            </xsl:text>
            
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


            <!-- === The class for this ontology === 
                Single individual as a member of the root class.
                
                The class must be present on the Configuration sheet.                
                $classId and $classDisplayName are set in the XSL that calls this module.
                
                Assert the individual
                Set its class to CityEHR:Class
                Set its displayName
            -->
            
            <xsl:if test="$classId">
                <xsl:variable name="classTermIRI"
                    select="cityEHRFunction:getIRI('#CityEHR:Term:',$classDisplayName)"/>
                
                <xsl:comment> ===== Assertions related to the class for this ontology ===== </xsl:comment>
                <xsl:text disable-output-escaping="yes">           
                </xsl:text>
                
                <Declaration>
                    <Class IRI="{$classIRI}"/>
                </Declaration>
                
                <SubClassOf>
                    <Class IRI="{$classIRI}"/>
                    <Class IRI="#CityEHR:Class"/>
                </SubClassOf>
                
                <Declaration>
                    <NamedIndividual IRI="{$classIRI}"/>
                </Declaration>
                
                <ClassAssertion>
                    <Class IRI="#CityEHR:Class"/>
                    <NamedIndividual IRI="{$classIRI}"/>
                </ClassAssertion>
                
                <ObjectPropertyAssertion>
                    <ObjectProperty IRI="#hasDisplayName"/>
                    <NamedIndividual IRI="{$classIRI}"/>
                    <NamedIndividual IRI="{$classTermIRI}"/>
                </ObjectPropertyAssertion>
                
                <!-- No need to declare the term, as it is picked up in the general declarations later on -->
            </xsl:if>



            <!-- The Language for this ontology -->
            <DataPropertyAssertion>
                <DataProperty IRI="#hasBaseLanguage"/>
                <NamedIndividual IRI="{$applicationIRI}"/>
                <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="rdf:PlainLiteral">
                    <xsl:value-of select="$baseLanguageCode"/>
                </Literal>
            </DataPropertyAssertion>



            <!-- === Declare all terms used in the ontology ======= 
                     ============================================== -->

            <xsl:comment> ===== Assertions related to the terms used in this ontology ===== </xsl:comment>
            <xsl:text disable-output-escaping="yes">           
            </xsl:text>

            <xsl:variable name="specialtyTerms"
                select="($applicationDisplayName,$specialtyDisplayName,$classDisplayName)"/>

            <!-- The displayName is the @TEXT attribute of each node -->
            <xsl:variable name="displayNameTerms"
                select="$rootNode/descendant::node/normalize-space(@TEXT)"/>

            <!-- allterms is a sequence of strings -->
            <xsl:variable name="allTerms" select="($specialtyTerms,$displayNameTerms)"/>

            <xsl:for-each select="distinct-values($allTerms)">
                <xsl:variable name="term" select="."/>
                <xsl:if test="$term != ''">
                    <xsl:variable name="termId" select="cityEHRFunction:CreateID($term)"/>
                    <xsl:variable name="termIRI"
                        select="cityEHRFunction:getIRI('#CityEHR:Term:',$termId)"/>
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
                        <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="rdf:PlainLiteral">
                            <xsl:value-of select="$term"/>
                        </Literal>
                    </DataPropertyAssertion>
                </xsl:if>
            </xsl:for-each>


            <!-- === The Class hierarchy for this ontology === 
                
                The Class hierarchy is represented as nested set of <node> elements
                               
                ==================================== -->
            <xsl:comment> ===== Assertions related to the class hierarchy represented in this
                ontology ===== </xsl:comment>
            <xsl:text disable-output-escaping="yes">           
            </xsl:text>

            <!-- Iterate through the level 1 (root) nodes -->
            <xsl:for-each select="$rootNode/node">

                <xsl:call-template name="outputNodeAssertions">
                    <xsl:with-param name="node" select="."/>
                    <xsl:with-param name="level" select="'1'"/>
                    <xsl:with-param name="childNodes" select="./node"/>
                    <xsl:with-param name="classIRI" select="$classIRI"/>
                </xsl:call-template>

            </xsl:for-each>

        </Ontology>
    </xsl:template>


    <!-- Template to output OWL assertions for a class node -->
    <xsl:template name="outputNodeAssertions">
        <xsl:param name="node"/>
        <xsl:param name="level"/>
        <xsl:param name="childNodes"/>
        <xsl:param name="classIRI"/>

        <xsl:variable name="nodeDisplayName" select="normalize-space($node/@TEXT)"/>
        <xsl:variable name="individualId" select="cityEHRFunction:CreateID($nodeDisplayName)"/>
        <xsl:variable name="individualIRI"
            select="cityEHRFunction:getIRI(concat($classIRI,':'),$individualId)"/>

        <Declaration xmlns="http://www.w3.org/2002/07/owl#">
            <NamedIndividual IRI="{$individualIRI}"/>
        </Declaration>

        <!-- Assert membership of class -->
        <ClassAssertion xmlns="http://www.w3.org/2002/07/owl#">
            <Class IRI="{$classIRI}"/>
            <NamedIndividual IRI="{$individualIRI}"/>
        </ClassAssertion>

        <!-- Set the assertion of the displayName for the individual -->
        <xsl:if test="$nodeDisplayName != ''">
            <xsl:variable name="termIRI"
                select="cityEHRFunction:getIRI('#CityEHR:Term:',$nodeDisplayName)"/>
            <ObjectPropertyAssertion xmlns="http://www.w3.org/2002/07/owl#">
                <ObjectProperty IRI="#hasDisplayName"/>
                <NamedIndividual IRI="{$individualIRI}"/>
                <NamedIndividual IRI="{$termIRI}"/>
            </ObjectPropertyAssertion>
        </xsl:if>

        <!-- Process children, including recursive call to  outputNodeAssertions -->
        <xsl:for-each select="$childNodes">
            <xsl:variable name="childNode" select="."/>
            <xsl:variable name="childDisplayName" select="normalize-space($childNode/@TEXT)"/>
            <xsl:variable name="childId" select="cityEHRFunction:CreateID($childDisplayName)"/>
            <xsl:variable name="childIRI"
                select="cityEHRFunction:getIRI(concat($classIRI,':') ,$childId)"/>

            <ObjectPropertyAssertion xmlns="http://www.w3.org/2002/07/owl#">
                <ObjectProperty IRI="#hasType"/>
                <NamedIndividual IRI="{$individualIRI}"/>
                <NamedIndividual IRI="{$childIRI}"/>
            </ObjectPropertyAssertion>

            <xsl:variable name="nextChildNodes" select="$childNode/node"/>
            <xsl:variable name="childNodeLevel"
                select="if (empty($nextChildNodes)) then '3' else '2'"/>
            <xsl:call-template name="outputNodeAssertions">
                <xsl:with-param name="node" select="."/>
                <xsl:with-param name="level" select="$childNodeLevel"/>
                <xsl:with-param name="childNodes" select="$nextChildNodes"/>
                <xsl:with-param name="classIRI" select="$classIRI"/>
            </xsl:call-template>
        </xsl:for-each>

    </xsl:template>




</xsl:stylesheet>
