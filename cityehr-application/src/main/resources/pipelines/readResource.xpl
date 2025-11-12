<!-- 
    *********************************************************************************************************
    cityEHR
    readResource.xpl
    
    Pipleline to read a resource from the cityEHR xmlstore
    Input to pipeline is the combined parameters as returned by getPipelineParameters.xpl
    The database location of the resource is passed in xmlCacheHandle
    The resource is transformed using transformationXSL (passed without a .xsl extension) if specified
    
    The resource is returned on the serializedResource output
    
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
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


    <!-- Input to pipeline is the combined parameters as returned by getPipelineParameters.xpl -->
    <p:param name="parameters" type="input"/>
    
    
    <!-- Returns the serialized resource from the database, transformed if necessary -->
    <!-- Standard pipeline output -->
    <p:param name="serializedResource" type="output"/>



    <p:choose href="#parameters">
        <!-- Check that the xmlCacheHandle is set -->
        <p:when test="//parameters[@type='session']/xmlCacheHandle != ''">

            <!-- Get the XML document for the resource
                 Located in the database at xmlstore/users/<userId>/xmlCache
                 The full xmlCacheHandle is found in the session parameters -->
            <p:processor name="oxf:xforms-submission">
                <p:input name="submission">
                    <xf:submission serialization="none" method="get" action="{//parameters[@type='session']/xmlCacheHandle}"/>
                </p:input>
                <p:input name="request" href="#parameters"/>
                <p:output name="response" id="ehrResourceReturned"/>
            </p:processor>

            <!-- The exception catcher behaves like the identity processor if there is no exception -->
            <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#ehrResourceReturned"/>
                <p:output name="data" id="ehrResource"/>
            </p:processor>
        </p:when>

        <!-- No xmlCacheHandle supplied - output an error -->
        <p:otherwise>
            <p:processor name="oxf:identity">
                <p:input name="data">
                    <badResourceHandle/>
                </p:input>
                <p:output name="data" id="ehrResource"/>
            </p:processor>
        </p:otherwise>
    </p:choose>


    <!-- Transform the ehrResource, if required -->
    <p:choose href="#parameters">
        <!-- If transformation is required -->
        <p:when test="//parameters[@type='session']/transformationXSL != ''">
            
            <!-- Get the stylesheet to use for transformation.
         Need the axsl namespace-alias so that we can generate xslt from xslt
         For some reason the xsl:import needs to use a protocol (we are using oxf:) in the url 
         If this is entered directly (i.e. not generated using xslt) then a relative path such as ../xslt/ works OK -->
            <p:processor name="oxf:xslt">
                <p:input name="data" href="#parameters"/>
                <p:input name="config">
                    <xsl:stylesheet version="2.0" xmlns:axsl="http://www.w3.org/1999/XSL/TransformAlias">
                        <xsl:namespace-alias stylesheet-prefix="axsl" result-prefix="xsl"/>
                        <xsl:template match="/">
                            <axsl:stylesheet version="2.0">
                                <axsl:import href="{concat('oxf:/apps/ehr/xslt/',//parameters[@type='session']/transformationXSL,'.xsl')}"/>
                            </axsl:stylesheet>
                        </xsl:template>
                    </xsl:stylesheet>
                </p:input>
                <p:output name="data" id="generatedStylesheet"/>
            </p:processor>
            
            <!-- The exception catcher behaves like the identity processor if there is no exception
         However if there is an exception, it catches it, and you get a serialized form of the exception.
         An exception will be raised if the stylesheet does not exist (including when transformationXSL is blank) -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#generatedStylesheet"/>
                <p:output name="data" id="stylesheet"/>
            </p:processor>
            
            <!-- Run transformation, if one has been specified -->
            <p:processor name="oxf:unsafe-xslt">
                <p:input name="config" href="#stylesheet"/>
                <p:input name="data" href="#ehrResource"/>
                <p:input name="parameters" href="#parameters"/>
                <p:output name="data" id="transformedResource"/>
            </p:processor>
            
            <!-- The exception catcher behaves like the identity processor if there is no exception -->
            <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
            <p:processor name="oxf:exception-catcher">
                <p:input name="data" href="#transformedResource"/>
                <p:output name="data" id="checkedTransformedResource"/>
            </p:processor>
            
            <!-- Convert the transformed resource to serialized text or XML -->
            <p:choose href="#checkedTransformedResource">
                <!-- Transformed resource is XML -->
                <p:when test="exists(*)">
                    <p:processor name="oxf:xml-serializer">
                        <p:input name="config">
                            <config>
                                <encoding>utf-8</encoding>
                            </config>
                        </p:input>
                        <p:input name="data" href="#checkedTransformedResource"/>
                        <p:output name="data" ref="serializedResource"/>
                    </p:processor>
                </p:when>
                <!-- Transformed resource is text (e.g. CSV) -->
                <p:otherwise>
                    <p:processor name="oxf:text-serializer">
                        <p:input name="config">
                            <config>
                                <encoding>utf-8</encoding>
                            </config>
                        </p:input>
                        <p:input name="data" href="#checkedTransformedResource"/>
                        <p:output name="data" ref="serializedResource"/>
                    </p:processor>
                </p:otherwise>
                
            </p:choose>
        </p:when>
        
        <!-- No transformation required -->
        <p:otherwise>
            <!-- Convert the ehrResource to serialized XML -->
            <p:processor name="oxf:xml-serializer">
                <p:input name="config">
                    <config>
                        <encoding>utf-8</encoding>
                    </config>
                </p:input>
                <p:input name="data" href="#ehrResource"/>
                <p:output name="data" ref="serializedResource"/>
            </p:processor>
        </p:otherwise>
        
    </p:choose>
    
    


</p:pipeline>
