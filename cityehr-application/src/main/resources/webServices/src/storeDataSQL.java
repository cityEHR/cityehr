 /*
    cityEHR
    storeDataSQL.java
    
    Servlet to store data in mySQL database
    Called with parameters:
       ?insertInto=table name&column1=value&column2=value@...
    
    <webService>
        <parameter name="">
            <value>   </value>
            ...
        </parameter>
        ...
    </webService>    
       
    Copyright (C) 2013-2017 John Chelsom.
    
    This program is free software; you can redistribute it and/or modify it under the terms of the
    GNU Lesser General Public License as published by the Free Software Foundation; either version
    2.1 of the License, or (at your option) any later version.
    
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Lesser General Public License for more details.
    
    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html  
*/

// Loading required libraries
import java.io.*;
import java.util.*;
import javax.servlet.*;
import javax.servlet.http.*;
import java.sql.*;
 
public class storeDataSQL extends HttpServlet{

   public void doGet(HttpServletRequest request, HttpServletResponse response)
      throws ServletException, IOException {
      
      response.setContentType("text/xml");
      PrintWriter out = response.getWriter();
    
      // Output xml document header (declaration and root element)
      String docType = "<?xml version=\"1.0\" encoding=\"UTF-8\"?> ";
      out.println(docType);
      
      // Wrapper for web service return
      out.println("<webServiceReturn>");
      
    try
    {
      
      // JDBC driver name and database URL
      String JDBC_DRIVER = "com.mysql.jdbc.Driver";  
      String DB_URL="jdbc:mysql://localhost/testdb?useUnicode=true&useJDBCCompliantTimezoneShift=true&useLegacyDatetimeCode=false&serverTimezone=UTC";

      //  Database credentials
      String USER = "root";
      String PASS = "password";
      
      // Register JDBC driver
      Class.forName(JDBC_DRIVER);

      // Open a connection
      Connection conn = DriverManager.getConnection(DB_URL, USER, PASS);
      

      // the mysql insert statement
      String query = " insert into persons (PersonID, FirstName, LastName, Address, City)"
        + " values (?, ?, ?, ?, ?)";

      // create the mysql insert preparedstatement
      PreparedStatement preparedStmt = conn.prepareStatement(query);
      preparedStmt.setInt    (1, 123456);
      preparedStmt.setString (2, "Barney");
      preparedStmt.setString (3, "Rubble");
      preparedStmt.setString (4, "The Cave");
      preparedStmt.setString (5, "Bedrock");


      // execute the preparedstatement
      preparedStmt.execute();
      
      conn.close();
    }
    catch (Exception e)
    {
      out.println("Threw an exception!");
      out.println(e);
    }
    
      // End of wrapper for web service return
      out.println("</webServiceReturn>");
  }
}

   
