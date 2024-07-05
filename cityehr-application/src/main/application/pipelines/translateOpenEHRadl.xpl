<!--
    cityEHR
    translateOpenEHRadl.xpl
    
    Pipeline calls XSLT processor to translate openEHR ADL to OWL ontology
    
    The translation is achieved in a sequence of steps:
        lexical
        syntax
        semantic
        codeGeneration
    
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

    <!-- Input to pipeline is the import-instance, containing the ADL inside a document element -->
    <p:param name="instance" type="input"/>

    <!-- Standard pipeline output -->
    <p:param name="data" type="output"/>
    

    <!-- Pass One - lexical analysis
         Run XSLT to convert ADL to top-level ADL XML structure -->
    <p:processor name="oxf:xslt">
        <p:input name="config"
            href="../xslt/adl2OWLlexical.xsl"/>
        <p:input name="data" href="#instance"/>
        <p:output name="data" id="lexicalAnalysisOutput"/>
    </p:processor>
 
    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#lexicalAnalysisOutput"/>
        <p:output name="data" id="syntaxAnalysisInput"/>
    </p:processor>
    
    <!-- Pass Two - syntax analysis
         Run XSLT to parse each ADL section, according to its specified syntax -->
    <p:processor name="oxf:xslt">
        <p:input name="config"
            href="../xslt/adl2OWLsyntax.xsl"/>
        <p:input name="data" href="#syntaxAnalysisInput"/>
        <p:output name="data" id="syntaxAnalysisOutput"/>
    </p:processor>
    
    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#syntaxAnalysisOutput"/>
        <p:output name="data" id="semanticAnalysisInput"/>
    </p:processor>
    
    <!-- Pass Three - semantic analysis
         Run XSLT to check semantic dependencies -->
    <p:processor name="oxf:xslt">
        <p:input name="config"
            href="../xslt/adl2OWLsemantic.xsl"/>
        <p:input name="data" href="#semanticAnalysisInput"/>
        <p:output name="data" id="semanticAnalysisOutput"/>
    </p:processor>
    
    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#semanticAnalysisOutput"/>
        <p:output name="data" id="codeGenerationInput"/>
    </p:processor>
    
    <!-- Pass Four - code generation
         Run XSLT to generate OWL/XML -->
    <p:processor name="oxf:xslt">
        <p:input name="config"
            href="../xslt/adl2OWLcode.xsl"/>
        <p:input name="data" href="#codeGenerationInput"/>
        <p:output name="data" id="codeGenerationOutput"/>
    </p:processor>
    
    <!-- The exception catcher behaves like the identity processor if there is no exception -->
    <!-- However if there is an exception, it catches it, and you get a serialized form of the exception -->
    <p:processor name="oxf:exception-catcher">
        <p:input name="data" href="#codeGenerationOutput"/>
        <p:output name="data" ref="data"/>
    </p:processor>
    
</p:pipeline>
