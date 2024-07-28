 /*
    cityEHR
    getXML.java
    Sample servlet - returns the parameters that the servlet was called with, in an xml document of the form:
    
    <webService>
        <parameter name="">
            <value>   </value>
            ...
        </parameter>
        ...
    </webService>    
    
    Called as http://localhost:8080/cityEHRWebServices/getXML?p1=hello&p2=world
       
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


public class getXML extends HttpServlet {
  public void doGet(HttpServletRequest request, 
         HttpServletResponse response)
        throws ServletException, IOException
  {
    response.setContentType("text/xml");
    PrintWriter out = response.getWriter();
    
      // Output xml document header (declaration and root element)
      String docType = "<?xml version=\"1.0\" encoding=\"UTF-8\"?> ";
      out.println(docType +"<webService>\n");

      // Iterate through the parameters
      Enumeration paramNames = request.getParameterNames();
      
      while(paramNames.hasMoreElements()) {
         String paramName = (String)paramNames.nextElement();
         out.print("<parameter name=\"" + paramName + "\">");
         String[] paramValues =
                request.getParameterValues(paramName);
         // Read single valued data
         if (paramValues.length == 1) {
           String paramValue = paramValues[0];
           if (paramValue.length() == 0)
             out.println("");
           else
             out.println(paramValue);
         } else {
             // Read multiple valued data
             for(int i=0; i < paramValues.length; i++) {
			 out.println("<value>" + paramValues[i] +"</value>");
             }
         }
		         out.print("</parameter>");
      }
      
      // Root element close tag
      out.println("</webService>");

    out.close();
  }
}