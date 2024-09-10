<!-- 
    *********************************************************************************************************
    cityEHR
    demographicsWebService.xpl
    
    Takes patientId as URL parameter and invokes webService pipeline
    
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
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xdb="http://orbeon.org/oxf/xml/xmldb"
    xmlns:cityEHR="http://openhealthinformatics.org/ehr">

    <!-- Input to pipeline is the view-parameters with URL parameters set -->
    <p:param name="instance" type="input"/>

    <!-- Run the webService pipeline -->
    <p:processor name="oxf:pipeline">
        <p:input name="config" href="webService.xpl"/>
        <p:input name="instance" transform="oxf:xslt" href="#instance">
            <parameters xsl:version="2.0">    
                <parameter name="serviceName" value="demographics"/>
                <parameter name="patientId" value="{//parameters/patientId}"/>
            </parameters>
        </p:input>
    </p:processor>  
    

    

 </p:pipeline>
