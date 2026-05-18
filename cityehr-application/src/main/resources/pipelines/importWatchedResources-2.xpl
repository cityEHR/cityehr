<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    importWatchedResources.xpl
    
    Pipeline to import patient records from the server directory specified in parameters/watchedDirectory
    
    Since this pipeline is run by the scheduler it can't take a normal input (e.g. view-parameters)
    Instead the parameters are stored at a fixed location in the built-in database
    These parameters contain
        watchedDirectory, processedDirectory and errorDirectory
    
    Get the list of files in the directory
    Iterate through the files
    Iterate through records in the file
    Import each record if patientId is specified
    Write the file to the processedDirectory or errorDirectory
    Delete the file
    
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
    xmlns:saxon="http://saxon.sf.net/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:f="http://orbeon.org/oxf/xml/formatting" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:cda="urn:hl7-org:v3" xmlns:exist="http://exist.sourceforge.net/NS/exist"
    xmlns:xdb="http://orbeon.org/oxf/xml/xmldb">

    <!-- Standard pipeline output -->
    <!--
    <p:param name="data" type="output"/>
    -->

    <!-- There is no input or output for this pipeline.
         But create a parameters instance for the oxf:xforms-submissions -->
    <p:processor name="oxf:identity">
        <p:input name="data">
            <parameters>
                <schedulerParametersURL
                    databaseLocation="/exist/rest/db/cityEHR/configuration/scheduler-parameters"/>
                <schedulerLogURL
                    databaseLocation="/exist/rest/db/cityEHR/configuration/schedulerLog"/>
            </parameters>
        </p:input>
        <p:output name="data" id="parameters"/>
    </p:processor>

    <!-- Get the scheduler-parameters.
         These are located in the built-in database at the location specified in the view-parameters -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission">
            <xf:submission serialization="none" method="get"
                action="{schedulerParametersURL/@databaseLocation}"/>
        </p:input>
        <p:input name="request" href="#parameters"/>
        <p:output name="response" id="schedulerParametersReturned"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#schedulerParametersReturned"/>
        <p:output name="data" id="schedulerParameters"/>
    </p:processor>



    <!-- Get list of files/folders in watchedDirectory folder.
       <directory name="address-book" path="c:\Documents and Settings\John Doe\OPS\src\examples\web\examples\address-book">
            <file last-modified-ms="1120343217984" last-modified-date="2005-07-03T00:26:57.984" size="961130" path="image0001.jpg" name="image0001.jpg"/>
        </directory>    
         -->
    <p:processor name="oxf:directory-scanner">
        <p:input name="config" transform="oxf:xslt" href="#schedulerParameters">
            <config xsl:version="2.0">
                <base-directory>
                    <xsl:value-of select="concat('file://',//watchedDirectory)"/>
                </base-directory>
                <include> *.* </include>
                <include> */*.* </include>
                <case-sensitive>false</case-sensitive>
            </config>
        </p:input>
        <p:output name="data" id="directoryListing"/>
    </p:processor>

    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#directoryListing"/>
        <p:output name="data" id="directoryListingChecked"/>
    </p:processor>

    <!-- Iterate through the directoryListing
         Read each file which is defined bt
         
            <file last-modified-ms="1719915616000" last-modified-date="2024-07-02T11:20:16.000" size="23" path="test.xml" name="test.xml"/>      
         -->
    <p:for-each href="#directoryListingChecked" select="//file" root="filesProcessed"
        id="filesProcessed">

        <!-- Set up file for processing -->
        <p:processor name="oxf:identity">
            <p:input name="data" href="current()"/>
            <p:output name="data" id="file"/>
        </p:processor>

        <!-- Read file -->
        <p:processor name="oxf:url-generator">
            <p:input name="config" transform="oxf:xslt"
                href="aggregate('configuration',#file,#schedulerParameters)">
                <config xsl:version="2.0">
                    <url>
                        <xsl:value-of
                            select="concat('file://',//watchedDirectory,'/',//file/@name)"
                        />
                    </url>
                    <content-type>application/xml</content-type>
                </config>
            </p:input>
            <p:output name="data" id="fileContent"/>
        </p:processor>

        <!-- Exception catcher - reading file content.
             Set up with count of each cda:ClinicalDocument -->
        <p:processor name="oxf:exception-catcher">
            <p:input name="data" transform="oxf:xslt" href="#fileContent">
                <documentCollection xsl:version="2.0">
                    <xsl:for-each select="//cda:ClinicalDocument">
                        <xsl:variable name="ClinicalDocument" select="."/>
                        <document>
                            <count>
                                <xsl:value-of
                                    select="count($ClinicalDocument/preceding-sibling::*) +1"/>
                            </count>
                            <xsl:copy-of select="$ClinicalDocument"/>
                        </document>
                    </xsl:for-each>
                </documentCollection>
            </p:input>
            <p:output name="data" id="fileContentChecked"/>
        </p:processor>


        <!-- Iterate through the cda:ClinicalDocument elements found in each file -->
        <p:for-each href="#fileContentChecked" select="//document" root="documentsProcessed"
            id="documentsProcessed">

            <!-- Current document for processing -->
            <p:processor name="oxf:identity">
                <p:input name="data" href="current()"/>
                <p:output name="data" id="document"/>
            </p:processor>

            <!-- Get patientId - only works for valid CDA -->
            <p:processor name="oxf:identity">
                <p:input name="data" transform="oxf:xslt" href="#document">
                    <patientId xsl:version="2.0">
                        <xsl:value-of
                            select="//cda:ClinicalDocument/cda:recordTarget/cda:patientRole/cda:id/@extension"
                        />
                    </patientId>
                </p:input>
                <p:output name="data" id="patientId"/>
            </p:processor>


            <!-- Check that the patient id is not blank-->
            <p:choose href="#patientId">
                <!-- There's a patientId so process the document -->
                <p:when test="patientId != ''">

                    <!-- Create query to check that this patient exists in the cityEHR record store -->
                    <p:processor name="oxf:identity">
                        <p:input name="data" transform="oxf:xslt"
                            href="aggregate('configuration',#patientId,#schedulerParameters)">
                            <exist:query xsl:version="2.0" start="1" max="1"
                                queryLocation="{//patientRecordsDatabaseURL}{//patientId}">
                                <exist:text xml:space="preserve">
                                    xquery version "1.0"; 
                                    declare namespace
                                    xmldb="http://exist-db.org/xquery/xmldb"; 
                                    let $result := xmldb:collection-available(request:get-path-info()) 
                                    return
                                    &lt;result>{$result}&lt;/result> 
                                </exist:text>
                            </exist:query>
                        </p:input>
                        <p:output name="data" id="query"/>
                    </p:processor>

                    <!-- Submit query to the xmlstore.
                     The AVT is relative to the request -->
                    <p:processor name="oxf:xforms-submission">
                        <p:input name="submission">
                            <xf:submission action="{@queryLocation}" method="post"/>
                        </p:input>
                        <p:input name="request" href="#query"/>
                        <p:output name="response" id="queryResults"/>
                    </p:processor>

                    <!-- Catch exception if query crashes out, otherwise acts like identity processor -->
                    <p:processor name="oxf:exception-catcher">
                        <p:input name="data" href="#queryResults"/>
                        <p:output name="data" id="checkedQueryResults"/>
                    </p:processor>


                    <!-- Next step depends on whether the patient exists in the database or not.
                         If the patientId record exists in the database then the event can be imprted.
                         If not then just report that patientIdNotRegistered -->

                    <p:choose href="#checkedQueryResults">
                        <!-- There's a patientId so process the document -->
                        <p:when test="//result = 'true'">

                            <!-- Set the typeId, id and effectiveTime for the CDA Header
                                
                                 Must sanitize the file name using translate() in case it contains characters that can't be used as resource names 
                                 CityEHR-Message-ImportWatchedResources-sanitizedFilename-$documentNumber-checkSum
                                 
                                 Also set the databaseHandle used for import
                                 -->
                            <p:processor name="oxf:identity">
                                <p:input name="data" transform="oxf:xslt"
                                    href="aggregate('document',#schedulerParameters,#file,#patientId,#document)">

                                    <cda-parameters xsl:version="2.0">
                                        <xsl:variable name="documentNumber" select="//count"/>
                                        <xsl:variable name="checkSum"
                                            select="string-length(//cda:ClinicalDocument)"/>
                                        <xsl:variable name="sanitizedFilename"
                                            select="translate(normalize-space(//file/@name),'# &#46;&#09;&#10;','')"/>
                                        <xsl:variable name="documentId"
                                            select="concat('CityEHR-Message-ImportWatchedResources-',$sanitizedFilename,'-',$documentNumber,'-',$checkSum)"/>
                                        <typeId xmlns="urn:hl7-org:v3" root="#CityEHR:Message"
                                            extension="#CityEHR:Message:ImportWatchedResources"/>
                                        <id xmlns="urn:hl7-org:v3" root="cityEHR"
                                            extension="{$documentId}"/>
                                        <effectiveTime xmlns="urn:hl7-org:v3"
                                            value="{current-dateTime()}"/>
                                        <databaseHandle>
                                            <xsl:value-of
                                                select="concat(//patientRecordsDatabaseURL,'/',//patientId,'/',$id)"
                                            />
                                        </databaseHandle>
                                    </cda-parameters>
                                </p:input>
                                <p:output name="data" id="cda-parameters"/>
                            </p:processor>


                            <!-- Replace the typeId, id and effectiveTime in the ClinicalDocument.
                                 Uses the XSLT procesor and identity transform.
                                 The aggregated input is:
                                    <document>
                                       <document>
                                          <count>
                                          <cda:ClinicalDocument>
                                       </document>
                                       <cda-parameters>
                                    </document>    
                            -->
                            <p:processor name="oxf:xslt">
                                <p:input name="config">
                                    <xsl:stylesheet version="2.0">
                                        <!-- Get CDA Header elements for replacement -->
                                        <xsl:variable name="typeId" select="//cda-parameters/cda:typeId"/>
                                        <xsl:variable name="id" select="//cda-parameters/cda:id"/>
                                        <xsl:variable name="effectiveTime"
                                            select="//cda-parameters/cda:effectiveTime"/>

                                        <!-- Start with document children -->
                                        <xsl:template match="document">
                                            <xsl:apply-templates/>
                                        </xsl:template>

                                        <!-- Don't output the count -->
                                        <xsl:template match="count"/>

                                        <!-- Don't output the cda-parameters -->
                                        <xsl:template match="cda-parameters"/>

                                        <!-- Replace typeId -->
                                        <xsl:template match="cda:ClinicalDocument/cda:typeId">
                                            <xsl:copy-of select="$typeId" copy-namespaces="no"/>
                                        </xsl:template>

                                        <!-- Replace id -->
                                        <xsl:template match="cda:ClinicalDocument/cda:id">
                                            <xsl:copy-of select="$id" copy-namespaces="no"/>
                                        </xsl:template>

                                        <!-- Replace effectiveTime -->
                                        <xsl:template match="cda:ClinicalDocument/cda:effectiveTime">
                                            <xsl:copy-of select="$effectiveTime"
                                                copy-namespaces="no"/>
                                        </xsl:template>


                                        <!-- Identity Transform - copy everything else to the output -->
                                        <xsl:template match="node() | @*">
                                            <xsl:copy>
                                                <xsl:apply-templates select="node() | @*"/>
                                            </xsl:copy>
                                        </xsl:template>

                                    </xsl:stylesheet>

                                </p:input>
                                <p:input name="data"
                                    href="aggregate('document',#document,#cda-parameters)"/>
                                <p:output name="data" id="ClinicalDocumentForImport"/>
                            </p:processor>

                            <!-- Write ClinicalDocument to the cityEHR record store -->
                            <p:processor name="oxf:xforms-submission">
                                <p:input name="submission" transform="oxf:xslt"
                                    href="#cda-parameters">
                                    <xf:submission xsl:version="2.0"
                                        action="{//databaseHandle}"
                                        validate="false" method="put" replace="none"
                                        includenamespacesprefixes=""/>
                                </p:input>
                                <p:input name="request" href="#ClinicalDocumentForImport"/>
                                <p:output name="response" id="importResponse"/>
                            </p:processor>

                            <!-- Exception catcher - importing ClinicalDocument -->
                            <p:processor name="oxf:exception-catcher">
                                <!--
                                <p:input name="data" href="#importResponse"/>
-->
                                <p:input name="data" transform="oxf:xslt" href="#importResponse">
                                    <cdaImport xsl:version="2.0">
                                        <xsl:value-of select="//cda:ClinicalDocument/name()"/>
                                    </cdaImport>
                                </p:input>
                                <p:output name="data" id="importResponseChecked"/>
                            </p:processor>

                            <!-- Report the ClinicalDocument was processed -->
                            <p:processor name="oxf:identity">
                                <p:input name="data" transform="oxf:xslt"
                                    href="aggregate('configuration',#patientId,#cda-parameters,#importResponseChecked)">
                                    <processed xsl:version="2.0" patientId="{//patientId}"
                                        result="patientIdRegistered">
                                        <xsl:copy-of select="//cda-parameters"/>
                                        <xsl:copy-of select="//cdaImport"/>
                                    </processed>
                                </p:input>
                                <p:output name="data" ref="documentsProcessed"/>
                            </p:processor>
                        </p:when>


                        <!-- Otherwise report that the patient record does not exist in database -->
                        <p:otherwise>
                            <p:processor name="oxf:identity">
                                <p:input name="data" transform="oxf:xslt" href="#patientId">
                                    <processed xsl:version="2.0" patientId="{patientId}"
                                        result="patientIdNotRegistered"/>
                                </p:input>
                                <p:output name="data" ref="documentsProcessed"/>
                            </p:processor>
                        </p:otherwise>

                    </p:choose>
                    <!-- End of check whether patientId has record in the database -->

                </p:when>
                <!-- End of processing when patientId is not blank -->

                <!-- When patientId is blank -->
                <p:otherwise>
                    <!-- Report that the ClinicalDocument was processed -->
                    <p:processor name="oxf:identity">
                        <p:input name="data">
                            <processed patientId="" result="patientIdBlank"/>
                        </p:input>
                        <p:output name="data" ref="documentsProcessed"/>
                    </p:processor>
                </p:otherwise>

            </p:choose>
            <!-- End of check whether patientId is blank -->

        </p:for-each>
        <!-- End or iteration through cda:ClinicalDocument elements in the file -->


        <!-- Convert the XML instance to serialized XML -->
        <p:processor name="oxf:text-serializer">
            <p:input name="config">
                <config>
                    <encoding>utf-8</encoding>
                </config>
            </p:input>
            <p:input name="data" href="#fileContentChecked"/>
            <p:output name="data" id="serializedFile"/>
        </p:processor>

        <p:processor name="oxf:exception-catcher">
            <p:input name="data" href="#serializedFile"/>
            <p:output name="data" id="serializedFileChecked"/>
        </p:processor>

        <!-- Write file -->
        <p:processor name="oxf:file-serializer">
            <p:input name="config" transform="oxf:xslt"
                href="aggregate('configuration',#file,#schedulerParameters)">
                <config xsl:version="2.0">
                    <directory>
                        <xsl:value-of select="//processedDirectory"/>
                    </directory>
                    <file>
                        <xsl:value-of select="//file/@name"/>
                    </file>
                    <make-directories>true</make-directories>
                    <append>false</append>
                </config>
            </p:input>
            
            <p:input name="data" href="#serializedFileChecked"/>
        </p:processor>


        <!-- Exception catcher - writing file -->
        <p:processor name="oxf:exception-catcher">
            <p:input name="data" transform="oxf:xslt"
                href="aggregate('configuration',#file,#schedulerParameters)">
                <fileWrite xsl:version="2.0">
                    <xsl:value-of select="//file/@name"/>
                </fileWrite>
            </p:input>
            <p:output name="data" id="fileWritehecked"/>
        </p:processor>


        <!-- Delete the file from the watchedDirectory -->
        <p:processor name="oxf:file">
            <p:input name="config" transform="oxf:xslt"
                href="aggregate('configuration',#file,#schedulerParameters)">
                <config xsl:version="2.0">
                    <delete>
                        <directory>
                            <xsl:value-of select="//watchedDirectory"/>
                        </directory>
                        <file>
                            <xsl:value-of select="//configuration/file/@name"/>
                        </file>
                    </delete>
                </config>
            </p:input>
        </p:processor>

        <!-- Exception catcher - deleting file -->
        <p:processor name="oxf:exception-catcher">
            <p:input name="data" transform="oxf:xslt"
                href="aggregate('configuration',#file,#schedulerParameters)">
                <fileDelete xsl:version="2.0">
                    <xsl:value-of select="//file/@name"/>
                </fileDelete>
            </p:input>
            <p:output name="data" id="fileDeleteChecked"/>
        </p:processor>

        <!-- Report filesProcessed -->
        <p:processor name="oxf:identity">
            <p:input name="data"
                href="aggregate('processedFile',#fileWritehecked,#fileDeleteChecked,#documentsProcessed)"/>
            <p:output name="data" ref="filesProcessed"/>
        </p:processor>

    </p:for-each>
    <!-- End or iteration through the files -->

    <!-- Write the schedulerLog -->
    <p:processor name="oxf:xforms-submission">
        <p:input name="submission" transform="oxf:xslt" href="#parameters">
            <xf:submission xsl:version="2.0" action="{//schedulerLogURL/@databaseLocation}"
                validate="false" method="put" replace="none" includenamespacesprefixes=""/>
        </p:input>
        <p:input name="request" transform="oxf:xslt" href="#filesProcessed">
            <schedulerLog xsl:version="2.0">
                <process>importWatchedResources</process>
                <timeStamp>
                    <xsl:value-of select="current-dateTime()"/>
                </timeStamp>
                <xsl:copy-of select="filesProcessed"/>
            </schedulerLog>
        </p:input>
        <p:output name="response" id="saveResponse"/>
    </p:processor>

    <!-- Exception catcher - audit information -->
    <!--
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#saveResponse"/>
        <p:output name="data" ref="data"/>
    </p:processor>
    -->

    <!-- Just consume the saveResponseChecked -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#saveResponse"/>
        <p:output name="data" id="saveResponseChecked"/>
    </p:processor>

    <p:processor name="oxf:null-serializer">
        <p:input name="data" href="#saveResponseChecked"/>
    </p:processor>

</p:pipeline>
