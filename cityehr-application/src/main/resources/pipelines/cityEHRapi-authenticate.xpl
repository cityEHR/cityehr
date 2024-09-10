<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRapi-authenticate.xpl
    
    cityEHR API Command Handler: authenticate
    Note that the pipeline document element must have an attribute cityEHR:type="cityEHRapi" in order for the pipeline to be invoked
    Invocataion is from cityEHRapi.xpl
    
    Pipleline to authenticate the user (agent) and return a session token
    
    ***This is a stub which returns a fixed sessionId for user=admin&password=password
    
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

    <!-- Get the user credentials.
         If these cannot be retrieved, then userId is invalid -->
 <!--
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission">
            <xf:submission serialization="none" method="get"
                action="{//parameters[@type='database'][1]/deployedDatabases/physicalCluster[@system='ehr'][1]/node[1]/@databaseURL}{//parameters[@type='database']/deployedDatabases/physicalCluster[@system='ehr'][1]/node[1]/@btuLocation}/xmlstore/users/{//parameters[@type='view']/userId}/credentials"
            />
        </p:input>
        <p:input name="request" href="#parameters"/>
        <p:output name="response" id="credentialsReturned"/>
    </p:processor>
-->

    <p:processor name="oxf:identity">
        <p:input name="data" transform="oxf:xslt" href="#parameters">
            <stub xsl:version="2.0">
                <xsl:if test="//parameters[@type='view'][1][userId='admin'][password='password']">
                    <sessionId>863fa22fd0253e00333d96bb4417973a</sessionId>
                </xsl:if>
                <xsl:if
                    test="not(//parameters[@type='view'][1][userId='admin'][password='password'])">
                    <userAuthenticationFailed/>             
                </xsl:if>
            </stub>
        </p:input>
        <p:output name="data" id="credentialsReturned"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#credentialsReturned"/>
        <p:output name="data" id="credentials"/>
    </p:processor>

    <!-- Encrypt the password supplied as parameter to API call.
         Use the seed key set in the user credentials to encrypt the password set as a parameter.
         Compare with the encrypted password stored in the credentials to authenticate the user. -->


    <!-- Start new sessiion.
         If the user was authenticated then generate a new sessionId -->


    <!-- Serialize the response to the API call -->
    <p:processor name="oxf:xml-serializer">
        <p:input name="config">
            <config>
                <encoding>utf-8</encoding>
            </config>
        </p:input>
        <p:input name="data" transform="oxf:xslt" href="#credentials">
            <cityEHRapiResponse xsl:version="2.0">
                <xsl:copy-of select="*/*"/>
            </cityEHRapiResponse>
        </p:input>
    </p:processor>

</p:pipeline>
