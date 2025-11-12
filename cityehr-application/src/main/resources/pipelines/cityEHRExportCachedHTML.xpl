<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRExportCachedHTML.xpl
    
    Pipeline to render HTML document as CSV (comma separated values) and then deliver to browser.
    The HTML is cached for the user at the database location defined by htmlCacheHandle
    The full database URL must be set in htmlCacheHandle before this pipeline is invoked
    HTML is then retrieved through htmlCacheHandle
    
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
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:saxon="http://saxon.sf.net/"
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
        <!-- Check that the htmlCacheHandle is set -->
        <p:when test="//parameters[@type='session']/htmlCacheHandle != ''">
            
            <!-- Get the HTML document for the resource
                 This is located in the database at xmlstore/users/<userId>/htmlCache
                 The full htmlCacheHandle is found in the session parameters -->
            <p:processor name="oxf:xforms-submission">
                <p:input name="submission">
                    <xf:submission serialization="none" method="get" action="{//parameters[@type='session']/htmlCacheHandle}"/>
                </p:input>
                <p:input name="request" href="#parameters"/>
                <p:output name="response" id="htmlReturned"/>
            </p:processor>
            
            <!-- The exception catcher behaves like the identity processor if there is no exception -->
            <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#htmlReturned"/>
                <p:output name="data" id="html"/>
            </p:processor>
        </p:when>
        
        <!-- No htmlCacheHandle supplied - output an error -->
        <p:otherwise>
            <p:processor name="oxf:identity">
                <p:input name="data">
                    <html>
                        <body>
                            <p>
                                Error - HTML not found.
                            </p>
                        </body>
                    </html>
                </p:input>
                <p:output name="data" id="html"/>
            </p:processor>
        </p:otherwise>
    </p:choose>
    
    
    <!-- Produce CSV -->
    <!-- Input is the HTML to be exported. -->
    <p:processor name="oxf:unsafe-xslt">
        <p:input name="config" href="../xslt/HTML2CSV.xsl"/>
        <p:input name="data" href="#html"/>
        <p:output name="data" id="csvDocument"/>
    </p:processor>
    
    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#csvDocument"/>
        <p:output name="data" id="checkedCSV"/>
    </p:processor>
    
    <!-- Convert the transformed resource to serialized text or XML -->
    <p:processor name="oxf:text-serializer">
        <p:input name="config">
            <config>
                <encoding>utf-8</encoding>
            </config>
        </p:input>
        <p:input name="data" href="#checkedCSV"/>
        <p:output name="data" id="serialized"/>
    </p:processor>
 

    <!-- Serialize to return to browser.
    The filename is set in externalId -->
    <p:processor name="oxf:http-serializer">
        <p:input name="config" transform="oxf:xslt" href="#instance">
            <config xsl:version="2.0">
                <header>
                    <name>Content-Disposition</name>
                    <value>attachement; filename=<xsl:value-of
                        select="parameters/externalId"/>.csv</value>
                </header>
                <content-type>application/text</content-type>
                <force-content-type>true</force-content-type>
            </config>
        </p:input>
        <p:input name="data" href="#serialized"/>
    </p:processor>



</p:pipeline>
