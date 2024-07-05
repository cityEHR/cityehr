<!--
    cityEHR
    copyResource.xpl
    
    Pipeline gets ontologies from database
    Then calls XSLT processor to merge the two ontolgies
    And stores the result in the first named ontology (target)
    
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

    <!-- Input to pipeline is view-parameters.xml.
         This contains the handles for source and target:
           sourceHandle
           targetHandle 
    
         Source is merged into target and the result is written back to target -->
    <p:param name="instance" type="input"/>

    <!-- Get the source from the database -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission" transform="oxf:xslt" href="#instance">
            <xf:submission xsl:version="2.0" action="{/parameters/sourceHandle}" serialization="none" method="get"/>
        </p:input>
        <p:input name="request" href="#instance"/>
        <p:output name="response" id="source"/>
    </p:processor>


    <!-- Write the source back to the target location (will overwrite anything that is already there) -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission" transform="oxf:xslt" href="#instance">
            <xf:submission xsl:version="2.0" action="{/parameters/targetHandle}" validate="false" method="put" replace="none" includenamespacesprefixes=""/>
        </p:input>
        <p:input name="request" href="#source"/>
        <p:output name="response" id="SaveResponse"/>
    </p:processor>

    <p:processor name="oxf:null-serializer">
        <p:input name="data" href="#SaveResponse"/>
    </p:processor>


</p:pipeline>
