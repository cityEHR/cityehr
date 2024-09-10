<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRapi-getApplicationList.xpl
    
    cityEHR API Command Handler: getApplicationList
    Note that the pipeline document element must have an attribute cityEHR:type="cityEHRapi" in order for the pipeline to be invoked
    Invocataion is from cityEHRapi.xpl
    
    Pipleline to return the set of applications installed for the cityEHR system.
    
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
<p:pipeline cityEHR:type="cityEHRapi" xmlns:p="http://www.orbeon.com/oxf/pipeline"
    xmlns:oxf="http://www.orbeon.com/oxf/processors"
    xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xdb="http://orbeon.org/oxf/xml/xmldb"
    xmlns:cityEHR="http://openhealthinformatics.org/ehr">

    <!-- Input to pipeline is the view-parameters with URL parameters set -->
    <p:param name="instance" type="input"/>

    <!-- Run the getPipelineParameters pipeline.
         Returns the combined application-parameters, session-parameters, system-parameters, database-parameters,  view-parameters -->
    <p:processor name="oxf:pipeline">
        <p:input name="config" href="getPipelineParameters.xpl"/>
        <p:input name="instance" href="#instance"/>
        <p:output name="parameters" id="parameters"/>
    </p:processor>
    
    <!-- Get the session for the user - TBD -->

    <!-- Check the session - this is a hardwired stub-->
    <p:choose href="#parameters">

        <!-- Session is valid -->
        <p:when
            test="//parameters[@type='view'][1][userId='admin'][sessionId='863fa22fd0253e00333d96bb4417973a']">
            
            <!-- Get the database query -->
            <p:processor name="oxf:url-generator">
                <p:input name="config">
                    <config>
                        <url>
                            ../xquery/applicationListXQuery.xml
                        </url>
                        <content-type>application/xml</content-type>
                    </config>
                </p:input>
                <p:output name="data" id="queryReturned"/>
            </p:processor>
            
            <!-- The exception catcher behaves like the identity processor if there is no exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#queryReturned"/>
                <p:output name="data" id="queryChecked"/>
            </p:processor>
            
            <!-- Submission to run the query -->
            <p:processor name="oxf:xforms-submission">
                <p:input name="submission">
                    <xf:submission method="post"
                        action="{//parameters[@type='database'][1]/deployedDatabases/physicalCluster[@system='ehr'][1]/node[1]/@databaseURL}{//parameters[@type='database']/deployedDatabases/physicalCluster[@system='ehr'][1]/node[1]/@btuLocation}/xmlstore/applications"
                    />
                </p:input>
                <p:input name="request" href="#queryChecked"/>
                <p:output name="response" id="applicationListReturned"/>
            </p:processor>
            
            <!-- The exception catcher behaves like the identity processor if there is no exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#applicationListReturned"/>
                <p:output name="data" id="return"/>
            </p:processor>
            

            <!-- Get the list of applications -->
            <!--
            <p:processor name="oxf:identity">
                <p:input name="data">
                    <getApplicationList/>
                </p:input>
                <p:output name="data" id="return"/>
            </p:processor>
            -->

        </p:when>

        <p:otherwise>
            <!-- Return an error -->
            <p:processor name="oxf:identity">
                <!-- Debugging -->
                <!--
                        <p:input name="data" href="#apiPipeline"/>
                        -->
                <p:input name="data">
                    <cityEHRapiResponse>
                        <invalidSession/>
                    </cityEHRapiResponse>
                </p:input>
                <p:output name="data" id="return"/>
            </p:processor>

        </p:otherwise>

    </p:choose>


    <!-- Serialize the response to the API call -->
    <p:processor name="oxf:xml-serializer">
        <p:input name="config">
            <config>
                <encoding>utf-8</encoding>
            </config>
        </p:input>
        <p:input name="data" transform="oxf:xslt" href="#return">
            <cityEHRapiResponse xsl:version="2.0">
                <xsl:copy-of select="*"/>
            </cityEHRapiResponse>
        </p:input>
    </p:processor>

</p:pipeline>
