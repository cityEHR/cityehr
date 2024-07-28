<!--
    cityEHR
    convertDatabase2PatientList.xpl
    
    Pipeline calls XSLT processor to convert cityEHR database format to patientSet XML
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
-->
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline"
    xmlns:oxf="http://www.orbeon.com/oxf/processors" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xf="http://www.w3.org/2002/xforms">

    <!-- Input to pipeline is xml/patient-view-parameters.xml as set in the page-flow.xml file 
    with parameters set in the page element -->
    <p:param name="instance" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>

    <!-- Run XSLT to convert database to patient list -->
    <p:processor name="oxf:xslt">
        <p:input name="config">
            <patientSet xsl:version="2.0">
                <xsl:for-each select="database/table[1]/record/field[1]">
                    <xsl:variable name="patientId" select="normalize-space(.)"/>
                    <patient id="{$patientId}"/>
                </xsl:for-each>
            </patientSet>          
        </p:input>
        <p:input name="data" href="#instance"/>
        <p:output name="data" id="transformedData"/>
    </p:processor>
    
    <!--
    <p:processor name="oxf:xslt">
        <p:input name="config"
            href="../xslt/Database2PatientList.xsl"/>
        <p:input name="data" href="#instance"/>
        <p:output name="data" id="transformedData"/>
    </p:processor>
    -->
    
    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#transformedData"/>
        <p:output name="data" ref="data"/>
    </p:processor>
    
</p:pipeline>
