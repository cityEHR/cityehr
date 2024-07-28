<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    getPatientRecord.xpl
    
    Pipeline to get a complete patient record and then deliver to browser as a zip.
    
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
    xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms">

    <!-- Input to pipeline is view-parameters.xml as set in the page-flow.xml file 
    with parameters set in the page element -->
    <p:param name="instance" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>

    <!-- Execute REST submission to get XML document for the CDA-->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission">
            <xf:submission serialization="none" method="get"
                action="{compositionHandle}"/>
        </p:input>
        <p:input name="request" href="#instance"/>
        <p:output name="response" id="composition"/>
    </p:processor>
    
    
    <!-- Produce XSL-FO -->
    <!-- Inputs are the composition (CDA) to be rendered and the patient demographics
         that have been found in the xmlstore with the REST submissions above. -->
    <p:processor name="oxf:xslt">
        <p:input name="config" href="../xslt/CDA2FO.xsl"/>
        <p:input name="data" href="#composition"/>
        <p:input name="parameters" href="#instance"/>
        <p:output name="data" ref="data"/>
    </p:processor>
    
    
    <!-- Run FO Processor to generate PDF-->
    <!--
    <p:processor name="oxf:xslfo-serializer">    
        <p:input name="config" >        
            <config>     
                <content-type>application/pdf</content-type>  
            </config>
        </p:input>
        <p:input name="data" href="#FOdocument"/>   
        <p:output name="data" ref="data"/>  
    </p:processor>
    -->
    

</p:pipeline>
