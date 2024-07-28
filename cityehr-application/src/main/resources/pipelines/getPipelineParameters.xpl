<!-- 
    *********************************************************************************************************
    cityEHR
    getPipelineParameters.xpl
    
    Pipeline to generate the combined parameters instance used by cityEHR pipelines.
    The parameters returned as combined-parameters are:
        view-parameters (passed as input to this pipeline)
        system-parameters
        database-parameters
        session-parameters
        application-parameters
    
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
    xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:cda="urn:hl7-org:v3" xmlns:exist="http://exist.sourceforge.net/NS/exist"
    xmlns:xdb="http://orbeon.org/oxf/xml/xmldb">

    <!-- Input to pipeline is view-parameters.xml -->
    <p:param name="instance" type="input"/>
    
    <!-- Standard pipeline output -->
    <p:param name="parameters" type="output"/>
    
    <!-- Get the system-parameters.
         These are located in the built-in database at the location specified in the view-parameters -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission">
            <xf:submission serialization="none" method="get" action="{systemResourcesURL/@localPrefix}{systemResourcesURL/@storageLocation}{systemResourcesURL/@systemParametersResource}"/>
        </p:input>
        <p:input name="request" href="#instance"/>
        <p:output name="response" id="systemParametersReturned"/>
    </p:processor>
    
    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#systemParametersReturned"/>
        <p:output name="data" id="systemParameters"/>
    </p:processor>
    
    <!-- Get the database-parameters.
         These are located in the built-in database at the location specified in the view-parameters. -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission">
            <xf:submission serialization="none" method="get" action="{databaseParametersURL/@databaseLocation}"/>
        </p:input>
        <p:input name="request" href="#instance"/>
        <p:output name="response" id="databaseParametersReturned"/>
    </p:processor>
    
    <!-- Combine parameters to use in other processing.
         The exception catcher behaves like the identity processor if there is no exception
         However if there is an exception, it catches it, and you get a serialized form of the exception 
         Here we also combine the system-parameters, datavase-parameters and view-parameters.
         So that combinedParameters is of the form:
         
         <combinedParameters>
            <parameters type="system">
                ...system parameters are here...
            </parameters>
            <parameters type="database">
                ...database parameters are here...
            </parameters>
            <parameters type="view">
                ...view parameters are here...
            </parameters>
         </combinedParameters>
    
    -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="aggregate('combinedParameters',#systemParameters,#databaseParametersReturned,#instance)"/>
        <p:output name="data" id="combinedParameters"/>
    </p:processor>
    
    <!-- Get the session-parameters.
         These are located in the database at xmlstore/users/<userId>/session-parameters
         The databaseURL is found in the first node of the deployed physicalCluster for the 'ehr' system in database-parameters.
         The userId was passed in the URL to view-parameters (#instance).
         If the userId is blank (i.e. not passed) then just return an empty element and do not make the submission -->
    <p:choose href="#combinedParameters">
        
        <!-- userId not specified -->
        <p:when test="//parameters[@type='view']/userId=''">
            
            <!-- session-parameters are empty -->
            <p:processor name="oxf:identity">
                <p:input name="data">
                    <parameters type="session"/>
                </p:input>
                <p:output name="data" id="sessionParameters"/>
            </p:processor>
            
        </p:when>
        
        <!-- userId specified -->
        <p:otherwise>      
            <!-- Get session parameters from the database -->
            <p:processor name="oxf:xforms-submission">
                <p:input name="submission">
                    <xf:submission serialization="none" method="get" action="{parameters[@type='database']/deployedDatabases/physicalCluster[@system='ehr'][1]/node[1]/@databaseURL}{parameters[@type='database']/deployedDatabases/physicalCluster[@system='ehr'][1]/node[1]/@btuLocation}/xmlstore/users/{parameters[@type='view']/userId}/session-parameters"/>
                </p:input>
                <p:input name="request" href="#combinedParameters"/>
                <p:output name="response" id="sessionParametersReturned"/>
            </p:processor>
            
            <!-- The exception catcher behaves like the identity processor if there is no exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#sessionParametersReturned"/>
                <p:output name="data" id="sessionParameters"/>
            </p:processor>
        </p:otherwise>  
    </p:choose>

    <!-- Get the configuration parameters for this application.
         The session-parameters contain all parameters needed to load the application parameters
         These are located in the database at /xmlstore/applications/<applicationId>/systemConfiguration/application-parameters.
         The databaseURL in session-parameters has been set to the URL of the database node holding the kernal BTU
         If the session-parameters are empty just return an empty element and do not make the submission 
         -->
    <p:choose href="#sessionParameters">
        
        <!-- sessionParameters are specified-->
        <p:when test="exists(parameters/databaseURL[.!=''][1]) and exists(parameters/applicationId[.!=''][1])">
            <p:processor name="oxf:xforms-submission">
                <p:input name="submission">
                    <xf:submission serialization="none" method="get"
                        action="{databaseURL[.!=''][1]}/xmlstore/applications/{applicationId[.!=''][1]}/systemConfiguration/application-parameters"
                    />
                </p:input>
                <p:input name="request" href="#sessionParameters"/>
                <p:output name="response" id="applicationParametersReturned"/>
            </p:processor>
            
            <!-- The exception catcher behaves like the identity processor if there is no exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#applicationParametersReturned"/>
                <p:output name="data" id="applicationParameters"/>
            </p:processor>
                       
        </p:when>
        
        <!-- sessionParameters are empty -->
        <p:otherwise>      
            <p:processor name="oxf:identity">
                <p:input name="data">
                    <parameters type="application"/>
                </p:input>
                <p:output name="data" id="applicationParameters"/>
            </p:processor>
            
        </p:otherwise>  
    </p:choose>    
    
    
    

    <!-- 
         parameters returned is now of the form:
            <parameters>
                <parameters type="application">
                    ...application parameters are here
                </parameters> 
                <parameters type="session">
                    ...session parameters are here...
                </parameters>
                <parameters type="system">
                    ...system parameters are here...
                </parameters>
                <parameters type="database">
                    ...database parameters are here...
                </parameters>
                <parameters type="view">
                    ...view parameters are here...
                </parameters>   
            </parameters>
            
            Note that view-parameters contains duplicates of session-parameters.
            Need to use the session-parameters in preference to view-parameters (which are placeholders).
            So make sure [1] predicate is used on any such parameters -->
    <p:processor name="oxf:identity">
        <p:input name="data" href="aggregate('parameters',#applicationParameters,#sessionParameters,#systemParameters,#databaseParametersReturned,#instance)"/>
        <p:output name="data" ref="parameters"/>
    </p:processor>
    
</p:pipeline>
