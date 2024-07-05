<!--
    cityEHR
    cityEHRFatalError.xpl
    
    Override the standard Orbeon error handler.
    This pipeline is invoked when the session times out.
    Set in the WEB-INF/web.xml (top level of deployed orbeon directory) file in the lines:
    
    <servlet>
        <servlet-name>orbeon-main-servlet</servlet-name>
        ...
        <init-param>
            <param-name>oxf.error-processor.name</param-name>
            <param-value>{http://www.orbeon.com/oxf/processors}pipeline</param-value>
        </init-param>
        <init-param>
            <param-name>oxf.error-processor.input.config</param-name>
            <param-value>oxf:/apps/ehr/pipelines/cityEHRFatalError.xpl</param-value>
        </init-param>
        ...
    </servlet>   
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
-->
<!--
    Copyright (C) 2005-2007 Orbeon, Inc.
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
-->
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:saxon="http://saxon.sf.net/"
    xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:oxf="http://www.orbeon.com/oxf/processors">

    <!-- Generate exception document -->
    <p:processor name="oxf:exception">
        <p:output name="data" id="exception"/>
    </p:processor>

    <!-- Get view-parameters -->
    <p:processor name="oxf:url-generator">
        <p:input name="config">
            <config>
                <url>oxf:/apps/ehr/view-parameters.xml</url>
                <content-type>application/xml</content-type>
                <validating>true</validating>
                <handle-xinclude>false</handle-xinclude>
                <external-entities>false</external-entities>
                <handle-lexical>false</handle-lexical>
            </config>
        </p:input>
        <p:output name="data" id="parameters"/>
    </p:processor>


    <!-- Construct the error page -->
    <p:processor name="oxf:unsafe-xslt">
        <p:input name="data" href="#exception"/>
        <p:input name="parameters" href="#parameters"/>
        <p:input name="config">
            <xsl:stylesheet version="2.0">
                <xsl:variable name="parameters" select="document('input:parameters')/parameters"/>
                <xsl:template match="/">
                    <xhtml:html>
                        <xhtml:head>
                            <xhtml:link rel="stylesheet" type="text/css"
                                href="../resources/styles/cityEHRSkin.css?{$parameters/versionNumber/@version}"
                                media="screen"/>

                            <!-- HTML Title is the displayName of the current application -->
                            <xhtml:title>
                                <xsl:value-of select="$parameters/applicationDisplayName"/>
                            </xhtml:title>

                        </xhtml:head>

                        <xhtml:body class="cityEHRBase">
                            <xhtml:div class="signOnBlock">
                                <xhtml:div class="errorContainer">
                                    <!-- Message and Button to return to cityEHRSignOn page.
                                         At top, as the exception displayed may be long -->
                                    <xhtml:br/>
                                    <xhtml:p>
                                        <xhtml:span class="error">
                                            <xsl:value-of
                                                select="$parameters/staticParameters/cityEHRFatalError/errorMessage"
                                            />
                                        </xhtml:span>                                       
                                        <xhtml:a class="button" href="../">
                                            <xsl:value-of
                                                select="$parameters/staticParameters/cityEHRFatalError/resumeButton"
                                            />
                                        </xhtml:a>
                                    </xhtml:p>
                                    <!-- Show the exception -->
                                    <xhtml:p>
                                        <xsl:value-of select="exceptions/exception[1]/type"/>
                                    </xhtml:p>
                                    <xhtml:p>
                                        <xsl:value-of select="exceptions/exception[1]/message[1]"/>
                                    </xhtml:p>
                                </xhtml:div>
                            </xhtml:div>
                        </xhtml:body>
                    </xhtml:html>
                </xsl:template>
            </xsl:stylesheet>
        </p:input>
        <p:output name="data" id="errorForm"/>
    </p:processor>


    <!-- Serialize to XML -->
    <p:processor name="oxf:xml-converter">
        <p:input name="config">
            <config/>
        </p:input>
        <p:input name="data" href="#errorForm"/>
        <p:output name="data" id="converted"/>
    </p:processor>


    <!-- Send response -->
    <p:processor name="oxf:http-serializer">
        <p:input name="config">
            <config>
                <status-code>500</status-code>
            </config>
        </p:input>
        <p:input name="data" href="#converted"/>
    </p:processor>

</p:pipeline>
