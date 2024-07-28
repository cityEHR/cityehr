<!--
    cityEHR
    cityEHRTransformXMLInstance.xpl
    
    Pipeline takes an XML instance as input, runs an XSLT transformation and outputs the result on the standard data output.
    The transformation to be run is specified in parameters/transformationXSL
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
-->
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- Input to pipeline is view-parameters.xml and the instance to be transformed -->
    <p:param name="parameters" type="input"/>
    <p:param name="instance" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>

    <!-- Get the XSLT for the transformation
         The location of the XSLT is set in the transformationXSL parameter -->
    <p:processor name="oxf:url-generator">
        <p:input name="config" transform="oxf:xslt" href="#parameters">
            <config xsl:version="2.0">
                <url>
                    <xsl:value-of select="parameters/transformationXSL"/>
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
            <p:processor name="oxf:xslt">
                <p:input name="config" href="#stylesheet"/>
                <p:input name="data" href="#instance"/>
                <p:output name="data" id="transformationOutput"/>
            </p:processor>

            <!-- Catch exception if anything goes wrong with the transformation -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#transformationOutput"/>
                <p:output name="data" id="transformedInstance"/>
            </p:processor>

            <p:processor name="oxf:identity">
                <p:input name="data" href="#transformedInstance"/>
                <p:output name="data" ref="data"/>
            </p:processor>
        </p:when>

        <p:otherwise>
            <p:processor name="oxf:identity">
                <p:input name="data" href="#stylesheet"/>
                <p:output name="data" ref="data"/>
            </p:processor>
        </p:otherwise>
    </p:choose>

</p:pipeline>
