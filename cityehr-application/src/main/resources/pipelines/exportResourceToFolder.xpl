<!-- 
    *********************************************************************************************************
    cityEHR
    exportResourceToFolder.xpl
    
    Pipleline to export a resource from the cityEHR xmlstore and write to the configured export folder
    The database location of the resource is passed in xmlCacheHandle and the transformation in transformationXSL
    The export folder is specified in the application-paraemters as exportDirectory
    
    Invokes the readResource.xpl pipeline to
        Read the resource from the specified xmlCacheHandle
        The resource is transformed using transformationXSL (passed without a .xsl extension) if specified
        
    The externalId and resourceFileExtension are used to create the file name exported
    
    The file is then written to the folder on the file system as specified in exportDirectory.
    
    The resource is also returned on the data output
    
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
    xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


    <!-- Input to pipeline is view-parameters.xml as set in the page-flow.xml file 
         with parameters set in the page element -->
    <p:param name="instance" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>

    <!-- Run the getPipelineParameters pipeline.
         Returns the combined application-parameters, session-parameters, system-parameters, database-parameters,  view-parameters -->
    <p:processor name="oxf:pipeline">
        <p:input name="config" href="getPipelineParameters.xpl"/>
        <p:input name="instance" href="#instance"/>
        <p:output name="parameters" id="parameters"/>
    </p:processor>

    <!-- Run the readResource pipeline.
         Returns the resource from the database, transformed if necessary
         Input to pipeline is the combined parameters as returned by getPipelineParameters.xpl
         The database location of the resource is passed in xmlCacheHandle
         The resource is transformed using transformationXSL (passed without a .xsl extension) if specified-->
    <p:processor name="oxf:pipeline">
        <p:input name="config" href="readResource.xpl"/>
        <p:input name="parameters" href="#parameters"/>
        <p:output name="serializedResource" id="serializedResourceReturned"/>
    </p:processor>

    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#serializedResourceReturned"/>
        <p:output name="data" id="serializedResource"/>
    </p:processor>


    <!-- Write the document to the exportDirectory. 
         <make-directories>false</make-directories> is required to prevent a crash
         If the directory does not exist then the processor will fail silently 
         Without <make-directories>false</make-directories> there is a crash that does not get caught by the exception handler-->

    <p:processor name="oxf:file-serializer">
        <p:input name="config" transform="oxf:xslt" href="#parameters">
            <config xsl:version="2.0">
                <directory>
                    <xsl:value-of
                        select="//parameters[@type='application']/importExport/exportPipeline/exportDirectory"
                    />
                </directory>
                <file>
                    <xsl:value-of
                        select="if (//parameters[@type='session']/externalId!='') then //parameters[@type='session']/externalId else concat(replace(replace(string(current-dateTime()),':','-'),'\+','*'),'-cityEHR-export.xml')"
                    />
                </file>
                <make-directories>false</make-directories>
                <append>false</append>
            </config>
        </p:input>
        <p:input name="data" href="#serializedResource"/>
    </p:processor>


    <!-- Return the resource that was exported or the exception if writing failed -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#serializedResource"/>
        <p:output name="data" ref="data"/>
    </p:processor>


</p:pipeline>
