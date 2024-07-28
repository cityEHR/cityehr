<!--
    cityEHR
    generateSVGChart.xpl
    
    Pipeline calls svg-serializer processor to generate .png file from SVG data input
    
    Input is CDA document or a graph instance
    And control file with list of variables to be plotted
    Run XSLT to transform CDA to SVG
    Convert SVG to PNG
    Write PNG to temporary file and return its location
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
-->
<p:pipeline xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:p="http://www.orbeon.com/oxf/pipeline"
    xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:cda="urn:hl7-org:v3">

    <!-- Input to pipeline is CDA view instance and a control-instance with parameters  -->
    <p:param name="instance" type="input"/>
    <p:param name="control" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>

    <!-- Debug input -->
    <!--
    <p:processor name="oxf:identity">
        <p:input name="data" transform="oxf:xslt" href="#control" xsl:version="2.0">
                <xsl:copy-of select="//svgData/svg:svg"/>
        </p:input>
        <p:output name="data" ref="output"/>
    </p:processor>
    -->

    <!-- Run XSLT to convert CDA view into SVG chart  -->
    <p:processor name="oxf:xslt">
        <p:input name="config" href="../xslt/CDA2SVGChart.xsl"/>
        <p:input name="data" href="#instance"/>
        <p:input name="control" href="#control"/>
        <p:output name="data" id="svgChart"/>
    </p:processor>


    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#svgChart"/>
        <p:output name="data" id="svgChartChecked"/>
    </p:processor>

    <!-- Always make some SVG, even if there was an error -->
    <p:choose href="#svgChartChecked">
        <p:when test="not(/*/name()='svg')">
            <p:processor name="oxf:xslt">
                <p:input name="config">
                    <svg xmlns="http://www.w3.org/2000/svg" width="200" height="300" version="1.1" xsl:version="2.0">
                        <rect x="0" y="0" width="100" height="100" fill="#E8E8E8"/>
                        <text x="50" y="50" font-size="12" text-anchor="middle">
                            <xsl:value-of select="/*/name()"/>
                            <xsl:value-of select="(//method-name)[1]"/>
                        </text>
                        <circle cx="30" cy="30" r="20" fill="blue" stroke="none"/>
                    </svg>
                </p:input>
                <p:input name="data" href="#svgChartChecked"/>
                <p:output name="data" id="svgOutput"/>
            </p:processor>
        </p:when>

        <p:otherwise>
            <p:processor name="oxf:identity">
                <p:input name="data" href="#svgChartChecked"/>
                <p:output name="data" id="svgOutput"/>
            </p:processor>
        </p:otherwise>
    </p:choose>


    <!-- Return jpg or svg -->
    <p:choose href="#control">
        <!-- Rendering as png - need to convert using svg-serialixer -->
        <p:when test="//rendition='jpg' ">

            <!-- Run SVG serializer to convert to JPG -->
            <p:processor name="oxf:svg-serializer">
                <p:input name="config">
                    <config>
                        <content-type>application/xml</content-type>
                    </config>
                </p:input>
                <p:input name="data" href="#svgOutput"/>
                <p:output name="data" id="jpgOutput"/>
            </p:processor>

            <!-- SVG Serializer (Batik) may throw an exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#jpgOutput"/>
                <p:output name="data" id="jpgOutputChecked"/>
            </p:processor>

            <!-- Write JPG (or error message) to temporary session file and return its location.
                 This is in an element named <url> -->
            <p:processor name="oxf:file-serializer">
                <p:input name="config">
                    <config>
                        <scope>session</scope>
                    </config>
                </p:input>
                <p:input name="data" href="#jpgOutputChecked"/>
                <p:output name="data" ref="data"/>
            </p:processor>

        </p:when>

        <p:otherwise>
            <p:processor name="oxf:identity">
                <p:input name="data" href="#svgOutput"/>
                <p:output name="data" ref="data"/>
            </p:processor>
        </p:otherwise>

    </p:choose>


    <!-- These can be used for debugging -->

    <!-- Convert  to serialized XML -->
    <!--
    <p:processor name="oxf:xml-serializer">
        <p:input name="config">
            <config>
                <encoding>utf-8</encoding>
                <indent>false</indent>
            </config>
        </p:input>
        <p:input name="data" href="#svgChartChecked"/>
        <p:output name="data" id="serializedXML"/>
    </p:processor>
    -->

    <!-- Write to a temporary file.
    File name is passed out on data as <url>...</url>-->
    <!--
    <p:processor name="oxf:file-serializer">
        <p:input name="config">
            <config>
                <scope>session</scope>
            </config>
        </p:input>
        <p:input name="data" href="#serializedXML"/>
        <p:output name="data" ref="data"/>
    </p:processor>
    -->

</p:pipeline>
