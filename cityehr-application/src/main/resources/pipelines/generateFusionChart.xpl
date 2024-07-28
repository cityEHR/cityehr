<!--
    cityEHR
    generateFusionChart.xpl
    
    Pipeline calls XSLT processor to generate fusion chart from view
    
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
    xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms">
    
    <!-- Input to pipeline is CDA view instance and a control-instance with parameters  -->
    <p:param name="instance" type="input"/>
    <p:param name="control" type="input"/>
    
    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>
    
    <!-- Run XSLT to convert CDA view into XML data for Fusion Charts -->
    <p:processor name="oxf:xslt">
        <p:input name="config"
            href="../xslt/CDA2FusionChart.xsl"/>
        <p:input name="data" href="#instance"/>
        <p:input name="control" href="#control"/>
        <p:output name="data" ref="data"/>
    </p:processor>
    
</p:pipeline>
