<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    OWLUtilities.xsl
    Included as a module in GraphML2OWL.xsl, OWL2Message and OWL2RuntimeFiles.xsl
    
    Contains named templates and functions used to generate parts of an OWL ontology.
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<!-- === Note: This version has &amp;rdf; replaced by rdf: -->

<xsl:stylesheet exclude-result-prefixes="xs" version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3"
    xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- ==============================================
         Additional global variables.
         These ones are independent of the information model format
        ============================================== -->

    <xsl:variable name="applicationIRI" select="cityEHRFunction:getIRI('#ISO-13606:EHR_Extract:',$applicationId)"/>

    <xsl:variable name="specialtyIRI" select="cityEHRFunction:getIRI('#ISO-13606:Folder:',$specialtyId)"/>
    <xsl:variable name="specialtyTermIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:',$specialtyDisplayName)"/>



    <!-- =============================================================== 
         Function to create ID by stripping out disallowed characters.
         Except that this may leave an empty string, so just return the string with spaces removed.
         Except that doesn't work because that string may include invalid characters
         So use encode-for-uri to remove funny characters and then remoce the % signs
         This should work OK - ids should have good characters anyway, but Ids for terms may only contain disallowed characters (e.g. %)
         
         So to summarise, the policy on generating ids is:
         
         0) If string inout is a list, join to form a single string
         1) Remove all spaces
         2) encode-for-uri
         3) Remove %
         
         =============================================================== -->

    <xsl:function name="cityEHRFunction:CreateID">
        <xsl:param name="string"/>

        <!-- Process if string argument exists -->
        <xsl:if test="exists($string)">
            <!-- 0. Join the string, in case it is a list of more than one string -->
            <xsl:variable name="joinedString" as="xs:string" select="string-join($string,' ')"/>

            <!-- 1. Remove spaces, line feed, carriage return using translate -->
            <xsl:variable name="reducedString" as="xs:string" select="translate($joinedString,'# &#09;&#10;','')"/>

            <!-- 2. encode-for-uri to replace funny characters -->
            <xsl:variable name="encodedString" as="xs:string" select="encode-for-uri($reducedString)"/>

            <!-- 3. Remove any % characters introduced by encode-for-uri -->
            <xsl:value-of select="replace($encodedString,'%','')"/>
        </xsl:if>

        <!-- Otherwise return empty string -->
        <xsl:if test="not(exists($string))">
            <xsl:value-of select="''"/>
        </xsl:if>

    </xsl:function>

    <!-- ====================================================================
        Returns a valid IRI from the input prefix and string.
        Returns an empty string if the $string parameter is empty
        The prefix is the class IRI with or without a trailing ':'
        If the trailing ':' is not present then this is added when constructing the IRI that is returned.
        
        The following characters are not valid in an IRI:
        
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getIRI">
        <xsl:param name="prefix"/>
        <xsl:param name="string"/>

        <xsl:variable name="prefixSeparator" as="xs:string" select="if (ends-with($prefix,':')) then '' else ':'"/>

        <xsl:variable name="outputIRI" as="xs:string" select="if ($string='') then '' else concat($prefix,$prefixSeparator,cityEHRFunction:CreateID($string))"/>

        <!-- Output the IRI -->
        <xsl:value-of select="$outputIRI"/>

    </xsl:function>


    <!-- === 
        Template to generate OWL/XML ontology containing an error message if the target ontology cannot be created    
        === -->
    <xsl:template name="generateOWLError">
        <xsl:param name="context"/>
        <xsl:param name="message"/>
        <!-- === Output the DOCTYPE and document type declaration subset with entity definitions.
            Plus the root document node for the Ontology -->
        <xsl:text disable-output-escaping="yes"><![CDATA[
            <!DOCTYPE Ontology [
            <!ENTITY xsd "http://www.w3.org/2001/XMLSchema#" >
            <!ENTITY xml "http://www.w3.org/XML/1998/namespace" >
            <!ENTITY rdfs "http://www.w3.org/2000/01/rdf-schema#" >
            <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#" >
            ]> 
            ]]></xsl:text>

        <Ontology xmlns="http://www.w3.org/2002/07/owl#" xml:base="http://www.elevenllp.com/owl/2011/2/16/Ontology1300280377354.owl"
            xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
            xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:xml="http://www.w3.org/XML/1998/namespace"
            ontologyIRI="http://www.elevenllp.com/owl/2011/2/16/Ontology1300280377354.owl">
            <xsl:call-template name="generateError">
                <xsl:with-param name="node" select="$rootNode"/>
                <xsl:with-param name="context" select="$context"/>
                <xsl:with-param name="message" select="$message"/>
            </xsl:call-template>
        </Ontology>

    </xsl:template>

    <!-- ====================================================================
         Template to generate Error              
        ==================================================================== -->
    <xsl:template name="generateError" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="node"/>
        <xsl:param name="context"/>
        <xsl:param name="message"/>

        <xsl:variable name="errorIRI" select="cityEHRFunction:getIRI('#CityEHR:Error:',generate-id($node))"/>

        <Declaration>
            <NamedIndividual IRI="{$errorIRI}"/>
        </Declaration>
        <ClassAssertion>
            <Class IRI="#CityEHR:Error"/>
            <NamedIndividual IRI="{$errorIRI}"/>
        </ClassAssertion>
        <DataPropertyAssertion>
            <DataProperty IRI="#hasValue"/>
            <NamedIndividual IRI="{$errorIRI}"/>
            <Literal xml:lang="en-gb" datatypeIRI="rdf:PlainLiteral"> Context: <xsl:value-of select="$context"/> Error: <xsl:value-of
                    select="$message"/>
            </Literal>
        </DataPropertyAssertion>

    </xsl:template>


    <!-- ====================================================================
        Template to generate Warning              
        ==================================================================== -->
    <xsl:template name="generateWarning" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="node"/>
        <xsl:param name="context"/>
        <xsl:param name="message"/>

        <xsl:variable name="warningIRI" select="cityEHRFunction:getIRI('#CityEHR:Warning:',generate-id($node))"/>

        <Declaration>
            <NamedIndividual IRI="{$warningIRI}"/>
        </Declaration>
        <ClassAssertion>
            <Class IRI="#CityEHR:Warning"/>
            <NamedIndividual IRI="{$warningIRI}"/>
        </ClassAssertion>
        <DataPropertyAssertion>
            <DataProperty IRI="#hasValue"/>
            <NamedIndividual IRI="{$warningIRI}"/>
            <Literal xml:lang="en-gb" datatypeIRI="rdf:PlainLiteral"> Context: <xsl:value-of select="$context"/> Warning: <xsl:value-of
                    select="$message"/>
            </Literal>
        </DataPropertyAssertion>

    </xsl:template>


    <!-- ====================================================================
        Template to generate Annotations for the Information Model              
        ==================================================================== -->
    <xsl:template name="generateAnnotations" xmlns="http://www.w3.org/2002/07/owl#">
        <Annotation>
            <AnnotationProperty abbreviatedIRI="rdfs:applicationId"/>
            <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="&amp;rdf;PlainLiteral">
                <xsl:value-of select="$applicationId"/>
            </Literal>
        </Annotation>
        <Annotation>
            <AnnotationProperty abbreviatedIRI="rdfs:specialtyId"/>
            <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="&amp;rdf;PlainLiteral">
                <xsl:value-of select="$specialtyId"/>
            </Literal>
        </Annotation>
        <Annotation>
            <AnnotationProperty abbreviatedIRI="rdfs:copyright"/>
            <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="&amp;rdf;PlainLiteral"><xsl:value-of
                select="('Copyright (c)',year-from-date(current-date()),$modelOwner)" separator=" "/>
            </Literal>
        </Annotation>
        <!-- The pathSeparator is used in expressions - usually / but was historically : -->
        <Annotation>
            <AnnotationProperty abbreviatedIRI="rdfs:pathSeparator"/>
            <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="&amp;rdf;PlainLiteral">
                <xsl:value-of select="$pathSeparator"/>
            </Literal>
        </Annotation>
    </xsl:template>


    <!-- ====================================================================
        Template to generate the configuration for the Information Model
        This information comes from the configiration sheet.
        ==================================================================== -->
    <xsl:template name="generateConfiguration" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="dataTypes"/>
        <xsl:param name="entryProperties"/>
        <xsl:param name="elementProperties"/>

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


        <!-- The data types for this ontology -->
        <xsl:for-each select="dataTypes">
            <xsl:variable name="dataType" as="xs:string" select="normalize-space(.)"/>

            <!-- Only process cells that contain some data -->
            <xsl:if test="$dataType != ''">
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

        <!-- The entry properties for this ontology
            These are cityEHR specific properties applied to the ISO-13606 Entry individuals
            Picked up from rows on the Configuration sheet
            Can be 'CRUD','Occurrence','InitialValue','Layout','Rendition','CohortSearch','Scope' 
        -->
        <xsl:for-each select="$entryProperties">
            <xsl:variable name="entryProperty" as="xs:string" select="normalize-space(.)"/>
            <!-- Only process cells that contain some data -->
            <xsl:if test="$entryProperty != ''">
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
            Can be 'ValueRequired','ElementType','Scope' 
            === -->
        <xsl:for-each select="$elementProperties">
            <xsl:variable name="elementProperty" as="xs:string" select="normalize-space(.)"/>
            <!-- Only process cells that contain some data -->
            <xsl:if test="$elementProperty != ''">
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


    </xsl:template>


    <!-- ====================================================================
        Template to generate assertions for all terms in the Information Model
        Parameter is a set of all terms in the model (should be distinct set, but check just in case).
        ==================================================================== -->
    <xsl:template name="generateTerms" xmlns="http://www.w3.org/2002/07/owl#">
        <xsl:param name="terms"/>

        <xsl:for-each select="distinct-values($terms)">
            <xsl:variable name="term" as="xs:string" select="normalize-space(.)"/>
            <xsl:if test="$term != ''">
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
                    <Literal xml:lang="{$baseLanguageCode}" datatypeIRI="&amp;rdf;PlainLiteral">
                        <xsl:value-of select="$term"/>
                    </Literal>
                </DataPropertyAssertion>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>



    <!-- ====================================================================
        Template to generate assertions for the class for this ontology
        Single individual as a member of the root class.
        
        The class must be present on the Configuration sheet.                
        $classId and $classDisplayName are set in the XSL that calls this module.
        
        Assert the individual
        Set its class to CityEHR:Class
        Set its displayName
        ==================================================================== -->
    <xsl:template name="generateClass" xmlns="http://www.w3.org/2002/07/owl#">

        <xsl:if test="$classId">
            <xsl:variable name="classIRI" select="cityEHRFunction:getIRI('#CityEHR:Class:',$classId)"/>
            <xsl:variable name="classTermIRI" select="cityEHRFunction:getIRI('#CityEHR:Term:',$classDisplayName)"/>

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
    </xsl:template>



</xsl:stylesheet>
