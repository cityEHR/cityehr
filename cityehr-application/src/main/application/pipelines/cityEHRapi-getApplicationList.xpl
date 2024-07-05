<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRapi-getApplicationList.xpl
    
    cityEHR API Command Handler: getApplicationList
    Note that the pipeline document element must have an attribute cityEHR:type="cityEHRapi" in order for the pipeline to be invoked
    Invocataion is from cityEHRapi.xpl
    
    Pipleline to return the set of applications installed for the cityEHR system.
    
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
<p:pipeline cityEHR:type="cityEHRapi" xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors"
    xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xdb="http://orbeon.org/oxf/xml/xmldb" xmlns:cityEHR="http://openhealthinformatics.org/ehr">

    <!-- Input to pipeline is the combined parameters -->
    <p:param name="parameters" type="input"/>


    <!-- Check the session -->
    
    
    
    <!-- Get the list of applications -->
    <p:processor name="oxf:identity">
        <p:input name="data">
            <getApplicationList/>
        </p:input>
        <p:output name="data" id="return"/>
    </p:processor>
    

    <!-- Serialize the response to the API call -->
    <p:processor name="oxf:xml-serializer">
        <p:input name="config">
            <config>
                <encoding>utf-8</encoding>
            </config>
        </p:input>
        <p:input name="data" transform="oxf:xslt" href="#return">
            <cityEHRapiResponse xsl:version="2.0">
                <xsl:copy-of select="*"/>
            </cityEHRapiResponse>
        </p:input>
    </p:processor>

</p:pipeline>
