<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRRegistration.xpl
    
    Pipleline to get registration xform from database and load page.
    
    There are seven stages:
        1. Get the combined parameters by calling getPipelineParameters pipeline
        2. Get cached form from database
        If cached form does not exist skip to step (3)
        3. Render the Xform
        If cached form does not exist
        4. Get CDA document fron the database
        5. Transform CDA to Xform content using the stylesheet
        6. Resolve xincudes in the template Xform so that the generated content is included
        7. Save the Xform in the database cache
        8. Render the Xform
        
        Requires the following to be set as input parameters in view-parameters:
        
            formCache
            compositionHandle
        
        Some Xincludes in the form can be resolved when the form is rendered.
        These must be represented in the XSLT as:
        
        <xsl:element name="include" namespace="http://www.w3.org/2001/XInclude">
            <xsl:attribute name="href" select="$imageMap"></xsl:attribute>
        </xsl:element>
        
        Otherwise they will get replaced in Step (2).
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    **********************************************************************************************************
-->
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline"
    xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:saxon="http://saxon.sf.net/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:f="http://orbeon.org/oxf/xml/formatting" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:cda="urn:hl7-org:v3">

    <!-- Input to pipeline is view-parameters.xml as set in the page-flow.xml file -->
    <p:param name="instance" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>
    
    <!-- 1. Run the getPipelineParameters pipeline.
            Returns the combined application-parameters, session-parameters, system-parameters, database-parameters,  view-parameters -->
    <p:processor name="oxf:pipeline">
        <p:input name="config" href="getPipelineParameters.xpl"/>               
        <p:input name="instance" href="#instance"/>
        <p:output name="parameters" id="parameters"/>
    </p:processor>

    <!-- 1. Execute REST submission to get cached XForm
        Do not use the cache if <useFormCache> in system-parameters is 'true' 
        This is achieved by setting formCache to 'blank' (or '') when the pipeline is called
        formCache is '' when the pipeline is called with no form to load
        Note that just submitting formCache of '' or 'blank' would cause an exception to be raised by Orbeon
        That's OK, but the p:choose prevents this, from 2017-09-30 -->
    <p:choose href="#parameters">
        <!-- If not looking for cached form. -->
        <p:when test="not(//dynamicParameters//useFormCache = 'true')">
            <p:processor name="oxf:identity">
                <p:input name="data">
                    <noCache/>
                </p:input>
                <p:output name="data" id="cachedForm"/>
            </p:processor>
        </p:when>
        
        <!-- Otherwise try to load the cached form -->
        <p:otherwise>
            <p:processor name="oxf:xforms-submission">
                <p:input name="submission">
                    <xf:submission serialization="none" method="get" action="{//parameters/formCache[1]}"/>
                </p:input>
                <p:input name="request" href="#parameters"/>
                <p:output name="response" id="cachedForm"/>
            </p:processor>
        </p:otherwise>
    </p:choose>
    
    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#cachedForm"/>
        <p:output name="data" id="cachedForm-checked"/>
    </p:processor>

    <!-- Other processing depends on whether a cached form was found, or not -->
    <p:choose href="#cachedForm-checked">
        
        <!-- If cached form exists it should have a root element. -->
        <p:when test="exists(xhtml:html)">
            <!-- 2. Render the XForm that was cached -->
            <p:processor name="oxf:pipeline">
                <p:input name="data" href="#cachedForm"/>
                <p:input name="instance" href="#instance"/>
                <p:input name="config" href="oxf:/config/epilogue.xpl"/>
                <p:output name="data" ref="data"/>
            </p:processor>
        </p:when>

        <!-- Otherwise generate the form content from the CDA document.
             And then render it. -->
        <p:otherwise>
            <!-- 3. Execute REST submission to get XML document for the CDA-->
            <p:processor name="oxf:xforms-submission">
                <p:input name="submission">
                    <xf:submission serialization="none" method="get"
                        action="{//parameters/compositionHandle[1]}"/>
                </p:input>
                <p:input name="request" href="#parameters"/>
                <p:output name="response" id="cda"/>
            </p:processor>

            <!-- 3a. Execute REST submission to get the data dictionary-->
            <p:processor name="oxf:xforms-submission">
                <p:input name="submission">
                    <xf:submission serialization="none" method="get" action="{//parameters/dictionaryHandle[1]}"
                    />
                </p:input>
                <p:input name="request" href="#parameters"/>
                <p:output name="response" id="dictionary"/>
            </p:processor>


            <!-- Check here to make sure a CDA document was found.
                 If not then return view with basic message included -->
            <p:choose href="#cda">
                <!-- No CDA document was found -->
                <p:when test="empty(//cda:ClinicalDocument)">

                    <!-- Resolve xincludes in the template xhtml view.
                         This pulls in the standard content defined in resources.
                         Note that this location is not configurable - will break if resources are moved -->
                    <p:processor name="oxf:xinclude">
                        <p:input name="config" href="../views/cityEHRRegistration.xhtml"/>
                        <p:input name="formContent" transform="oxf:xslt" href="#parameters">
                            <xhtml:p xsl:version="2.0" class="message">
                                <xsl:value-of
                                    select="//parameters/staticParameters/cityEHRRegistration/noRegistrationEvent"
                                />
                            </xhtml:p>
                        </p:input>
                        <p:output name="data" id="form"/>
                    </p:processor>

                    <!-- 7. Render the XForm that was generated -->
                    <p:processor name="oxf:pipeline">
                        <p:input name="data" href="#form"/>
                        <p:input name="instance" href="#instance"/>
                        <p:input name="config" href="oxf:/config/epilogue.xpl"/>
                        <p:output name="data" ref="data"/>
                    </p:processor>

                </p:when>

                <p:otherwise>
                    <!-- 4. Generate XForm from CDA using XSLT -->
                    <!-- Inputs are the composition (CDA) to be rendered and the patient demographics
                         that have been found in the xmlstore with the REST submissions above. -->
                    <p:processor name="oxf:unsafe-xslt">
                        <p:input name="config" href="../xslt/CDA2XForm.xsl"/>
                        <p:input name="data" href="#cda"/>
                        <p:input name="parameters" href="#instance"/>
                        <p:input name="dictionary" href="#dictionary"/>
                        <p:output name="data" id="generatedContent"/>
                    </p:processor>

                    <!-- 4a. Get template HTML view -->
                    <!--
                    <p:processor name="oxf:url-generator">
                        <p:input name="config">
                            <config>
                                <url>oxf:/apps/ehr/views/cityEHRFolder-Forms.xhtml</url>
                            </config>
                        </p:input>
                        <p:input name="data" href="#instance"/>
                        <p:output name="data" id="view"/>
                    </p:processor>
                    -->

                    <!-- 5. Resolve xincludes in the template xhtml view.
                            This pulls in the form content that was generated in Step 4-->
                    <p:processor name="oxf:xinclude">
                        <p:input name="config" href="oxf:/apps/ehr/views/cityEHRRegistration.xhtml"/>
                        <p:input name="formContent" href="#generatedContent"/>
                        <p:output name="data" id="form"/>
                    </p:processor>

                    <!-- 6. Execute REST submission to save generated form in the cache.
                            AVT in action is relative to the request XML document
                            So must already have added meta tag to the HTML of the form in Step 4 -->
                    <p:processor name="oxf:xforms-submission">
                        <p:input name="submission">
                            <xf:submission
                                action="{//xhtml:div[@class='ISO13606-Composition'][1]/@cache}"
                                validate="false" method="put" replace="none"
                                includenamespacesprefixes=""/>
                        </p:input>
                        <p:input name="request" href="#form"/>
                        <p:output name="response" id="SaveResponse"/>
                    </p:processor>

                    <p:processor name="oxf:null-serializer">
                        <p:input name="data" href="#SaveResponse"/>
                    </p:processor>

                    <!-- 7. Render the XForm that was generated -->
                    <p:processor name="oxf:pipeline">
                        <p:input name="data" href="#form"/>
                        <p:input name="instance" href="#instance"/>
                        <p:input name="config" href="oxf:/config/epilogue.xpl"/>
                        <p:output name="data" ref="data"/>
                    </p:processor>
                </p:otherwise>
            </p:choose>
        </p:otherwise>
    </p:choose>



</p:pipeline>
