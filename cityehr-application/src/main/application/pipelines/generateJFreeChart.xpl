<!--
    cityEHR
    generateJFreeChart.xpl
    
    Pipeline calls chart processor to generate JFreeChart chart from data input
    
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

    <!-- Input to pipeline is CDA view instance and a control-instance with parameters  -->
    <p:param name="control" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>


    <!-- Debug input -->
    <!--
    <p:processor name="oxf:identity">
        <p:input name="data" transform="oxf:xslt" href="#control">
            <data xsl:version="2.0">
                <xsl:copy-of select="//data[1]/*"/>
            </data>
        </p:input>
        <p:output name="data" ref="data"/>
    </p:processor>
    -->
    

    <p:processor name="oxf:chart">
        <p:input name="config">
            <config/>
        </p:input>
        <p:input name="data" transform="oxf:xslt" href="#control">
        <data xsl:version="2.0">
            <xsl:copy-of select="dashboardQuery/queryResults/category"/>
        </data>
        </p:input>
        <p:input name="chart" transform="oxf:xslt" href="#control">
            <chart xsl:version="2.0">
                <xsl:copy-of select="dashboardQuery/chart/*"/>
            </chart>
        </p:input>
        <p:output name="data" ref="data"/>
    </p:processor>

</p:pipeline>
