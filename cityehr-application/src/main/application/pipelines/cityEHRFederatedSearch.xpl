<?xml version="1.0" encoding="UTF-8"?>
<!-- 
    *********************************************************************************************************
    cityEHR
    cityEHRFederatedSearch.xpl
    
    Pipeline to run an xquery across a set of database instances
    Returns the aggregated results set
        
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
    xmlns:exist="http://exist.sourceforge.net/NS/exist" xmlns:xdb="http://orbeon.org/oxf/xml/xmldb">

    <!-- Input to pipeline is view-parameters.xml -->
    <p:param name="instance" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="result" type="output"/>

    <!-- Generate query text -->
    <!-- Input is the view-parameters. -->
    <p:processor name="oxf:xslt">
        <p:input name="config">
            <xdb:query xsl:version="2.0" collection="{parameters/runXqueryContext}">
                <xsl:value-of select="parameters/runXqueryQueryText"/>
            </xdb:query>
        </p:input>
        <p:input name="data" href="#instance"/>
        <p:output name="data" id="query"/>
    </p:processor>

    <!-- Aggregate results from federated queries -->
    <p:for-each href="#instance" select="parameters/federatedDatabaseInstances/xmlstore"
        root="aggregatedResults" id="aggregatedResult">

        <!-- Configure data source for query -->
        <p:processor name="oxf:xslt">
            <p:input name="config">
                <datasource xsl:version="2.0">
                    <driver-class-name>org.exist.xmldb.DatabaseImpl</driver-class-name>
                    <uri>
                        <xsl:value-of select="xmlstore/databaseURI/@prefix"/>
                        <xsl:value-of select="xmlstore/server"/>
                        <xsl:value-of select="xmlstore/port"/>
                        <xsl:value-of select="xmlstore/databaseURI/@suffix"/>
                    </uri>
                    <username>
                        <xsl:value-of select="xmlstore/username"/>
                    </username>
                    <password>
                        <xsl:value-of select="xmlstore/password"/>
                    </password>
                </datasource>
            </p:input>
            <p:input name="data" href="current()"/>
            <p:output name="data" id="datasource"/>
        </p:processor>

        <!-- Submit query to the xmlstore -->
        <p:processor name="oxf:xmldb-query">
            <p:input name="datasource" href="#datasource"/>
            <p:input name="query" href="#query"/>
            <p:output name="data" id="queryResponse"/>
        </p:processor>

        <!-- The exception catcher behaves like the identity processor if there is no exception -->
        <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
        <p:processor name="oxf:exception-catcher">
            <p:input name="data" href="#queryResponse"/>
            <p:output name="data" ref="aggregatedResult"/>
        </p:processor>
    </p:for-each>

    <!-- Return aggregated results -->
    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#aggregatedResult"/>
        <p:output name="data" ref="result"/>
    </p:processor>

</p:pipeline>
