
1. Open terminal in this directory and compile the java code that implements the pingURL processor using
   javac -classpath "../../../../lib/*" pingURL.java

   (Note the quotes " " are required on Linux)

2. Move the resulting .class file to the WEB-INF/classes folder

3. Map the cityEHR:pingURL processor in custom-processors.xml located in WEB-INF/resources/config

4. Restart Tomcat to deploy
