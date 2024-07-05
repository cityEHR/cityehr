<!--
    cityEHR
    generateDictionary.xpl
    
    Input instance is an OWL/XML ontology model
    Calls XSLT processor to generate a data dictionary
    And stores the result in the named dictionary (target)
    
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

    <!-- Input to pipeline is OWL/XML specialty model -->
    <p:param name="instance" type="input"/>
    
    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>
    
    <!-- Run XSLT to convert OWL/XML to a Data Dictionary -->
    <p:processor name="oxf:xslt">
        <p:input name="config" href="../xslt/OWL2DataDictionary.xsl"/>
        <p:input name="data" href="#instance"/>
        <!--
        <p:input name="parameters" href="#parameters"/>
        -->
        <p:output name="data" ref="data"/>
    </p:processor>
    
</p:pipeline>
