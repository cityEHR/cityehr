<!--
    cityEHR
    mergeOntologies.xpl
    
    Pipeline calls XSLT processor to merge two ontolgies
    Ontologies are passed in as master and merge inputs
    Master is copied through to output, assertions from merge are added if not present in master
    Merged ontology is passed out on standard data output
    
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
    xmlns:oxf="http://www.orbeon.com/oxf/processors" xmlns:xf="http://www.w3.org/2002/xforms">

    <!-- Input to pipeline is master OWL/XML instance and a merge OWL/XML instance  -->
    <p:param name="master" type="input"/>
    <p:param name="merge" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>

    <!-- Run XSLT to merge the ontologies -->
    <p:processor name="oxf:xslt">
        <p:input name="config"
        href="../xslt/MergeOWL.xsl"/>
        <p:input name="data" href="#master"/>
        <p:input name="merge" href="#merge"/>
        <p:output name="data" ref="data"/>
    </p:processor>
    
</p:pipeline>
