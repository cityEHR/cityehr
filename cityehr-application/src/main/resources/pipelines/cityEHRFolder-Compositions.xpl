<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHR-Compositions.xpl
    
    Pipleline to get xform from database and load page.
    
    Requires the following to be set as input parameters in session-parameters:      
            formCacheHandle
            compositionHandle
    
    There are 13 stages:
            1) getPipelineParameters pipeline returns combined parameters           
            2) Get cached form from database (if required and it exists)

            When cached form was returned in (2)
                3) Set up cached form for rendering
                
            Otherwise cached form not returned in (2)
                        
                When handle for composition has not been passed 
                    4) Set non-cda composition
                
                Otherwise handle for composition has been passed
                    5) Get CDA composition fron the database
                    
                6) Get the template composition XForm (forms. letter, order, etc)
                
                When non-cda composition was set or CDA not found in database 
                    7) Resolve xincudes in the template Xform so that message is included
                
                Otherwise cda composition was found
                    8) Get dictionary from the database
                    9) Transform CDA to Xform content using the stylesheet        
                    10) Resolve xincludes in the template Xform so that the generated content is included
                    
                    When using form cache
                        11) Save generated form to the cache
                    Otherwise
                        Don't do anything
                        
                12) Set up the generated form for rendering                
        
            13) Render the Xform (generated or cached)
        
        Some Xincludes in the form can be resolved when the form is rendered.
        These must be represented in the XSLT as:
        
        <xsl:element name="include" namespace="http://www.w3.org/2001/XInclude">
            <xsl:attribute name="href" select="$imageMap"></xsl:attribute>
        </xsl:element>
        
        Otherwise they will get replaced in Step (7 or 10).
    
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
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:saxon="http://saxon.sf.net/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:f="http://orbeon.org/oxf/xml/formatting"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:cda="urn:hl7-org:v3">

    <!-- Input to pipeline is view-parameters.xml as set in the page-flow.xml file 
         with parameters set in the page element -->
    <p:param name="instance" type="input"/>

    <!-- 1. Run the getPipelineParameters pipeline.
            Returns the combined application-parameters, session-parameters, system-parameters, database-parameters,  view-parameters -->
    <p:processor name="oxf:pipeline">
        <p:input name="config" href="getPipelineParameters.xpl"/>
        <p:input name="instance" href="#instance"/>
        <p:output name="parameters" id="parameters"/>
    </p:processor>

    <!-- 2. Execute REST submission to get cached XForm
            Do not use the cache if <useFormCache> in system-parameters is 'false'
            
            Also don't use the cache if we are not loading a form
            This is achieved by setting formCacheHandle to 'blank' (or '') when the pipeline is called
            formCacheHandle is '' when the pipeline is called with no form to load
            Note that just submitting formCacheHandle of '' or 'blank' would cause an exception to be raised by Orbeon
            That's OK, but the p:choose prevents this, from 2017-01-25 -->
    <p:choose href="#parameters">
        <!-- If not looking for cached form. -->
        <p:when test="not(//parameters[@type='system']/dynamicParameters/useFormCache/@value = 'true')">
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
                    <xf:submission serialization="none" method="get" action="{//parameters[@type='session']/formCacheHandle}"/>
                </p:input>
                <p:input name="request" href="#parameters"/>
                <p:output name="response" id="cachedForm"/>
            </p:processor>
        </p:otherwise>
    </p:choose>

    <!-- The submission will raise an exception if the cached form does not exist, so need to handle it.
         The exception catcher behaves like the identity processor if there is no exception.
         However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#cachedForm"/>
        <p:output name="data" id="cachedForm-checked"/>
    </p:processor>


    <!-- Other processing depends on whether a cached form was found, or not.
         This choose sets the #form instance which is one of:
            1. the cached form from the database
            2. the initialFormView, if no form was retrieved from the database (i.e. blank handle was passed)
            3. the form generated from the CDA document found in the database 
            
         This choose outputs the form
    -->
    <p:choose href="#cachedForm-checked">
        <!-- 3. Set up to render the XForm that was cached
                If cached form exists it should have a root element. -->
        <p:when test="exists(xhtml:html)">
            <p:processor name="oxf:identity">
                <p:input name="data" href="#cachedForm"/>
                <p:output name="data" id="form"/>
            </p:processor>
        </p:when>

        <!-- Otherwise generate the form content. -->
        <p:otherwise>

            <!-- Check the compositionHandle passed as a parameter
                 to sey non-cda or cda composition
                 
                 This choose outputs the composition -->
            <p:choose href="#parameters">
                <!-- 4. Not looking for composition, so just set up message -->
                <p:when test="//parameters[@type='session']/compositionHandle=('','blank')">
                    <p:processor name="oxf:identity">
                        <p:input name="data">
                            <noComposition/>
                        </p:input>
                        <p:output name="data" id="composition"/>
                    </p:processor>
                </p:when>

                <p:otherwise>
                    <!-- 5. Execute REST submission to get XML document for the CDA. -->
                    <p:processor name="oxf:xforms-submission">
                        <p:input name="submission">
                            <xf:submission serialization="none" method="get" action="{//parameters[@type='session']/compositionHandle}"/>
                        </p:input>
                        <p:input name="request" href="#parameters"/>
                        <p:output name="response" id="composition"/>
                    </p:processor>
                </p:otherwise>
            </p:choose>

            <!-- The exception catcher behaves like the identity processor if there is no exception -->
            <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#composition"/>
                <p:output name="data" id="composition-checked"/>
            </p:processor>


            <!-- 6. Get the template view (xhtml).
                    Page is passed as parameter in view-parameters, so can use #instance -->
            <p:processor name="oxf:url-generator">
                <p:input name="config" transform="oxf:xslt" href="#instance">
                    <config xsl:version="2.0">
                        <url>
                            <xsl:value-of select="concat('../views/',parameters/page,'.xhtml')"/>
                        </url>
                        <content-type>application/xml</content-type>
                    </config>
                </p:input>
                <p:output name="data" id="templateView"/>
            </p:processor>

            <!-- The exception catcher behaves like the identity processor if there is no exception
                 However if there is an exception, it catches it, and you get a serialized form of the exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#templateView"/>
                <p:output name="data" id="templateView-checked"/>
            </p:processor>


            <!-- Check here to make sure a CDA document was found as the composition
                 If not then return view with basic message included.
                 Note that the cda:ClinicalDocument may be contained in a wrapper element, hence the use of descendant axis 
            
                 This choose outputs the form -->
            <p:choose href="#composition-checked">

                <!-- No CDA document was found -->
                <p:when test="not(exists(//cda:ClinicalDocument))">
                    <!-- 7. Resolve xincludes in the template xhtml view. -->
                    <p:processor name="oxf:xinclude">
                        <p:input name="config" href="#templateView-checked"/>
                        <p:input name="formContent" transform="oxf:xslt" href="#parameters">
                            <xhtml:p xsl:version="2.0" class="message">
                                <xsl:value-of select="//parameters[@type='view']/pageInformation/page[@page=../../page]/@emptyViewMessage"/>
                            </xhtml:p>
                        </p:input>
                        <p:output name="data" id="form"/>
                    </p:processor>
                </p:when>

                <!-- CDA document was found -->
                <p:otherwise>
                    <!-- 8. Execute REST submission to get the data dictionary-->
                    <p:processor name="oxf:xforms-submission">
                        <p:input name="submission">
                            <xf:submission serialization="none" method="get" action="{//parameters[@type='session']/dictionaryHandle}"/>
                        </p:input>
                        <p:input name="request" href="#parameters"/>
                        <p:output name="response" id="dictionary"/>
                    </p:processor>

                    <!-- The exception catcher behaves like the identity processor if there is no exception
                         However if there is an exception, it catches it, and you get a serialized form of the exception -->
                    <p:processor name="oxf:exception-catcher">
                        <p:input name="data" href="#dictionary"/>
                        <p:output name="data" id="dictionary-checked"/>
                    </p:processor>

                    <!-- 8a. Get the xmlCache of imageMaps in the composition.
                         This was created by save-svgCache in imageMapModel which sets the xmlCacheHandle -->
                    <p:processor name="oxf:xforms-submission">
                        <p:input name="submission">
                            <xf:submission serialization="none" method="get" action="{//parameters[@type='session']/xmlCacheHandle}"/>
                        </p:input>
                        <p:input name="request" href="#parameters"/>
                        <p:output name="response" id="svgImageMaps"/>
                    </p:processor>

                    <!-- The exception catcher behaves like the identity processor if there is no exception
                         However if there is an exception, it catches it, and you get a serialized form of the exception -->
                    <p:processor name="oxf:exception-catcher">
                        <p:input name="data" href="#svgImageMaps"/>
                        <p:output name="data" id="svgImageMaps-checked"/>
                    </p:processor>


                    <!-- 9. Generate XForm from CDA using XSLT 
                         Inputs are the CDA composition o be rendered and the dictionary
                         that have been found in the xmlstore with the REST submissions above. -->
                    <p:processor name="oxf:unsafe-xslt">
                        <p:input name="config" href="../xslt/CDA2XForm.xsl"/>
                        <p:input name="data" href="#composition-checked"/>
                        <p:input name="parameters" href="#parameters"/>
                        <p:input name="dictionary" href="#dictionary-checked"/>
                        <p:input name="svgImageMaps" href="#svgImageMaps-checked"/>
                        <p:output name="data" id="generatedContent"/>
                    </p:processor>

                    <!-- The exception catcher behaves like the identity processor if there is no exception
                         However if there is an exception, it catches it, and you get a serialized form of the exception -->
                    <p:processor name="oxf:exception-catcher">
                        <p:input name="data" href="#generatedContent"/>
                        <p:output name="data" id="generatedContent-checked"/>
                    </p:processor>

                    <!-- 10. Resolve xincludes in the template xhtml view.
                            This pulls in the form content that was generated in Step 4.
                            The template depends on the type of composition being displayed -->
                    <p:processor name="oxf:xinclude">
                        <p:input name="config" href="#templateView-checked"/>
                        <p:input name="formContent" href="#generatedContent-checked"/>
                        <p:output name="data" id="generatedForm"/>
                    </p:processor>
                                       
                    <!-- The exception catcher behaves like the identity processor if there is no exception
                         However if there is an exception, it catches it, and you get a serialized form of the exception -->
                    <p:processor name="oxf:exception-catcher">
                        <p:input name="data" href="#generatedForm"/>
                        <p:output name="data" id="generatedForm-checked"/>
                    </p:processor>

                    <!-- If using form cache, then need to save generated xform. -->
                    <p:choose href="#parameters">
                        <p:when test="//parameters[@type='system']/dynamicParameters/useFormCache/@value = 'true'">

                            <!-- 11. Execute REST submission to save generated form in the cache -->
                            <p:processor name="oxf:xforms-submission">
                                <p:input name="submission" transform="oxf:xslt" href="#parameters">
                                    <xf:submission xsl:version="2.0" action="{//parameters[@type='session']/formCacheHandle}" validate="false"
                                        method="put" replace="none" includenamespacesprefixes=""/>
                                </p:input>
                                <p:input name="request" href="#generatedForm-checked"/>
                                <p:output name="response" id="saveResponse"/>
                            </p:processor>

                            <!-- The exception catcher behaves like the identity processor if there is no exception
                             However if there is an exception, it catches it, and you get a serialized form of the exception -->
                            <p:processor name="oxf:exception-catcher">
                                <p:input name="data" href="#saveResponse"/>
                                <p:output name="data" id="saveResponse-checked"/>
                            </p:processor>

                            <!-- Not using the saveResponse -->
                            <p:processor name="oxf:null-serializer">
                                <p:input name="data" href="#saveResponse-checked"/>
                            </p:processor>
                        </p:when>
                    </p:choose>

                    <!-- 12 Set the XForm that was generated -->
                    <p:processor name="oxf:identity">
                        <p:input name="data" href="#generatedForm-checked"/>
                        <p:output name="data" id="form"/>
                    </p:processor>

                </p:otherwise>

            </p:choose>

        </p:otherwise>

    </p:choose>


    <!-- 13. A form has now been retrieved from cache or generated.
             So render it -->
    <p:processor name="oxf:pipeline">
        <p:input name="data" href="#form"/>
        <p:input name="instance" href="#instance"/>
        <p:input name="config" href="oxf:/config/epilogue.xpl"/>
    </p:processor>

</p:pipeline>
