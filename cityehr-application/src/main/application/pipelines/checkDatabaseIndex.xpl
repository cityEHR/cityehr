<!--
    cityEHR
    checkDatabaseIndex.xpl
    
    Pipeline runs xquery to check the database index
    If the index does not exist, then import the index and re-index the database
    Input parameters are the index file (instance) and the view-parameters (parameters)
    
    Returns <result> indexExists | indexCreated | storeIndexFailed | createdCollectionPathFailed </result> or <exception> element
    
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
-->
<p:pipeline xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:xdb="http://orbeon.org/oxf/xml/xmldb">

    <!-- Input to pipeline is an XML instance containing the index and a view-parameters-instance with parameters  -->
    <p:param name="instance" type="input"/>
    <p:param name="parameters" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>

    <!-- Serialize the input document with the index.
         This is then in a form that can be written to the database -->
    <p:processor name="oxf:xml-converter">
        <p:input name="config">
            <config>
                <encoding>utf-8</encoding>
            </config>
        </p:input>
        <p:input name="data" href="#instance"/>
        <p:output name="data" id="indexDocumentText"/>
    </p:processor>

    <!-- Get the system-parameters -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission">
            <xf:submission serialization="none" method="get" action="{systemResourcesURL/@localPrefix}{systemResourcesURL/@storageLocation}{systemResourcesURL/@systemParametersResource}"/>
        </p:input>
        <p:input name="request" href="#parameters"/>
        <p:output name="response" id="systemParametersReturned"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#systemParametersReturned"/>
        <p:output name="data" id="systemParameters"/>
    </p:processor>

    <!-- Configure data source for query -->
    <p:processor name="oxf:xslt">
        <p:input name="config">
            <datasource xsl:version="2.0">
                <xsl:variable name="activeXMLstore"
                    select="parameters/coreParameters/databaseConfiguration/activeDatabases/xmlstore[@system='ehr']"/>
                <xsl:variable name="xmlstore"
                    select="parameters/coreParameters/databaseConfiguration/installedDatabases/xmlstore[@value=$activeXMLstore/@value]"/>
                <driver-class-name>org.exist.xmldb.DatabaseImpl</driver-class-name>
                <uri>
                    <xsl:value-of select="$xmlstore/databaseURI"/>
                </uri>
                <username>
                    <xsl:value-of select="$xmlstore/username"/>
                </username>
                <password>
                    <xsl:value-of select="$xmlstore/password"/>
                </password>
            </datasource>
        </p:input>
        <p:input name="data" href="#systemParameters"/>
        <p:output name="data" id="datasource"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#datasource"/>
        <p:output name="data" id="datasourceChecked"/>
    </p:processor>


    <!-- Submit query to the xmlstore -->
    <p:processor name="oxf:xmldb-query">
        <p:input name="datasource" href="#datasourceChecked"/>

        <p:input name="query" transform="oxf:xslt" href="aggregate('config',#systemParameters,#indexDocumentText)">
            <xdb:query xsl:version="2.0" collection="/db" xml:space="preserve"> 
                <xsl:variable name="activeXMLstore" select="config/parameters/coreParameters/databaseConfiguration/activeDatabases/xmlstore[@system='ehr']"/>
                <xsl:variable name="xmlstore" select="config/parameters/coreParameters/databaseConfiguration/installedDatabases/xmlstore[@value=$activeXMLstore/@value]"/>
                xquery version "1.0"; 
                declare namespace xmldb="http://exist-db.org/xquery/xmldb"; 
                (:
                Function to create collections in a specified path 
                Arguments are the path to be created and the path created so far 
                Path must start with '/' 
                First call must have createdPath of '/db' 
                Then gets called recursively until all collections in the path have been created :)
                
                declare function local:createCollectionPath($path as xs:string, $createdPath as xs:string) as xs:string { 
                let $extendedPath := concat($createdPath,'/') 
                let $newPath := substring-after($path,$extendedPath) 
                let $collection := if (contains($newPath,'/')) then substring-before($newPath,'/') else $newPath let $collectionPath := concat($extendedPath,$collection) 
                let $newCreatedPath := if ($collection and xmldb:collection-available($collectionPath)) then $collectionPath 
                                       else if ($collection and xmldb:create-collection($createdPath, $collection)) then $collectionPath 
                                       else '' 
                let $recursiveCall := if ($newCreatedPath='') then $createdPath else local:createCollectionPath($path,$newCreatedPath) return $recursiveCall }; 
                let $indexLocation := '<xsl:value-of select="$xmlstore/indexLocation/@prefix"/><xsl:value-of select="$activeXMLstore/@storageLocation"/>' 
                let $indexPath := '<xsl:value-of select="$xmlstore/indexLocation/@prefix"/><xsl:value-of select="$activeXMLstore/@storageLocation"/>/collection.xconf' 
                let $indexDocumentText := '<xsl:value-of select="config/*[2]"/>' 
                let $indexExists := doc-available($indexPath) 
                let $createCollectionPath := if (not($indexExists)) then local:createCollectionPath($indexLocation,'/db') else '' 
                let $importIndex := if ($createCollectionPath) then xmldb:store($indexLocation,'collection.xconf',xs:string($indexDocumentText)) else '' 
                (: Don't need to re-index, since the xmlstore collection doesn't exist yet :) 
                (: let $reindex := if ($importIndex) then xmldb:reindex('<xsl:value-of select="$xmlstore/databaseURI"/>') else '' :) 
                let $reindex := '' 
                return
                &lt;result> {if ($reindex) then 'indexCreated' 
                             else if ($importIndex) then 'indexCreated' 
                             else if ($createCollectionPath) then 'storeIndexFailed' 
                             else if (not($indexExists)) then 'createdCollectionPathFailed' 
                             else 'indexExists'
                             }
                &lt;/result> 
            </xdb:query>
        </p:input>
        <p:output name="data" id="xqueryResult"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#xqueryResult"/>
        <p:output name="data" id="xqueryResultChecked"/>
    </p:processor>

    <!-- Although this is a choice, both branches return the same thing (#xqueryResultChecked) -->
    <p:choose href="#xqueryResultChecked">
        <!-- Exception thrown xquery -->
        <p:when test="//exceptions">
            <p:processor name="oxf:identity">
                <p:input name="data" href="#xqueryResultChecked"/>
                <p:output name="data" ref="data"/>
            </p:processor>
        </p:when>

        <!-- xQuery OK - just return the result -->
        <p:otherwise>
            <p:processor name="oxf:identity">
                <p:input name="data" href="#xqueryResultChecked"/>
                <p:output name="data" ref="data"/>
            </p:processor>
        </p:otherwise>
    </p:choose>

</p:pipeline>
