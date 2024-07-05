<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHR-Views.xpl
    
    Pipleline to load page for summary views.
    
    There are four stages:
        1) Get the data dictionary from the database which contains a list of views to be rendered
        2) Run transformation to created generated content (for the list of views)
        3) Resolve xincudes in the template cityEHR-Views.xhtml so that the generated content is included
        4) Render the Xform
    
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
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:saxon="http://saxon.sf.net/" xmlns:f="http://orbeon.org/oxf/xml/formatting" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:cda="urn:hl7-org:v3">

    <!-- Input to pipeline is view-parameters.xml as set in the page-flow.xml file 
         with parameters set in the page element -->
    <p:param name="instance" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>

    <!-- 1. Execute REST submission to get the data dictionary
            -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission">
            <xf:submission serialization="none" method="get" action="{formCache}"/>
        </p:input>
        <p:input name="request" href="#instance"/>
        <p:output name="response" id="cachedForm"/>
    </p:processor>

    <!-- 2. Generate XForm from CDA using XSLT -->
    <!-- Inputs are the data dictionary that has been found in the xmlstore with the REST submissions above. -->
    <p:processor name="oxf:unsafe-xslt">
        <p:input name="config" href="../xslt/CDA2XForm.xsl"/>
        <p:input name="data" href="#cda"/>
        <p:input name="parameters" href="#instance"/>
        <p:output name="data" id="generatedContent"/>
    </p:processor>

    <!-- 3. Resolve xincludes in the template xhtml view.
            This pulls in the form content that was generated in Step 2-->
    <p:processor name="oxf:xinclude">
        <p:input name="config" href="../views/cityEHRFolder-Forms.xhtml"/>
        <p:input name="formContent" href="#generatedContent"/>
        <p:output name="data" id="form"/>
    </p:processor>

    <!-- 4. Render the XForm that was generated -->
    <p:processor name="oxf:pipeline">
        <p:input name="data" href="#form"/>
        <p:input name="instance" href="#instance"/>
        <p:input name="config" href="oxf:/config/epilogue.xpl"/>
        <p:output name="data" ref="data"/>
    </p:processor>


</p:pipeline>
