<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    OWL2ModelUtilities.xsl
    Included as a module in OWL2Composition.xsl and OWL2CompositionSet.xsl
    
    Contains named templates used to generate parts of a CDA document in forms and messages.
    Can handle the 2018 version of the ontology structure or the original (labelled 2017)
    
    Uses compositionIRI, etc but this should be refactored to compositionIRI since these utilities can be used for all compositions
    
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
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cda="urn:hl7-org:v3"
    xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions">
    <xsl:output method="xml" indent="yes" name="xml"/>

    <!-- === Global variables ======================= 
    ============================================ -->

    <!-- pathSeparator is used to separate the components in the identifiers used in expressions
         eg:  entryId:clusterId:elementId  when the separator is ':'
         or   entryId/clusterId/elementId  when the separator is '/'
         
         pathSeparator is specified in the ontology as an annotation, but use the default of '/' if it was not found
         <Annotation>
             <AnnotationProperty abbreviatedIRI="rdfs:pathSeparator"/>
             <Literal xml:lang="en" datatypeIRI="rdf:PlainLiteral"/>
         </Annotation>
    -->
    <xsl:variable name="specifiedPathSeparator"
        select="//owl:Ontology/owl:Annotation[owl:AnnotationProperty/@abbreviatedIRI = 'rdfs:pathSeparator']/owl:Literal"/>
    <xsl:variable name="defaultPathSeparator" select="'/'"/>
    <xsl:variable name="pathSeparator"
        select="
            if (exists($specifiedPathSeparator) and $specifiedPathSeparator != '') then
                $specifiedPathSeparator
            else
                $defaultPathSeparator"/>

    <!-- ontologyVersion is used to switch between the original (pre-2018) ontology format and the new format introduced in 2018.
         So the values are 2017 or 2018 - these are used to switch various other variables throughout the stylesjeet.
         
         The main change in the 2018 version is the representation of properties, which has been refactored to be more uniform.
         
         So in 2018 we have 
         
         <Declaration>
            <Class IRI="#CityEHR:Property"/>
         </Declaration>
         
         Each property is named #CityEHR:Property:Sequence (for the Sequence property) etc
         And the values are named #CityEHR:Property:Sequence:Ranked, etc
         
         Whereas in the previous 2017 version we have two different properties and names which could have been ambiguous:
         
         <Declaration>
            <Class IRI="#CityEHR:ElementProperty"/>
         </Declaration>
         <Declaration>
            <Class IRI="#CityEHR:EntryProperty"/>
         </Declaration>
         
         The property values are represented as #CityEHR:EntryProperty:Ranked and there is no declaration of which property the value belongs to.
         -->

    <xsl:variable name="ontologyVersion"
        select="
            if (exists($rootNode/owl:Declaration[owl:Class/@IRI = '#CityEHR:Property'])) then
                '2018'
            else
                '2017'"/>


    <!-- === Template to generate hidden sections 
        
        Hidden section for entries used in expressions (conditions, calculations or defaults) 
        But not used elsewhere on the form (i.e. need to be pre-filled from the record)
        
        <DataPropertyAssertion>
        <DataProperty IRI="#hasConditions"/>
        <NamedIndividual IRI="#ISO-13606:Entry:FractureSite"/>
        <Literal xml:lang="en" datatypeIRI="&amp;rdf;PlainLiteral">HasFracture:Boolean = 'true'</Literal>
        </DataPropertyAssertion>
        
        First get the list of tokenised entry:cluster:element and entry:element instances from the expressions that are used on this form.
        Expressions are used in conditions on sections and entries and calculated values for elements
        
        Then check each one to see if the entry is used elsewhere on the form
        If not, then put an entry into the hidden section
        
        Since these entries are 
    -->
    <xsl:template name="generateHiddenSections">
        <xsl:param name="rootNode"/>
        <xsl:param name="compositionIRI"/>
        <xsl:param name="formSections"/>
        <xsl:param name="formEntries"/>
        <xsl:param name="formRecordedEntries"/>

        <!-- Get all the elements on this form -->
        <xsl:variable name="allFormElements" select="cityEHRFunction:getElements($rootNode, $formEntries)"/>
        <xsl:variable name="formElements" select="distinct-values($allFormElements)"/>

        <!-- Get all evaluationContext for the sections and entries in the form.
             We need to use formEntries, since evaluation context may be different for an aliased root entry compared to its recorded entry.
             Include the empty evaluationContext in the set (is done in cityEHRFunction:getEvaluationContext) -->
        <xsl:variable name="evaluationContextSet" select="distinct-values(cityEHRFunction:getEvaluationContext(($formSections, $formEntries)))"/>

        <!-- External variables.
             Hidden section contains all entries that are used in expressions, but don't appear for user input on the form.
             Although evaluationContext is an expression, it is designed to evaluate conditions on other forms, so is not included in expressions to be analysed -->
        <component xmlns="urn:hl7-org:v3">
            <section cityEHR:visibility="alwaysHidden">
                <title>External Variables</title>
                <!-- Entries are output for each evaluationContext -->
                <xsl:for-each select="$evaluationContextSet">
                    <xsl:variable name="evaluationContext" select="."/>

                    <!-- Get sections, entries and elements in the evaluation context.
                         For the empty evaluation context, everything is in context -->
                    <xsl:variable name="contextSections"
                        select="$formSections[$evaluationContext = '' or cityEHRFunction:getEvaluationContextProperty(.) = $evaluationContext]"/>
                    <xsl:variable name="contextEntries"
                        select="$formEntries[$evaluationContext = '' or cityEHRFunction:getEvaluationContextProperty(.) = $evaluationContext]"/>
                    <xsl:variable name="allContextElements" select="cityEHRFunction:getElements($rootNode, $contextEntries)"/>
                    <xsl:variable name="contextElements" select="distinct-values($allContextElements)"/>

                    <!-- Get lists of entries in conditions, calculated and default values.
                         These are for the evaluationContext -->
                    <xsl:variable name="conditionEntries"
                        select="cityEHRFunction:getExpressionEntries($rootNode, ($contextSections, $contextEntries, $contextElements), '#hasConditions')"/>
                    <xsl:variable name="preConditionEntries"
                        select="cityEHRFunction:getExpressionEntries($rootNode, ($contextSections, $contextEntries), '#hasPreConditions')"/>
                    <xsl:variable name="calculatedValueEntries"
                        select="cityEHRFunction:getExpressionEntries($rootNode, $contextElements, '#hasCalculatedValue')"/>
                    <xsl:variable name="defaultValueEntries"
                        select="cityEHRFunction:getExpressionEntries($rootNode, $contextElements, '#hasDefaultValue')"/>

                    <!-- Output these lists for debugging only -->
                    <!--
            <p>Form sections: <xsl:value-of select="$formSections" separator="+"/></p>
            <p>Form entries: <xsl:value-of select="$formEntries" separator="+"/></p>
            <p>Form elements: <xsl:value-of select="$formElements" separator="+"/></p>
            <p>Condition entries: <xsl:value-of select="$conditionEntries" separator="+"/></p>
            <p>Calculated value entries: <xsl:value-of select="$calculatedValueEntries" separator="+"/></p>
            <p>Default value entries: <xsl:value-of select="$defaultValueEntries" separator="+"/></p>
            <p>Evaluation context set: <xsl:value-of select="$evaluationContextSet" separator="' / '"/></p>
            -->

                    <!-- Need to cater for proxy entries/elements here -->
                    <xsl:for-each select="distinct-values(($conditionEntries, $preConditionEntries, $calculatedValueEntries, $defaultValueEntries))">
                        <xsl:variable name="entryIRI" select="."/>

                        <!-- Add Entry to section if it doesn't appear elsewhere on the form.
                             Note that the formEntries is a list of the entry root IRIs, so the test also needs to check
                             whether there is an entry on the form which is a root of the entryIRI.
                             **JC expressions should use the actual entry (@extension) so do we just need the test for $formRecordedEntries -->
                        <xsl:if test="not($entryIRI = $formEntries) and not($entryIRI = $formRecordedEntries)">

                            <xsl:variable name="entryDisplayNameTermIRI" as="xs:string"
                                select="
                                    if (exists(key('termIRIList', $entryIRI, $rootNode))) then
                                        key('termIRIList', $entryIRI, $rootNode)[1]
                                    else
                                        ''"/>
                            <xsl:variable name="entryDisplayNameTerm" as="xs:string"
                                select="
                                    if (exists(key('termDisplayNameList', $entryDisplayNameTermIRI, $rootNode))) then
                                        key('termDisplayNameList', $entryDisplayNameTermIRI, $rootNode)[1]
                                    else
                                        ''"/>

                            <xsl:variable name="entryOccurrence" as="xs:string"
                                select="
                                    if (exists(key('specifiedObjectPropertyList', concat('#hasOccurrence', $entryIRI), $rootNode))) then
                                        key('specifiedObjectPropertyList', concat('#hasOccurrence', $entryIRI), $rootNode)[1]
                                    else
                                        '#CityEHR:Property:Occurrence:Single'"/>

                            <!-- Call template to generate hidden entry.
                                 usingExpressions is 'true' because although entries are pre-filled, we want to use any calculated values
                                 with data from current form. -->
                            <entry cityEHR:initialValue="#CityEHR:Property:InitialValue:Pre-filled">
                                <!-- Add evaluationContext attribute on the entry, if needed.
                                     $evaluationContext is the expression used as a predicate when retrieving pre-filled entries 
                                     This is used to retrieve the correct external variable, so need the proper expression, not the normalised version -->
                                <xsl:if test="$evaluationContext != ''">
                                    <!--
                                     Expand the evaluationContext. ***jc
                                     Note that the evaluationContext of the evaluationContext expression is '' -->
                                    <xsl:variable name="evaluationContextPredicate"
                                        select="string-join(cityEHRFunction:replaceExpressionVariables($entryIRI, '', 'composition', '', '', $formRecordedEntries, $evaluationContext), '')"/>
                                    <!-- Remove form-instance root since this expression is used as a predicate to select cda:ClinicalDocument in XQuery to return cda:entry -->
                                    <!--
                                    <xsl:variable name="targetString">xxf:instance\('form-instance'\)</xsl:variable>
                                    <xsl:variable name="replacementString">ancestor::cda:ClinicalDocument</xsl:variable>
                                    <xsl:variable name="evaluationContextPredicate"
                                        select="replace($expandedEvaluationContext,$targetString,$replacementString)"/>
                                    -->
                                    <!-- Add the attribute - this one is the expanded expression, on the cda:entry element-->
                                    <xsl:attribute name="cityEHR:evaluationContext">
                                        <xsl:value-of select="$evaluationContextPredicate"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <!-- Get normalised evaluation context for use in pattern matching -->
                                <xsl:variable name="normalisedEvaluationContext" as="xs:string"
                                    select="cityEHRFunction:getNormalisedProperty($evaluationContext)"/>
                                <!-- Single occurence, no enumeratedClass elements -->
                                <xsl:if test="$entryOccurrence = ('#CityEHR:EntryProperty:Single', '#CityEHR:Property:Occurrence:Single')">
                                    <xsl:call-template name="generateEntry">
                                        <xsl:with-param name="rootNode" select="$rootNode"/>
                                        <xsl:with-param name="entryIRI" select="$entryIRI"/>
                                        <xsl:with-param name="displayName" select="$entryDisplayNameTerm"/>
                                        <xsl:with-param name="entryRendition" select="''"/>
                                        <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                                        <xsl:with-param name="usingExpressions" select="'true'"/>
                                        <xsl:with-param name="recordEvaluationContext" select="'true'"/>
                                        <xsl:with-param name="evaluationContext" select="$normalisedEvaluationContext"/>
                                        <xsl:with-param name="origin" select="''"/>
                                    </xsl:call-template>
                                </xsl:if>
                                <!-- Multiple occurrence -->
                                <xsl:if
                                    test="$entryOccurrence = ('#CityEHR:EntryProperty:MultipleEntry', '#CityEHR:Property:Occurrence:MultipleEntry')">
                                    <xsl:call-template name="generateMultipleEntry">
                                        <xsl:with-param name="rootNode" select="$rootNode"/>
                                        <xsl:with-param name="entryIRI" select="$entryIRI"/>
                                        <xsl:with-param name="displayName" select="$entryDisplayNameTerm"/>
                                        <xsl:with-param name="entryRendition" select="''"/>
                                        <xsl:with-param name="usingExpressions" select="'true'"/>
                                        <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                                        <xsl:with-param name="recordEvaluationContext" select="'true'"/>
                                        <xsl:with-param name="evaluationContext" select="$normalisedEvaluationContext"/>
                                        <xsl:with-param name="entryCRUD" select="'#CityEHR:Property:CRUD:CRUD'"/>
                                    </xsl:call-template>
                                </xsl:if>
                            </entry>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:for-each>


                <!-- The cityEHR:lookup function looks up the value of an element of directoryElement type
                     Need to add an entry with the set of all directoryElement type elements that don't appear anywhere else on the form -->

                <!-- Get lists of cityEHR:lookup elements in conditions, calculated and default values -->
                <xsl:variable name="conditionLookupElements"
                    select="cityEHRFunction:getExpressionLookupElements($rootNode, ($formSections, $formEntries, $formElements), '#hasConditions')"/>
                <xsl:variable name="preConditionLookupElements"
                    select="cityEHRFunction:getExpressionLookupElements($rootNode, ($formSections, $formEntries), '#hasPreConditions')"/>
                <xsl:variable name="calculatedValueLookupElements"
                    select="cityEHRFunction:getExpressionLookupElements($rootNode, $formElements, '#hasCalculatedValue')"/>
                <xsl:variable name="defaultValueLookupElements"
                    select="cityEHRFunction:getExpressionLookupElements($rootNode, $formElements, '#hasDefaultValue')"/>


                <!-- Hidden section contains all cityEHR:lookup elements that are used in expressions, but don't appear for user input on the form -->
                <entry>
                    <observation>
                        <xsl:for-each
                            select="distinct-values(($conditionLookupElements, $preConditionLookupElements, $calculatedValueLookupElements, $defaultValueLookupElements))">
                            <xsl:variable name="elementIRI" select="."/>

                            <!-- Add Element to the entry if it doesn't appear elsewhere on the form  -->
                            <xsl:if test="not($elementIRI = $formElements)">
                                <value root="{$elementIRI}" cityEHR:elementType="#CityEHR:Property:ElementType:enumeratedDirectory"/>
                            </xsl:if>
                        </xsl:for-each>
                    </observation>
                </entry>

            </section>
        </component>

    </xsl:template>



    <!-- === Template to generate the Section of a form or message === 
        Input parameters are the sectionIRI and sectionSequence
    -->
    <xsl:template name="generateSection">
        <xsl:param name="rootNode"/>
        <xsl:param name="compositionTypeIRI"/>
        <xsl:param name="sectionIRI"/>
        <xsl:param name="sectionSequence"/>
        <xsl:param name="formRecordedEntries"/>
        <xsl:param name="usingExpressions"/>

        <xsl:variable name="sectionDisplayNameTermIRI" as="xs:string"
            select="
                if (exists(key('termIRIList', $sectionIRI, $rootNode))) then
                    key('termIRIList', $sectionIRI, $rootNode)[1]
                else
                    ''"/>
        <xsl:variable name="sectionDisplayNameTerm" as="xs:string"
            select="
                if (exists(key('termDisplayNameList', $sectionDisplayNameTermIRI, $rootNode))) then
                    key('termDisplayNameList', $sectionDisplayNameTermIRI, $rootNode)[1]
                else
                    ''"/>

        <component xmlns="urn:hl7-org:v3">
            <section cityEHR:Sequence="{$sectionSequence}" cityEHR:labelWidth="{cityEHRFunction:getSectionLabelWidth($sectionIRI)}">

                <!-- Get property for #hasRendition -->
                <!--
                <xsl:variable name="sectionRendition" as="xs:string"
                    select="
                        if (exists(key('specifiedObjectPropertyList', concat('#hasRendition', $sectionIRI), $rootNode))) then
                            key('specifiedObjectPropertyList', concat('#hasRendition', $sectionIRI), $rootNode)[1]
                        else
                            ''"/>
                            -->
                <xsl:variable name="sectionRendition" as="xs:string"
                    select="cityEHRFunction:getObjectPropertyValue($rootNode, $sectionIRI, 'EntryProperty', '#hasRendition')"/>


                <!-- Add attribute if the section has rendition set -->
                <xsl:if test="string-length($sectionRendition) &gt; 0">
                    <xsl:attribute name="cityEHR:rendition">
                        <xsl:value-of select="$sectionRendition"/>
                    </xsl:attribute>
                </xsl:if>

                <!-- Add attibutes if the section represents a care pathway task.
                -->
                <xsl:if test="$compositionTypeIRI = '#CityEHR:Pathway'">
                    <xsl:attribute name="cityEHR:status">charted</xsl:attribute>
                    <xsl:attribute name="cityEHR:sessionStatus">charted</xsl:attribute>
                    <xsl:attribute name="cityEHR:outcome">toBeConfirmed</xsl:attribute>
                </xsl:if>

                <!-- Add atrributes for hint and alert -->
                <!-- Get property for #hasAlert -->
                <xsl:variable name="sectionAlert" as="xs:string"
                    select="
                        if (exists(key('specifiedDataPropertyList', concat('#hasAlert', $sectionIRI), $rootNode))) then
                            key('specifiedDataPropertyList', concat('#hasAlert', $sectionIRI), $rootNode)[1]
                        else
                            ''"/>
                <xsl:if test="$sectionAlert != ''">
                    <xsl:attribute name="cityEHR:Alert">
                        <xsl:value-of select="$sectionAlert"/>
                    </xsl:attribute>
                </xsl:if>

                <!-- Get property for #hasHint -->
                <xsl:variable name="sectionHint" as="xs:string"
                    select="
                        if (exists(key('specifiedDataPropertyList', concat('#hasHint', $sectionIRI), $rootNode))) then
                            key('specifiedDataPropertyList', concat('#hasHint', $sectionIRI), $rootNode)[1]
                        else
                            ''"/>
                <xsl:if test="$sectionHint != ''">
                    <xsl:attribute name="cityEHR:Hint">
                        <xsl:value-of select="$sectionHint"/>
                    </xsl:attribute>
                </xsl:if>

                <!-- Conditions, Preconditions and EvaluationContext on sections only processed if usingExpressions -->
                <xsl:if test="$usingExpressions = 'true'">

                    <!-- Get normalized representation of evaluationContext -->
                    <xsl:variable name="evaluationContext" as="xs:string"
                        select="cityEHRFunction:getNormalisedProperty(cityEHRFunction:getEvaluationContextProperty($sectionIRI))"/>

                    <!-- Get data property for #hasConditions -->
                    <xsl:variable name="sectionConditions" as="xs:string"
                        select="
                            if ($usingExpressions = 'true' and exists(key('specifiedDataPropertyList', concat('#hasConditions', $sectionIRI), $rootNode))) then
                                key('specifiedDataPropertyList', concat('#hasConditions', $sectionIRI), $rootNode)
                            else
                                ''"/>
                    <xsl:variable name="expandedSectionConditions">
                        <xsl:call-template name="expandExpression">
                            <xsl:with-param name="expressionType" select="'condition'"/>
                            <xsl:with-param name="contextEntryIRI" select="''"/>
                            <xsl:with-param name="contextContentIRI" select="''"/>
                            <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                            <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                            <xsl:with-param name="expression" select="$sectionConditions"/>
                        </xsl:call-template>
                    </xsl:variable>

                    <!-- Get data property for #hasPreConditions -->
                    <xsl:variable name="sectionPreConditions" as="xs:string"
                        select="
                            if ($usingExpressions = 'true' and exists(key('specifiedDataPropertyList', concat('#hasPreConditions', $sectionIRI), $rootNode))) then
                                key('specifiedDataPropertyList', concat('#hasPreConditions', $sectionIRI), $rootNode)
                            else
                                ''"/>
                    <xsl:variable name="expandedSectionPreConditions">
                        <xsl:call-template name="expandExpression">
                            <xsl:with-param name="expressionType" select="'condition'"/>
                            <xsl:with-param name="contextEntryIRI" select="''"/>
                            <xsl:with-param name="contextContentIRI" select="''"/>
                            <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                            <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                            <xsl:with-param name="expression" select="$sectionPreConditions"/>
                        </xsl:call-template>
                    </xsl:variable>

                    <!-- Add attibutes if the section has conditional visibility.
                         The cityEHR:visibility attribute has no value but is set when the conditions are evaluated -->
                    <xsl:if test="string-length($expandedSectionConditions) &gt; 0">
                        <xsl:attribute name="cityEHR:conditions">
                            <xsl:value-of select="$expandedSectionConditions"/>
                        </xsl:attribute>
                        <xsl:attribute name="cityEHR:visibility"/>
                    </xsl:if>

                    <!-- Add attibutes if the section has pre-conditions.
                         The cityEHR:visibility attribute has no value but is set when the pre-conditions are evaluated -->
                    <xsl:if test="string-length($expandedSectionPreConditions) &gt; 0">
                        <xsl:attribute name="cityEHR:preConditions">
                            <xsl:value-of select="$expandedSectionPreConditions"/>
                        </xsl:attribute>
                        <xsl:attribute name="cityEHR:visibility"/>
                    </xsl:if>

                </xsl:if>

                <id root="cityEHR" extension="{$sectionIRI}"/>
                <title>
                    <xsl:value-of select="$sectionDisplayNameTerm"/>
                </title>

                <!-- Iterate through contents of a section 
                    <ObjectPropertyAssertion>
                        <ObjectProperty IRI="#hasContent"/>
                        <NamedIndividual IRI="$sectionIRI"/>
                        <NamedIndividual IRI="contentIRI"/>
                    </ObjectPropertyAssertion>
                    
                    Content is either a ISO-13606:Section or ISO-13606:Entry.
                    Contents are sorted in the order defined by the hasContentsList data attribute.
                    The position order is determined by the length of the string before the section/entry is matched in the list
                -->

                <!-- Get data property for #hasContentsList
                     Has IRIs separated by spaces -->
                <xsl:variable name="contentsList" as="xs:string"
                    select="
                        if (exists(key('specifiedDataPropertyList', concat('#hasContentsList', $sectionIRI), $rootNode))) then
                            key('specifiedDataPropertyList', concat('#hasContentsList', $sectionIRI), $rootNode)
                        else
                            ''"/>
                <xsl:variable name="contents" select="tokenize($contentsList, ' ')"/>

                <!-- Iterate through the contents of the section -->
                <xsl:for-each select="$contents">
                    <xsl:variable name="contentIRI" as="xs:string" select="."/>

                    <!-- Just make sure the contentIRI is OK - tokenize with ' ' can go wrong if the string got formatted -->
                    <xsl:if test="starts-with($contentIRI, '#')">

                        <xsl:variable name="contentDisplayNameTermIRI" as="xs:string"
                            select="
                                if (exists(key('termIRIList', $contentIRI, $rootNode))) then
                                    key('termIRIList', $contentIRI, $rootNode)[1]
                                else
                                    ''"/>
                        <xsl:variable name="contentDisplayNameTerm" as="xs:string"
                            select="
                                if (exists(key('termDisplayNameList', $contentDisplayNameTermIRI, $rootNode))) then
                                    key('termDisplayNameList', $contentDisplayNameTermIRI, $rootNode)[1]
                                else
                                    ''"/>

                        <!-- Get data property for #hasSequence
                             These are recorded in the cityEHR'Sequence attribute as Ranked or Unranked 
                             In V2 this is now an objectProperty, so need to handle both (data property or object property)
                             In the ontology V1 as Ranked or Unranked but in V2 as #CityEHR:Property:Sequence:Ranked or #CityEHR:Property:Sequence:Unranked-->
                        <xsl:variable name="contentSequenceProperty" as="xs:string"
                            select="
                                if (exists(key('specifiedDataPropertyList', concat('#hasSequence', $contentIRI), $rootNode))) then
                                    key('specifiedDataPropertyList', concat('#hasSequence', $contentIRI), $rootNode)
                                else
                                    if (exists(key('specifiedObjectPropertyList', concat('#hasSequence', $contentIRI), $rootNode))) then
                                        key('specifiedObjectPropertyList', concat('#hasSequence', $contentIRI), $rootNode)
                                    else
                                        '#CityEHR:Property:Sequence:Unranked'"/>

                        <xsl:variable name="contentSequence" as="xs:string"
                            select="
                                if (contains($contentSequenceProperty, 'Unranked')) then
                                    'Unranked'
                                else
                                    'Ranked'"/>

                        <!-- Content is a section -->
                        <xsl:if test="starts-with($contentIRI, '#ISO-13606:Section')">
                            <xsl:call-template name="generateSection">
                                <xsl:with-param name="rootNode" select="$rootNode"/>
                                <xsl:with-param name="compositionTypeIRI" select="$compositionTypeIRI"/>
                                <xsl:with-param name="sectionIRI" select="$contentIRI"/>
                                <xsl:with-param name="sectionSequence" select="$contentSequence"/>
                                <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                                <xsl:with-param name="usingExpressions" select="$usingExpressions"/>
                            </xsl:call-template>
                        </xsl:if>

                        <!-- Content is an entry -->
                        <xsl:if test="starts-with($contentIRI, '#ISO-13606:Entry')">
                            <!-- Get property for #hasOccurrence -->
                            <xsl:variable name="entryOccurrence" as="xs:string"
                                select="
                                    if (exists(key('specifiedObjectPropertyList', concat('#hasOccurrence', $contentIRI), $rootNode))) then
                                        key('specifiedObjectPropertyList', concat('#hasOccurrence', $contentIRI), $rootNode)[1]
                                    else
                                        '#CityEHR:Property:Occurrence:Single'"/>

                            <!-- Check whether this entry is the root of another (i.e. is a proxy entry).
                             The root of the entry in the CDA is always the entryIRI.
                             If this entry is the root of another then the extension records that entry, otherwise the extension is the same as the root. -->

                            <!-- Get property for #isRootOf or #hasExtension (from 2019-02-13).
                                 2019-02-13 - the specialisationProperty changed from isRootOf to hasExtension -->
                            <xsl:variable name="specialisationProperty" as="xs:string"
                                select="
                                    if (exists($rootNode/owl:Declaration[owl:ObjectProperty/@IRI = '#hasRoot'])) then
                                        '#isRootOf'
                                    else
                                        '#hasExtension'"/>
                            <xsl:variable name="recordedEntryIRI" as="xs:string"
                                select="
                                    if (exists(key('specifiedObjectPropertyList', concat($specialisationProperty, $contentIRI), $rootNode))) then
                                        key('specifiedObjectPropertyList', concat($specialisationProperty, $contentIRI), $rootNode)[1]
                                    else
                                        $contentIRI"/>

                            <!-- Get normalized representation of evaluationContext -->
                            <xsl:variable name="evaluationContext" as="xs:string"
                                select="cityEHRFunction:getNormalisedProperty(cityEHRFunction:getEvaluationContextProperty($contentIRI))"/>

                            <!-- Conditions on entries only processed if usingExpressions.
                             Get data property for #hasConditions -->
                            <xsl:variable name="entryConditions" as="xs:string"
                                select="
                                    if ($usingExpressions = 'true' and exists(key('specifiedDataPropertyList', concat('#hasConditions', $contentIRI), $rootNode))) then
                                        key('specifiedDataPropertyList', concat('#hasConditions', $contentIRI), $rootNode)
                                    else
                                        ''"/>
                            <xsl:variable name="expandedEntryConditions">
                                <xsl:call-template name="expandExpression">
                                    <xsl:with-param name="expressionType" select="'condition'"/>
                                    <xsl:with-param name="contextEntryIRI" select="''"/>
                                    <xsl:with-param name="contextContentIRI" select="''"/>
                                    <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                                    <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                                    <xsl:with-param name="expression" select="$entryConditions"/>
                                </xsl:call-template>
                            </xsl:variable>

                            <!-- PreConditions on entries only processed if usingExpressions.
                             Pre-conditions are evaluated when pre-filling entries using the context of the entry, 
                             so contextEntryIRI is set to the recordedEntryIRI
                             Get data property for #hasPreConditions -->
                            <xsl:variable name="entryPreConditions" as="xs:string"
                                select="
                                    if ($usingExpressions = 'true' and exists(key('specifiedDataPropertyList', concat('#hasPreConditions', $contentIRI), $rootNode))) then
                                        key('specifiedDataPropertyList', concat('#hasPreConditions', $contentIRI), $rootNode)
                                    else
                                        ''"/>
                            <xsl:variable name="expandedEntryPreConditions">
                                <xsl:call-template name="expandExpression">
                                    <xsl:with-param name="expressionType" select="'condition'"/>
                                    <xsl:with-param name="contextEntryIRI" select="$recordedEntryIRI"/>
                                    <xsl:with-param name="contextContentIRI" select="$recordedEntryIRI"/>
                                    <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                                    <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                                    <xsl:with-param name="expression" select="$entryPreConditions"/>
                                </xsl:call-template>
                            </xsl:variable>

                            <!-- Get property for #hasRendition -->
                            <!--
                            <xsl:variable name="entryRendition" as="xs:string"
                                select="
                                    if (exists(key('specifiedObjectPropertyList', concat('#hasRendition', $contentIRI), $rootNode))) then
                                        key('specifiedObjectPropertyList', concat('#hasRendition', $contentIRI), $rootNode)[1]
                                    else
                                        '#CityEHR:Property:Rendition:Form'"/>
                                        -->
                            <xsl:variable name="entryRendition" as="xs:string"
                                select="cityEHRFunction:getObjectPropertyValue($rootNode, $contentIRI, 'EntryProperty', '#hasRendition')"/>


                            <!-- Get property for #hasInitialValue -->
                            <!--
                            <xsl:variable name="entryInitialValue" as="xs:string"
                                select="
                                    if (exists(key('specifiedObjectPropertyList', concat('#hasInitialValue', $contentIRI), $rootNode))) then
                                        key('specifiedObjectPropertyList', concat('#hasInitialValue', $contentIRI), $rootNode)[1]
                                    else
                                        '#CityEHR:Property:InitialValue:Default'"/>
                                        -->
                            <xsl:variable name="entryInitialValue" as="xs:string"
                                select="cityEHRFunction:getObjectPropertyValue($rootNode, $contentIRI, 'EntryProperty', '#hasInitialValue')"/>


                            <!-- Get property for #hasCRUD -->
                            <!--
                            <xsl:variable name="entryCRUD" as="xs:string"
                                select="
                                    if (exists(key('specifiedObjectPropertyList', concat('#hasCRUD', $contentIRI), $rootNode))) then
                                        key('specifiedObjectPropertyList', concat('#hasCRUD', $contentIRI), $rootNode)[1]
                                    else
                                        '#CityEHR:Property:CRUD:CRUD'"/>
                                        -->
                            <xsl:variable name="entryCRUD" as="xs:string"
                                select="cityEHRFunction:getObjectPropertyValue($rootNode, $contentIRI, 'EntryProperty', '#hasCRUD')"/>


                            <!-- Get property for #hasSortOrder -->
                            <!--
                            <xsl:variable name="entrySortOrder" as="xs:string"
                                select="
                                    if (exists(key('specifiedObjectPropertyList', concat('#hasSortOrder', $contentIRI), $rootNode))) then
                                        key('specifiedObjectPropertyList', concat('#hasSortOrder', $contentIRI), $rootNode)[1]
                                    else
                                        ''"/>
                                        -->
                            <xsl:variable name="entrySortOrder" as="xs:string"
                                select="cityEHRFunction:getObjectPropertyValue($rootNode, $contentIRI, 'EntryProperty', '#hasSortOrder')"/>


                            <!-- Get property for #hasSortCriteria -->
                            <xsl:variable name="entrySortCriteria" as="xs:string"
                                select="
                                    if (exists(key('specifiedObjectPropertyList', concat('#hasSortCriteria', $contentIRI), $rootNode))) then
                                        key('specifiedObjectPropertyList', concat('#hasSortCriteria', $contentIRI), $rootNode)[1]
                                    else
                                        ''"/>

                            <!-- Get property for #hasCategorizationCriteria -->
                            <xsl:variable name="entryCategorizationCriteria" as="xs:string"
                                select="
                                    if (exists(key('specifiedObjectPropertyList', concat('#hasCategorizationCriteria', $contentIRI), $rootNode))) then
                                        key('specifiedObjectPropertyList', concat('#hasCategorizationCriteria', $contentIRI), $rootNode)[1]
                                    else
                                        ''"/>

                            <!-- Get property for #hasScope -->
                            <!--
                            <xsl:variable name="entryScope" as="xs:string"
                                select="
                                    if (exists(key('specifiedObjectPropertyList', concat('#hasScope', $contentIRI), $rootNode))) then
                                        key('specifiedObjectPropertyList', concat('#hasScope', $contentIRI), $rootNode)[1]
                                    else
                                        ''"/>
                                        -->
                            <xsl:variable name="entryScope" as="xs:string"
                                select="cityEHRFunction:getObjectPropertyValue($rootNode, $contentIRI, 'EntryProperty', '#hasScope')"/>


                            <entry cityEHR:Sequence="{$contentSequence}" cityEHR:rendition="{$entryRendition}"
                                cityEHR:initialValue="{$entryInitialValue}" cityEHR:labelWidth="{cityEHRFunction:getEntryLabelWidth($contentIRI)}">

                                <xsl:if test="$usingExpressions = 'true'">
                                    <!-- Add attibutes if the entry has conditional visibility
                                     The cityEHR:visibility attribute has no value but is set when the conditions are evaluated -->
                                    <xsl:if test="string-length($expandedEntryConditions) &gt; 0">
                                        <xsl:attribute name="cityEHR:conditions">
                                            <xsl:value-of select="$expandedEntryConditions"/>
                                        </xsl:attribute>
                                        <xsl:attribute name="cityEHR:visibility"/>
                                    </xsl:if>

                                    <!-- Add attributes if the entry has PreConditions.
                                     The cityEHR:visibility attribute has no value but is set when the pre-conditions are evaluated -->
                                    <xsl:if test="string-length($expandedEntryPreConditions) &gt; 0">
                                        <xsl:attribute name="cityEHR:preConditions">
                                            <xsl:value-of select="$expandedEntryPreConditions"/>
                                        </xsl:attribute>
                                        <xsl:attribute name="cityEHR:visibility"/>
                                    </xsl:if>
                                </xsl:if>

                                <!-- Add attribute if the entry contains an expanded scope element -->
                                <!-- Now using specific property on the entry to set the scope.
                                 This is needed so that aliased entries containing an expanded element can be set to not expand -->
                                <!--
                            <xsl:variable name="containsExpandedScope" select="cityEHRFunction:containsExpandedScope($contentIRI)"/>
                            -->
                                <xsl:if test="$entryScope != ''">
                                    <xsl:attribute name="cityEHR:Scope">
                                        <xsl:value-of select="$entryScope"/>
                                    </xsl:attribute>
                                </xsl:if>

                                <!-- Add attribute if the entry is not the standard CRUD (the assumed default) -->
                                <xsl:if test="not($entryCRUD = ('#CityEHR:EntryProperty:CRUD', '#CityEHR:Property:CRUD:CRUD'))">
                                    <xsl:attribute name="cityEHR:CRUD">
                                        <xsl:value-of select="$entryCRUD"/>
                                    </xsl:attribute>
                                </xsl:if>

                                <!-- Add attribute if the entry has sort order -->
                                <xsl:if test="$entrySortOrder != ''">
                                    <xsl:attribute name="cityEHR:sortOrder">
                                        <xsl:value-of select="$entrySortOrder"/>
                                    </xsl:attribute>
                                </xsl:if>

                                <!-- Add attribute if the entry has sort criteria -->
                                <xsl:if test="$entrySortCriteria != ''">
                                    <xsl:attribute name="cityEHR:sortCriteria">
                                        <xsl:value-of select="$entrySortCriteria"/>
                                    </xsl:attribute>
                                </xsl:if>

                                <!-- Add attribute if the entry has categorization criteria -->
                                <xsl:if test="$entryCategorizationCriteria != ''">
                                    <xsl:attribute name="cityEHR:categorizationCriteria">
                                        <xsl:value-of select="$entryCategorizationCriteria"/>
                                    </xsl:attribute>
                                </xsl:if>

                                <!-- Add atrributes for hint and alert -->
                                <!-- Get property for #hasAlert -->
                                <xsl:variable name="entryAlert" as="xs:string"
                                    select="
                                        if (exists(key('specifiedDataPropertyList', concat('#hasAlert', $contentIRI), $rootNode))) then
                                            key('specifiedDataPropertyList', concat('#hasAlert', $contentIRI), $rootNode)[1]
                                        else
                                            ''"/>
                                <xsl:if test="$entryAlert != ''">
                                    <xsl:attribute name="cityEHR:Alert">
                                        <xsl:value-of select="$entryAlert"/>
                                    </xsl:attribute>
                                </xsl:if>

                                <!-- Get property for #hasHint -->
                                <xsl:variable name="entryHint" as="xs:string"
                                    select="
                                        if (exists(key('specifiedDataPropertyList', concat('#hasHint', $contentIRI), $rootNode))) then
                                            key('specifiedDataPropertyList', concat('#hasHint', $contentIRI), $rootNode)[1]
                                        else
                                            ''"/>
                                <xsl:if test="$entryHint != ''">
                                    <xsl:attribute name="cityEHR:Hint">
                                        <xsl:value-of select="$entryHint"/>
                                    </xsl:attribute>
                                </xsl:if>

                                <!-- Single occurence, no enumeratedClass elements ***jc -->
                                <xsl:if test="$entryOccurrence = ('#CityEHR:EntryProperty:Single', '#CityEHR:Property:Occurrence:Single')">
                                    <xsl:call-template name="generateEntry">
                                        <xsl:with-param name="rootNode" select="$rootNode"/>
                                        <xsl:with-param name="entryIRI" select="$contentIRI"/>
                                        <xsl:with-param name="displayName" select="$contentDisplayNameTerm"/>
                                        <xsl:with-param name="entryRendition" select="$entryRendition"/>
                                        <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                                        <xsl:with-param name="usingExpressions" select="$usingExpressions"/>
                                        <xsl:with-param name="recordEvaluationContext" select="'false'"/>
                                        <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                                        <xsl:with-param name="origin" select="''"/>
                                    </xsl:call-template>
                                </xsl:if>


                                <!-- Multiple occurrence -->
                                <xsl:if
                                    test="$entryOccurrence = ('#CityEHR:EntryProperty:MultipleEntry', '#CityEHR:Property:Occurrence:MultipleEntry')">
                                    <xsl:call-template name="generateMultipleEntry">
                                        <xsl:with-param name="rootNode" select="$rootNode"/>
                                        <xsl:with-param name="entryIRI" select="$contentIRI"/>
                                        <xsl:with-param name="displayName" select="$contentDisplayNameTerm"/>
                                        <xsl:with-param name="entryRendition" select="$entryRendition"/>
                                        <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                                        <xsl:with-param name="usingExpressions" select="$usingExpressions"/>
                                        <xsl:with-param name="recordEvaluationContext" select="'false'"/>
                                        <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                                        <xsl:with-param name="entryCRUD" select="$entryCRUD"/>
                                    </xsl:call-template>
                                </xsl:if>
                            </entry>

                        </xsl:if>
                        <!-- End of handling an entry -->
                    </xsl:if>
                </xsl:for-each>

            </section>
        </component>
    </xsl:template>


    <!-- === Template to generate an Entry as a CDA entry of the appropriate class === 
             Input parameters are the entryIRI and displayName for the entry
             
             usingExpressions denotes whether expressions will be expanded
             evaluationContext is the evaluation context for the entry
             origin is the cityEHR:origin attribute is used at runtime to record the origin of supplementary data sets and the category of sorted multiple entries
             It can be set to 'cityEHR:Template' in multiple entry templates so that the entry is ignored in calculations
        
        Until 2019-02-13 Type of the entry is found from 
            <ClassAssertion>
                <Class IRI="{$entryClassIRI}"/>
                <NamedIndividual IRI="{$entryIRI}"/>
            </ClassAssertion>
            
        From 2019-02-13 use the #hasEntryType object property - then need to append the #HL7-CDA prefix to get the IRI
        e.g. #CityEHR:Property:EntryType:Observation becomes #HL7-CDA::Observation
       
    -->
    <xsl:template name="generateEntry">
        <xsl:param name="rootNode"/>
        <xsl:param name="entryIRI"/>
        <xsl:param name="displayName"/>
        <xsl:param name="entryRendition"/>
        <xsl:param name="formRecordedEntries"/>
        <xsl:param name="usingExpressions"/>
        <xsl:param name="recordEvaluationContext"/>
        <xsl:param name="evaluationContext"/>
        <xsl:param name="origin"/>

        <xsl:variable name="entryClass" as="xs:string"
            select="
                if (exists(key('classIRIList', $entryIRI, $rootNode))) then
                    key('classIRIList', $entryIRI, $rootNode)[1]
                else
                    ''"/>

        <!-- From 2019-02-13 entryClass is always #ISO-13606:Entry, so need to use #hasEntryType property -->
        <xsl:variable name="entryType" as="xs:string"
            select="
                if (exists(key('specifiedObjectPropertyList', concat('#hasEntryType', $entryIRI), $rootNode))) then
                    key('specifiedObjectPropertyList', concat('#hasEntryType', $entryIRI), $rootNode)[1]
                else
                    ''"/>

        <xsl:variable name="entryTypeIRI" as="xs:string"
            select="
                if ($entryClass != '#ISO-13606:Entry') then
                    $entryClass
                else
                    if ($entryType != '') then
                        replace($entryType, '#CityEHR:Property:EntryType', '#HL7-CDA')
                    else
                        ''"/>

        <xsl:if test="$entryTypeIRI = '#HL7-CDA:Observation'">
            <observation xmlns="urn:hl7-org:v3">
                <!-- ***jc 2021-01-03 - evaluation context is only needed on the external entries -->
                <xsl:if test="$recordEvaluationContext = 'true' and $evaluationContext != ''">
                    <xsl:attribute name="cityEHR:evaluationContext">
                        <xsl:value-of select="$evaluationContext"/>
                    </xsl:attribute>
                </xsl:if>

                <xsl:call-template name="generateEntryContent">
                    <xsl:with-param name="rootNode" select="$rootNode"/>
                    <xsl:with-param name="entryIRI" select="$entryIRI"/>
                    <xsl:with-param name="entryType" select="$entryTypeIRI"/>
                    <xsl:with-param name="displayName" select="$displayName"/>
                    <xsl:with-param name="entryRendition" select="$entryRendition"/>
                    <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                    <xsl:with-param name="usingExpressions" select="$usingExpressions"/>
                    <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                    <xsl:with-param name="origin" select="$origin"/>
                </xsl:call-template>
            </observation>
        </xsl:if>

        <xsl:if test="$entryTypeIRI = '#HL7-CDA:Encounter'">
            <encounter xmlns="urn:hl7-org:v3">
                <xsl:call-template name="generateEntryContent">
                    <xsl:with-param name="rootNode" select="$rootNode"/>
                    <xsl:with-param name="entryIRI" select="$entryIRI"/>
                    <xsl:with-param name="entryType" select="$entryTypeIRI"/>
                    <xsl:with-param name="displayName" select="$displayName"/>
                    <xsl:with-param name="entryRendition" select="$entryRendition"/>
                    <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                    <xsl:with-param name="usingExpressions" select="$usingExpressions"/>
                    <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                    <xsl:with-param name="origin" select="$origin"/>
                </xsl:call-template>
            </encounter>
        </xsl:if>

        <xsl:if test="$entryTypeIRI = '#HL7-CDA:Act'">
            <xsl:variable name="entryInterval" as="xs:string"
                select="
                    if (exists(key('specifiedDataPropertyList', concat('#hasInterval', $entryIRI), $rootNode))) then
                        key('specifiedDataPropertyList', concat('#hasInterval', $entryIRI), $rootNode)
                    else
                        ''"/>

            <act xmlns="urn:hl7-org:v3" cityEHR:role="" cityEHR:start="" cityEHR:delay="{$entryInterval}" cityEHR:status="charted"
                cityEHR:sessionStatus="charted" cityEHR:outcome="toBeConfirmed">
                <xsl:call-template name="generateEntryContent">
                    <xsl:with-param name="rootNode" select="$rootNode"/>
                    <xsl:with-param name="entryIRI" select="$entryIRI"/>
                    <xsl:with-param name="entryType" select="$entryTypeIRI"/>
                    <xsl:with-param name="displayName" select="$displayName"/>
                    <xsl:with-param name="entryRendition" select="$entryRendition"/>
                    <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                    <xsl:with-param name="usingExpressions" select="$usingExpressions"/>
                    <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                    <xsl:with-param name="origin" select="$origin"/>
                </xsl:call-template>
            </act>
        </xsl:if>

        <xsl:if test="$entryTypeIRI = '#HL7-CDA:Supply'">
            <supply xmlns="urn:hl7-org:v3">
                <xsl:call-template name="generateEntryContent">
                    <xsl:with-param name="rootNode" select="$rootNode"/>
                    <xsl:with-param name="entryIRI" select="$entryIRI"/>
                    <xsl:with-param name="entryType" select="$entryTypeIRI"/>
                    <xsl:with-param name="displayName" select="$displayName"/>
                    <xsl:with-param name="entryRendition" select="$entryRendition"/>
                    <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                    <xsl:with-param name="usingExpressions" select="$usingExpressions"/>
                    <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                    <xsl:with-param name="origin" select="$origin"/>
                </xsl:call-template>
            </supply>
        </xsl:if>

    </xsl:template>


    <!-- === Template to generate the content of a CDA Entry === 
         Input parameters are the entryIRI, entryType and displayName
    -->
    <xsl:template name="generateEntryContent">
        <xsl:param name="rootNode"/>
        <xsl:param name="entryIRI"/>
        <xsl:param name="entryType"/>
        <xsl:param name="displayName"/>
        <xsl:param name="entryRendition"/>
        <xsl:param name="formRecordedEntries"/>
        <xsl:param name="usingExpressions"/>
        <xsl:param name="evaluationContext"/>
        <xsl:param name="origin"/>

        <!-- Check whether this entry is the root of another (i.e. is a specialisation of another entry).
             The root of the entry in the CDA is always the entryIRI, the extension is different if this is a specialisation.
             If this entry is the root of another then the extension records that entry, otherwise the extension is the same as the root. 
             The cityEHR:origin attribute is used at runtime to record the origin of supplementary data sets and the category of sorted multiple entries.
             It is also set to 'cityEHR:Template' in the template entry for a multiple entry (so that it can be ignored in calculations) -->
        <!-- Get property for #isRootOf or #hasExtension (from 2019-02-13).
             2019-02-13 - the specialisationProperty changed from isRootOf to hasExtension -->
        <xsl:variable name="specialisationProperty" as="xs:string"
            select="
                if (exists($rootNode/owl:Declaration[owl:ObjectProperty/@IRI = '#hasRoot'])) then
                    '#isRootOf'
                else
                    '#hasExtension'"/>
        <xsl:variable name="recordedEntryIRI" as="xs:string"
            select="
                if (exists(key('specifiedObjectPropertyList', concat($specialisationProperty, $entryIRI), $rootNode))) then
                    key('specifiedObjectPropertyList', concat($specialisationProperty, $entryIRI), $rootNode)[1]
                else
                    $entryIRI"/>
        <typeId xmlns="urn:hl7-org:v3" root="cityEHR" extension="{$entryType}"/>
        <id xmlns="urn:hl7-org:v3" root="{$entryIRI}" extension="{$recordedEntryIRI}" cityEHR:origin="{$origin}"/>
        <code xmlns="urn:hl7-org:v3" code="" codeSystem="cityEHR" displayName="{$displayName}"/>

        <!-- Add a code element for each codePoint with this entry as Context ***jc
             2023-11 - Use single code point and have associated CodeSet composition with the codes
             TBD
        
        <ObjectPropertyAssertion>
            <ObjectProperty IRI="#hasContext"/>
            <NamedIndividual IRI="#CityEHR:CodePoint:BMIObese"/>
            <NamedIndividual IRI="#ISO-13606:EntryBMI"/>
        </ObjectPropertyAssertion>
        
        -->
        <xsl:variable name="entryCodePoints"
            select="$rootNode/owl:ObjectPropertyAssertion[owl:ObjectProperty/@IRI = '#hasContext'][owl:NamedIndividual[2]/@IRI = $recordedEntryIRI]/owl:NamedIndividual[1]/@IRI"/>

        <!-- Iterate through the codePoints -->
        <xsl:for-each select="$entryCodePoints">
            <xsl:variable name="codePointIRI" select="."/>

            <xsl:variable name="code" as="xs:string"
                select="
                    if (exists(key('specifiedDataPropertyList', concat('#hasCode', $codePointIRI), $rootNode))) then
                        key('specifiedDataPropertyList', concat('#hasCode', $codePointIRI), $rootNode)[1]
                    else
                        ''"/>
            <xsl:variable name="codeSystem" as="xs:string"
                select="
                    if (exists(key('specifiedObjectPropertyList', concat('hasCodeSystem', $codePointIRI), $rootNode))) then
                        key('specifiedObjectPropertyList', concat('hasCodeSystem', $codePointIRI), $rootNode)[1]
                    else
                        ''"/>

            <xsl:variable name="displayNameTermIRI" as="xs:string"
                select="
                    if (exists(key('termIRIList', $codePointIRI, $rootNode))) then
                        key('termIRIList', $codePointIRI, $rootNode)[1]
                    else
                        ''"/>
            <xsl:variable name="displayNameTerm" as="xs:string"
                select="
                    if (exists(key('termDisplayNameList', $displayNameTermIRI, $rootNode))) then
                        key('termDisplayNameList', $displayNameTermIRI, $rootNode)[1]
                    else
                        ''"/>

            <xsl:variable name="conditions" as="xs:string"
                select="
                    if (exists(key('specifiedDataPropertyList', concat('#hasConditions', $codePointIRI), $rootNode))) then
                        key('specifiedDataPropertyList', concat('#hasConditions', $codePointIRI), $rootNode)[1]
                    else
                        ''"/>
            <xsl:variable name="expandedConditions">
                <xsl:call-template name="expandExpression">
                    <xsl:with-param name="expressionType" select="'condition'"/>
                    <xsl:with-param name="contextEntryIRI" select="$entryIRI"/>
                    <xsl:with-param name="contextContentIRI" select="''"/>
                    <xsl:with-param name="evaluationContext" select="''"/>
                    <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                    <xsl:with-param name="expression" select="$conditions"/>
                </xsl:call-template>
            </xsl:variable>

            <xsl:variable name="visibility" as="xs:string"
                select="
                    if ($conditions = '') then
                        'true'
                    else
                        ''"/>

            <code-1 xmlns="urn:hl7-org:v3" code="{$code}" codeSystem="{$codeSystem}" displayName="{$displayNameTerm}"
                cityEHR:conditions="{$expandedConditions}" cityEHR:visibility="{$visibility}"/>
        </xsl:for-each>

        <!--

-->
        <!-- Content in entry which is an act 
            <subject>
              <typeId root="#CityEHR:Form" extension="#CityEHR:Form:BMIData"/>
              <id root="cityEHR" extension=""/>
            </subject> 
            
            The subject in this case is a compositionIRI - the form, letter, pathway, etc which is the subject of the act.
            -->
        <xsl:if test="$entryType = '#HL7-CDA:Act'">
            <xsl:variable name="subjectCompositionIRI" as="xs:string"
                select="
                    if (exists(key('specifiedObjectPropertyList', concat('#hasSubject', $entryIRI), $rootNode))) then
                        key('specifiedObjectPropertyList', concat('#hasSubject', $entryIRI), $rootNode)[1]
                    else
                        ''"/>

            <xsl:variable name="subjectCompositionTypeIRI" as="xs:string"
                select="
                    if (exists(key('classIRIList', $subjectCompositionIRI, $rootNode))) then
                        key('classIRIList', $subjectCompositionIRI, $rootNode)[1]
                    else
                        ''"/>
            <xsl:variable name="subjectCompositionDisplayNameTermIRI" as="xs:string"
                select="
                    if (exists(key('termIRIList', $subjectCompositionIRI, $rootNode))) then
                        key('termIRIList', $subjectCompositionIRI, $rootNode)[1]
                    else
                        ''"/>
            <xsl:variable name="subjectCompositionDisplayNameTerm" as="xs:string"
                select="
                    if (exists(key('termDisplayNameList', $subjectCompositionDisplayNameTermIRI, $rootNode))) then
                        key('termDisplayNameList', $subjectCompositionDisplayNameTermIRI, $rootNode)[1]
                    else
                        ''"/>

            <subject xmlns="urn:hl7-org:v3">
                <typeId root="{$subjectCompositionTypeIRI}" extension="{$subjectCompositionIRI}"/>
                <id root="cityEHR" extension=""/>
                <code xmlns="urn:hl7-org:v3" code="" codeSystem="cityEHR" displayName="{$subjectCompositionDisplayNameTerm}"/>
            </subject>
        </xsl:if>



        <!-- Iterate through clusters and elements in an entry 
                <ObjectPropertyAssertion>
                    <ObjectProperty IRI="#hasContent"/>
                    <NamedIndividual IRI="$entryIRI"/>
                    <NamedIndividual IRI="contentIRI"/>
                </ObjectPropertyAssertion>   
                
                Content is either a ISO-13606:Cluster or ISO-13606:Element.
                Contents are sorted in the order defined by the hasContentsList data attribute.
                The position order is determined by the length of the string before the cluster/element is matched in the list               
        -->
        <!-- Get data property for #hasContentsList
              Has IRIs separated by spaces-->
        <xsl:variable name="contentsList" as="xs:string"
            select="
                if (exists(key('specifiedDataPropertyList', concat('#hasContentsList', $entryIRI), $rootNode))) then
                    key('specifiedDataPropertyList', concat('#hasContentsList', $entryIRI), $rootNode)
                else
                    ''"/>
        <xsl:variable name="contents" select="tokenize($contentsList, ' ')"/>
        <!-- Iterate through the contents of the entry -->
        <xsl:for-each select="$contents">
            <xsl:variable name="contentIRI" as="xs:string" select="."/>
            <!-- Just make sure the contentIRI is OK - tokenize with ' ' can go wrong if the string got formatted -->
            <xsl:if test="starts-with($contentIRI, '#')">
                <xsl:call-template name="processEntryComponent">
                    <xsl:with-param name="rootNode" select="$rootNode"/>
                    <xsl:with-param name="recordedEntryIRI" select="$recordedEntryIRI"/>
                    <xsl:with-param name="entryType" select="$entryType"/>
                    <xsl:with-param name="entryRendition" select="$entryRendition"/>
                    <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                    <xsl:with-param name="contentIRI" select="$contentIRI"/>
                    <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                    <xsl:with-param name="usingExpressions" select="$usingExpressions"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>


    <!-- === Template to generate an Entry with multiple occurrence (MultipleEntry) as a CDA Organizer === 
        Input parameters are the entryIRI and entryType and displayName
    -->
    <xsl:template name="generateMultipleEntry">
        <xsl:param name="rootNode"/>
        <xsl:param name="entryIRI"/>
        <xsl:param name="displayName"/>
        <xsl:param name="entryRendition"/>
        <xsl:param name="formRecordedEntries"/>
        <xsl:param name="usingExpressions"/>
        <xsl:param name="recordEvaluationContext"/>
        <xsl:param name="evaluationContext"/>
        <xsl:param name="entryCRUD"/>


        <organizer xmlns="urn:hl7-org:v3" moodCode="EVN" classCode="MultipleEntry">
            <!-- First component contains the template for the Entry.
                 The origin is set to #CityEHR:Template so that the template can be ignored in calculations -->
            <component>
                <!-- Add attribute if the entry cannot be updated.
                     This attribute is set when the entry is pre-filled, so that the pre-filled values cannot be updated and/or deleted -->
                <!--
                <xsl:if
                    test="$entryCRUD = ('#CityEHR:EntryProperty:CRD', '#CityEHR:EntryProperty:CR', '#CityEHR:EntryProperty:R', '#CityEHR:Property:CRUD:CRD', '#CityEHR:Property:CRUD:CR', '#CityEHR:Property:CRUD:R')">
                    <xsl:attribute name="cityEHR:CRUD"/>
                </xsl:if>
                -->
                <xsl:attribute name="cityEHR:CRUD">
                    <xsl:value-of select="$entryCRUD"/>
                </xsl:attribute>
                <!-- Generate the entry template -->
                <xsl:call-template name="generateEntry">
                    <xsl:with-param name="rootNode" select="$rootNode"/>
                    <xsl:with-param name="entryIRI" select="$entryIRI"/>
                    <xsl:with-param name="displayName" select="$displayName"/>
                    <xsl:with-param name="entryRendition" select="$entryRendition"/>
                    <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                    <xsl:with-param name="usingExpressions" select="$usingExpressions"/>
                    <xsl:with-param name="recordEvaluationContext" select="$recordEvaluationContext"/>
                    <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                    <xsl:with-param name="origin" select="'#CityEHR:Template'"/>
                </xsl:call-template>

            </component>
            <!-- Second component contains an organizer for the Entries that are added when the form is filled out.
                 Currently we are setting this organizer to contain an empty entry.
                 Could comment this out, although whether to use the empty entry depends on the context of the multiple entry on the form. -->
            <component>
                <organizer>
                    <!-- Only do this if we want an empty element as default
                        <component>
                            <xsl:call-template name="generateEntry">
                                <xsl:with-param name="rootNode" select="$rootNode"/>
                                <xsl:with-param name="entryIRI" select="$entryIRI"/>
                                <xsl:with-param name="displayName" select="$displayName"/>
                                <xsl:with-param name="entryRendition" select="$entryRendition"/>
                                <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                                <xsl:with-param name="usingExpressions" select="$usingExpressions"/>
                                <xsl:with-param name="origin"
                                select="''"/>
                            </xsl:call-template>
                        </component>
                    -->
                </organizer>
            </component>
        </organizer>
    </xsl:template>


    <!-- === Template to process content component for an entry.
        The component may be a cluster or an element
    -->
    <xsl:template name="processEntryComponent">
        <xsl:param name="rootNode"/>
        <xsl:param name="recordedEntryIRI"/>
        <xsl:param name="entryType"/>
        <xsl:param name="entryRendition"/>
        <xsl:param name="formRecordedEntries"/>
        <xsl:param name="contentIRI"/>
        <xsl:param name="evaluationContext"/>
        <xsl:param name="usingExpressions"/>

        <!-- A cluster should have a list of contents (elements and/or clusters) -->
        <xsl:variable name="cluster" as="xs:string"
            select="
                if (exists(key('contentsIRIList', $contentIRI, $rootNode))) then
                    'true'
                else
                    'false'"/>

        <!-- Better to just get the type of the contentIRI and see if its a cluster -->
        <xsl:variable name="contentTypeIRI" as="xs:string"
            select="
                if (exists(key('classIRIList', $contentIRI, $rootNode))) then
                    key('classIRIList', $contentIRI, $rootNode)[1]
                else
                    ''"/>

        <!-- Generate the contents of a cluster -->
        <xsl:if test="$contentTypeIRI = '#ISO-13606:Cluster'">
            <xsl:call-template name="generateCluster">
                <xsl:with-param name="rootNode" select="$rootNode"/>
                <xsl:with-param name="recordedEntryIRI" select="$recordedEntryIRI"/>
                <xsl:with-param name="entryType" select="$entryType"/>
                <xsl:with-param name="entryRendition" select="$entryRendition"/>
                <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                <xsl:with-param name="clusterIRI" select="$contentIRI"/>
                <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                <xsl:with-param name="usingExpressions" select="$usingExpressions"/>
            </xsl:call-template>
        </xsl:if>

        <!-- Not a cluster, just generate the element -->
        <xsl:if test="$contentTypeIRI != '#ISO-13606:Cluster'">
            <xsl:call-template name="generateElement">
                <xsl:with-param name="rootNode" select="$rootNode"/>
                <xsl:with-param name="recordedEntryIRI" select="$recordedEntryIRI"/>
                <xsl:with-param name="entryType" select="$entryType"/>
                <xsl:with-param name="entryRendition" select="$entryRendition"/>
                <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                <xsl:with-param name="elementIRI" select="$contentIRI"/>
                <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                <xsl:with-param name="usingExpressions" select="$usingExpressions"/>
            </xsl:call-template>
        </xsl:if>

    </xsl:template>


    <!-- === Template to generate a Cluster === 
        Input parameter is the clusterIRI 
    -->
    <xsl:template name="generateCluster">
        <xsl:param name="rootNode"/>
        <xsl:param name="recordedEntryIRI"/>
        <xsl:param name="entryType"/>
        <xsl:param name="entryRendition"/>
        <xsl:param name="formRecordedEntries"/>
        <xsl:param name="clusterIRI"/>
        <xsl:param name="evaluationContext"/>
        <xsl:param name="usingExpressions"/>

        <xsl:variable name="clusterDisplayNameTermIRI" as="xs:string"
            select="
                if (exists(key('termIRIList', $clusterIRI, $rootNode))) then
                    key('termIRIList', $clusterIRI, $rootNode)[1]
                else
                    ''"/>
        <xsl:variable name="clusterDisplayNameTerm" as="xs:string"
            select="
                if (exists(key('termDisplayNameList', $clusterDisplayNameTermIRI, $rootNode))) then
                    key('termDisplayNameList', $clusterDisplayNameTermIRI, $rootNode)[1]
                else
                    ''"/>

        <!-- From 2017-10-09 no longer using proxy for cluster since clusters are just used for layout, not context  
             Check whether this cluster is the root of another (i.e. is a proxy cluster).
            The root of the cluster in the CDA is always the clusterIRI.
            If this cluster is the root of another then the extension records that cluster, otherwise the extension is the same as the root. -->
        <!-- Get property for #isRootOf -->
        <!--
        <xsl:variable name="recordedClusterIRI" as="xs:string"
            select="if (exists(key('specifiedObjectPropertyList',concat('#isRootOf',$clusterIRI),$rootNode))) then key('specifiedObjectPropertyList',concat('#isRootOf',$clusterIRI),$rootNode)[1] else $clusterIRI"/>
        -->

        <!-- Get data property for #hasConditions -->
        <xsl:variable name="clusterConditions" as="xs:string"
            select="
                if (exists(key('specifiedDataPropertyList', concat('#hasConditions', $clusterIRI), $rootNode))) then
                    key('specifiedDataPropertyList', concat('#hasConditions', $clusterIRI), $rootNode)
                else
                    ''"/>
        <xsl:variable name="expandedClusterConditions">
            <xsl:call-template name="expandExpression">
                <xsl:with-param name="expressionType" select="'condition'"/>
                <xsl:with-param name="contextEntryIRI" select="$recordedEntryIRI"/>
                <xsl:with-param name="contextContentIRI" select="$clusterIRI"/>
                <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                <xsl:with-param name="expression" select="$clusterConditions"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- Get data property for #hasContentsList
             Has IRIs separated by spaces -->
        <xsl:variable name="contentsList" as="xs:string"
            select="
                if (exists(key('specifiedDataPropertyList', concat('#hasContentsList', $clusterIRI), $rootNode))) then
                    key('specifiedDataPropertyList', concat('#hasContentsList', $clusterIRI), $rootNode)
                else
                    ''"/>
        <xsl:variable name="contents" select="tokenize($contentsList, ' ')"/>

        <value xmlns="urn:hl7-org:v3" code="" codeSystem="" displayName="" root="{$clusterIRI}" extension="{$clusterIRI}"
            cityEHR:elementDisplayName="{$clusterDisplayNameTerm}">

            <xsl:call-template name="addComponentAttribute">
                <xsl:with-param name="rootNode" select="$rootNode"/>
                <xsl:with-param name="componentIRI" select="$clusterIRI"/>
                <xsl:with-param name="property" select="'#hasSequence'"/>
            </xsl:call-template>

            <!-- If using expressions -->
            <xsl:if test="$usingExpressions = 'true'">
                <!-- Add attibutes if the cluster has conditional visibility -->
                <xsl:if test="string-length($expandedClusterConditions) &gt; 0">
                    <xsl:attribute name="cityEHR:conditions">
                        <xsl:value-of select="$expandedClusterConditions"/>
                    </xsl:attribute>
                    <xsl:attribute name="cityEHR:visibility"/>
                </xsl:if>
            </xsl:if>

            <!-- Iterate through the contents of the cluster.
                 Can be another cluster or an element -->
            <xsl:for-each select="$contents">
                <xsl:variable name="contentIRI" as="xs:string" select="."/>

                <!-- Just make sure the contentIRI is OK - tokenize with ' ' can go wrong if the string got formatted -->
                <xsl:if test="starts-with($contentIRI, '#')">
                    <xsl:call-template name="processEntryComponent">
                        <xsl:with-param name="rootNode" select="$rootNode"/>
                        <xsl:with-param name="recordedEntryIRI" select="$recordedEntryIRI"/>
                        <xsl:with-param name="entryType" select="$entryType"/>
                        <xsl:with-param name="entryRendition" select="$entryRendition"/>
                        <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                        <xsl:with-param name="contentIRI" select="$contentIRI"/>
                        <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                        <xsl:with-param name="usingExpressions" select="$usingExpressions"/>
                    </xsl:call-template>
                </xsl:if>
            </xsl:for-each>

        </value>

    </xsl:template>


    <!-- === Template to generate an Element === 
         Input parameter is the elementIRI.
         The 
    -->
    <xsl:template name="generateElement">
        <xsl:param name="rootNode"/>
        <xsl:param name="recordedEntryIRI"/>
        <xsl:param name="entryType"/>
        <xsl:param name="entryRendition"/>
        <xsl:param name="formRecordedEntries"/>
        <xsl:param name="elementIRI"/>
        <xsl:param name="evaluationContext"/>
        <xsl:param name="usingExpressions"/>

        <!-- Set elementId from the IRI -->
        <xsl:variable name="elementId" select="substring-after($elementIRI, 'Element:')"/>

        <!-- Check whether this element is the root of another (i.e. is a proxy element).
            The root of the element in the CDA is always the elementIRI.
            If this element is the root of another then the extension records that element, otherwise the extension is the same as the root. -->

        <!-- Get property for #isRootOf or #hasExtension (from 2019-02-13).
             2019-02-13 - the specialisationProperty changed from isRootOf to hasExtension -->
        <xsl:variable name="specialisationProperty" as="xs:string"
            select="
                if (exists($rootNode/owl:Declaration[owl:ObjectProperty/@IRI = '#hasRoot'])) then
                    '#isRootOf'
                else
                    '#hasExtension'"/>
        <xsl:variable name="recordedElementIRI" as="xs:string"
            select="
                if (exists(key('specifiedObjectPropertyList', concat($specialisationProperty, $elementIRI), $rootNode))) then
                    key('specifiedObjectPropertyList', concat($specialisationProperty, $elementIRI), $rootNode)[1]
                else
                    $elementIRI"/>

        <!-- Get property for #hasDataType
             Properties are of the form #CityEHR:Property:DataType:string or #CityEHR:DataType:string
             Depending on whether 2018 or 2017 ontologyVersion -->
        <xsl:variable name="elementDataType" as="xs:string"
            select="
                if (exists(key('specifiedObjectPropertyList', concat('#hasDataType', $elementIRI), $rootNode))) then
                    key('specifiedObjectPropertyList', concat('#hasDataType', $elementIRI), $rootNode)[1]
                else
                    ''"/>
        <xsl:variable name="dataType" as="xs:string"
            select="
                if (string-length(substring-after($elementDataType, 'DataType:')) > 0) then
                    concat('xs:', substring-after($elementDataType, 'DataType:'))
                else
                    'xs:string'"/>

        <!-- Get displayNameTerm -->
        <xsl:variable name="elementDisplayNameTermIRI" as="xs:string"
            select="
                if (exists(key('termIRIList', $elementIRI, $rootNode))) then
                    key('termIRIList', $elementIRI, $rootNode)[1]
                else
                    ''"/>
        <xsl:variable name="elementDisplayNameTerm" as="xs:string"
            select="
                if (exists(key('termDisplayNameList', $elementDisplayNameTermIRI, $rootNode))) then
                    key('termDisplayNameList', $elementDisplayNameTermIRI, $rootNode)[1]
                else
                    ''"/>

        <!-- Get property for #hasElementType ***jc1-->
        <xsl:variable name="elementTypeIRI" as="xs:string"
            select="cityEHRFunction:getObjectPropertyValue($rootNode, $elementIRI, 'ElementProperty', '#hasElementType')"/>


        <!-- Get properties for first #hasValue.
             These are the value and displayName of the value -->
        <xsl:variable name="firstValueIRI" as="xs:string"
            select="
                if (exists(key('specifiedObjectPropertyList', concat('#hasValue', $elementIRI), $rootNode))) then
                    key('specifiedObjectPropertyList', concat('#hasValue', $elementIRI), $rootNode)[1]
                else
                    ''"/>
        <xsl:variable name="firstValueValue" as="xs:string"
            select="
                if (exists(key('specifiedDataPropertyList', concat('#hasValue', $firstValueIRI), $rootNode))) then
                    key('specifiedDataPropertyList', concat('#hasValue', $firstValueIRI), $rootNode)[1]
                else
                    ''"/>
        <xsl:variable name="firstValueDisplayNameTermIRI" as="xs:string"
            select="
                if (exists(key('termIRIList', $firstValueIRI, $rootNode))) then
                    key('termIRIList', $firstValueIRI, $rootNode)[1]
                else
                    ''"/>
        <xsl:variable name="firstValueDisplayNameTerm" as="xs:string"
            select="
                if (exists(key('termDisplayNameList', $firstValueDisplayNameTermIRI, $rootNode))) then
                    key('termDisplayNameList', $firstValueDisplayNameTermIRI, $rootNode)[1]
                else
                    ''"/>

        <!-- If elementTypeIRI is #CityEHR:ElementProperty:url then the value and displayName for the element need to be fixed. -->
        <xsl:if test="$elementTypeIRI = ('#CityEHR:ElementProperty:url', '#CityEHR:Property:ElementType:url')"> </xsl:if>

        <!-- Value for element is blank unless its an xs:boolean or a URL
             2018-02-12 Now setting default value of false for xs:boolean when forms are loaded -->
        <xsl:variable name="value" as="xs:string"
            select="
                if ($dataType = 'xs:boolean') then
                    ''
                else
                    if ($elementTypeIRI = ('#CityEHR:ElementProperty:url', '#CityEHR:Property:ElementType:url')) then
                        $firstValueValue
                    else
                        ''"/>

        <!-- Display name for element is blank unless its a URL -->
        <xsl:variable name="displayName" as="xs:string"
            select="
                if ($elementTypeIRI = ('#CityEHR:ElementProperty:url', '#CityEHR:Property:ElementType:url')) then
                    $firstValueDisplayNameTerm
                else
                    ''"/>

        <!-- Get property for #hasUnit.
             This property is either #CityEHR:Unit:Id (specified units) or #ISO-13606:Element:Id (calculated units).
        
             If the IRI is of the form #CityEHR:Unit:Id then it should have a unit term, otherwise this will not be found (and is then set to '')
        
             If the IRI is of the form #ISO-13606:Element:Id then a calculatedUnit will be set (see below) -->
        <xsl:variable name="elementUnitIRI" as="xs:string"
            select="
                if (exists(key('specifiedObjectPropertyList', concat('#hasUnit', $elementIRI), $rootNode))) then
                    key('specifiedObjectPropertyList', concat('#hasUnit', $elementIRI), $rootNode)[1]
                else
                    ''"/>
        <xsl:variable name="elementUnitClassIRI" select="key('classIRIList', $elementUnitIRI, $rootNode)"/>
        <xsl:variable name="elementUnitTermIRI" as="xs:string"
            select="
                if ($elementUnitClassIRI = '#CityEHR:Unit' and exists(key('termIRIList', $elementUnitIRI, $rootNode))) then
                    key('termIRIList', $elementUnitIRI, $rootNode)[1]
                else
                    ''"/>
        <xsl:variable name="elementUnitTerm" as="xs:string"
            select="
                if (exists(key('termDisplayNameList', $elementUnitTermIRI, $rootNode))) then
                    key('termDisplayNameList', $elementUnitTermIRI, $rootNode)[1]
                else
                    ''"/>


        <!-- Get property for #hasRendition -->
        <!--
        <xsl:variable name="elementRenditionIRI" as="xs:string"
            select="
                if (exists(key('specifiedObjectPropertyList', concat('#hasRendition', $elementIRI), $rootNode))) then
                    key('specifiedObjectPropertyList', concat('#hasRendition', $elementIRI), $rootNode)[1]
                else
                    '#CityEHR:Property:Rendition:Form'"/>
                    -->
        <xsl:variable name="elementRenditionIRI" as="xs:string"
            select="cityEHRFunction:getObjectPropertyValue($rootNode, $elementIRI, 'ElementProperty', '#hasRendition')"/>


        <!-- Get property for #hasScope -->
        <!--
        <xsl:variable name="elementScopeIRI" as="xs:string"
            select="
                if (exists(key('specifiedObjectPropertyList', concat('#hasScope', $elementIRI), $rootNode))) then
                    key('specifiedObjectPropertyList', concat('#hasScope', $elementIRI), $rootNode)[1]
                else
                    ''"/>
                    -->
        <xsl:variable name="elementScopeIRI" as="xs:string"
            select="cityEHRFunction:getObjectPropertyValue($rootNode, $elementIRI, 'ElementProperty', '#hasScope')"/>


        <!-- Get property for #hasPrecision -->
        <xsl:variable name="elementPrecision" as="xs:string"
            select="
                if (exists(key('specifiedDataPropertyList', concat('#hasPrecision', $elementIRI), $rootNode))) then
                    key('specifiedDataPropertyList', concat('#hasPrecision', $elementIRI), $rootNode)[1]
                else
                    ''"/>

        <!-- Get data property for #hasCalculatedValue -->
        <xsl:variable name="elementCalculatedValue" as="xs:string"
            select="
                if (exists(key('specifiedDataPropertyList', concat('#hasCalculatedValue', $elementIRI), $rootNode))) then
                    key('specifiedDataPropertyList', concat('#hasCalculatedValue', $elementIRI), $rootNode)
                else
                    ''"/>
        <xsl:variable name="expandedElementCalculatedValue" as="xs:string">
            <xsl:call-template name="expandExpression">
                <xsl:with-param name="expressionType" select="'calculation'"/>
                <xsl:with-param name="contextEntryIRI" select="$recordedEntryIRI"/>
                <xsl:with-param name="contextContentIRI" select="$recordedElementIRI"/>
                <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                <xsl:with-param name="expression" select="$elementCalculatedValue"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- Get property for #hasDefaultValue -->
        <xsl:variable name="elementDefaultValue" as="xs:string"
            select="
                if (exists(key('specifiedDataPropertyList', concat('#hasDefaultValue', $elementIRI), $rootNode))) then
                    key('specifiedDataPropertyList', concat('#hasDefaultValue', $elementIRI), $rootNode)[1]
                else
                    ''"/>
        <xsl:variable name="expandedElementDefaultValue" as="xs:string">
            <xsl:call-template name="expandExpression">
                <xsl:with-param name="expressionType" select="'calculation'"/>
                <xsl:with-param name="contextEntryIRI" select="$recordedEntryIRI"/>
                <xsl:with-param name="contextContentIRI" select="$recordedElementIRI"/>
                <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                <xsl:with-param name="expression" select="$elementDefaultValue"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- Get data property for #hasConstraints -->
        <xsl:variable name="elementConstraints" as="xs:string"
            select="
                if (exists(key('specifiedDataPropertyList', concat('#hasConstraints', $elementIRI), $rootNode))) then
                    key('specifiedDataPropertyList', concat('#hasConstraints', $elementIRI), $rootNode)
                else
                    ''"/>
        <xsl:variable name="expandedElementConstraints" as="xs:string">
            <xsl:call-template name="expandExpression">
                <xsl:with-param name="expressionType" select="'condition'"/>
                <xsl:with-param name="contextEntryIRI" select="$recordedEntryIRI"/>
                <xsl:with-param name="contextContentIRI" select="$recordedElementIRI"/>
                <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                <xsl:with-param name="expression" select="$elementConstraints"/>
            </xsl:call-template>
        </xsl:variable>

        <!-- Get data property for #hasConditions -->
        <xsl:variable name="elementConditions" as="xs:string"
            select="
                if (exists(key('specifiedDataPropertyList', concat('#hasConditions', $elementIRI), $rootNode))) then
                    key('specifiedDataPropertyList', concat('#hasConditions', $elementIRI), $rootNode)
                else
                    ''"/>
        <xsl:variable name="expandedElementConditions">
            <xsl:call-template name="expandExpression">
                <xsl:with-param name="expressionType" select="'condition'"/>
                <xsl:with-param name="contextEntryIRI" select="$recordedEntryIRI"/>
                <xsl:with-param name="contextContentIRI" select="$recordedElementIRI"/>
                <xsl:with-param name="formRecordedEntries" select="$formRecordedEntries"/>
                <xsl:with-param name="evaluationContext" select="$evaluationContext"/>
                <xsl:with-param name="expression" select="$elementConditions"/>
            </xsl:call-template>
        </xsl:variable>


        <!-- Element in entry which is an observation  -->
        <xsl:if test="$entryType = '#HL7-CDA:Observation'">
            <value xmlns="urn:hl7-org:v3" root="{$elementIRI}" extension="{$recordedElementIRI}" xsi:type="{$dataType}" value="{$value}"
                units="{$elementUnitTerm}" code="" codeSystem="" displayName="{$displayName}" cityEHR:elementDisplayName="{$elementDisplayNameTerm}"
                cityEHR:elementType="{$elementTypeIRI}" cityEHR:focus="">
                
                <!-- Add attribute for RequiredValue -->
                <xsl:call-template name="addComponentAttribute">
                    <xsl:with-param name="rootNode" select="$rootNode"/>
                    <xsl:with-param name="componentIRI" select="$elementIRI"/>
                    <xsl:with-param name="property" select="'#hasRequiredValue'"/>
                </xsl:call-template>

                <!-- Add attribute if the element has a specified field length -->
                <xsl:if test="string-length($elementPrecision) &gt; 0">
                    <xsl:attribute name="cityEHR:Precision">
                        <xsl:value-of select="$elementPrecision"/>
                    </xsl:attribute>
                </xsl:if>

                <!-- Add attribute if the element has a rendition other than the default (#CityEHR:ElementProperty:Form or #CityEHR:Property:Rendition:Form) -->
                <xsl:if test="not($elementRenditionIRI = ('#CityEHR:ElementProperty:Form', '#CityEHR:Property:Rendition:Form'))">
                    <xsl:attribute name="cityEHR:elementRendition">
                        <xsl:value-of select="$elementRenditionIRI"/>
                    </xsl:attribute>
                </xsl:if>

                <!-- Add attribute if the element id for an entry with Image rendition -->
                <xsl:if test="$entryRendition = ('#CityEHR:EntryProperty:Image', '#CityEHR:Property:Rendition:Image')">
                    <xsl:attribute name="cityEHR:height"/>
                    <xsl:attribute name="cityEHR:width"/>
                </xsl:if>

                <!-- Add attribute if the element has a scope (of full or expanded) -->
                <xsl:if test="string-length($elementScopeIRI) &gt; 0">
                    <xsl:attribute name="cityEHR:Scope">
                        <xsl:value-of select="$elementScopeIRI"/>
                    </xsl:attribute>
                </xsl:if>

                <!-- Add attribute if the element has calculated units -->
                <xsl:if test="starts-with($elementUnitIRI, '#ISO-13606:Element')">
                    <xsl:attribute name="cityEHR:calculatedUnit">
                        <xsl:value-of select="$elementUnitIRI"/>
                    </xsl:attribute>
                </xsl:if>

                <!-- Add attribute to carry supplementary data set if element is of enumeratedClass type -->
                <xsl:if test="$elementTypeIRI = ('#CityEHR:ElementProperty:enumeratedClass', '#CityEHR:Property:ElementType:enumeratedClass')">
                    <xsl:attribute name="cityEHR:suppDataSet"/>
                </xsl:if>
                <!-- Add attribute to carry input control Id if element is of enumeratedClass type -->
                <xsl:if test="$elementTypeIRI = ('#CityEHR:ElementProperty:enumeratedClass', '#CityEHR:Property:ElementType:enumeratedClass')">
                    <xsl:attribute name="cityEHR:elementControlId"/>
                </xsl:if>

                <!-- Calculated values, default values and constraints are processed if usingExpressions (i.e. for a form) -->
                <xsl:if test="$usingExpressions = 'true'">

                    <!-- Add attibutes if the element has conditional visibility -->
                    <xsl:if test="string-length($expandedElementConditions) &gt; 0">
                        <xsl:attribute name="cityEHR:conditions">
                            <xsl:value-of select="$expandedElementConditions"/>
                        </xsl:attribute>
                        <xsl:attribute name="cityEHR:visibility"/>
                    </xsl:if>

                    <!-- Add attribute if the element has a calculated value -->
                    <xsl:if test="string-length($expandedElementCalculatedValue) &gt; 0">
                        <xsl:attribute name="cityEHR:calculatedValue">
                            <xsl:value-of select="$expandedElementCalculatedValue"/>
                        </xsl:attribute>
                    </xsl:if>

                    <!-- Add attribute if the element has a default value -->
                    <xsl:if test="string-length($expandedElementDefaultValue) &gt; 0">
                        <xsl:attribute name="cityEHR:defaultValue">
                            <xsl:value-of select="$expandedElementDefaultValue"/>
                        </xsl:attribute>
                    </xsl:if>

                    <!-- Add attribute if the element has a constraint -->
                    <xsl:if test="string-length($expandedElementConstraints) &gt; 0">
                        <xsl:attribute name="cityEHR:constraints">
                            <xsl:value-of select="$expandedElementConstraints"/>
                        </xsl:attribute>
                    </xsl:if>
                </xsl:if>
            </value>
        </xsl:if>


        <!-- Element in entry which is an act 
            <subject>
              <typeId root="#CityEHR:Form" extension="#CityEHR:Form:BMIData"/>
              <id root="cityEHR" extension=""/>
            </subject> 
            
            The elementIRI in this case is a compositionIRI - the form, letter, pathway, etc which is the subject of the act.
            -->
        <xsl:if test="$entryType = '#HL7-CDA:Act'">
            <xsl:variable name="subjectCompositionIRI" as="xs:string" select="replace($elementIRI, '#ISO-13606:', '#CityEHR:')"/>

            <xsl:variable name="subjectCompositionTypeIRI" as="xs:string"
                select="
                    if (exists(key('classIRIList', $subjectCompositionIRI, $rootNode))) then
                        key('classIRIList', $subjectCompositionIRI, $rootNode)[1]
                    else
                        ''"/>
            <xsl:variable name="subjectCompositionDisplayNameTermIRI" as="xs:string"
                select="
                    if (exists(key('termIRIList', $subjectCompositionIRI, $rootNode))) then
                        key('termIRIList', $subjectCompositionIRI, $rootNode)[1]
                    else
                        ''"/>
            <xsl:variable name="subjectCompositionDisplayNameTerm" as="xs:string"
                select="
                    if (exists(key('termDisplayNameList', $subjectCompositionDisplayNameTermIRI, $rootNode))) then
                        key('termDisplayNameList', $subjectCompositionDisplayNameTermIRI, $rootNode)[1]
                    else
                        ''"/>

            <subject xmlns="urn:hl7-org:v3">
                <typeId root="{$subjectCompositionTypeIRI}" extension="{$subjectCompositionIRI}"/>
                <id root="cityEHR" extension=""/>
                <code xmlns="urn:hl7-org:v3" code="" codeSystem="cityEHR" displayName="{$subjectCompositionDisplayNameTerm}"/>
            </subject>
        </xsl:if>


        <!-- Element in entry which is an encounter 
            <participant>
                <participantRole>
                <id root="#ISO-13606:Element:BookingAction" extension="#ISO-13606:Element:BookingAction"/>
                <playingEntity xsi:type="xs:string" cityEHR:elementDisplayName="Appointment" value="book" code="" codeSystem="" displayName=""/>
                </participantRole>
            </participant>
        -->
        <xsl:if test="$entryType = '#HL7-CDA:Encounter'">
            <participant xmlns="urn:hl7-org:v3">
                <participantRole>
                    <id root="{$elementIRI}" extension="{$recordedElementIRI}"/>
                    <playingEntity xsi:type="{$dataType}" value="{$value}" units="" code="" codeSystem="" displayName=""
                        cityEHR:elementDisplayName="{$elementDisplayNameTerm}" cityEHR:elementType="{$elementTypeIRI}">
                        
                        <!-- Add attribute for RequiredValue -->
                        <xsl:call-template name="addComponentAttribute">
                            <xsl:with-param name="rootNode" select="$rootNode"/>
                            <xsl:with-param name="componentIRI" select="$elementIRI"/>
                            <xsl:with-param name="property" select="'#hasRequiredValue'"/>
                        </xsl:call-template>
                        

                        <!-- Add attribute if the element has a specified field length -->
                        <xsl:if test="string-length($elementPrecision) &gt; 0">
                            <xsl:attribute name="cityEHR:Precision">
                                <xsl:value-of select="$elementPrecision"/>
                            </xsl:attribute>
                        </xsl:if>

                        <!-- Add attribute to carry supplementary data set if element is of enumeratedClass type -->
                        <xsl:if test="$elementTypeIRI = ('#CityEHR:ElementProperty:enumeratedClass', '#CityEHR:Property:ElementType:enumeratedClass')">
                            <xsl:attribute name="cityEHR:suppDataSet"/>
                        </xsl:if>

                        <!-- Calculated values and constraints are processed if usingExpressions (i.e. for a form) -->
                        <xsl:if test="$usingExpressions = 'true'">
                            <!-- Add attribute if the element has a calculated value -->
                            <xsl:if test="string-length($expandedElementCalculatedValue) &gt; 0">
                                <xsl:attribute name="cityEHR:calculatedValue">
                                    <xsl:value-of select="$expandedElementCalculatedValue"/>
                                </xsl:attribute>
                            </xsl:if>
                            <!-- Add attribute if the element has a constraint -->
                            <xsl:if test="string-length($expandedElementConstraints) &gt; 0">
                                <xsl:attribute name="cityEHR:constraints">
                                    <xsl:value-of select="$expandedElementConstraints"/>
                                </xsl:attribute>
                            </xsl:if>
                        </xsl:if>
                    </playingEntity>
                </participantRole>
            </participant>

        </xsl:if>


    </xsl:template>


    <!-- ====================================================================
        Get the sections in the form.
        Uses $compositionIRI and iterates through every section and subsection, outputting its IRI.       
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getFormSections">
        <xsl:param name="rootNode"/>
        <xsl:param name="compositionIRI"/>
        <xsl:for-each select="key('contentsIRIList', $compositionIRI, $rootNode)">

            <xsl:variable name="sectionIRI" as="xs:string" select="."/>

            <!-- Output the section IRI -->
            <xsl:value-of select="$sectionIRI"/>

            <xsl:for-each select="cityEHRFunction:getSectionSections($rootNode, $sectionIRI)">
                <xsl:value-of select="."/>
            </xsl:for-each>

        </xsl:for-each>

        <!-- If the composition has a header, then this is also a section -->

        <xsl:if test="exists(key('specifiedObjectPropertyList', concat('#hasHeader', $compositionIRI), $rootNode))">
            <xsl:variable name="headerSectionIRI" as="xs:string"
                select="key('specifiedObjectPropertyList', concat('#hasHeader', $compositionIRI), $rootNode)"/>
            <xsl:if test="$headerSectionIRI != ''">
                <xsl:value-of select="$headerSectionIRI"/>
                <xsl:for-each select="cityEHRFunction:getSectionSections($rootNode, $headerSectionIRI)">
                    <xsl:value-of select="."/>
                </xsl:for-each>
            </xsl:if>
        </xsl:if>

    </xsl:function>


    <!-- ====================================================================
        Get the sections in a section (i.e. subsections).
        Iterates through contents of the section, outputting the IRI if content is a section.
        Then recursively calls to get the sections in that section.
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getSectionSections">
        <xsl:param name="rootNode"/>
        <xsl:param name="sectionIRI"/>
        <xsl:for-each select="key('contentsIRIList', $sectionIRI, $rootNode)">

            <xsl:variable name="contentIRI" as="xs:string" select="."/>

            <!-- Content is a section -->
            <xsl:if test="starts-with($contentIRI, '#ISO-13606:Section')">
                <!-- Output the section IRI -->
                <xsl:value-of select="$contentIRI"/>

                <!-- recursive call to get its subsections -->
                <xsl:for-each select="cityEHRFunction:getSectionSections($rootNode, $contentIRI)">
                    <xsl:value-of select="."/>
                </xsl:for-each>
            </xsl:if>

        </xsl:for-each>
    </xsl:function>


    <!-- ====================================================================
        Get the elements in a set of entries.
        Uses $entrySet and iterates through every entry getting its elements       
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getElements">
        <xsl:param name="rootNode"/>
        <xsl:param name="entrySet"/>
        <xsl:for-each select="$entrySet">

            <xsl:variable name="entryIRI" select="."/>

            <xsl:for-each select="cityEHRFunction:getEntryElements($rootNode, $entryIRI)">
                <xsl:value-of select="."/>
            </xsl:for-each>

        </xsl:for-each>
    </xsl:function>


    <!-- ====================================================================
        Get the elements in an entry.
        Uses $entryIRI and iterates through every element getting its IRI       
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getEntryElements">
        <xsl:param name="rootNode"/>
        <xsl:param name="entryIRI"/>

        <xsl:for-each select="key('contentsIRIList', $entryIRI, $rootNode)">
            <xsl:variable name="elementIRI" as="xs:string" select="."/>

            <!-- Output the element IRI -->
            <xsl:value-of select="$elementIRI"/>

        </xsl:for-each>
    </xsl:function>


    <!-- ====================================================================
        Get the entries in a form.
        Uses $compositionIRI and iterates through every section getting its entries       
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getFormEntries">
        <xsl:param name="rootNode"/>
        <xsl:param name="formSections"/>
        <xsl:for-each select="$formSections">

            <xsl:variable name="sectionIRI" as="xs:string" select="."/>

            <xsl:for-each select="cityEHRFunction:getSectionEntries($rootNode, $sectionIRI)">
                <xsl:value-of select="."/>
            </xsl:for-each>

        </xsl:for-each>
    </xsl:function>

    <!-- ====================================================================
        Get the recorded entries from a list of root entryIRIs.
        Returns the list of entries recorded (i.e. the set of @extension values)
        If the entry is not the root of another then return its id
        If the entry is the root of another then return the id of the aliased entry
        So eliminates entries that are alias of another
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getRecordedEntries">
        <xsl:param name="rootNode"/>
        <xsl:param name="entryIRIList"/>
        <xsl:for-each select="$entryIRIList">

            <xsl:variable name="entryIRI" as="xs:string" select="."/>

            <!-- Get property for #isRootOf or #hasExtension (from 2019-02-13).
                 2019-02-13 - the specialisationProperty changed from isRootOf to hasExtension -->
            <xsl:variable name="specialisationProperty" as="xs:string"
                select="
                    if (exists($rootNode/owl:Declaration[owl:ObjectProperty/@IRI = '#hasRoot'])) then
                        '#isRootOf'
                    else
                        '#hasExtension'"/>
            <xsl:variable name="recordedEntryIRI" as="xs:string"
                select="
                    if (exists(key('specifiedObjectPropertyList', concat($specialisationProperty, $entryIRI), $rootNode))) then
                        key('specifiedObjectPropertyList', concat($specialisationProperty, $entryIRI), $rootNode)[1]
                    else
                        $entryIRI"/>


            <xsl:if test="$entryIRI != $recordedEntryIRI">
                <xsl:value-of select="$recordedEntryIRI"/>
            </xsl:if>

        </xsl:for-each>
    </xsl:function>


    <!-- ====================================================================
        Get the evaluation context from a list of sectionIRIs and entryIRIs.
        Returns the set of evaluationContext strings, including the empty context ('')
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getEvaluationContext">
        <xsl:param name="componentIRIList"/>

        <xsl:for-each select="$componentIRIList">
            <xsl:variable name="componentIRI" as="xs:string" select="."/>

            <xsl:variable name="evaluationContextKey" as="xs:string" select="concat('#hasEvaluationContext', $componentIRI)"/>
            <xsl:value-of
                select="
                    if (exists(key('specifiedDataPropertyList', $evaluationContextKey, $rootNode))) then
                        key('specifiedDataPropertyList', $evaluationContextKey, $rootNode)
                    else
                        ''"/>

        </xsl:for-each>
    </xsl:function>


    <!-- ====================================================================
        Get the entries in a section 
        Iterates through contents of the section, outputting the IRI if content is an entry.
        If content is a section, recursively calls to get the entries in that section.
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getSectionEntries">
        <xsl:param name="rootNode"/>
        <xsl:param name="sectionIRI"/>
        <xsl:for-each select="key('contentsIRIList', $sectionIRI, $rootNode)">

            <xsl:variable name="contentIRI" as="xs:string" select="."/>

            <!-- Content is a section -->
            <!-- Don't need to do anything now, because the list of sections used includes the sub-sections -->
            <xsl:if test="starts-with($contentIRI, '#ISO-13606:Section')">
                <!-- recursive call to get entries in the subsection -->
                <!--
                <xsl:for-each select="cityEHRFunction:getSectionEntries($rootNode,$contentIRI)">
                    <xsl:value-of select="."/>
                </xsl:for-each>
                -->
            </xsl:if>

            <!-- Content is an entry -->
            <xsl:if test="starts-with($contentIRI, '#ISO-13606:Entry')">
                <!-- Output the entry IRI -->
                <xsl:value-of select="$contentIRI"/>
            </xsl:if>

        </xsl:for-each>
    </xsl:function>


    <!-- ==================================================================================================
         Add an attribute to a component for a specified property.
         Must be called within the context of the element to which the attribute is to be attached.
         Properties in the model are of the form #CityEHR:Property:Sequence:Unranked
         If no property exists for the component, then no attribute is added.
        ==================================================================================================== -->
    <xsl:template name="addComponentAttribute">
        <xsl:param name="rootNode"/>
        <xsl:param name="componentIRI"/>
        <xsl:param name="property"/>

        <xsl:variable name="propertyAssertion" as="xs:string"
            select="
                if (exists(key('specifiedObjectPropertyList', concat($property, $componentIRI), $rootNode))) then
                    key('specifiedObjectPropertyList', concat($property, $componentIRI), $rootNode)
                else
                    ''"/>

        <xsl:variable name="propertyAssertionTokens" select="tokenize($propertyAssertion, ':')"/>
        <xsl:variable name="propertyName" select="concat('cityEHR:',$propertyAssertionTokens[3])"/>
        <xsl:variable name="propertyValue" select="$propertyAssertionTokens[4]"/>

        <xsl:if test="$propertyValue != ''">
            <xsl:attribute name="{$propertyName}">
                <xsl:value-of select="$propertyValue"/>
            </xsl:attribute>
        </xsl:if>

    </xsl:template>


    <!-- ==================================================================================================
        Get the elements in an entry or cluster that are of the designated type.
        Element types are CityEHR:ElementProperty:memo,	CityEHR:ElementProperty:media, CityEHR:ElementProperty:calculatedValue, 
        CityEHR:ElementProperty:enumeratedValue, CityEHR:ElementProperty:enumeratedClass, CityEHR:ElementProperty:simpleType
        
        Iterates through contents of the entry/cluster, outputting the IRI if content is a matching element.
        ==================================================================================================== -->
    <xsl:template name="getComponentElements">
        <xsl:param name="componentIRI"/>
        <xsl:param name="elementType"/>

        <!-- Iterate through the content -->
        <xsl:for-each select="key('contentsIRIList', $componentIRI, $rootNode)">

            <xsl:variable name="contentIRI" as="xs:string" select="."/>

            <!-- Content is a cluster -->
            <xsl:if test="starts-with($contentIRI, '#ISO-13606:Cluster')">
                <!-- recursive call to get entries in the cluster -->
                <xsl:call-template name="getComponentElements">
                    <xsl:with-param name="componentIRI" select="$contentIRI"/>
                    <xsl:with-param name="elementType" select="$elementType"/>
                </xsl:call-template>
            </xsl:if>

            <!-- Content is an element -->
            <xsl:if
                test="starts-with($contentIRI, '#ISO-13606:Element') and key('specifiedObjectPropertyList', concat('#hasElementType', $contentIRI), $rootNode) = $elementType">
                <!-- Output the entry IRI -->
                <xsl:value-of select="$contentIRI"/>
            </xsl:if>

        </xsl:for-each>
    </xsl:template>


    <!-- ====================================================================
         Get the value of an object property ***jc1
         In the ontology V1 property is held as #CityEHR:ElementProperty:[propertyValue] or #CityEHR:EntryProperty:[propertyValue] e.g. #CityEHR:ElementProperty:enumeratedValue
         But in V2 as #CityEHR:Property:[propertyName]:[propertyValue] eg #CityEHR:Property:ElementType:enumeratedValue
         
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getObjectPropertyValue">
        <xsl:param name="rootNode"/>
        <xsl:param name="component"/>
        <xsl:param name="propertyType"/>
        <xsl:param name="property"/>

        <!-- Look up the object property -->
        <xsl:variable name="objectProperty" as="xs:string"
            select="
                if (exists(key('specifiedObjectPropertyList', concat($property, $component), $rootNode))) then
                    key('specifiedObjectPropertyList', concat($property, $component), $rootNode)[1]
                else
                    ''"/>

        <xsl:variable name="value" as="xs:string" select="tokenize($objectProperty, ':')[last()]"/>

        <!-- Convert the property to V1 format (eventually this will get refactored to just use the value -->
        <xsl:variable name="objectPropertyValue" as="xs:string"
            select="
                if ($objectProperty = '') then
                    ''
                else
                    if (contains($objectProperty, $propertyType)) then
                        $objectProperty
                    else
                        concat('#CityEHR:', $propertyType, ':', $value)"/>

        <xsl:value-of select="$objectPropertyValue"/>

    </xsl:function>


    <!-- ====================================================================
        Get the entries in the expression for a set of components.
        Uses $componentSet and iterates through every component getting its expression and analyzing it to get entries it contains 
        The $property contains the property of the components that contain the expression
        The evaluationContext is the context (or none) for the components
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getExpressionEntries">
        <xsl:param name="rootNode"/>
        <xsl:param name="componentSet"/>
        <xsl:param name="property"/>

        <xsl:for-each select="$componentSet">
            <xsl:variable name="componentIRI" select="."/>
            <xsl:variable name="expression" select="key('specifiedDataPropertyList', concat($property, $componentIRI), $rootNode)"/>

            <xsl:if test="exists($expression)">

                <xsl:for-each select="cityEHRFunction:tokenizeExpressionEntries($expression)">
                    <xsl:value-of select="."/>
                </xsl:for-each>

            </xsl:if>

        </xsl:for-each>
    </xsl:function>


    <!-- ====================================================================
        Get the entries in the expression as a set of tokens.
        Uses $expression and iterates through every match in the string getting the entry IRI
        
        Except that math:functionName is reserved for maths extension functions (at some stage the reserved namespaces may become configurable)
        ==================================================================== -->

    <xsl:function name="cityEHRFunction:tokenizeExpressionEntries">
        <xsl:param name="expression"/>
        <xsl:variable name="regex" select="concat('([-a-zA-Z0-9_]+)', $pathSeparator)"/>

        <xsl:analyze-string select="$expression" regex="{$regex}">
            <xsl:matching-substring>
                <xsl:variable name="entryId" as="xs:string" select="regex-group(1)"/>
                <xsl:if test="$entryId != 'math'">
                    <xsl:value-of select="concat('#ISO-13606:Entry:', $entryId)"/>
                </xsl:if>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>


    <!-- ====================================================================
        Get the cityEHR:lookup elements in the expression for a set of components.
        This function is of the form cityEHR:lookup(elementId,elementValue) - we are looking for the elementIds
        Uses $componentSet and iterates through every component getting its expression and analyzing it to get the cityEHR:lookup elements it contains 
        The $property contains the property of the components that contain the expression
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getExpressionLookupElements">
        <xsl:param name="rootNode"/>
        <xsl:param name="componentSet"/>
        <xsl:param name="property"/>
        <xsl:for-each select="$componentSet">
            <xsl:variable name="componentIRI" select="."/>

            <xsl:variable name="expression" select="key('specifiedDataPropertyList', concat($property, $componentIRI), $rootNode)"/>

            <xsl:if test="exists($expression)">

                <xsl:for-each select="cityEHRFunction:tokenizeExpressionLookupElements($expression)">
                    <xsl:value-of select="."/>
                </xsl:for-each>

            </xsl:if>

        </xsl:for-each>
    </xsl:function>


    <!-- ====================================================================
        Get the cityEHR:lookup elements in the expression as a set of tokens.
        This function is of the form cityEHR:lookup(elementId,elementValue) - we are looking for the elementIds
        Uses $expression and iterates through every match in the string getting the element Id
        Returns the element IRI
       ==================================================================== -->

    <xsl:function name="cityEHRFunction:tokenizeExpressionLookupElements">
        <xsl:param name="expression"/>
        <xsl:variable name="regex" select="'cityEHR:lookup\(([^,]*),[^)]*\)'"/>

        <xsl:analyze-string select="$expression" regex="{$regex}">
            <xsl:matching-substring>
                <xsl:variable name="elementId" as="xs:string" select="regex-group(1)"/>
                <xsl:if test="$elementId != ''">
                    <xsl:value-of select="concat('#ISO-13606:Element:', $elementId)"/>
                </xsl:if>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>



    <!-- ====================================================================
        Expand an expression to make it suitable for evaluation.
        There are two parts to the expanded expression:
            1) a check that each variable can be cast to its data type
            2) the expression itself, replacing variables with values from elements in the form
            
        Expressions can be for conditions on sections, entries, clusters or elements
        Pre-conditions on sections or entries
        Constraints on elements
        Calculated values or default values on elements
        
        Local paths to variables may be used in expressions on entries, clusters or elements.
        contextEntryIRI and contextContentIRI are passed as the context of the expression
        The contextEntryIRI  - the entryIRI for the entry element containing the expression (so blank for section and entry conditions)
        The contextContentIRI - the IRI for the XML element holding the expression (as an attribute) - section, entry, cluster or element
        An additional predicateEntryIRI is used in replaceExpressionVariables (then getVariableAttribute and getValueContext) to expand the 2nd argument of the built-in cityEHR:getValues function
        The evaluationContext is used to constrain variables to be found in the specified context, which is used to looukp EXTERNAL variables 
        (i.e. variables that are not in the same composition as the source of the expression)
        ==================================================================== -->
    <xsl:template name="expandExpression">
        <xsl:param name="expressionType"/>
        <xsl:param name="contextEntryIRI"/>
        <xsl:param name="contextContentIRI"/>
        <xsl:param name="formRecordedEntries"/>
        <xsl:param name="evaluationContext"/>
        <xsl:param name="expression"/>

        <xsl:if test="string-length($expression) = 0">
            <xsl:value-of select="''"/>
        </xsl:if>

        <xsl:if test="string-length($expression) &gt; 0">

            <!-- From 2018-05-10 use distinct-values so that repeated variables only result in one cast expression clause -->
            <xsl:variable name="expressionCasts"
                select="string-join(distinct-values(cityEHRFunction:getExpressionCasts($contextEntryIRI, $contextContentIRI, $evaluationContext, $formRecordedEntries, $expression)), ' and ')"/>

            <xsl:variable name="expressionEvaluation"
                select="string-join(cityEHRFunction:replaceExpressionVariables($contextEntryIRI, $contextContentIRI, 'attribute', '', $formRecordedEntries, $evaluationContext, $expression), '')"/>

            <!-- Default value is used if the expression cannot be evaluated. -->
            <xsl:variable name="defaultCalculationExpression" select="''''''"/>
            <xsl:variable name="defaultConditionExpression" select="'false()'"/>
            <xsl:variable name="defaultExpression"
                select="
                    if ($expressionType = 'calculation') then
                        $defaultCalculationExpression
                    else
                        $defaultConditionExpression"/>

            <!-- Expression context.
                 For expressions within an entry, set up as a query (for $entry in ...) so that $entry can be used as a local variable.
                 The required ancestor is cda:enty for simple entries or cda:component for multiple entries -->

            <!-- Get property for #hasOccurrence -->
            <xsl:variable name="entryOccurrence" as="xs:string"
                select="
                    if (exists(key('specifiedObjectPropertyList', concat('#hasOccurrence', $contextEntryIRI), $rootNode))) then
                        key('specifiedObjectPropertyList', concat('#hasOccurrence', $contextEntryIRI), $rootNode)[1]
                    else
                        '#CityEHR:Property:Occurrence:Single'"/>

            <xsl:variable name="expressionContext"
                select="
                    if ($contextEntryIRI = '') then
                        ''
                    else
                        if ($entryOccurrence = ('#CityEHR:EntryProperty:Single', '#CityEHR:Property:Occurrence:Single')) then
                            'for $entry in ancestor::cda:entry[1] return '
                        else
                            'for $entry in ancestor::cda:component[1] return '"/>

            <!-- Output the expression 
                 If there are expressionCasts then test them first, if not (only the case if the expression contains no variables) then just evaluate the expression
                 
                 The string-join should work with the second argument being the separator, but doesn't work for some reason.
                 If it did work, the separator for $expressionCasts would be ' and ' but instead the ' and ' is added to the end of every cast expression.
                 The last ' and ' then needs to be removed by taking off the last 5 characters of the expressionCasts string
                 
                 The expandedExpression is of the form:
                 
                 if ($expressionCasts) then ($expressionEvaluation) else ($defaultExpression)
               -->
            <xsl:variable name="expandedExpression" as="xs:string"
                select="
                    if (string-length($expressionCasts) = 0) then
                        concat($expressionContext, $expressionEvaluation)
                    else
                        concat($expressionContext, ' if (', $expressionCasts, ') then (', $expressionEvaluation, ') else ', $defaultExpression)"/>
            <xsl:value-of select="$expandedExpression"/>

        </xsl:if>

    </xsl:template>


    <!-- ====================================================================
        Get the list of casts for an expression.
        The matching in the expression is the same as the replaceExpressionVariables
        
        Find each variable and output the cast expression.
        Make sure that any variable patterns found within built-in functions do not produce a cast expression
        
        A variable of the form EntryId/ElementId produces the expression:
        
        ancestor::cda:ClinicalDocument/cda:component/cda:structuredBody/cda:component/cda:section/descendant::cda:entry[*/cda:id/@extension='{EntryId}']/*/cda:value[@extension='{ElementId}']/@value castable as xs:type
        
        where {EntryId} and {ElementId} are replaced by the identifiers found in the variable and xs:type is the type of the element found in the ontology.
        
        Except that math:functionName is reserved for maths extension functions (at some stage the reserved namespaces may become configurable)
        
        and
        
        cityEHR:function(argument1,argument2) is reserved for built-in cityEHR functions
        
        contextEntryIRI is the IRI of entry in which the expression is contained (as a default value, calculation, condition, etc) - paths are relative to this entry, if necessary
        contextContentIRI is the IRI of the section, entry, cluster or element on which the expression is found
        evaluationContext is the (normalised, scrunched) representation of the evaluation context expressiom, used to select the evaluation context for entry/element variables
        
        For casts, cityEHRFunction:getPathFromContent is called with contextRoot of 'attribute' since the casts are always relative to an element value, even for variables found in getValues
        ==================================================================== -->

    <xsl:function name="cityEHRFunction:getExpressionCasts">
        <xsl:param name="contextEntryIRI"/>
        <xsl:param name="contextContentIRI"/>
        <xsl:param name="evaluationContext"/>
        <xsl:param name="formRecordedEntries"/>
        <xsl:param name="expression"/>


        <xsl:variable name="builtInPrefix" select="'cityEHR:'"/>

        <!-- Match any quoted text and pass it straight through, so that variables and built-ins don't get found inside quotes -->
        <xsl:variable name="regexQuoted" select="'(''[^'']*'')'"/>
        <!-- Match the variables -->
        <xsl:variable name="regexVariables" select="concat('([-a-zA-Z0-9_]+)', $pathSeparator, '([-a-zA-Z0-9_]+)')"/>
        <!-- Match the built-in functions (which may contain sub-patterns that look like variables)
             2018-11-15 - added ? (after ,) so that arguments are not required -->
        <xsl:variable name="regexBuiltInFunctions" select="concat('(', $builtInPrefix, '[^(]*)\(([^,]*),?([^)]*)\)')"/>

        <xsl:variable name="regex" select="concat($regexQuoted, '|', $regexBuiltInFunctions, '|', $regexVariables)"/>


        <!-- Match the patterns in the expression. 
            
            There are six groups in the regex - in case 1, group1 is set; in case 2, group2 and group3 are set; in case 3, group4 and group5 are set
            
            1  'quoted text'                                                group1 ='quoted text'
            2. cityEHR:function(instance,path)                              group2 = function, group3 = argument1, group4 = argument2
            3. entryId/elementId                                            group5 = entryId, group6 = elementId
            
            They must be matched in this order since 1 can contain 2 can contain 3
            
        -->
        <xsl:analyze-string select="$expression" regex="{$regex}">
            <xsl:matching-substring>

                <xsl:variable name="group1" as="xs:string" select="regex-group(1)"/>
                <xsl:variable name="group2" as="xs:string" select="regex-group(2)"/>
                <xsl:variable name="group3" as="xs:string" select="regex-group(3)"/>
                <xsl:variable name="group4" as="xs:string" select="regex-group(4)"/>
                <xsl:variable name="group5" as="xs:string" select="regex-group(5)"/>
                <xsl:variable name="group6" as="xs:string" select="regex-group(6)"/>

                <xsl:variable name="matchType" as="xs:string"
                    select="
                        if ($group1 != '') then
                            'quoted'
                        else
                            if ($pathSeparator = ':' and $group5 = 'math') then
                                'maths'
                            else
                                if (starts-with($group2, $builtInPrefix)) then
                                    'built-in'
                                else
                                    if ($group5 != '' and $group6 != '') then
                                        'variable'
                                    else
                                        'error'"/>

                <!-- Processing depends on type of match found.
                     Quoted text, maths and some arguments of built-in functions don't need cast expressions, so just ignore them -->

                <!-- Variable -->
                <xsl:if test="$matchType = 'variable'">

                    <xsl:variable name="entryIRI" as="xs:string" select="concat('#ISO-13606:Entry:', $group5)"/>
                    <xsl:variable name="elementIRI" as="xs:string" select="concat('#ISO-13606:Element:', $group6)"/>

                    <!-- Check that element belongs to the entry - path is returned as a sequence -->
                    <xsl:variable name="pathToEntry" select="cityEHRFunction:getPathFromContent($entryIRI, $elementIRI, 'attribute', '')"/>

                    <!-- Only make cast expression for the variable if the entry/element exists in the model
                         Otherwise, this is just something that looks like a variable (or its an error)
                         Until 2018-05-05 cast was true only if all instances were castable.
                         Since 2018-05-05 cast is true is any instance is castable (with extra selector predicate on the value in expression evaluation) -->
                    <xsl:if test="exists($pathToEntry)">
                        <!-- Get property for #hasDataType
                             Properties are of the form #CityEHR:Property:DataType:string or #CityEHR:DataType:string
                             Depending on whether 2018 or 2017 ontologyVersion -->
                        <xsl:variable name="elementDataType" as="xs:string"
                            select="
                                if (exists(key('specifiedObjectPropertyList', concat('#hasDataType', $elementIRI), $rootNode))) then
                                    key('specifiedObjectPropertyList', concat('#hasDataType', $elementIRI), $rootNode)[1]
                                else
                                    ''"/>
                        <xsl:variable name="dataType" as="xs:string"
                            select="
                                if (string-length(substring-after($elementDataType, 'DataType:')) > 0) then
                                    concat('xs:', substring-after($elementDataType, 'DataType:'))
                                else
                                    'xs:string'"/>

                        <xsl:variable name="elementValueContext"
                            select="cityEHRFunction:getValueContext($contextEntryIRI, $contextContentIRI, 'attribute', '', $entryIRI, $elementIRI, $formRecordedEntries, $evaluationContext)"/>
                        <!-- Until 2018-05-05 
                        <xsl:variable name="castExpression"
                            select="concat('exists(',$elementValueContext,'/@value) and not((for $i in ',$elementValueContext,'/@value return $i castable as ',$dataType,') = false())')"/>
                        -->
                        <xsl:variable name="castExpression"
                            select="concat('exists(', $elementValueContext, '/@value) and (for $i in ', $elementValueContext, '/@value return $i castable as ', $dataType, ') = true()')"/>

                        <xsl:sequence select="$castExpression"/>
                    </xsl:if>
                </xsl:if>

                <!-- Built-in
                     Look for variables in the 2nd argument of cityEHR:lookup, cityEHR:instance, cityEHR:getAttribute -->
                <xsl:if test="$matchType = 'built-in' and $group2 = ('cityEHR:lookup', 'cityEHR:instance', 'cityEHR:getAttribute')">
                    <xsl:variable name="castExpression"
                        select="cityEHRFunction:getExpressionCasts($contextEntryIRI, $contextContentIRI, $evaluationContext, $formRecordedEntries, $group4)"/>
                    <xsl:sequence select="$castExpression"/>
                </xsl:if>
                <!-- Built-in
                     Look for variables in the 1st and 2nd argument of cityEHR:getValues, context still the $contextEntryIRI/$contextContentIRI -->
                <xsl:if test="$matchType = 'built-in' and $group2 = 'cityEHR:getValues'">
                    <!-- First argument (should just be entryId/elementId) -->
                    <xsl:variable name="castExpression1"
                        select="cityEHRFunction:getExpressionCasts($contextEntryIRI, $contextContentIRI, $evaluationContext, $formRecordedEntries, $group3)"/>
                    <xsl:sequence select="$castExpression1"/>
                    <!-- Second argument ***jc - may not be needed here any more 2018-02 - yes it is 2018-05-16 -->
                    <xsl:variable name="castExpression2"
                        select="cityEHRFunction:getExpressionCasts($contextEntryIRI, $contextContentIRI, $evaluationContext, $formRecordedEntries, $group4)"/>
                    <xsl:sequence select="$castExpression2"/>
                </xsl:if>

            </xsl:matching-substring>

        </xsl:analyze-string>

    </xsl:function>


    <!-- ====================================================================
        Replace variables in an expression.
        Find each variable and replace with lookup of value in the form-instance.
        
        The evaluation context is cda:value/@value 
        
        Variables
        Assuming the separator is set as '/' a variable of the form EntryId/ElementId is replaced by:       
        xs:type(ancestor::cda:ClinicalDocument/cda:component/cda:structuredBody/cda:component/cda:section/descendant::cda:entry[*/cda:id/@extension='{EntryId}']/*/cda:value[@extension='{ElementId}']/@value)
         where {EntryId} and {ElementId} are replaced by the identifiers found in the variable and xs:type is the type of the element found in the ontology.
         
         Except that math:functionName is reserved for maths extension functions (at some stage the reserved namespaces may become configurable)
         
         Functions
         cityEHR:instance(path) is reserved for built-in cityEHR functions
         So cityEHR:instance(user-instance,credentials/username)  is replaced by 
         
         xxf:instance('user-instance')/credentials/username
         
         contextEntryIRI is the IRI of entry in which the expression is contained (as a default value, calculation, condition, etc) - paths are relative to this entry, if necessary
         contextContentIRI is the IRI of the section, entry, cluster or element on which the expression is found
         predicateEntryIRI is the context of the predicate in cityEHR:getValues (2nd argument)
         contextRoot is either attribute, element or composition - whether the expression is evaluated in the context of the XML element defined by contextEntryIRI/contextContentIRI, an attribute on it or the whole document (used for rvaluationContext only)
         evaluationContext is the (normalised, scrunched) representation of the evaluation context expression, used to select the evaluation context for entry/element variables
         
         Since 2018-05-05 extra predicate to select values that are castable to the specified data type.
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:replaceExpressionVariables">
        <xsl:param name="contextEntryIRI"/>
        <xsl:param name="contextContentIRI"/>
        <xsl:param name="contextRoot"/>
        <xsl:param name="predicateEntryIRI"/>
        <xsl:param name="formRecordedEntries"/>
        <xsl:param name="evaluationContext"/>
        <xsl:param name="expression"/>

        <xsl:variable name="builtInPrefix" select="'cityEHR:'"/>

        <!-- Match any quoted text and pass it straight through, so that variables and built-ins don't get found inside quotes -->
        <xsl:variable name="regexQuoted" select="'(''[^'']*'')'"/>
        <!-- Match the variables -->
        <xsl:variable name="regexVariables" select="concat('([-a-zA-Z0-9_]+)', $pathSeparator, '([-a-zA-Z0-9_]+)')"/>
        <!-- Match the built-in functions (which may contain sub-patterns that look like variables)
             2018-11-15 - added ? (after ,) so that arguments are not required - also need [^,)]* as pattern for argument1 -->
        <xsl:variable name="regexBuiltInFunctions" select="concat('(', $builtInPrefix, '[^(]*)\(([^,)]*),?([^)]*)\)')"/>

        <xsl:variable name="regex" select="concat($regexQuoted, '|', $regexBuiltInFunctions, '|', $regexVariables)"/>


        <!-- Match the patterns in the expression. 
            
            There are six groups in the regex - in case 1, group1 is set; in case 2, group2 and group3 are set; in case 3, group4 and group5 are set
            
            1  'quoted text'                                                group1 ='quoted text'
            2. cityEHR:function(instance,path)                              group2 = function, group3 = argument1, group4 = argument2
            3. entryId/elementId                                            group5 = entryId, group6 = elementId
            
            They must be matched in this order since 1 can contain 2 can contain 3

        -->
        <xsl:analyze-string select="$expression" regex="{$regex}">
            <xsl:matching-substring>

                <xsl:variable name="group1" as="xs:string" select="regex-group(1)"/>
                <xsl:variable name="group2" as="xs:string" select="regex-group(2)"/>
                <xsl:variable name="group3" as="xs:string" select="regex-group(3)"/>
                <xsl:variable name="group4" as="xs:string" select="regex-group(4)"/>
                <xsl:variable name="group5" as="xs:string" select="regex-group(5)"/>
                <xsl:variable name="group6" as="xs:string" select="regex-group(6)"/>

                <xsl:variable name="matchType" as="xs:string"
                    select="
                        if ($group1 != '') then
                            'quoted'
                        else
                            if ($pathSeparator = ':' and $group5 = 'math') then
                                'maths'
                            else
                                if (starts-with($group2, $builtInPrefix)) then
                                    'built-in'
                                else
                                    if ($group5 != '' and $group6 != '') then
                                        'variable'
                                    else
                                        'error'"/>

                <!-- Processing depends on type of match found -->
                <!-- Quoted text -->
                <xsl:if test="$matchType = 'quoted'">
                    <xsl:sequence select="$group1"/>
                </xsl:if>

                <!-- Maths function -->
                <xsl:if test="$matchType = 'maths'">
                    <xsl:sequence select="concat($group5, ':', $group6)"/>
                </xsl:if>

                <!-- Built-in function.
                      These always have two arguments, separated by commas
                      Currently, three functions are supported:
                     
                      instance - gets the value of the specified instance path
                        cityEHR:instance(patient-instance,currentAge/years)
                        
                      lookup - looks up the value of the specified directory element (instance is the directory element name, path is an expression to match with  the element value (lookup), returns the element displayName)
                        cityEHR:lookup(patientmedslettertext,drug1/drugname)
                        
                      getValues - gets values of the specified entry/element (first argument), applying predicate in the second argument 
                        
                      getAttribute - gets the attribute specified in argument1 (normally displayName) of the entry/element in argument2 (normally the @value is used)   
                      
                      effectiveTime - returns effectiveTime attribute on parent entry or component. Used as a pre-condition on pre-filled entries.
                     -->
                <xsl:if test="$matchType = 'built-in'">
                    <xsl:variable name="function" as="xs:string" select="substring-after($group2, $builtInPrefix)"/>
                    <xsl:variable name="argument1" as="xs:string" select="$group3"/>
                    <xsl:variable name="argument2" as="xs:string" select="$group4"/>

                    <!-- instance = get value from specified xf:instance
                         replace any variables in the path (argument 2)
                         This means we need to be careful when the path is specified in the model since it may contain stuff that looks like a variable
                         This is only a problem if the instance path contains x/y where x is an entry that contains an element y, in which case the path will get replaced
                         Note that the global context must be used for all variables. otherwise the expression will be looking for values relative to the instance, not the entry/element
                         -->
                    <xsl:if test="$function = 'instance'">
                        <xsl:variable name="expandedArgument"
                            select="string-join(cityEHRFunction:replaceExpressionVariables('', $contextContentIRI, 'attribute', $predicateEntryIRI, $formRecordedEntries, $evaluationContext, $argument2), '')"/>
                        <xsl:sequence select="concat('xxf:instance(''', $argument1, ''')/', $expandedArgument)"/>
                    </xsl:if>

                    <!-- lookup = get value from directoryElements-instance.
                         Also replace any variables found in the path (argument 2).
                         The comparison of the directory element value is on ($expandedPath) so that the expanded path can be a list of more than one term, separated by commas.
                         Only one value can be returned from the directory lookup, even if there are multiple matches ( so use (match)[1]/@displayName )-->
                    <xsl:if test="$function = 'lookup'">
                        <xsl:variable name="expandedArgument"
                            select="string-join(cityEHRFunction:replaceExpressionVariables($contextEntryIRI, $contextContentIRI, 'attribute', $predicateEntryIRI, $formRecordedEntries, $evaluationContext, $argument2), '')"/>
                        <xsl:sequence
                            select="concat('(if (exists(xxf:instance(''directoryElements-instance'')/iso-13606:elementCollection/iso-13606:element[@root=''#ISO-13606:Element:', $argument1, ''']/iso-13606:data[@value=', $expandedArgument, '])) then (xxf:instance(''directoryElements-instance'')/iso-13606:elementCollection/iso-13606:element[@root=''#ISO-13606:Element:', $argument1, ''']/iso-13606:data[@value=', $expandedArgument, '])[1]/@displayName else '''')')"/>
                        <!--  This one has extra  ( ) around the value comparison                       
                            <xsl:sequence
                            select="concat('(if (exists(xxf:instance(''directoryElements-instance'')/iso-13606:elementCollection/iso-13606:element[@root=''#ISO-13606:Element:',$argument1,''']/iso-13606:data[@value=(',$expandedArgument,')])) then (xxf:instance(''directoryElements-instance'')/iso-13606:elementCollection/iso-13606:element[@root=''#ISO-13606:Element:',$argument1,''']/iso-13606:data[@value=(',$expandedArgument,')])[1]/@displayName else '''')')"
                            /> -->
                    </xsl:if>

                    <!-- getValues - get values of entry/element in argument1 using argument2 as the predicate for selection
                         argument1 should be of the form entry/element (i.e. a variable, matching $regexVariables
                         argument2 is an expression that must be expanded using the entry/element as context -->
                    <xsl:if test="$function = 'getValues'">
                        <xsl:variable name="entryId" select="substring-before($argument1, '/')"/>
                        <xsl:variable name="elementId" select="substring-after($argument1, '/')"/>

                        <xsl:variable name="entryIRI" as="xs:string" select="concat('#ISO-13606:Entry:', $entryId)"/>
                        <xsl:variable name="elementIRI" as="xs:string" select="concat('#ISO-13606:Element:', $elementId)"/>

                        <!-- Output the variable -  attribute is 'getValues' (i.e. no path to attribute is returned) -->
                        <xsl:sequence
                            select="cityEHRFunction:getVariableAttribute($contextEntryIRI, $contextContentIRI, $contextRoot, $predicateEntryIRI, $evaluationContext, $formRecordedEntries, $entryId, $elementId, 'getValues')"/>

                        <!-- Output the predicate and path to attribute - context is the entryIRI, elementIRI
                             But they were set to -->
                        <xsl:variable name="attributePath" as="xs:string" select="'/xs:string(@value)'"/>
                        <xsl:variable name="expandedArgument"
                            select="string-join(cityEHRFunction:replaceExpressionVariables($contextEntryIRI, $contextContentIRI, 'element', $entryIRI, $formRecordedEntries, $evaluationContext, $argument2), '')"/>
                        <xsl:sequence
                            select="
                                if ($expandedArgument != '') then
                                    concat('[', $expandedArgument, ']', $attributePath)
                                else
                                    $attributePath"
                        />
                    </xsl:if>

                    <!-- getAttrbute - get the attribute specified by argument1 of the entry/element in argument2 -->
                    <xsl:if test="$function = 'getAttribute'">
                        <xsl:variable name="entryId" select="substring-before($argument2, '/')"/>
                        <xsl:variable name="elementId" select="substring-after($argument2, '/')"/>
                        <xsl:sequence
                            select="cityEHRFunction:getVariableAttribute($contextEntryIRI, $contextContentIRI, $contextRoot, $predicateEntryIRI, $evaluationContext, $formRecordedEntries, $entryId, $elementId, $argument1)"
                        />
                    </xsl:if>

                    <!-- effectiveTime = get effectiveTime attribute from containing (ancestor) element
                         This is used in pre-conditions on pre-filled entries.
                    -->
                    <xsl:if test="$function = 'effectiveTime'">
                        <xsl:sequence select="'ancestor::*/@effectiveTime'"/>
                    </xsl:if>

                </xsl:if>

                <!-- Variable -->
                <xsl:if test="$matchType = 'variable'">
                    <xsl:sequence
                        select="cityEHRFunction:getVariableAttribute($contextEntryIRI, $contextContentIRI, $contextRoot, $predicateEntryIRI, $evaluationContext, $formRecordedEntries, $group5, $group6, 'value')"
                    />
                </xsl:if>

                <!-- Error.
                     This shouldn't happen, but if it does just output everything that was matched -->
                <xsl:if test="$matchType = 'error'">
                    <xsl:sequence select="$group1"/>
                    <xsl:sequence select="$group2"/>
                    <xsl:sequence select="$group3"/>
                    <xsl:sequence select="$group4"/>
                    <xsl:sequence select="$group5"/>
                </xsl:if>

            </xsl:matching-substring>

            <xsl:non-matching-substring>
                <xsl:sequence select="."/>
            </xsl:non-matching-substring>

        </xsl:analyze-string>
    </xsl:function>


    <!-- ====================================================================
         For an entry/element pair, get the path to the specified attrbute on the element.
         For normal calculations the @value attribute is found, but for the cityEHR:getAttribute function a different attrbute (e.g. @displayName) may be found
         When getVariableAttribute is called for the argument of the cityEHR:getValues function:
                path is from element, not attribute, which is why contextRoot is passed
                no attribute is specified in the path - this is added after the predicate specified in the second argument of cityEHR:getValues
        
        ==================================================================== -->

    <xsl:function name="cityEHRFunction:getVariableAttribute">
        <xsl:param name="contextEntryIRI"/>
        <xsl:param name="contextContentIRI"/>
        <xsl:param name="contextRoot"/>
        <xsl:param name="predicateEntryIRI"/>
        <xsl:param name="evaluationContext"/>
        <xsl:param name="formRecordedEntries"/>
        <xsl:param name="entryId"/>
        <xsl:param name="elementId"/>
        <xsl:param name="attribute"/>


        <xsl:variable name="entryIRI" as="xs:string" select="concat('#ISO-13606:Entry:', $entryId)"/>
        <xsl:variable name="elementIRI" as="xs:string" select="concat('#ISO-13606:Element:', $elementId)"/>

        <!-- Check that element belongs to the entry - path to entry from the element is returned as a sequence.
             If the path does not exist (empty) then the element does not belong to the entry in the model -->
        <xsl:variable name="pathToEntry" select="cityEHRFunction:getPathFromContent($entryIRI, $elementIRI, $contextRoot, '')"/>

        <!-- Only expand the variable if the entry/element exists in the model
             Otherwise, this is just something that looks like a variable (or its an error) -->
        <xsl:if test="exists($pathToEntry)">
            <!-- Get context for the element value -->
            <xsl:variable name="elementValueContext"
                select="cityEHRFunction:getValueContext($contextEntryIRI, $contextContentIRI, $contextRoot, $predicateEntryIRI, $entryIRI, $elementIRI, $formRecordedEntries, $evaluationContext)"/>
            <!-- Get property for #hasDataType
                Properties are of the form #CityEHR:Property:DataType:string or #CityEHR:DataType:string
                Depending on whether 2018 or 2017 ontologyVersion -->
            <xsl:variable name="elementDataType" as="xs:string"
                select="
                    if (exists(key('specifiedObjectPropertyList', concat('#hasDataType', $elementIRI), $rootNode))) then
                        key('specifiedObjectPropertyList', concat('#hasDataType', $elementIRI), $rootNode)[1]
                    else
                        ''"/>
            <!-- Only use the data type of the element if we are getting its @value attribute - otherwise we just need a string -->
            <xsl:variable name="dataType" as="xs:string"
                select="
                    if ($attribute = 'value' and string-length(substring-after($elementDataType, 'DataType:')) > 0) then
                        concat('xs:', substring-after($elementDataType, 'DataType:'))
                    else
                        'xs:string'"/>
            <!-- Check cast for all datatypes, except xs:string -->
            <xsl:variable name="castCheck" as="xs:string"
                select="
                    if ($dataType = 'xs:string') then
                        ''
                    else
                        concat('[@', $attribute, ' castable as ', $dataType, ']')"/>
            <!-- Do not need element attribute path for getValues -->
            <xsl:variable name="attributePath" as="xs:string"
                select="
                    if ($attribute = 'getValues') then
                        ''
                    else
                        concat($castCheck, '/', $dataType, '(@', $attribute, ')')"/>

            <xsl:sequence select="concat('(', $elementValueContext, $attributePath, ')')"/>
        </xsl:if>

        <!-- This wasn't a variable, after all -->
        <xsl:if test="not(exists($pathToEntry))">
            <xsl:sequence select="concat($entryId, '/', $elementId)"/>
        </xsl:if>

    </xsl:function>



    <!-- ====================================================================
        Get the context for the value of an element in an expression.
        This is the path to the element relative to the context in which the expression is evaluated (defined by contextEntryIRI/contextContentIRI)
        The path returned ends in / - then needs @value or xs:type(@value) appended 
        
        If the contextEntryIRI is the same as the entryIRI (of the expression) then local paths may apply to elements in the expression.
        If the predicateEntryIRI is the same as the entryIRI (of the expression) then path to the predicated entry may apply to elements in the expression.
        Otherwise the context is the current CDA document (form-instance).
        
        Note that the context IRIs passed are the recorded IRIs i.e. if the context IRI is the root of another then that alias has been passed to this function.
        
        Note that this assumes the composition is in form-instance (even for letters, pathways, etc)
        ==================================================================== -->

    <xsl:function name="cityEHRFunction:getValueContext">
        <xsl:param name="contextEntryIRI"/>
        <xsl:param name="contextContentIRI"/>
        <xsl:param name="contextRoot"/>
        <xsl:param name="predicateEntryIRI"/>
        <xsl:param name="entryIRI"/>
        <xsl:param name="elementIRI"/>
        <xsl:param name="formRecordedEntries"/>
        <xsl:param name="evaluationContext"/>

        <!-- For global context, allvalues are returned so valueSelector is '' -->
        <!--
        <xsl:variable name="valueSelector" as="xs:string"
            select="if ($contextEntryIRI='getValues' and $contextContentIRI castable as xs:integer) then concat('[',$contextContentIRI,']')
                    else if ($contextEntryIRI='getValues' and  $contextContentIRI='last') then '[last()]'
                    else if ($contextEntryIRI='getValues') then '' else '[1]'"/>
        -->
        <xsl:variable name="valueSelector" as="xs:string" select="''"/>

        <!-- For external variables only.
             Evaluation context - entry must match evaluation context, if there is one.
             If no evaluation context (i.e. it is blank) then the entry must not have cityEHR:evaluationContext attribute -->
        <xsl:variable name="evaluationContextSelector" as="xs:string"
            select="
                if ($entryIRI = $formRecordedEntries and $evaluationContext = '') then
                    '[not(@cityEHR:evaluationContext)]'
                else
                    if ($entryIRI = $formRecordedEntries) then
                        concat('[@cityEHR:evaluationContext=''', $evaluationContext, ''']')
                    else
                        ''"/>

        <!-- contextRoot is 'composition' for expressions in the evaluationContext of an entry ***jc
             From 2019-11-28 @cityEHR:evaluationContext is on cda:entry, not cda:observation, etc -->
        <xsl:if test="$contextRoot = 'composition'">
            <xsl:variable name="compositionValuePath" as="xs:string"
                select="concat('ancestor::cda:ClinicalDocument/descendant::cda:entry/descendant::*[cda:id[@extension=''', $entryIRI, '''][@cityEHR:origin!=''#CityEHR:Template'']]', $evaluationContextSelector, '/descendant::cda:value[@extension=''', $elementIRI, ''']')"/>

            <xsl:value-of select="$compositionValuePath"/>
        </xsl:if>

        <!-- contextRoot is 'element' or 'attribute' -->
        <xsl:if test="$contextRoot != 'composition'">
            <!-- The global context of the value. -->
            <xsl:if test="$contextEntryIRI != $entryIRI and $predicateEntryIRI != $entryIRI">
                <xsl:variable name="globalValuePath" as="xs:string"
                    select="concat('ancestor::cda:ClinicalDocument/descendant::cda:entry/descendant::*[cda:id[@extension=''', $entryIRI, '''][@cityEHR:origin!=''#CityEHR:Template'']]', $evaluationContextSelector, '/descendant::cda:value[@extension=''', $elementIRI, ''']')"/>

                <xsl:value-of select="$globalValuePath"/>
            </xsl:if>

            <!-- Need to use predicate context if predicateEntryIRI = entryIRI -->
            <xsl:if test="$predicateEntryIRI = $entryIRI">
                <!-- Get property for #hasOccurrence of the $predicateEntryIRI -->
                <xsl:variable name="entryOccurrence" as="xs:string"
                    select="
                        if (exists(key('specifiedObjectPropertyList', concat('#hasOccurrence', $predicateEntryIRI), $rootNode))) then
                            key('specifiedObjectPropertyList', concat('#hasOccurrence', $predicateEntryIRI), $rootNode)[1]
                        else
                            '#CityEHR:Property:Occurrence:Single'"/>

                <!-- 2019-08-29 just use ancestor cda:observation - so that multiple entries can be aliased to single entries
                Then don't need to use the $entryOccurrence, which will be of the wrong type for the aliased entry -->
                <!--
                <xsl:variable name="predicateContext"
                    select="if ($predicateEntryIRI='') then '' else if ($entryOccurrence=('#CityEHR:EntryProperty:Single','#CityEHR:Property:Occurrence:Single')) then 'ancestor::cda:entry[1]' else 'ancestor::cda:component[1]'"/>
                -->
                <xsl:variable name="predicateContext"
                    select="
                        if ($predicateEntryIRI = '') then
                            ''
                        else
                            'ancestor::cda:observation[1]'"/>

                <xsl:variable name="predicateValuePath" as="xs:string"
                    select="concat($predicateContext, '/descendant::cda:value[@extension=''', $elementIRI, ''']')"/>
                <xsl:value-of select="$predicateValuePath"/>
            </xsl:if>

            <!-- Need to use local context if contextEntryIRI = entryIRI -->
            <xsl:if test="$contextEntryIRI = $entryIRI">
                <!-- Until 2017-12-29 -->
                <!--
            <xsl:variable name="localValuePath" as="xs:string"
            select="string-join(cityEHRFunction:getLocalValuePath($entryIRI,$contextContentIRI,$contextRoot,$elementIRI),'')"/>
            <xsl:value-of select="if ($localValuePath!='') then $localValuePath else $globalValuePath"/>
            -->
                <xsl:variable name="localValuePath" as="xs:string" select="concat('$entry/descendant::cda:value[@extension=''', $elementIRI, ''']')"/>
                <xsl:value-of select="$localValuePath"/>
            </xsl:if>
        </xsl:if>
    </xsl:function>


    <!-- ====================================================================
         Get the path to from source value to target value within an entry.
         This function calls two (recursive) functions that get the path to the entry and then the path to the value.
         If either of these paths is empty then the resulting path is empty, otherwise its the concatenation of pathToEntry/pathToValue
         Used until 2017-12-29
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getLocalValuePath">
        <xsl:param name="entryIRI"/>
        <xsl:param name="contextContentIRI"/>
        <xsl:param name="contextRoot"/>
        <xsl:param name="elementIRI"/>

        <xsl:variable name="pathToEntry" as="xs:string"
            select="string-join(cityEHRFunction:getPathFromContent($entryIRI, $contextContentIRI, $contextRoot, ''), '')"/>
        <xsl:variable name="pathToValue" as="xs:string" select="string-join(cityEHRFunction:getPathToContent($entryIRI, $elementIRI, ''), '')"/>

        <!-- If sourceElementIRI and targetElementIRI are in the entryIRI then the paths will not be empty -->
        <xsl:if test="$pathToEntry != '' and $pathToValue != ''">
            <xsl:value-of select="concat($pathToEntry, $pathToValue)"/>
        </xsl:if>
    </xsl:function>


    <!-- ====================================================================
         Recursive function that returns the path from an element value to its ancestor entry.
         If contextRoot is 'attribute'
         then returns path from an attribute on the contentIRI element back to ancestor containerIRI element

         If contextRoot is 'element'
         then returns path from the contentIRI element back to ancestor containerIRI element
         
         If contextRoot is 'composition' then ? ***jc

         path builds recursively and is retuned when $containerIRI = $contentIRI
         If containerIRI does not contain contentIRI then nothing is returned
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getPathFromContent">
        <xsl:param name="containerIRI"/>
        <xsl:param name="contentIRI"/>
        <xsl:param name="contextRoot"/>
        <xsl:param name="path"/>

        <!-- Container has been found - stop iterations to build path.
             If the context root is element then one less step is needed in anccestor path.
             (But the path must always end with ..) -->
        <xsl:if test="$containerIRI = $contentIRI">
            <xsl:value-of
                select="
                    if ($contextRoot = 'element') then
                        concat(substring-after($path, '../'), '..')
                    else
                        concat($path, '..')"
            />
        </xsl:if>

        <!-- Recursive call -->
        <xsl:if test="$containerIRI != $contentIRI">
            <xsl:variable name="nextPath" select="concat($path, '../')"/>
            <xsl:for-each select="key('contentsIRIList', $containerIRI, $rootNode)">
                <xsl:variable name="nextContainerIRI" select="."/>
                <xsl:value-of select="cityEHRFunction:getPathFromContent($nextContainerIRI, $contentIRI, $contextRoot, $nextPath)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:function>

    <!-- ====================================================================
        Recursive function that returns the path to content from its ancestor container.
        If containerIRI does not contain contentIRI then nothing is returned
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getPathToContent">
        <xsl:param name="containerIRI"/>
        <xsl:param name="contentIRI"/>
        <xsl:param name="path"/>

        <xsl:if test="$containerIRI = $contentIRI">
            <xsl:value-of select="$path"/>
        </xsl:if>
        <xsl:if test="$containerIRI != $contentIRI">
            <xsl:for-each select="key('contentsIRIList', $containerIRI, $rootNode)">
                <xsl:variable name="nextContainerIRI" select="."/>
                <xsl:variable name="nextPath" select="concat($path, '/cda:value[@extension=''', $nextContainerIRI, ''']')"/>
                <xsl:value-of select="cityEHRFunction:getPathToContent($nextContainerIRI, $contentIRI, $nextPath)"/>
            </xsl:for-each>
        </xsl:if>
    </xsl:function>


    <!-- ====================================================================
        Check the count of characters in an expression.
        Used to check ( ) " and ' which must be balanced
        The characters to check are passed as a string
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getCharacterCount">
        <xsl:param name="expression"/>
        <xsl:param name="codePoints"/>

        <xsl:variable name="expressionCodePoints" select="string-to-codepoints($expression)"/>
        <xsl:value-of select="count($expressionCodePoints[. = $codePoints])"/>

    </xsl:function>

    <!-- ====================================================================
        Check whether characters in a string are balanced
        The two characters are passed as openCharacter, closeCharacter which are unicode coe points
        If unmatched then returns the errorCode, else the empty string
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:checkBalance">
        <xsl:param name="expression"/>
        <xsl:param name="openCharacter"/>
        <xsl:param name="closeCharacter"/>
        <xsl:param name="errorCode"/>

        <xsl:value-of
            select="
                if (cityEHRFunction:getCharacterCount($expression, $openCharacter) = cityEHRFunction:getCharacterCount($expression, $closeCharacter)) then
                    ''
                else
                    $errorCode"/>

    </xsl:function>



    <!-- ====================================================================
        Get the maximum length of displayName in the labels of entries in a section.
        ==================================================================== -->

    <xsl:function name="cityEHRFunction:getSectionLabelWidth">
        <xsl:param name="sectionIRI"/>

        <xsl:variable name="entryLabelWidths" as="xs:integer *">
            <xsl:for-each select="key('contentsIRIList', $sectionIRI, $rootNode)">
                <xsl:variable name="contentIRI" as="xs:string" select="."/>
                <!-- Content is an entry -->
                <xsl:if test="starts-with($contentIRI, '#ISO-13606:Entry')">
                    <xsl:sequence select="cityEHRFunction:getEntryLabelWidth($contentIRI)"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>

        <xsl:variable name="entryLabelWidth"
            select="
                if (empty($entryLabelWidths)) then
                    0
                else
                    max($entryLabelWidths)"/>
        <xsl:value-of
            select="
                if ($entryLabelWidth castable as xs:integer) then
                    xs:integer($entryLabelWidth)
                else
                    0"/>

    </xsl:function>

    <!-- ====================================================================
        Get the maximum length of displayName in the labels of an entry.
        ==================================================================== -->

    <xsl:function name="cityEHRFunction:getEntryLabelWidth">
        <xsl:param name="entryIRI"/>

        <!-- Get width of the entry label -->
        <xsl:variable name="entryDisplayNameTermIRI" as="xs:string"
            select="
                if (exists(key('termIRIList', $entryIRI, $rootNode))) then
                    key('termIRIList', $entryIRI, $rootNode)[1]
                else
                    ''"/>
        <xsl:variable name="entryDisplayNameTerm" as="xs:string"
            select="
                if (exists(key('termDisplayNameList', $entryDisplayNameTermIRI, $rootNode))) then
                    key('termDisplayNameList', $entryDisplayNameTermIRI, $rootNode)[1]
                else
                    ''"/>
        <xsl:variable name="entryLabelWidth" select="string-length($entryDisplayNameTerm)"/>

        <!-- Get the maximum width of element labels for the entry -->
        <xsl:variable name="elementLabelWidth" as="xs:integer *" select="cityEHRFunction:getEntryElementLabelWidth($entryIRI)"/>

        <xsl:value-of
            select="
                if ($elementLabelWidth castable as xs:integer) then
                    xs:integer($elementLabelWidth) + $entryLabelWidth
                else
                    $entryLabelWidth"/>

    </xsl:function>

    <!-- ====================================================================
        Get the maximum length of displayName in the label of elements in an entry.
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getEntryElementLabelWidth">
        <xsl:param name="entryIRI"/>
        <xsl:variable name="elementLabelWidths" as="xs:integer *">
            <xsl:for-each select="key('contentsIRIList', $entryIRI, $rootNode)">
                <xsl:variable name="contentIRI" as="xs:string" select="."/>
                <xsl:variable name="cluster" as="xs:string"
                    select="
                        if (exists(key('contentsIRIList', $contentIRI, $rootNode))) then
                            'true'
                        else
                            'false'"/>

                <!-- Output label width of a cluster -->
                <xsl:if test="$cluster = 'true'">
                    <xsl:sequence select="cityEHRFunction:getClusterLabelWidth($contentIRI)"/>
                </xsl:if>

                <!-- Output label width of an element -->
                <xsl:if test="$cluster = 'false'">
                    <xsl:sequence select="cityEHRFunction:getElementLabelWidth($contentIRI)"/>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>

        <xsl:variable name="maxElementLabelWidth"
            select="
                if (empty($elementLabelWidths)) then
                    0
                else
                    max($elementLabelWidths)"/>

        <xsl:value-of select="$maxElementLabelWidth"/>
    </xsl:function>

    <!-- ====================================================================
        Get the length of displayName in the label of an element.
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getElementLabelWidth">
        <xsl:param name="elementIRI"/>
        <xsl:variable name="elementDisplayNameTermIRI" as="xs:string"
            select="
                if (exists(key('termIRIList', $elementIRI, $rootNode))) then
                    key('termIRIList', $elementIRI, $rootNode)[1]
                else
                    ''"/>
        <xsl:variable name="elementDisplayNameTerm" as="xs:string"
            select="
                if (exists(key('termDisplayNameList', $elementDisplayNameTermIRI, $rootNode))) then
                    key('termDisplayNameList', $elementDisplayNameTermIRI, $rootNode)[1]
                else
                    ''"/>
        <xsl:variable name="elementLabelWidth" select="string-length($elementDisplayNameTerm)"/>
        <xsl:value-of select="$elementLabelWidth"/>
    </xsl:function>


    <!-- ====================================================================
        Get the length of displayName in the label of a cluster.
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getClusterLabelWidth">
        <xsl:param name="clusterIRI"/>
        <xsl:variable name="clusterDisplayNameTermIRI" as="xs:string"
            select="
                if (exists(key('termIRIList', $clusterIRI, $rootNode))) then
                    key('termIRIList', $clusterIRI, $rootNode)[1]
                else
                    ''"/>
        <xsl:variable name="clusterDisplayNameTerm" as="xs:string"
            select="
                if (exists(key('termDisplayNameList', $clusterDisplayNameTermIRI, $rootNode))) then
                    key('termDisplayNameList', $clusterDisplayNameTermIRI, $rootNode)[1]
                else
                    ''"/>
        <xsl:variable name="clusterLabelWidth" select="string-length($clusterDisplayNameTerm)"/>

        <!-- Total width also has the maximum label width of content elements -->
        <xsl:variable name="elementLabelWidths" as="xs:integer *">
            <xsl:for-each select="key('contentsIRIList', $clusterIRI, $rootNode)">
                <xsl:variable name="elementIRI" as="xs:string" select="."/>
                <xsl:sequence select="cityEHRFunction:getElementLabelWidth($elementIRI)"/>
            </xsl:for-each>
        </xsl:variable>

        <xsl:variable name="elementLabelWidth"
            select="
                if (empty($elementLabelWidths)) then
                    0
                else
                    max($elementLabelWidths)"/>

        <xsl:value-of
            select="
                if ($elementLabelWidth castable as xs:integer) then
                    $clusterLabelWidth + xs:integer($elementLabelWidth)
                else
                    $clusterLabelWidth"/>

    </xsl:function>


    <!-- ====================================================================
         Check to see if an entry or cluster contains any elements with expanded scope.
         Recursive call to check the contents (so that clusters are handled).
         This returns a sequence which will contain at least one 'true' if the condition is met 
         (may contain more than one, but sequence can be compared to 'true')
         ==================================================================== -->
    <xsl:function name="cityEHRFunction:containsExpandedScope">
        <xsl:param name="containerIRI"/>

        <!-- Iterate through the contents -->
        <xsl:for-each select="key('contentsIRIList', $containerIRI, $rootNode)">
            <xsl:variable name="contentIRI" as="xs:string" select="."/>
            <!-- If the element has expanded scope then output 'true', otherwise recursively check its contents (if a cluster) -->
            <xsl:value-of
                select="
                    if (key('specifiedObjectPropertyList', concat('#hasScope', $contentIRI), $rootNode) = ('#CityEHR:ElementProperty:Expanded', '#CityEHR:Property:Scope:Full')) then
                        'true'
                    else
                        cityEHRFunction:containsExpandedScope($contentIRI)"
            />
        </xsl:for-each>
    </xsl:function>


    <!-- ====================================================================
        Get data property for #hasEvaluationContext.
        The context used for calculations has spaces and quotes removed using cityEHRFunction:getNormalisedProperty.
        This is because the context is only evaluated on the pre-filled entries in the (hidden) external variable section.
        Everywhere else its just a pattern to match and will be enclosed in quotes (hence the need to remove quotes from the property)
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:getEvaluationContextProperty">
        <xsl:param name="componentIRI"/>

        <xsl:variable name="evaluationContextKey" as="xs:string" select="concat('#hasEvaluationContext', $componentIRI)"/>
        <xsl:value-of
            select="
                if (exists(key('specifiedDataPropertyList', $evaluationContextKey, $rootNode))) then
                    key('specifiedDataPropertyList', $evaluationContextKey, $rootNode)
                else
                    ''"/>

    </xsl:function>

    <!-- ====================================================================
         Get normalised property
         Remove spaces and quotes so that the property can be used for matching in an expression.
         ==================================================================== -->
    <xsl:function name="cityEHRFunction:getNormalisedProperty">
        <xsl:param name="property"/>

        <!-- Remove space and quotes (single quote is &#39;)
        Note that must use &quot; to delimit parameters of translate() so that we can include the single quote &#39; in the matched characters -->
        <xsl:variable name="replaceCharacters" as="xs:string"> &#39;&#9;&#10;&#13;</xsl:variable>
        <xsl:value-of select="translate($property, $replaceCharacters, '')"/>

    </xsl:function>


    <!-- ====================================================================
         Check if entry is in the composition or is an external entry
         Returns true or false.
        ==================================================================== -->
    <xsl:function name="cityEHRFunction:isExternalEntry">
        <xsl:param name="entryIRI"/>
        <xsl:param name="recordedEntries"/>

        <xsl:value-of
            select="
                if ($entryIRI = $recordedEntries) then
                    false()
                else
                    true()"/>

    </xsl:function>



</xsl:stylesheet>
