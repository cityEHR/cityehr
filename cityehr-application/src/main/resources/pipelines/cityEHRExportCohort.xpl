<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRExportCohort.xpl
    
    Pipleline to transform input to CSV, or other defined formats and return to browser
    Input is the patientSet-instance of patientSet containing patientInfo/patientData elements
    
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

    <!-- Input to pipeline is patientSet-instance -->
    <p:param name="instance" type="input"/>
    
    <!-- Get the stylesheet to use for transformation.
        Need the axsl namespace-alias so that we can generate xslt from xslt
        For some reason the xsl:import needs to use a protocol (we are using oxf:) in the url 
        If this is entered directly (i.e. not generated using xslt) then a relative path such as ../xslt/ works OK -->
    <p:processor name="oxf:xslt">
        <p:input name="data" href="#instance"/>
        <p:input name="config">
            <xsl:stylesheet version="2.0" xmlns:axsl="http://www.w3.org/1999/XSL/TransformAlias">
                <xsl:namespace-alias stylesheet-prefix="axsl" result-prefix="xsl"/>
                <xsl:template match="/">
                    <axsl:stylesheet version="2.0">
                        <axsl:import href="{concat('oxf:/apps/ehr/xslt/',patientSet/@transformationXSL)}"
                        />
                    </axsl:stylesheet>
                </xsl:template>
            </xsl:stylesheet>
        </p:input>
        <p:output name="data" id="stylesheet"/>
    </p:processor>
    
    
    <p:choose href="#instance">
        <!-- If transformation is required -->
        <p:when test="patientSet/@transformationXSL != ''">
            <!-- Run transformation, if one has been specified -->
            <p:processor name="oxf:unsafe-xslt">
                <p:input name="config" href="#stylesheet"/>
                <p:input name="data" href="#instance"/>
                <p:input name="parameters" href="#instance"/>
                <p:output name="data" id="transformedInstance"/>
            </p:processor>
            
            <!-- The exception catcher behaves like the identity processor if there is no exception -->
            <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#transformedInstance"/>
                <p:output name="data" id="checkedTransformedInstance"/>
            </p:processor>
            
            <!-- Convert the transformed resource to serialized text or XML -->
            <p:processor name="oxf:text-serializer">
                <p:input name="config">
                    <config>
                        <encoding>utf-8</encoding>
                    </config>
                </p:input>
                <p:input name="data" href="#checkedTransformedInstance"/>
                <p:output name="data" id="serialized"/>
            </p:processor>
        </p:when>
        
        <!-- No transformation required -->
        <p:otherwise>
            <!-- Convert the resource to serialized XML -->
            <p:processor name="oxf:xml-serializer">
                <p:input name="config">
                    <config>
                        <encoding>utf-8</encoding>
                    </config>
                </p:input>
                <p:input name="data" href="#instance"/>
                <p:output name="data" id="serialized"/>
            </p:processor>
        </p:otherwise>
        
    </p:choose>
    
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
        <p:input name="data" transform="oxf:xslt"
            href="aggregate('config',#exportLocation,#instance)">
            <files xsl:version="2.0">
                <xsl:variable name="fileName"
                    select="if (config/patientSet/@externalId!='') then config/patientSet/@externalId else concat(replace(replace(string(current-dateTime()),':','-'),'\+','*'),'-cityEHR-export')"/>
                <xsl:variable name="fileExtension"
                    select="if (config/patientSet/@resourceFileExtension!='') then config/patientSet/@resourceFileExtension else 'xml'"/>
                <file
                    name="{$fileName}.{$fileExtension}">
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
        <p:input name="config" transform="oxf:xslt" href="#instance">
            <config xsl:version="2.0">
                <xsl:variable name="fileName"
                    select="if (patientSet/@externalId!='') then patientSet/@externalId else concat(replace(replace(string(current-dateTime()),':','-'),'\+','*'),'-cityEHR-export')"/>
                <header>
                    <name>Content-Disposition</name>
                    <value>attachement; filename=<xsl:value-of
                        select="concat($fileName,'.zip')"/></value>
                </header>
                <content-type>application/zip</content-type>
                <force-content-type>true</force-content-type>
            </config>
        </p:input>
        <p:input name="data" href="#zipped-doc"/>
    </p:processor>

</p:pipeline>
