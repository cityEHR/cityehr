<?xml version="1.0" encoding="UTF-8"?>
<!-- ====================================================================
    generateDemographics.xsl
    This transformation is called from webService.xpl as an example web service to return patient demographics
    Input is parameters from web service call, including the patient Id
    Plus sets of family names, male/female given names
    
    Generates a CDA entry with randomly generated demographics for the CDA header.
    Note that this works with the specific information model used in the cityEHR default application.
    This is defined in the specialty model #ISO-13606:Folder:cityEHRBase
           
    Copyright (C) 2013-2021 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
    ==================================================================== -->

<xsl:stylesheet version="2.0" xmlns:xf="http://www.w3.org/2002/xforms"
    xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xxf="http://orbeon.org/oxf/xml/xforms"
    xmlns:fr="http://orbeon.org/oxf/xml/form-runner" xmlns:xi="http://www.w3.org/2001/XInclude"
    xmlns:xxi="http://orbeon.org/oxf/xml/xinclude" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:cda="urn:hl7-org:v3" xmlns:iso-13606="http://www.iso.org/iso-13606"
    xmlns:cityEHR="http://openhealthinformatics.org/ehr"
    xmlns:cityEHRFunction="http://openhealthinformatics.org/ehr/functions"
    xmlns:saxon="http://saxon.sf.net/">
    <!-- Need the indent="no" to make sure no white space is output between elements -->
    <xsl:output method="xml" indent="no" name="xml"/>

    <!-- familyNames.xml is passed on familyNames input -->
    <xsl:variable name="familyNames" select="document('input:familyNames')"/>

    <!-- maleGivenNames.xml is passed on maleGivenNames input -->
    <xsl:variable name="maleGivenNames" select="document('input:maleGivenNames')"/>

    <!-- femaleGivenNames.xml is passed on maleGivenNames input -->
    <xsl:variable name="femaleGivenNames" select="document('input:femaleGivenNames')"/>
    
    <!-- addressLines.xml is passed on addressLines input -->
    <xsl:variable name="addressLines" select="document('input:addressLines')"/>
    
    <!-- townNames.xml is passed on townNames input -->
    <xsl:variable name="townNames" select="document('input:townNames')"/>
    

    <!-- Match root to output the CDA document.
         Note that this works with the specific information model used in the cityEHR default application.
         This is defined in the specialty model #ISO-13606:Folder:cityEHRBase
         The cda:value elements just need @value, @displayName, @code, @codeSystem - these are the ones set in the directory entry lookup -->
    <xsl:template match="/">
        <!-- Generate a random number -->
        <xsl:variable name="randomNumber" select="cityEHRFunction:generateRandomNumber(100)"/>

        <!-- Set gender Male | Female - values match information model -->
        <xsl:variable name="gender"
            select="if (xs:integer($randomNumber) le 50) then 'Male' else 'Female'"/>

        <!-- Set title Mr | Ms - values match information model -->
        <xsl:variable name="title" select="if ($gender='Male') then 'Mr' else 'Ms'"/>

        <!-- Given names -->
        <xsl:variable name="givenNameSet"
            select="if ($gender='Male') then $maleGivenNames/descendant::name else $femaleGivenNames/descendant::name"/>
        <xsl:variable name="givenName" select="cityEHRFunction:getRandomSelection($givenNameSet)"/>
        
        <!-- Family name -->
        <xsl:variable name="familyName" select="cityEHRFunction:getRandomSelection($familyNames/descendant::name)"/>
        
        <!-- Date of birth.
             Year is current yer minus 18 to 88
             Month is 01 to 09 
             Day is 11 to 28 -->
        <xsl:variable name="currentYear" select="substring(xs:string(current-date()),1,4)"/>
        <xsl:variable name="dateOfBirth" select="concat(xs:string(xs:integer($currentYear) - 18 - xs:integer(cityEHRFunction:generateRandomNumber(70))),'-0',cityEHRFunction:generateRandomNumber(9),'-',10+xs:integer(cityEHRFunction:generateRandomNumber(18)))"/>

        <!-- Address -->
        <xsl:variable name="address" select="cityEHRFunction:getRandomSelection($addressLines/descendant::line)"/>
 
        <!-- Town -->
        <xsl:variable name="town" select="cityEHRFunction:getRandomSelection($townNames/descendant::name)"/>
        
        <!-- Postcode - Uppercase first two letters of town, digit 1-10, space, digit 1-10, two uppercase letters.
             A is codepoint 65, Z is codepoint 90-->
        <xsl:variable name="postcode" select="concat(upper-case(substring($town,1,2)),cityEHRFunction:generateRandomNumber(9),' ',xs:string(10 - cityEHRFunction:generateRandomNumber(9)),codepoints-to-string(64 + xs:integer(cityEHRFunction:generateRandomNumber(26))),codepoints-to-string(91 - xs:integer(cityEHRFunction:generateRandomNumber(26))))"/>
        
        
        <cda:entry>
            <cda:observation>
                <cda:typeid extension="Type:Observation" root="cityEHR"/>
                <cda:id extension="#ISO-13606:Entry:Demographics" root="cityEHR"/>
                <cda:code code="" codeSystem="cityEHR" displayName="Demographics"/>
                <!-- NHSNumber -->
                <cda:value code="" codeSystem="" displayName=""
                    cityEHR:elementType="#CityEHR:ElementProperty:simpleType"
                    extension="#ISO-13606:Element:NHSNumber" root="cityEHR" xsi:type="xs:string"
                    units="" value="{parameters/parameter[@name='patientId']/@value}"/>
                <!-- HospitalNumber -->
                <cda:value code="" codeSystem="" displayName=""
                    cityEHR:elementType="#CityEHR:ElementProperty:simpleType"
                    extension="#ISO-13606:Element:HospitalNumber" root="cityEHR"
                    xsi:type="xs:string" units="" value="{cityEHRFunction:generateRandomNumber(100000000)}"/>
                <!-- Title -->
                <cda:value root="#ISO-13606:Element:Title" extension="#ISO-13606:Element:Title"
                    xsi:type="xs:string" value="{$title}" units="" code=""
                    codeSystem="cityEHR" displayName="{$title}"/>
                <!-- Forename -->
                <cda:value root="#ISO-13606:Element:Forename"
                    extension="#ISO-13606:Element:Forename" xsi:type="xs:string"
                    value="{$givenName}" units="" code="" codeSystem="" displayName="{$givenName}"/>
                <!-- Surname -->
                <cda:value root="#ISO-13606:Element:Surname" extension="#ISO-13606:Element:Surname"
                    xsi:type="xs:string" value="{$familyName}" units="" code="" codeSystem=""
                    displayName="{$familyName}"/>
                <!-- Gender -->
                <cda:value root="#ISO-13606:Element:Sex" extension="#ISO-13606:Element:Sex"
                    xsi:type="xs:string" value="{$gender}" units=""
                    code="" codeSystem="cityEHR" displayName="{$gender}"/>
                <!-- Gender -->
                <cda:value root="#ISO-13606:Element:Gender" extension="#ISO-13606:Element:Gender"
                    xsi:type="xs:string" value="{$gender}" units=""
                    code="" codeSystem="cityEHR" displayName="{$gender}"/>
                <!-- DateOfBirth -->
                <cda:value root="#ISO-13606:Element:DateOfBirth"
                    extension="#ISO-13606:Element:DateOfBirth" xsi:type="xs:date" value="{if ($dateOfBirth castable as xs:date) then $dateOfBirth else '1962-01-30'}"
                    units="" code="" codeSystem="" displayName=""/>
                <!-- Address -->
                <!--
                <cda:value root="#ISO-13606:Element:Address" extension="#ISO-13606:Element:Address"
                    xsi:type="xs:string" value="{cityEHRFunction:generateRandomNumber(100)} {$address}" units="" code="" codeSystem=""
                    displayName="{ceiling($randomNumber div 10)} {$address}"/>
                -->
                <!-- This one for testing execution of source expressions in web service return -->
                <cda:value root="#ISO-13606:Element:StreetAddress" extension="#ISO-13606:Element:StreetAddress"
                    xsi:type="xs:string" value="{cityEHRFunction:generateRandomNumber(100)} {$address}" units="" code="" codeSystem=""
                    displayName="{ceiling($randomNumber div 10)} {$address}"/>
                
                <!-- Town -->
                <cda:value root="#ISO-13606:Element:TownCity" extension="#ISO-13606:Element:TownCity"
                    xsi:type="xs:string" value="{$town}" units="" code="" codeSystem=""
                    displayName="{$town}"/>

                <!-- Postcode -->
                <cda:value root="#ISO-13606:Element:PostCode"
                    extension="#ISO-13606:Element:PostCode" xsi:type="xs:string" value="{$postcode}"
                    units="" code="" codeSystem="" displayName="{$postcode}"/>

            </cda:observation>
        </cda:entry>
    </xsl:template>


    <!-- Function to generate a random number from the current-dateTime
         The seed is of the form 2014-06-30T19:03:28.047+01:00 
        Timezone can be Z or +/- HH:MM
        Just take the first 23 characters which will strip the timezone and leave milliseconds as the last three characters.
        Except that the milliseconds may not use all three decimal places, so the resulting string may be between 20 and 23 characters
        Then remove the characters -T:.+Z using translate to give the randomString
        
        The randomSuffix reverses the randomString and casts to xs:integer to remove any potential leading zeros 
        (which there probably can't be due to the way current-dateTime drops trailing zeros) 
        
        The randomInteger gets the last randomNumberSize characters of randomString and may include leading zeros
        The random number set for ongoing use is usually 1-999 (determined by randomNumberSize=3)             
    -->

    <xsl:function name="cityEHRFunction:generateRandomNumber">
        <xsl:param name="randomNumberCeiling"/>
        
        <xsl:variable name="randomString"
            select="xs:string(translate(substring(xs:string(current-dateTime()),1,23),'0123456789-T:.+Z','0123456789'))"/>
       
        <xsl:variable name="randomSuffix"
            select="xs:string(xs:integer(codepoints-to-string(reverse(string-to-codepoints($randomString)))))"/>
        
        <xsl:variable name="randomNumberBase" select="string-length(xs:string($randomNumberCeiling))"/>
        <xsl:variable name="maxPowerBase"
            select="'1000000000000'"/>
        <xsl:variable name="powerBase"
            select="substring($maxPowerBase, 1, $randomNumberBase + 1)"/>
     
        <xsl:variable name="randomInteger"
            select="xs:integer(substring($randomSuffix, 1, $randomNumberBase))"/>

        <xsl:variable name="randomNumber"
            select="ceiling((xs:integer($randomInteger) * xs:integer($randomNumberCeiling)) div xs:integer($powerBase))"/>
        
        <xsl:value-of select="$randomNumber"/>
        
    </xsl:function>
    
    <!--
    <xsl:function name="cityEHRFunction:generateRandomNumber">
        <xsl:param name="randomNumberBase"/>

        <xsl:variable name="randomString"
            select="xs:string(translate(substring(xs:string(current-dateTime()),1,23),'0123456789-T:.+Z','0123456789'))"/>

        <xsl:variable name="randomSuffix"
            select="xs:string(xs:integer(codepoints-to-string(reverse(string-to-codepoints($randomString)))))"/>

        <xsl:variable name="randomNumberBaseSize" select="string-length($randomNumberBase)"/>

        <xsl:variable name="randomNumberSize" select="$randomNumberBaseSize - 1"/>

        <xsl:variable name="randomInteger"
            select="xs:integer(substring($randomString, string-length($randomString) - $randomNumberBaseSize, $randomNumberSize))"/>

        <xsl:value-of select="$randomInteger"/>

    </xsl:function>
    -->

    
    <!-- Function to get a random selection from a sequence of values.
         The sequence is a set of elements
         The return is the data value (string) of the randomly selected element -->
    <xsl:function name="cityEHRFunction:getRandomSelection">
        <xsl:param name="valueSet"/>
        
        <xsl:variable name="selectionCount"
        select="count($valueSet)"/>

        <xsl:variable name="selection"
            select="cityEHRFunction:generateRandomNumber($selectionCount)"/>
        
        <xsl:value-of select="$valueSet[xs:integer($selection)]"/>

    </xsl:function>
    


</xsl:stylesheet>
