 /*
    cityEHR
    isReachable.java
    Sample servlet - returns the status (online, offline) of an ip address:
    
    <webService>
       online
    </webService>    
    
    Called as http://localhost:8080/cityEHRWebServices/isReachable?ip=127.1.1.1
       
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
import java.net.InetAddress;


public class isReachable extends HttpServlet {
  public void doGet(HttpServletRequest request, 
         HttpServletResponse response)
        throws ServletException, IOException
  {
    response.setContentType("text/xml");
    PrintWriter out = response.getWriter();
    
      // Output xml document header (declaration)
      String docType = "<?xml version=\"1.0\" encoding=\"UTF-8\"?> ";

      // May have multiple ip address arguments
      String[] ipParam =
                request.getParameterValues("ip");
      int ipAddressCount = ipParam.length;
      
      // May have timeout argument
      String[] timeoutParam = request.getParameterValues("timeout");
      int timeoutMinimum=10000;
      int timeout;
      
       try {
        timeout = Integer.parseInt(timeoutParam[0]);
       }
       catch (Exception e) {
         timeout=timeoutMinimum;
       }
        
      if (ipAddressCount == 0) 
      {
      out.println(docType +"<webService/>\n");
      }
      else {
            out.println(docType +"<webService>\n");
            
      for (int i=0; i < ipAddressCount; i++) {
	    String ipAddress = (String) ipParam[i];
      
      try {
            InetAddress address = InetAddress.getByName(ipAddress);

            // Try to reach the specified address within the timeout
            // period. If during this period the address cannot be
            // reach then the method returns false.
            boolean reachable = address.isReachable(timeout);
            String status;
           if (reachable)
             status = "online";
           else
             status = "offline";
             
            out.println("<node ipAddress=\"" + ipAddress + "\" status=\"" + status + "\"/>");
             
        } 
        catch (Exception e) {
            out.println("<node ipAddress=\"" + ipAddress + "\" status=\"offline\"/>");
        }

      } // for
      
            
      // Root element close tag
      out.println("</webService>");
      
      } // else
      
    
    out.close();
  }
}