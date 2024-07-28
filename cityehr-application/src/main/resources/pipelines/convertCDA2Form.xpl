<!-- 
    *********************************************************************************************************
    cityEHR
    convertCDA2Form.xpl
    
    Pipleline transform CDA to Xform and load page.
    
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

    <!-- Input to pipeline (instance) is xml/patient-view-parameters.xml as set in the page-flow.xml file 
        with parameters set in the page element -->
    <p:param name="instance" type="input"/>
    <p:param name="cda" type="input"/>   
    
    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>
    
    
    <!-- Produce XForm -->
    <!-- Inputs are the composition (CDA) to be rendered and the patient demographics
        that have been found in the xmlstore with the REST submissions above. -->
    <p:processor name="oxf:xslt">
        <p:input name="config" href="../xslt/CDA2XForm.xsl"/>
        <p:input name="data" href="#cda"/>
        <p:input name="parameters" href="#instance"/>
        <p:output name="data" id="form"/>
    </p:processor>
 
     <!-- Render the XForm -->
    <p:processor name="oxf:pipeline">
        <p:input name="data" href="#form"/>
        <p:input name="instance" href="#instance"/>
        <p:input name="config" href="oxf:/config/epilogue.xpl"/>
        <p:output name="data" ref="data"/>
    </p:processor>

</p:pipeline>
