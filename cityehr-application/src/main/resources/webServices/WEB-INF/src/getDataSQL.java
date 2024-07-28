 /*
    cityEHR
    getDataSQL.java
    
    Based on sample code at: https://www.tutorialspoint.com/servlets/servlets-database-access.htm
    
    Sample servlet - returns the parameters that the servlet was called with, in an xml document of the form:
    
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
 
public class getDataSQL extends HttpServlet{

   public void doGet(HttpServletRequest request, HttpServletResponse response)
      throws ServletException, IOException {
   
      // JDBC driver name and database URL
      String JDBC_DRIVER = "com.mysql.jdbc.Driver";  
      String DB_URL="jdbc:mysql://localhost/testdb";

      //  Database credentials
      String USER = "root";
      String PASS = "password";

      // Set response content type
      response.setContentType("text/html");
      PrintWriter out = response.getWriter();
      String title = "Database Result";
      
      String docType =
         "<!doctype html public \"-//w3c//dtd html 4.0 " + "transitional//en\">\n";
      
      out.println(docType +
         "<html>\n" +
         "<head><title>" + title + "</title></head>\n" +
         "<body bgcolor = \"#f0f0f0\">\n" +
         "<h1 align = \"center\">" + title + "</h1>\n");
      try {
         // Register JDBC driver
         Class.forName("com.mysql.jdbc.Driver");

         // Open a connection
         Connection conn = DriverManager.getConnection(DB_URL, USER, PASS);

         // Execute SQL query
         Statement stmt = conn.createStatement();
         String sql;
         sql = "SELECT PersonID, FirstName, LastName, Address, City FROM persons";
         ResultSet rs = stmt.executeQuery(sql);

         // Extract data from result set
         while(rs.next()){
            //Retrieve by column name
            int PersonID  = rs.getInt("PersonID");
            String FirstName = rs.getString("FirstName");
            String LastName = rs.getString("LastName");

            //Display values
            out.println("PersonID: " + PersonID + "<br>");
            out.println(", FirstName: " + FirstName + "<br>");
            out.println(", LastName: " + LastName + "<br>");
         }
         out.println("</body></html>");

         // Clean-up environment
         rs.close();
         stmt.close();
         conn.close();
      } 
      catch(SQLException se) {
         //Handle errors for JDBC
         se.printStackTrace();
      } 
      catch(Exception e) {
         //Handle errors for Class.forName
         e.printStackTrace();
      } 
   }
} 