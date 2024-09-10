<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRExportInstance.xpl
    
    Pipleline to run xquery and return results as a zip file to browser
    Input is view-parameters
    The following parameters must have been set in session-parameters:
        runXqueryQueryText, runXqueryContext, transformationXSL
        
    Executes the query to get an instance, then runs the transformation (if specified), then zips to return to browser
    
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
    xmlns:oxf="http://www.orbeon.com/oxf/processors"
    xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xdb="http://orbeon.org/oxf/xml/xmldb">

    <!-- Input to pipeline is view-parameters.xml -->
    <p:param name="instance" type="input"/>

    <!-- Run the getPipelineParameters pipeline.
         Returns the combined application-parameters, session-parameters, system-parameters, database-parameters,  view-parameters -->
    <p:processor name="oxf:pipeline">
        <p:input name="config" href="getPipelineParameters.xpl"/>               
        <p:input name="instance" href="#instance"/>
        <p:output name="parameters" id="parameters"/>
    </p:processor>
    
    <!-- Set the query -->
    <p:processor name="oxf:xslt">
        <p:input name="config">
            <xsl:stylesheet version="2.0">
                <xsl:variable name="queryRoot" select="//parameters[@type='session']/databaseURL[.!=''][1]"/>
                <xsl:variable name="runXqueryContext" select="//parameters[@type='session']/runXqueryContext"/>
                <xsl:variable name="runXqueryQueryText" select="//parameters[@type='session']/runXqueryQueryText"/>
                              
                <!-- Output is the exist:query -->
                <xsl:template match="/">
                    <exist:query start="1" max="1000"
                        queryLocation="{concat($queryRoot,$runXqueryContext)}">
                        <exist:text>
                            <xsl:value-of select="$runXqueryQueryText"/>
                        </exist:text>
                    </exist:query>
                </xsl:template>
                
                <!-- Mop up text nodes -->
                <xsl:template match="text()"/>
            </xsl:stylesheet>            
        </p:input>
        <p:input name="data" href="#parameters"/>
        <p:output name="data" id="query"/>
    </p:processor>
    
    <!-- Submit query to the xmlstore.
         The AVT is relative to the request -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission">
            <xf:submission action="{@queryLocation}" method="post"/>
        </p:input>
        <p:input name="request" href="#query"/>
        <p:output name="response" id="queryResults"/>
    </p:processor>   
    

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#queryResults"/>
        <p:output name="data" id="queryResponse-checked"/>
    </p:processor>

    <!-- Transform the record set (if required).
         The transformation to run must have been set up in the parameters -->

    <p:choose href="#parameters">
        <!-- If a transformation has been set. -->
        <p:when test="parameters[@type='session']/transformationXSL != ''">
            <!-- Get the XSLT for the transformation
                The location of the XSLT is set in the transformationXSL parameter -->
            <p:processor name="oxf:url-generator">
                <p:input name="config" transform="oxf:xslt" href="#instance">
                    <config xsl:version="2.0">
                        <url> ../xslt/<xsl:value-of select="parameters[@type='session']/transformationXSL"/>
                        </url>
                        <content-type>application/xml</content-type>
                    </config>
                </p:input>
                <p:output name="data" id="xslt"/>
            </p:processor>

            <!-- Catch exception if anything goes wrong loading the stylesheet -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#xslt"/>
                <p:output name="data" id="stylesheet"/>
            </p:processor>


            <!-- Other processing depends on whether the stylesheet is now XSLT or whether an exception was raised -->
            <p:choose href="#stylesheet">
                <!-- If stylesheet is good it should have a root element. -->
                <p:when test="exists(xsl:stylesheet)">
                    <!-- Run XSLT to transform the input instance -->
                    <p:processor name="oxf:unsafe-xslt">
                        <p:input name="config" href="#stylesheet"/>
                        <p:input name="data" href="#queryResponse-checked"/>
                        <p:input name="parameters" href="#instance"/>
                        <p:output name="data" id="transformationOutput"/>
                    </p:processor>

                    <!-- Catch exception if anything goes wrong with the transformation -->
                    <p:processor name="oxf:exception-catcher">
                        <p:input name="data" href="#transformationOutput"/>
                        <p:output name="data" id="transformedInstance"/>
                    </p:processor>
                </p:when>

                <!-- Stylesheet is no good, so don't transform anything -->
                <p:otherwise>
                    <p:processor name="oxf:identity">
                        <p:input name="data" href="#queryResponse-checked"/>
                        <p:output name="data"
                            id="transformedInstance"/>
                    </p:processor>
                </p:otherwise>
            </p:choose>
        </p:when>

        <!-- Or if no transformation is required, just pass straight through -->
        <p:otherwise>
            <p:processor name="oxf:identity">
                <p:input name="data" href="#queryResponse-checked"/>
                <p:output name="data" id="transformedInstance"/>
            </p:processor>
        </p:otherwise>
    </p:choose>

    <!-- Convert the output to serialized XML -->
    <p:processor name="oxf:xml-serializer">
        <p:input name="config">
            <config>
                <encoding>utf-8</encoding>
            </config>
        </p:input>
        <p:input name="data" href="#transformedInstance"/>
        <p:output name="data" id="serialized"/>
    </p:processor>

    <!-- Write the document to a temporary file. 
         File name is passed out on data as <url>...</url>-->
    <p:processor name="oxf:file-serializer">
        <p:input name="config">
            <config>
                <scope>session</scope>
            </config>
        </p:input>
        <p:input name="data" href="#serialized"/>
        <p:output name="data" id="exportLocation"/>
    </p:processor>

    <!-- Zip complete document -->
    <p:processor name="oxf:zip">
        <p:input name="data" transform="oxf:xslt" href="#exportLocation">
            <files xsl:version="2.0">
                <file
                    name="export-{replace(replace(string(current-dateTime()),':','-'),'\+','*')}.xml">
                    <xsl:value-of select="url"/>
                </file>
            </files>
        </p:input>
        <p:output name="data" id="zipped-doc"/>
    </p:processor>

    <!-- Serialize to return to browser.
         The filename is concatenated from:
         current time stamp -->
    <p:processor name="oxf:http-serializer">
        <p:input name="config" transform="oxf:xslt" href="#exportLocation">
            <config xsl:version="2.0">
                <header>
                    <name>Content-Disposition</name>
                    <value>attachement; filename=export-<xsl:value-of
                            select="replace(replace(string(current-dateTime()),':','-'),'\+','*')"
                        />.zip</value>
                </header>
                <content-type>application/zip</content-type>
                <force-content-type>true</force-content-type>
            </config>
        </p:input>
        <p:input name="data" href="#zipped-doc"/>
    </p:processor>

</p:pipeline>
