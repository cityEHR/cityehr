<!-- 
    *********************************************************************************************************
    cityEHR
    createDatabaseFolder.xpl

    Pipleline to export a resource from the cityEHR xmlstore and write to the configured export folder
    The database location of the resource is passed in resourceHandle and the transformation in transformationXSL
    The export folder is specified in the application-paraemters as exportDirectory
    
    Invokes the readResource.xpl pipeline to
        Read the resource from the specified resourceHandle
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
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema">


    <!-- Input to pipeline is view-parameters.xml as set in the page-flow.xml file 
         with parameters set in the page element -->
    <p:param name="instance" type="input"/>


    <!-- Write the document to the exportDirectory. 
         <make-directories>false</make-directories> is required to prevent a crash
         If the directory does not exist then the processor will fail silently 
         Without <make-directories>false</make-directories> there is a crash that does not get caught by the exception handler-->

    <p:processor name="oxf:file-serializer">
        <p:input name="config" transform="oxf:xslt" href="#instance">
            <config xsl:version="2.0">
                <directory>
                    <xsl:value-of select="//parameters/filePath"/>
                </directory>
                <file> cityEHR-version.txt </file>
                <make-directories>true</make-directories>
                <append>false</append>
            </config>
        </p:input>
        <p:input name="data" transform="oxf:xslt" href="#instance">
            <versionNumber xsl:version="2.0" xsi:type="xs:string">
                <xsl:value-of select="//parameters/versionNumber/@version"/>
            </versionNumber>
        </p:input>
    </p:processor>

</p:pipeline>
