 //   *********************************************************************************************************
 //   cityEHR
 //   pingURL.java
    
 //   Called as an orbeon processor cityEHR:pingURL
 //   Pings a URL (IP address) which is specifed in the input
 //   Returns the IP in a <node> XML element if ping was successful, otherwise empty <node/>
        
 //   Copyright (C) 2013-2021 John Chelsom.
    
//    This program is free software; you can redistribute it and/or modify it under the terms of the
//    GNU Lesser General Public License as published by the Free Software Foundation; either version
//    2.1 of the License, or (at your option) any later version.
    
//    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//    See the GNU Lesser General Public License for more details.
    
//    The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
//    **********************************************************************************************************

import org.orbeon.oxf.pipeline.api.PipelineContext;
import org.orbeon.oxf.processor.ProcessorInputOutputInfo;
import org.orbeon.oxf.processor.SimpleProcessor;
import org.xml.sax.ContentHandler;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.AttributesImpl;
import java.net.Socket;
import java.net.InetSocketAddress;
import java.io.IOException;
import org.dom4j.Document;
import org.dom4j.Node;

public class pingURL extends SimpleProcessor {

    public pingURL() {
        addInputInfo(new ProcessorInputOutputInfo("data"));
        addOutputInfo(new ProcessorInputOutputInfo("data"));
    }

    public void generateData(PipelineContext context,
                             ContentHandler contentHandler)
            throws SAXException {
            
        Document dataDocument = readInputAsDOM4J(context, "data");
        Node node = dataDocument.selectSingleNode("//node");
        
        String host = node.valueOf("@host");
        int port = Integer.parseInt(node.valueOf("@port"));        
        boolean pingReturn = pingHost(host,port,5);
        
        contentHandler.startDocument();
        contentHandler.startElement("", "status", "status", new AttributesImpl());
        if (pingReturn) {
        //contentHandler.characters(host.toCharArray(), 0, host.length());
        String availability = "online";
        contentHandler.characters(availability.toCharArray(), 0, availability.length());
        }
        else {
        String availability = "offline";
        contentHandler.characters(availability.toCharArray(), 0, availability.length());        
        }
        contentHandler.endElement("", "status", "status");
        contentHandler.endDocument();
    }
    
    public static boolean pingHost(String host, int port, int timeout) {
    try (Socket socket = new Socket()) {
        socket.connect(new InetSocketAddress(host, port), timeout);
        return true;
    } catch (IOException e) {
        return false; // Either timeout or unreachable or failed DNS lookup.
    }
}
}