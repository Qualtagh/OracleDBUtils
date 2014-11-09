create or replace and compile java source named "org/quinto/admin/Command" as
package org.quinto.admin;

import java.io.File;
import java.io.IOException;

public class Command
{
    public static void runCommand( String command )
    {
        try
        {
            String cmdArray[] = File.separatorChar == '/' ? new String[]{ "/bin/sh", "-c", command } : new String[]{ "cmd.exe", "/y", "/c", command };
            Runtime.getRuntime().exec( cmdArray ).waitFor();
        }
        catch ( IOException e )
        {
            e.printStackTrace();
        }
        catch ( InterruptedException e )
        {
            e.printStackTrace();
        }
    }
};
/
create or replace procedure runCommand( tCommand in varchar2 ) is language java name
 'org.quinto.admin.Command.runCommand( java.lang.String )';
 /