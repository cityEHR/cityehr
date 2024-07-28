<!--
    cityEHR
    getEventDisplay.xpl
    
    Pipeline calls XSLT processor to generate HTML from CDA Document 
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
-->
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Input to pipeline is xml instance for CDA and view-parameters.xml as parameters input 
         with parameters set in the page element -->
    <p:param name="instance" type="input"/>
    <p:param name="view-parameters" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>
    
    <!-- Run the getPipelineParameters pipeline.
         Returns the combined application-parameters, session-parameters, system-parameters, database-parameters,  view-parameters -->
    <p:processor name="oxf:pipeline">
        <p:input name="config" href="getPipelineParameters.xpl"/>               
        <p:input name="instance" href="#view-parameters"/>
        <p:output name="parameters" id="parameters"/>
    </p:processor>

    <!-- Execute REST submission to get XML document for the event-->
    <!--
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission">
            <xf:submission serialization="none" method="get"
                action="{storageObject}"/>
        </p:input>
        <p:input name="request" href="#instance"/>
        <p:output name="response" id="eventDoc"/>
    </p:processor>
-->

    <!-- Produce HTML view of event from CDA -->
    <p:processor name="oxf:xslt">
        <p:input name="config" href="../xslt/CDA2HTML.xsl"/>
        <p:input name="data" href="#instance"/>
        <p:input name="parameters" href="#parameters"/>
        <p:output name="data" id="htmlView"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#htmlView"/>
        <p:output name="data" id="htmlView-checked"/>
    </p:processor>

    <!-- Create an HTML error message if there was a problem.
         This pipeline must output HTML -->
    <p:choose href="#htmlView-checked">
        <!-- HTML document was found, so pass straight through to output -->
        <p:when test="exists(html)">
            <p:processor name="oxf:identity">
                <p:input name="data" href="#htmlView-checked"/>
                <p:output name="data" ref="data"/>
            </p:processor>
        </p:when>

        <!-- No html document was found -->
        <p:otherwise>
            <!-- Produce an error message -->
            <p:processor name="oxf:identity">
                <p:input name="data" transform="oxf:xslt" href="#parameters">
                    <html xsl:version="2.0">
                        <head/>
                        <body>
                            <p>
                                <xsl:value-of select="parameters/htmlPipeline/errorMessage"/>
                            </p>
                        </body>
                    </html>
                </p:input>

                <p:output name="data" ref="data"/>
            </p:processor>
        </p:otherwise>
    </p:choose>



</p:pipeline>
