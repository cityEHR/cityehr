 /*
    cityEHR
    getDemographics.java
    Sample servlet - returns an HL7 CDA entry with test demographics:
    
    Called as http://localhost:8080/cityEHRWebServices/getDemographics
    
    Returns xml as:
    <webServiceReturn>
        <entry cityEHR:initialValue="#CityEHR:EntryProperty:Default" cityEHR:Sequence="Unranked" cityEHR:rendition="#CityEHR:EntryProperty:Form">
            <observation>
                <typeid extension="Type:Observation" root="cityEHR"/>
                <id extension="#ISO-13606:Entry:PatientDemographics" root="cityEHR"/><code code="" codeSystem="" displayName="Patient Demographics"/>
                <value code="" codeSystem="" displayName="" cityEHR:elementType="#CityEHR:ElementProperty:simpleType" extension="#ISO-13606:Element:Surname" root="cityEHR" xsi:type="xs:string" units="" value="Abernathy" cityEHR:valueRequired="#CityEHR:ElementProperty:Optional"/>
            </observation>
        </entry>
    </webServiceReturn>
       
    Copyright (C) 2013-2017 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html  
*/

import java.io.*;
import javax.servlet.*;
import javax.servlet.http.*;
import java.util.*;


public class getDemographics extends HttpServlet {
  public void doGet(HttpServletRequest request, 
         HttpServletResponse response)
        throws ServletException, IOException
  {
    response.setContentType("text/xml");
    PrintWriter out = response.getWriter();
    
      // Output xml document header (declaration and root element)
      String docType = "<?xml version=\"1.0\" encoding=\"UTF-8\"?> ";
      out.println(docType);

      // Get demographics that were passed in the call
         
         // Wrapper for web service return
            out.println("<webServiceReturn>");
            
        // Output CDA entry element    
            out.println("<entry xmlns=\"urn:hl7-org:v3\" xmlns:cityEHR=\"http://openhealthinformatics.org/ehr\"");
            out.println("cityEHR:initialValue=\"#CityEHR:EntryProperty:Default\"");
            out.println("cityEHR:Sequence=\"Unranked\"");
            out.println("cityEHR:rendition=\"#CityEHR:EntryProperty:Form\">");
            out.println("<observation>");
            out.println("<typeId extension=\"#HL7-CDA:Observation\" root=\"cityEHR\"/>");
            out.println("<id extension=\"#ISO-13606:Entry:PatientDemographics\" root=\"cityEHR\"/>");
            out.println("<code code=\"\" codeSystem=\"\" displayName=\"Patient Demographics\"/>");
            
            //Surname value
                out.println("<value xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" code=\"\" codeSystem=\"\"");
                out.println(" displayName=\"\"");
                out.println(" cityEHR:elementType=\"#CityEHR:ElementProperty:simpleType\"");
                out.println(" extension=\"#ISO-13606:Element:Surname\"");
                out.println(" root=\"cityEHR\"");
                out.println(" xsi:type=\"xs:string\"");
                out.println(" units=\"\"");
                out.println(" value=\"Abernathy\"");
                out.println(" cityEHR:valueRequired=\"#CityEHR:ElementProperty:Optional\"/>");
         
         
            out.println("</observation>");
            out.println("</entry>");
            
            // End of wrapper for web service return
            out.println("</webServiceReturn>");
         
    out.close();
  }
}