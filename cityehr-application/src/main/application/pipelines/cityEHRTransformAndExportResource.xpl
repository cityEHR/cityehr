<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRTransformAndExportResoutce.xpl
    
    Pipleline to export a resource from the cityEHR xmlstore
    The database location of the resource is passed in resourceHandle
    The externalId and resourceFileExtension are used to create the file name exported
    
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
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


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

    <p:choose href="#parameters">
        <!-- Check that the resourceHandle is set -->
        <p:when test="//parameters[@type='session']/resourceHandle != ''">

            <!-- Get the XML document for the resource
         These are located in the database at xmlstore/users/<userId>/xmlCache
         The full resourceHandle is found in the session parameters -->
            <p:processor name="oxf:xforms-submission">
                <p:input name="submission">
                    <xf:submission serialization="none" method="get" action="{//parameters[@type='session']/resourceHandle}"/>
                </p:input>
                <p:input name="request" href="#parameters"/>
                <p:output name="response" id="ehrResourceReturned"/>
            </p:processor>

            <!-- The exception catcher behaves like the identity processor if there is no exception -->
            <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#ehrResourceReturned"/>
                <p:output name="data" id="ehrResource"/>
            </p:processor>
        </p:when>

        <!-- No resourceHandle supplied - output an error -->
        <p:otherwise>
            <p:processor name="oxf:identity">
                <p:input name="data">
                    <badResourceHandle/>
                </p:input>
                <p:output name="data" id="ehrResource"/>
            </p:processor>
        </p:otherwise>
    </p:choose>

    <!-- Get the stylesheet to use for transformation.
         Need the axsl namespace-alias so that we can generate xslt from xslt
         For some reason the xsl:import needs to use a protocol (we are using oxf:) in the url 
         If this is entered directly (i.e. not generated using xslt) then a relative path such as ../xslt/ works OK -->
    <p:processor name="oxf:xslt">
        <p:input name="data" href="#parameters"/>
        <p:input name="config">
            <xsl:stylesheet version="2.0" xmlns:axsl="http://www.w3.org/1999/XSL/TransformAlias">
                <xsl:namespace-alias stylesheet-prefix="axsl" result-prefix="xsl"/>
                <xsl:template match="/">
                    <axsl:stylesheet version="2.0">
                        <axsl:import href="{concat('oxf:/apps/ehr/xslt/',//parameters[@type='session']/transformationXSL,'.xsl')}"/>
                    </axsl:stylesheet>
                </xsl:template>
            </xsl:stylesheet>
        </p:input>
        <p:output name="data" id="generatedStylesheet"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception
         However if there is an exception, it catches it, and you get a serialized form of the exception.
         An exception will be raised if the stylesheet does not exist (including when transformationXSL is blank) -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#generatedStylesheet"/>
        <p:output name="data" id="stylesheet"/>
    </p:processor>


    <p:choose href="#parameters">
        <!-- If transformation is required -->
        <p:when test="//parameters[@type='session']/transformationXSL != ''">
            <!-- Run transformation, if one has been specified -->
            <p:processor name="oxf:unsafe-xslt">
                <p:input name="config" href="#stylesheet"/>
                <p:input name="data" href="#ehrResource"/>
                <p:input name="parameters" href="#parameters"/>
                <p:output name="data" id="transformedResourceReturned"/>
            </p:processor>

            <!-- The exception catcher behaves like the identity processor if there is no exception -->
            <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#transformedResourceReturned"/>
                <p:output name="data" id="exportResource"/>
            </p:processor>
        </p:when>

        <!-- No transformation required - just pass ehrResource to exportResource -->
        <p:otherwise>
            <p:processor name="oxf:identity">
                <p:input name="data" href="#ehrResource"/>
                <p:output name="data" id="exportResource"/>
            </p:processor>
        </p:otherwise>

    </p:choose>

    <!-- Convert the exportResource to serialized XML -->
    <p:processor name="oxf:xml-serializer">
        <p:input name="config">
            <config>
                <encoding>utf-8</encoding>
            </config>
        </p:input>
        <p:input name="data" href="#exportResource"/>
        <p:output name="data" id="serializedResource"/>
    </p:processor>

    <!-- Write the document to a temporary file. 
         File name is passed out on data as <url>...</url>-->
    <p:processor name="oxf:file-serializer">
        <p:input name="config">
            <config>
                <scope>session</scope>
            </config>
        </p:input>
        <p:input name="data" href="#serializedResource"/>
        <p:output name="data" id="exportFileLocation"/>
    </p:processor>

    <!-- Zip complete document -->
    <p:processor name="oxf:zip">
        <p:input name="data" transform="oxf:xslt" href="aggregate('config',#exportFileLocation,#parameters)">
            <files xsl:version="2.0">
                <xsl:variable name="fileName"
                    select="if (//parameters[@type='session']/externalId!='') then //parameters[@type='session']/externalId else concat(replace(replace(string(current-dateTime()),':','-'),'\+','*'),'-cityEHR-export')"/>
                <xsl:variable name="fileExtension"
                    select="if (//parameters[@type='session']/resourceFileExtension!='') then //parameters[@type='session']/resourceFileExtension else 'xml'"/>
                <file name="{$fileName}.{$fileExtension}">
                    <xsl:value-of select="config/url"/>
                </file>
            </files>
        </p:input>
        <p:output name="data" id="zipped-doc"/>
    </p:processor>

    <!-- Serialize to return to browser.
        The filename is concatenated from:
        patientId
        suffix set in view-parameters.xml
        current time stamp -->
    <p:processor name="oxf:http-serializer">
        <p:input name="config" transform="oxf:xslt" href="#parameters">
            <config xsl:version="2.0">
                <xsl:variable name="fileName"
                    select="if (//parameters[@type='session']/externalId!='') then //parameters[@type='session']/externalId else concat(replace(replace(string(current-dateTime()),':','-'),'\+','*'),'-cityEHR-export')"/>
                <header>
                    <name>Content-Disposition</name>
                    <value>attachement; filename=<xsl:value-of select="concat($fileName,'.zip')"/></value>
                </header>
                <content-type>application/zip</content-type>
                <force-content-type>true</force-content-type>
            </config>
        </p:input>
        <p:input name="data" href="#zipped-doc"/>
    </p:processor>

</p:pipeline>
