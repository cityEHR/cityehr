<!--
    cityEHR
    cityEHRapi.xpl
    
    Pipeline can be called as a RESTful web service.
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
-->
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline"
    xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:saxon="http://saxon.sf.net/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:f="http://orbeon.org/oxf/xml/formatting" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:cda="urn:hl7-org:v3" xmlns:exist="http://exist.sourceforge.net/NS/exist"
    xmlns:xdb="http://orbeon.org/oxf/xml/xmldb" xmlns:cityEHR="http://openhealthinformatics.org/ehr">

    <!-- Input to pipeline is view-parameters.xml as set in the page-flow.xml file 
         with parameters set in the page element -->
    <p:param name="instance" type="input"/>

    <!-- Run the getPipelineParameters pipeline.
         Returns the combined application-parameters, session-parameters, system-parameters, database-parameters,  view-parameters -->
    <p:processor name="oxf:pipeline">
        <p:input name="config" href="getPipelineParameters.xpl"/>
        <p:input name="instance" href="#instance"/>
        <p:output name="parameters" id="parameters"/>
    </p:processor>


    <!-- Check that API access is enabled in system-parameters -->
    <p:choose href="#parameters">

        <!-- API is not enabled -->
        <p:when
            test="not(exists(//parameters[@type='system']/dynamicParameters/enableAPI[@value='true']))">
            <!-- Return notification -->
            <p:processor name="oxf:identity">
                <p:input name="data" transform="oxf:xslt" href="#parameters">
                    <cityEHRapi xsl:version="2.0">
                        <xsl:copy-of select="(//parameters[@type='view'])[1]/cityEHRapiDisabled"/>
                    </cityEHRapi>
                </p:input>
                <p:output name="data" id="return"/>
            </p:processor>
        </p:when>

        <p:otherwise>

            <!-- Get the pipeline for handling the API command.
         This will fail if the command is not set or is not supported -->
            <p:processor name="oxf:url-generator">
                <p:input name="config" transform="oxf:xslt" href="#instance">
                    <config xsl:version="2.0">
                        <url>
                            <xsl:value-of
                                select="concat('cityEHRapi-',//parameters[@type='view']/command,'.xpl')"
                            />
                        </url>
                        <content-type>application/xml</content-type>
                    </config>
                </p:input>
                <p:output name="data" id="apiPipelineReturned"/>
            </p:processor>

            <!-- The exception catcher behaves like the identity processor if there is no exception
         However if there is an exception, it catches it, and you get a serialized form of the exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#apiPipelineReturned"/>
                <p:output name="data" id="apiPipeline"/>
            </p:processor>


            <!-- Handle the API commands -->
            <p:choose href="#apiPipeline">
                <!-- Command handler pipeline was found.
             Note that the pipeline must have the cityEHR:type specified.
             This is to prevent URL injection that tries to invoke pipelines that are not API commands -->
                <p:when test="exists(//p:pipeline[@cityEHR:type='cityEHRapi'])">

                    <!-- Check the API command parameters.
                         Note that the input is the view-parameters (#instance) not the combined parameters (#parameters) -->
                    <p:processor name="oxf:pipeline">
                        <p:input name="config" href="checkAPIParameters.xpl"/>
                        <p:input name="instance" href="#instance"/>
                        <p:output name="checkResult" id="checkResult"/>
                    </p:processor>

                    <!-- The checkAPIParameters returns either validParameters or the definition of the API command if any of the parameters is unset -->
                    <p:choose href="#checkResult">
                        <!-- Command parameter check OK -->
                        <p:when test="exists(//validParameters)">
                            <!-- Invoke the pipline to handle the command -->
                            <p:processor name="oxf:pipeline">
                                <p:input name="config" href="#apiPipeline"/>
                                <p:input name="instance" href="#instance"/>
                                <p:output name="parameters" id="apiPipelineReturn"/>
                            </p:processor>

                            <!-- The exception catcher behaves like the identity processor if there is no exception
                                 However if there is an exception, it catches it, and you get a serialized form of the exception -->
                            <p:processor name="oxf:exception-catcher">
                                <p:input name="data" href="#apiPipelineReturn"/>
                                <p:output name="data" id="return"/>
                            </p:processor>
                        </p:when>

                        <!-- Command parameter check failed - just return the checkResult -->
                        <p:otherwise>
                            <!-- Return the checkResult -->
                            <p:processor name="oxf:identity">
                                <p:input name="data" href="#checkResult"/>
                                <p:output name="data" id="return"/>
                            </p:processor>
                        </p:otherwise>
                    </p:choose>

                </p:when>

                <!-- Command does not have a handler pipeline -->
                <p:otherwise>
                    <!-- Return the specification of the API 
                 This is in view-parameters -->
                    <p:processor name="oxf:identity">
                        <!-- Debugging -->
                        <!--
                        <p:input name="data" href="#apiPipeline"/>
                        -->
                        <p:input name="data" transform="oxf:xslt" href="#parameters">
                            <cityEHRapi xsl:version="2.0">
                                <xsl:copy-of
                                    select="(//parameters[@type='view'])[1]/cityEHRapiCommandNotFound"/>
                                <xsl:copy-of select="(//parameters[@type='view'])[1]/cityEHRapi/*"/>
                            </cityEHRapi>
                        </p:input>
                        <p:output name="data" id="return"/>
                    </p:processor>

                </p:otherwise>

            </p:choose>

        </p:otherwise>
    </p:choose>


    <!-- Return XML -->
    <p:processor name="oxf:xml-serializer">
        <p:input name="config">
            <config>
                <encoding>utf-8</encoding>
            </config>
        </p:input>
        <p:input name="data" href="#return"/>
    </p:processor>

</p:pipeline>
