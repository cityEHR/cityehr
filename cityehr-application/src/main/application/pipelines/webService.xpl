<!--
    cityEHR
    webService.xpl
    
    Pipeline can be called as a web service.
    Used for testing web services in cityEHRAdmin and in the default cityEHR application.
    
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
    xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:cda="urn:hl7-org:v3">

    <!-- Input to pipeline is the web service parameters -->
    <p:param name="instance" type="input"/>

    <!-- Return from web service depends on the parameters passed.
         Test is on value of parameter 'serviceName' -->
    <p:choose href="#instance">
        <!-- Return a random set of demographics (this is just for testing)  -->
        <p:when test="exists(//parameter[@name='serviceName'][@value='demographics'])">
            <p:processor name="oxf:xslt">
                <p:input name="config" href="../xslt/generateDemographics.xsl"/>
                <p:input name="data" href="#instance"/>
                <p:input name="familyNames" href="../resources/testData/familyNames.xml"/>
                <p:input name="maleGivenNames" href="../resources/testData/maleGivenNames.xml"/>
                <p:input name="femaleGivenNames" href="../resources/testData/femaleGivenNames.xml"/>
                <p:input name="addressLines" href="../resources/testData/addressLines.xml"/>
                <p:input name="townNames" href="../resources/testData/townNames.xml"/>
                <p:output name="data" id="demographics"/>
            </p:processor>
            
            <!-- The exception catcher behaves like the identity processor if there is no exception -->
            <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#demographics"/>
                <p:output name="data" id="return"/>
            </p:processor>
        </p:when>
        
        <!-- Add other when clauses here for other web services -->

        <!-- Otherwise, no specific web service call was found -->
        <p:otherwise>
            <!-- Return the input parameters -->
            <p:processor name="oxf:identity">
                <p:input name="data" href="#instance"/>
                <p:output name="data" id="return"/>
            </p:processor>
        </p:otherwise>
    </p:choose>

    <!-- Return XML -->
    <p:processor name="oxf:xml-serializer">
        <p:input name="config">
            <config>
                <encoding>utf-8</encoding>
            </config>
        </p:input>
        <p:input name="data" href="#return"/>
    </p:processor>


</p:pipeline>
