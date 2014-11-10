#OracleDBUtils
Helpful PL/SQL utilities for Oracle database.
Written and tested for Oracle 10.2 (should work for later versions, some parts may work for earlier versions too).
___
#p_admin
A package for sessions and jobs control.
If jobs are intensively running all the time, it's hard to compile source code used by them (compilation would hang).
So we need to stop jobs before this process. But inner database methods (such as "alter system kill session" or marking job as broken) may take too long while waiting for resources to be disposed or waiting for the job to be finished. A detailed description of various methods of killing sessions can be found [here][killing sessions]. This package offers methods for immediate jobs and sessions termination. Usually this task is performed by DBAs, not by developers. But sometimes it may ease the process of frequent compilations for both DBAs and developers (by giving more privileges for latter ones), e.g. on test databases.
[killing sessions]:http://oracle-base.com/articles/misc/killing-oracle-sessions.php
___
```pl-sql
procedure killSession( tSid in number );
```
This procedure takes session SID (from view V$SESSION) as argument and kills a corresponding session by calling orakill.exe (on Windows server) or kill -9 (on UNIX machines).
The call is performed via Java stored procedure (see runCommand.sql), which source code is a modified version of Host class available [here][shell commands].
[shell commands]:http://oracle-base.com/articles/8i/shell-commands-from-plsql.php
___
```pl-sql
procedure killAllSessions;
```
This procedure just calls killSession for all sessions available at V$SESSION view ignoring system sessions and a current one. It's useful for releasing locks on database objects.
___
```pl-sql
procedure killDevelopersSessions;
```
Kill sessions of all users logged in with their accounts (sessions, for which OSUSER differs from 'SYSTEM'). Modify it not to kill sessions of application server such as Tomcat by adding corresponding user name (if it's not NT AUTHORITY\SYSTEM) to exceptions inside this procedure.
___
```pl-sql
procedure killUserSessions;
```
Kill sessions of current user (OSUSER in V$SESSION). It's useful if your query takes too long to finish and cannot be killed immediately by "alter system kill session".
___
```pl-sql
procedure killUserTestSessions;
```
Kill debug (Test Window) sessions of current user when logged in via [PL/SQL Developer].
[PL/SQL Developer]:http://www.allroundautomations.com/plsqldev.html
___
```pl-sql
procedure killJob( tJob in number );
```
Stop DBMS_JOB execution by a given identifier (JOB from view USER_JOBS).
___
```pl-sql
procedure pauseAllJobs( tMin in number default 1 / 144, tMax in number default null, tIncr in number default null );
```
Consider the following example:
- Current time is 10:00.
- Job #1 is running.
- Job #2 is scheduled to run at 10:05.
- Job #3 is scheduled to run at 10:30.

We call pauseAllJobs( tMin => 1 / 144 ). So we want to pause all jobs for 10 minutes. What happens:
- Job #1 is killed and scheduled to run at 10:10.
- Job #2 is scheduled to run at 10:10.
- Job #3 is not touched and still scheduled to run at 10:30.

It lets us a time gap to compile source code. And we are sure that no job is executing and no job would start execution during the nearest 10 minutes.

We call pauseAllJobs( tMax => 1 / 144 ). The result is:
- Job #1 is killed and scheduled to launch immediately (at least not later than 10:10).
- Job #2 is not touched and scheduled to run at 10:05.
- Job #3 is scheduled to run at 10:10.

Use it if you need to launch all (or some - see further methods) jobs in nearest time. Say, you have corrected an error in source file used by all jobs and need to recalculate all values filled by jobs.

After call to pauseAllJobs( tIncr => 1 / 144 ) we get:
- Job #1 is killed and scheduled to run at 10:10.
- Job #2 is scheduled to run at 10:15.
- Job #3 is scheduled to run at 10:40.

It just shifts the existing NEXT_DATE (from USER_JOBS) if tIncr is set.

So, more formally, this method kills all jobs and schedules them to launch at max( sysdate + tMin, min( sysdate + tMax, NEXT_DATE + tIncr ) ).
___
```pl-sql
procedure pauseJob( tJob in number, tMin in number default 1 / 144, tMax in number default null, tIncr in number default null );
```
This method pauses (kills and re-schedules) a job by a given identifier.

http://oracle-base.com/articles/misc/string-aggregation-techniques.php
https://asktom.oracle.com/pls/apex/f?p=100:11:0::::P11_QUESTION_ID:2196162600402

http://oracle-base.com/articles/8i/shell-commands-from-plsql.php

https://github.com/xtender/XT_REGEXP

http://www.oracle-developer.net/content/utilities/stk.sql