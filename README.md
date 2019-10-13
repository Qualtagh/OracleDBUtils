# OracleDBUtils
Helpful PL/SQL utilities for Oracle database.
Written and tested for Oracle 10.2 (should work for later versions, some parts may work for earlier versions too).

Contents:

1. [p_admin](#p_admin)
    1. [killSession](#killSession)
    2. [killAllSessions](#killAllSessions)
    3. [killDevelopersSessions](#killDevelopersSessions)
    4. [killUserSessions](#killUserSessions)
    5. [killUserTestSessions](#killUserTestSessions)
    6. [killJob](#killJob)
    7. [pauseAllJobs](#pauseAllJobs)
    8. [pauseJob](#pauseJob)
    9. [pauseJobsLike](#pauseJobsLike)
    10. [getSessionId](#getSessionId)
    11. [getJobId](#getJobId)
2. [p_utils](#p_utils)
    1. [numberToChar](#numberToChar)
    2. [getAssociativeArray](#getAssociativeArray)
    3. [getAssociativeArrayKeys](#getAssociativeArrayKeys)
    4. [getAssociativeArrayValues](#getAssociativeArrayValues)
    5. [truncToSeconds](#truncToSeconds)
    6. [distinguishXML](#distinguishXML)
    7. [calculate](#calculate)
3. [p_stack](#p_stack)
    1. [getCallStack](#getCallStack)
    2. [whoAmI](#whoAmI)
    3. [whoCalledMe](#whoCalledMe)
    4. [getCallStackLine](#getCallStackLine)
    5. [getDynamicDepth](#getDynamicDepth)
    6. [getLexicalDepth](#getLexicalDepth)
    7. [getUnitLine](#getUnitLine)
    8. [getOwner](#getOwner)
    9. [getProgram](#getProgram)
    10. [getProgramType](#getProgramType)
    11. [getSubprogram](#getSubprogram)
    12. [getSubprogramType](#getSubprogramType)
    13. [getSubprograms](#getSubprograms)
    14. [getSubprogramsTypes](#getSubprogramsTypes)
    15. [getConcatenatedSubprograms](#getConcatenatedSubprograms)
    16. [getErrorStack](#getErrorStack)
    17. [getErrorDepth](#getErrorDepth)
    18. [getErrorCode](#getErrorCode)
    19. [getErrorMessage](#getErrorMessage)
    20. [getBacktraceStack](#getBacktraceStack)
    21. [getBacktraceDepth](#getBacktraceDepth)
4. [utl_call_stack](#utl_call_stack)
5. [String aggregation](#string-aggregation)
6. [Links to other packages from various authors](#links-to-other-packages-from-various-authors)

Released into public domain.

___
# p_admin
A package for sessions and jobs control.
If jobs are intensively running all the time, it's hard to compile source code used by them (compilation would hang).
So we need to stop jobs before this process. But inner database methods (such as "alter system kill session" or marking job as broken) may take too long while waiting for resources to be disposed or waiting for the job to be finished. A detailed description of various methods of killing sessions can be found [here](http://oracle-base.com/articles/misc/killing-oracle-sessions.php). This package offers methods for immediate jobs and sessions termination. Usually this task is performed by DBAs, not by developers. But sometimes it may ease the process of frequent compilations for both DBAs and developers (by giving more privileges for latter ones), e.g. on test databases.
___
<a name="killSession"></a>
```PLpgSQL
procedure killSession( tSid in number );
```
This procedure takes session SID (from view V$SESSION) as argument and kills a corresponding session by calling orakill.exe (on Windows server) or kill -9 (on UNIX machines).
The call is performed via Java stored procedure (see runCommand.sql), which source code is a modified version of Host class available [here](http://oracle-base.com/articles/8i/shell-commands-from-plsql.php).
Only current schema sessions killing is allowed (you can modify the source code to avoid this restriction). So it's safe to grant execute on this package to any schema. The owner of this package is allowed to kill any schema session (except SYS).
___
<a name="killAllSessions"></a>
```PLpgSQL
procedure killAllSessions;
```
This procedure just calls killSession for all sessions available at V$SESSION view ignoring system sessions and a current one. It's useful for releasing locks on database objects.
___
<a name="killDevelopersSessions"></a>
```PLpgSQL
procedure killDevelopersSessions;
```
Kill sessions of all users logged in with their accounts (sessions, for which OSUSER differs from 'SYSTEM'). Modify it not to kill sessions of application server such as Tomcat by adding corresponding user name (if it's not NT AUTHORITY\SYSTEM) to exceptions inside this procedure.
___
<a name="killUserSessions"></a>
```PLpgSQL
procedure killUserSessions;
```
Kill sessions of current user (OSUSER in V$SESSION). It's useful if your query takes too long to finish and cannot be killed immediately by "alter system kill session".
___
<a name="killUserTestSessions"></a>
```PLpgSQL
procedure killUserTestSessions;
```
Kill debug (Test Window) sessions of current user when logged in via [PL/SQL Developer](http://www.allroundautomations.com/plsqldev.html).
___
<a name="killJob"></a>
```PLpgSQL
procedure killJob( tJob in number );
```
Stop DBMS_JOB execution by a given identifier (JOB from view USER_JOBS).
___
<a name="pauseAllJobs"></a>
```PLpgSQL
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

So, more formally, this method kills all jobs and schedules them to launch at min( sysdate + tMax, max( sysdate + tMin, NEXT_DATE + tIncr ) ).
___
<a name="pauseJob"></a>
```PLpgSQL
procedure pauseJob( tJob in number, tMin in number default 1 / 144, tMax in number default null, tIncr in number default null );
```
This method pauses (kills and reschedules) a job by a given identifier.
___
<a name="pauseJobsLike"></a>
```PLpgSQL
procedure pauseJobsLike( tLikeCondition in varchar2, tMin in number default 1 / 144, tMax in number default null, tIncr in number default null, tJob in number default null );
```
This is the most generic method of jobs delaying.
It takes a mask as argument (tLikeCondition). This mask affects WHAT column of USER_JOBS view.
All jobs that suit the mask condition would be killed (if needed) and rescheduled. Example:
```PLpgSQL
pauseJobsLike( 'my_schema.my_package.%' );
```
This call will guarantee that all jobs starting from 'my_schema.my_package.' would wait at least 10 minutes before next run.
The condition is simple: where WHAT like tLikeCondition. So wildcards like '%' and '_' are acceptable.
___
<a name="getSessionId"></a>
```PLpgSQL
function getSessionId return number;
```
This method returns SID of a current session. This call is equivalent to sys_context( 'userenv', 'sessionid' ).
___
<a name="getJobId"></a>
```PLpgSQL
function getJobId return number;
```
This method returns an identifier of the current executing job. This is the field JOB from USER_JOBS.
___
**Installation notes:**

First, compile runCommand.sql under sys. Grant appropriate Java right to access files if needed as described [here](http://oracle-base.com/articles/8i/shell-commands-from-plsql.php). Example for *NIX environment:
```PLpgSQL
begin
  dbms_java.grant_permission( 'Schema_that_owns_runCommand', 'SYS:java.io.FilePermission', '/bin/sh', 'execute' );
end;
```
It may require additional permission which can be set like this:
```PLpgSQL
begin
  dbms_java.grant_policy_permission( 'Schema_that_owns_runCommand', 'SYS', 'java.io.FilePermission', '*' );
end;
```
Run it under sys or with JAVA_ADMIN role granted. Use the following snippet to remove this policy permission after file execution permission is granted:
```PLpgSQL
declare
  tSeq number;
begin
  select SEQ
  into tSeq
  from DBA_JAVA_POLICY
  where KIND = 'GRANT'
    and GRANTEE = 'Schema_that_owns_runCommand'
    and TYPE_SCHEMA = 'SYS'
    and TYPE_NAME = 'oracle.aurora.rdbms.security.PolicyTablePermission'
    and NAME = '0:java.io.FilePermission#*';
  dbms_java.disable_permission( tSeq );
  dbms_java.delete_permission( tSeq );
end;
```
It's not recommended to grant rights on runCommand procedure to someone else except sys.
Then, compile p_admin.sql under sys and grant rights/add synonym to target user schema.
The target user may also need an access to V$SESSION view to find SID of hanged session.
___
# p_utils
A package for various tasks: collections manipulation, numeric utilities.
___
<a name="numberToChar"></a>
```PLpgSQL
function numberToChar( tNumber in number ) return varchar2;
```
Standard to_char( 0.23 ) returns '.23' (zero omitted), this function adds zero when needed ('0.23' for the example above).
A detailed explanation of the problem on [StackOverflow](http://stackoverflow.com/questions/6695604/oracle-why-does-the-leading-zero-of-a-number-disappear-when-converting-it-to-c). Examples:
```sql
with SAMPLES as (
  select -4.67 as VALUE from dual union all
  select -4 from dual union all
  select -0.25 from dual union all
  select 0.25 from dual union all
  select 0.5 from dual union all
  select 0 from dual union all
  select 1 from dual union all
  select 1.5 from dual union all
  select 100 from dual union all
  select 100.25 from dual union all
  select 1000 from dual
)
select VALUE,
       to_char( VALUE ) as TO_CHAR,
       rtrim( rtrim( ltrim( to_char( VALUE, '990.99' ) ), '0' ), '.' ) as TO_CHAR_FORMATTED,
       p_utils.numberToChar( VALUE ) as P_UTILS
from SAMPLES
```
Output:

VALUE | TO_CHAR | TO_CHAR_FORMATTED | P_UTILS
--: | :-- | :-- | :--
-4,67 | -4.67 | -4.67 | -4.67
-4 | -4 | -4 | -4
-0,25 | -.25 | -0.25 | -0.25
0,25 | .25 | 0.25 | 0.25
0,5 | .5 | 0.5 | 0.5
0 | 0 | 0 | 0
1 | 1 | 1 | 1
1,5 | 1.5 | 1.5 | 1.5
100 | 100 | 100 | 100
100,25 | 100.25 | 100.25 | 100.25
1000 | 1000 | ####### | 1000

As you can see, to_char format depends on the length of the input, so it's hard (verbose) to achieve the same functionality.
___
<a name="getAssociativeArray"></a>
```PLpgSQL
function getAssociativeArray( tKeys in num_table ) return dbms_sql.number_table;
```
Create a set from an array of keys. num_table is user defined type (see types.sql). All values of the returned associative array are null.
[Click here](http://oracle-base.com/articles/9i/associative-arrays-9i.php) for more information on associative arrays in Oracle.
___
```PLpgSQL
function getAssociativeArray( tKeys in num_table, tValues in num_table ) return dbms_sql.number_table;
function getAssociativeArray( tKeys in num_table, tValues in date_table ) return dbms_sql.date_table;
function getAssociativeArray( tKeys in num_table, tValues in str_table ) return dbms_sql.varchar2_table;
```
Create a map from an array of keys and an array of corresponding values. Example:
```PLpgSQL
declare
  map dbms_sql.number_table := p_utils.getAssociativeArray( num_table( 1, 2, 5 ), num_table( 10, 20, 50 ) );
begin
  dbms_output.put_line( map( 5 ) );
end;
```
Output is "50". This code is equivalent to:
```PLpgSQL
declare
  map dbms_sql.number_table;
begin
  map( 1 ) := 10;
  map( 2 ) := 20;
  map( 5 ) := 50;
  dbms_output.put_line( map( 5 ) );
end;
```
These methods are useful when keys and values are the results of bulk select statement. And further constant-time access to them is required.
___
<a name="getAssociativeArrayKeys"></a>
```PLpgSQL
function getAssociativeArrayKeys( tMap in dbms_sql.number_table ) return num_table;
function getAssociativeArrayKeys( tMap in dbms_sql.date_table ) return num_table;
function getAssociativeArrayKeys( tMap in dbms_sql.varchar2_table ) return num_table;
```
Get an array of keys from a given map.
___
<a name="getAssociativeArrayValues"></a>
```PLpgSQL
function getAssociativeArrayValues( tMap in dbms_sql.number_table ) return num_table;
function getAssociativeArrayValues( tMap in dbms_sql.date_table ) return date_table;
function getAssociativeArrayValues( tMap in dbms_sql.varchar2_table ) return str_table;
```
Get an array of values from a given map.
___
<a name="truncToSeconds"></a>
```PLpgSQL
function truncToSeconds( tTimestamp in timestamp ) return date;
```
Oracle rounds (half up) timestamp to date when using cast( ts as date ) in versions prior to 11 and truncates in version 11.
[More on this issue](http://stackoverflow.com/questions/1712208/oracle-casttimestamp-as-date) on StackOverflow.
This function always truncates timestamp to date.
___
<a name="distinguishXML"></a>
```PLpgSQL
function distinguishXML( xml in XMLType ) return XMLType;
```
Leave only distinct XML nodes of a document. This method is useful for string aggregation ([see section below](#string-aggregation)).
___
<a name="calculate"></a>
```PLpgSQL
function calculate( expression in varchar2 ) return number;
```
Evaluate arithmetic expression. Consider you need to evaluate simple arithmetic expressions written in varchar2 strings, e.g. '23*(4+5)'.
These expressions are generated dynamically (e.g., by users or randomly for captcha).
One way to do this is via using 'execute immediate' construction.
But this approach would fill queries cache soon due to the need of hard parsing of every such query.
So it's better to use Java stored procedure for parsing and calculation (see fraction.sql).
Only simple operations are supported such as addition, subtraction, multiplication, division and parentheses.
Calculations are performed in fractions, so the result is accurate.
For more operations (and big fractions) use Java package org.quinto.math (coming soon), but it requires Java 1.5 at least due to the usage of generics.
___
**Installation notes:**

Compile types.sql and fraction.sql, then p_utils.sql. Java rights are needed only for "calculate" function.
___
# p_stack
A package for call stack control.

There do exist [predefined inquiry directives](http://docs.oracle.com/cd/B19306_01/appdev.102/b14261/fundamentals.htm#BEIBIDCE) `$$PLSQL_LINE` and `$$PLSQL_UNIT` which allow to get information about current stored program unit and source code line in it.
Also, there's a function `dbms_utility.format_call_stack` which allows to get the whole call stack. But it contains only stored program unit names and source code line numbers too.
`V$SESSION` view contains fields `PLSQL_ENTRY_OBJECT_ID`, `PLSQL_ENTRY_SUBPROGRAM_ID`, `PLSQL_OBJECT_ID`, `PLSQL_SUBPROGRAM_ID` which can lead to a subprogram. But that subprogram should be declared in package. Inner package body subprograms aren't traced.
Oracle 12 introduces a package `utl_call_stack` which provides information about subprogram units. In Oracle versions prior to 12, there's no way to get subprogram name except parsing the source code.
The purpose of package `p_stack` is to find subprogram name by parsing the source code according to information returned by `dbms_utility.format_call_stack`.

There are two versions of this package released: one for Oracle 9 (`p_stack.9.sql`) and another one for Oracle 10 and 11 (`p_stack.sql`). Also, you can use the latter one in Oracle 12 as well. `p_stack` provides some information that `utl_call_stack` lacks: program and subprogram types (PACKAGE, PROCEDURE, FUNCTION etc.), subprogram names for backtrace stack. Methods `getDynamicDepth`, `getErrorDepth` and `getBacktraceDepth` are optimized for Oracle 12 by calling `utl_call_stack` functions.

Anonymous classes source code is retrieved via views `V$SQL` and `V$SQLTEXT_WITH_NEWLINES`. Stored program units code is gained via `ALL_SOURCE`. The type of the program unit in `getBacktraceStack` is requested from `ALL_OBJECTS`.
This package is written in pure PL/SQL. Double quoted identifiers are supported. Strings `q`-notation is supported too. Procedures and functions without definitions are skipped properly.
Conditional compilation is supported. Multiline and one-line comments are skipped properly. Calls via database link aren't traced by `dbms_utility.format_call_stack` so they aren't traced by `p_stack` too.
One-liner subprogram definitions cannot be distinguished (see example below).
___
<a name="getCallStack"></a>
```PLpgSQL
function getCallStack( tDepth in number default null ) return varchar2;
```
Returns a call stack. The call of this procedure is included and is at the first line.
`tDepth` sets which line of stack to show. Lesser numbers are most recent calls. Numeration starts from 1.
The call of this procedure has depth = 1.
If `tDepth` is null then the whole stack is returned as a string where lines are delimited by "new line" symbol.

Output format of each stack line: `LINE || ': ' || OWNER || '.' || PROGRAM TYPE || [ ' ' || PROGRAM NAME ]? || [ '.' || SUBPROGRAM TYPE || ' ' || SUBPROGRAM NAME ]*`

`LINE` is a source code line number as returned by `dbms_utility.format_call_stack`.

`OWNER` is an owner of program unit being called, or parsing schema name for anonymous blocks.
If the parsing schema name could not be retrieved then `OWNER` equals to current schema name.

`PROGRAM TYPE` is one of `ANONYMOUS BLOCK`, `PACKAGE`, `PACKAGE BODY`, `TYPE BODY`, `TRIGGER`, `PROCEDURE`, `FUNCTION`.
It's the type of outermost program unit.

`PROGRAM NAME` is the name of program unit being called as returned by `dbms_utility.format_call_stack`.
It's absent for anonymous blocks.
It's double quoted if the source code contains its name in double quotes.

`SUBPROGRAM TYPE` is one of `PROCEDURE` or `FUNCTION`.
It's the type of inner subprogram.

`SUBPROGRAM NAME` is the name of inner subprogram.
If there are several inner units then all of them are separated by dots.

**Sample usage:**
```PLpgSQL
create package APCKG is
  procedure PROC;
end;
/
create package body APCKG is
  procedure PROC is
    procedure "INNER/proc" is
    begin
      dbms_output.put_line( p_stack.whoAmI );
    end;
  begin
    "INNER/proc";
  end;
end;
/
begin
  APCKG.PROC;
end;
/
drop package APCKG;
```
Output:
```
5: YOUR_SCHEMA.PACKAGE BODY APCKG.PROCEDURE PROC.PROCEDURE "INNER/proc"
```
One-liner definitions cannot be distinguished. Consider the following example:
```PLpgSQL
create or replace procedure outer_proc( t in number ) is
procedure inner_proc1 is begin dbms_output.put_line( dbms_utility.format_call_stack ); end; procedure inner_proc2 is begin dbms_output.put_line( dbms_utility.format_call_stack ); end;
begin
  if t = 1 then inner_proc1; else inner_proc2; end if;
end;
/
begin
  outer_proc( trunc( dbms_random.value( 1, 3 ) ) );
end;
/
drop procedure outer_proc;
```
The output is:
```
----- PL/SQL Call Stack -----
  object      line  object
  handle    number  name
C4462284         2  procedure YOUR_SCHEMA.OUTER_PROC
C4462284         4  procedure YOUR_SCHEMA.OUTER_PROC
C249BADC         2  anonymous block
```
Line 2 contains two subprograms. It's impossible to find out which one was called.
___
<a name="whoAmI"></a>
```PLpgSQL
function whoAmI return varchar2;
```
Returns the stack information of a current program unit.
Example:
```PLpgSQL
declare
  procedure inner_proc is
  begin
    dbms_output.put_line( p_stack.whoAmI );
  end;
begin
  inner_proc;
end;
```
Output:
```
4: YOUR_SCHEMA.ANONYMOUS BLOCK.PROCEDURE INNER_PROC
```
See output format description of function `getCallStack`.

If you just need to get the name of current subprogram, use:
```PLpgSQL
dbms_output.put_line( p_stack.getSubprogram( p_stack.whoAmI ) );
```
Or this variant for the fully qualified subprogram name:
```PLpgSQL
dbms_output.put_line( p_stack.getConcatenatedSubprograms( p_stack.whoAmI ) );
```
___
<a name="whoCalledMe"></a>
```PLpgSQL
function whoCalledMe return varchar2;
```
Returns the stack information of a program unit which has called currently executing code. Sample usage:
```PLpgSQL
dbms_output.put_line( p_stack.getConcatenatedSubprograms( p_stack.whoCalledMe ) );
```
___
<a name="getCallStackLine"></a>
```PLpgSQL
function getCallStackLine( tCallStack in varchar2, tDepth in number ) return varchar2;
```
Returns one stack line at a given depth. A common example for all further functions:
```PLpgSQL
declare
  procedure outer_proc is
    procedure inner_proc is
      tCallStack varchar2( 4000 );
      tDepth number;
      tCallLine varchar2( 4000 );
    begin
      tCallStack := p_stack.getCallStack;
      tDepth := p_stack.getDynamicDepth( tCallStack );
      dbms_output.put_line( 'DEPTH LINE OWNER       LEX  PROGRAM_TYPE    PROGRAM SUBPROGRAM_TYPE SUBPROGRAM   CONCATENATED' );
      for i in 1 .. tDepth loop
        tCallLine := p_stack.getCallStackLine( tCallStack, i );
        dbms_output.put( rpad( i, 6 ) );
        dbms_output.put( rpad( p_stack.getUnitLine( tCallLine ), 5 ) );
        dbms_output.put( rpad( p_stack.getOwner( tCallLine ), 12 ) );
        dbms_output.put( rpad( p_stack.getLexicalDepth( tCallLine ), 5 ) );
        dbms_output.put( rpad( p_stack.getProgramType( tCallLine ), 16 ) );
        dbms_output.put( rpad( nvl( p_stack.getProgram( tCallLine ), ' ' ), 8 ) );
        dbms_output.put( rpad( nvl( p_stack.getSubprogramType( tCallLine ), ' ' ), 16 ) );
        dbms_output.put( rpad( nvl( p_stack.getSubprogram( tCallLine ), ' ' ), 13 ) );
        dbms_output.put_line( p_stack.getConcatenatedSubprograms( tCallLine ) );
      end loop;
    end;
  begin
    inner_proc;
  end;
begin
  outer_proc;
end;
```
Output:
```
DEPTH LINE OWNER       LEX  PROGRAM_TYPE    PROGRAM SUBPROGRAM_TYPE SUBPROGRAM   CONCATENATED
1     73   YOUR_SCHEMA 1    PACKAGE BODY    P_STACK FUNCTION        GETCALLSTACK P_STACK.GETCALLSTACK
2     8    YOUR_SCHEMA 2    ANONYMOUS BLOCK         PROCEDURE       INNER_PROC   ANONYMOUS BLOCK.OUTER_PROC.INNER_PROC
3     25   YOUR_SCHEMA 1    ANONYMOUS BLOCK         PROCEDURE       OUTER_PROC   ANONYMOUS BLOCK.OUTER_PROC
4     28   YOUR_SCHEMA 0    ANONYMOUS BLOCK         ANONYMOUS BLOCK              ANONYMOUS BLOCK
```
The rest functions simulate the behaviour of `utl_call_stack` package.

If you simply need a string output in default format then use `dbms_output.put_line( p_stack.getCallStack )`.
___
<a name="getDynamicDepth"></a>
```PLpgSQL
function getDynamicDepth( tCallStack in varchar2 default '' ) return number;
```
Returns current stack depth including the call of this function. Similar to `utl_call_stack.dynamic_depth`.

`tCallStack` is information returned by `getCallStack`. Can be omitted.
___
<a name="getLexicalDepth"></a>
```PLpgSQL
function getLexicalDepth( tCallStack in varchar2, tDepth in number default null ) return number;
```
Returns a depth of a current program unit. Similar to `utl_call_stack.lexical_depth`.
Stored procedures, functions, packages and their bodies, type bodies, triggers and anonymous blocks have a depth equal to `0`.
Inner procedures and functions have depth equal to `1 + depth of parent program unit`.

`tCallStack` is information returned by getCallStack if `tDepth` is set, or information returned by `getCallStackLine`.

`tDepth` is a number of requested line if `tCallStack` = `getCallStack`, `null` otherwise.
___
<a name="getUnitLine"></a>
```PLpgSQL
function getUnitLine( tCallStack in varchar2, tDepth in number default null ) return number;
```
Returns a source line number as returned by `dbms_utility.format_call_stack`. Similar to `utl_call_stack.unit_line`.
___
<a name="getOwner"></a>
```PLpgSQL
function getOwner( tCallStack in varchar2, tDepth in number default null ) return varchar2;
```
Returns owner of a requested program unit, or a parsing schema for an anonymous block.
If the parsing schema name could not be retrieved then OWNER equals to current schema name.
Similar to `utl_call_stack.owner`.
___
<a name="getProgram"></a>
```PLpgSQL
function getProgram( tCallStack in varchar2, tDepth in number default null ) return varchar2;
```
Returns name of a requested stored procedure. Empty string for anonymous block. The name returned won't contain double quotes.
___
<a name="getProgramType"></a>
```PLpgSQL
function getProgramType( tCallStack in varchar2, tDepth in number default null ) return varchar2;
```
Returns a type of a requested stored procedure. One of:
`ANONYMOUS BLOCK`, `PROCEDURE`, `FUNCTION`, `TRIGGER`, `PACKAGE`, `PACKAGE BODY`, `TYPE BODY`.
___
<a name="getSubprogram"></a>
```PLpgSQL
function getSubprogram( tCallStack in varchar2, tDepth in number default null ) return varchar2;
```
Returns a name of a requested innermost subprogram. The name returned never contains double quotes.
___
<a name="getSubprogramType"></a>
```PLpgSQL
function getSubprogramType( tCallStack in varchar2, tDepth in number default null ) return varchar2;
```
Returns a type of requested innermost subprogram. Value returned is one of `PROCEDURE` or `FUNCTION`.
___
<a name="getSubprograms"></a>
```PLpgSQL
function getSubprograms( tCallStack in varchar2, tDepth in number default null ) return str_table;
```
Returns an array of names of a requested subprograms. Names returned never contain double quotes. Similar to `utl_call_stack.subprogram` except for the outermost program name: it is included in `utl_call_stack` and is not included in `getSubprograms`.
___
<a name="getSubprogramsTypes"></a>
```PLpgSQL
function getSubprogramsTypes( tCallStack in varchar2, tDepth in number default null ) return str_table;
```
Returns an array of types of requested subprograms. Each value in the array returned is one of `PROCEDURE` or `FUNCTION`.
___
<a name="getConcatenatedSubprograms"></a>
```PLpgSQL
function getConcatenatedSubprograms( tCallStack in varchar2, tDepth in number default null ) return varchar2;
```
Returns the hierarchy of names separated by dot from outermost to innermost program unit.
If one of program units in this hierarchy has double quotes in its name, they would be preserved.
Similar to `utl_call_stack.concatenate_subprogram`.
___
<a name="getErrorStack"></a>
```PLpgSQL
function getErrorStack( tDepth in number default null ) return varchar2;
```
Returns an error stack as a string.

`tDepth` is the number of requested stack line. Lesser numbers are most recent errors. Numeration starts from 1.
If omitted then the full stack is concatenated via newline character.
If `tDepth` is out of bounds then `null` is returned.
The full stack output equals to `dbms_utility.format_call_stack`.

Sample usage:
```PLpgSQL
declare
  x number;
  tErrorStack varchar2( 4000 );
  tErrorLine varchar2( 4000 );
  tDepth pls_integer;
begin
  x := 1 / 0;
exception
  when OTHERS then
    begin
      select 1 into x from dual where 1 = 0;
    exception
      when OTHERS then
        begin
          select 1 into x from dual union all select 2 from dual;
        exception
          when OTHERS then
            dbms_output.put_line( 'DEPTH CODE       MESSAGE' );
            tErrorStack := p_stack.getErrorStack;
            tDepth := p_stack.getErrorDepth( tErrorStack );
            for i in 1 .. tDepth loop
              tErrorLine := p_stack.getCallStackLine( tErrorStack, i );
              dbms_output.put( rpad( i, 6 ) );
              dbms_output.put( 'ORA-' );
              dbms_output.put( lpad( p_stack.getErrorCode( tErrorLine ), 5, '0' ) );
              dbms_output.put( '  ' );
              dbms_output.put_line( p_stack.getErrorMessage( tErrorLine ) );
            end loop;
        end;
    end;
end;
```
Output:
```
DEPTH CODE       MESSAGE
1     ORA-01422  exact fetch returns more than requested number of rows
2     ORA-01403  no data found
3     ORA-01476  divisor is equal to zero
```
If you simply need a string output in default format then use `dbms_output.put_line( p_stack.getErrorStack )`.
___
<a name="getErrorDepth"></a>
```PLpgSQL
function getErrorDepth( tErrorStack in varchar2 default '' ) return number;
```
Returns current error stack depth.
Similar to `utl_call_stack.error_depth`.

`tErrorStack` is the information returned by `getErrorStack`. Can be omitted.
___
<a name="getErrorCode"></a>
```PLpgSQL
function getErrorCode( tErrorStack in varchar2, tDepth in number default null ) return number;
```
Returns error code at a given depth.
Similar to `utl_call_stack.error_number`.

`tErrorStack` is the information returned by `getErrorStack`.

`tDepth` is the number of requested stack line if `tErrorStack` = `getErrorStack`, `null` otherwise.
___
<a name="getErrorMessage"></a>
```PLpgSQL
function getErrorMessage( tErrorStack in varchar2, tDepth in number default null ) return varchar2;
```
Returns error message at a given depth.
Similar to `utl_call_stack.error_msg`.

`tErrorStack` is the information returned by `getErrorStack`.

`tDepth` is the number of requested stack line if `tErrorStack` = `getErrorStack`, `null` otherwise.
___
<a name="getBacktraceStack"></a>
```PLpgSQL
function getBacktraceStack( tDepth in number default null ) return varchar2;
```
Returns a backtrace stack as a string.
It shows program units and line numbers where the last error has occurred.
The output format is the same as in `getCallStack`.
See [getCallStack](#getCallStack) documentation to get more information about the output format.
Use methods like `getProgramType`, `getSubprograms` and others to get properties of the backtrace stack like it's done with `getCallStack`.
Similar to `dbms_utility.format_error_backtrace`.

`tDepth` is the number of requested stack line. Lesser numbers are most recent calls. Numeration starts from 1.

- The order equals to the order returned by `dbms_utility.format_error_backtrace`.
- Also, the order equals to the order returned by `getCallStack`.
- But it doesn't equal to the order returned by `utl_call_stack.backtrace_unit` which is reversed.

If `tDepth` is omitted then the full stack is concatenated via newline character.

`getBacktraceStack` and `getBacktraceDepth` functions are implemented via a call to `dbms_utility.format_error_backtrace` which appeared in Oracle 10.
So the version of the package `p_stack` for Oracle 9 does not contain these methods.

`getBacktraceStack` method provides more functionality than `utl_call_stack`. The latter one provides information only about the outermost program unit name, owner and a line number.
`getBacktraceStack` allows to get inner procedures and functions names and types as it's done in `getCallStack`.

However, there exists one more limitation comparing to `getCallStack`. The method `dbms_utility.format_error_backtrace` returns only the name of the program unit without its type. It may lead to ambiguity if the error occurs in a package. Take a look at the example:
```PLpgSQL
create or replace package pckg is
  n number := 1 / trunc( dbms_random.value( 0, 2 ) ); -- Raise division by zero exception with 50% probability.
  
  q varchar2( 100 ) := 'PACKAGE INITIALIZED PROPERLY';
  
  procedure null_proc;
end;
/
create or replace package body pckg is
  m number := 1 / 0;
  
  procedure null_proc is
  begin
    null;
  end;
end;
/
begin
  begin
    pckg.null_proc;
  exception
    when OTHERS then
      dbms_output.put_line( dbms_utility.format_error_backtrace );
  end;
  dbms_output.put_line( pckg.q );
end;
/
drop package body pckg;
drop package pckg;
```
Run this script several times. With 50% probability the output would be:
```
ORA-06512: at "YOUR_SCHEMA.PCKG", line 2
ORA-06512: at line 3
```
It means that the package variable `q` was not initialized. So a division by zero exception occurred at `n` initialization in a package (not in its body).

In other cases the output would be:
```
ORA-06512: at "YOUR_SCHEMA.PCKG", line 2
ORA-06512: at line 3

PACKAGE INITIALIZED PROPERLY
```
The package variable `q` was initialized. So a division by zero was raised at `m` initialization in the package body. But the output of `dbms_utility.format_error_backtrace` is the same in both cases. So it's impossible to distinguish packages and their bodies at backtrace stack parsing.

`getBacktraceStack` assumes that the type of the program unit is always `PACKAGE BODY` when such an ambiguity happens because errors in package initialization are quite rare.
___
<a name="getBacktraceDepth"></a>
```PLpgSQL
function getBacktraceDepth( tBacktraceStack in varchar2 default '' ) return number;
```
Returns backtrace stack depth.
Similar to `utl_call_stack.backtrace_depth`.

`tBacktraceStack` is the information returned by `getBacktraceStack`. Can be omitted.

Sample usage:
```PLpgSQL
create or replace procedure outer_proc is
  procedure inner_proc is
    x number;
  begin
    x := 1 / 0;
  end;
begin
  inner_proc;
end;
/
declare
  tBacktraceStack varchar2( 4000 );
  tCallLine varchar2( 4000 );
  tDepth pls_integer;
  
  procedure local_proc is
  begin
    outer_proc;
  end;
begin
  local_proc;
exception
  when OTHERS then
    tBacktraceStack := p_stack.getBacktraceStack;
    tDepth := p_stack.getBacktraceDepth( tBacktraceStack );
    dbms_output.put_line( 'DEPTH LINE OWNER       LEX  PROGRAM_TYPE    PROGRAM    SUBPROGRAM_TYPE SUBPROGRAM   CONCATENATED' );
    for i in 1 .. tDepth loop
      tCallLine := p_stack.getCallStackLine( tBacktraceStack, i );
      dbms_output.put( rpad( i, 6 ) );
      dbms_output.put( rpad( p_stack.getUnitLine( tCallLine ), 5 ) );
      dbms_output.put( rpad( p_stack.getOwner( tCallLine ), 12 ) );
      dbms_output.put( rpad( p_stack.getLexicalDepth( tCallLine ), 5 ) );
      dbms_output.put( rpad( p_stack.getProgramType( tCallLine ), 16 ) );
      dbms_output.put( rpad( nvl( p_stack.getProgram( tCallLine ), ' ' ), 11 ) );
      dbms_output.put( rpad( nvl( p_stack.getSubprogramType( tCallLine ), ' ' ), 16 ) );
      dbms_output.put( rpad( nvl( p_stack.getSubprogram( tCallLine ), ' ' ), 13 ) );
      dbms_output.put_line( p_stack.getConcatenatedSubprograms( tCallLine ) );
    end loop;
end;
/
drop procedure outer_proc;
```
The output would be:
```
DEPTH LINE OWNER       LEX  PROGRAM_TYPE    PROGRAM    SUBPROGRAM_TYPE SUBPROGRAM   CONCATENATED
1     5    YOUR_SCHEMA 1    PROCEDURE       OUTER_PROC PROCEDURE       INNER_PROC   OUTER_PROC.INNER_PROC
2     8    YOUR_SCHEMA 0    PROCEDURE       OUTER_PROC PROCEDURE                    OUTER_PROC
3     8    YOUR_SCHEMA 1    ANONYMOUS BLOCK            PROCEDURE       LOCAL_PROC   ANONYMOUS BLOCK.LOCAL_PROC
4     11   YOUR_SCHEMA 0    ANONYMOUS BLOCK            ANONYMOUS BLOCK              ANONYMOUS BLOCK
```
It shows the full backtrace of an error (division by zero) from the line where an error has happened (depth 1) to the line where the function was called and the error was catched (depth 4).

If you simply need a string output in default format then use `dbms_output.put_line( p_stack.getBacktraceStack )`.
___
**Installation notes:**

Compile types.sql. Then compile p_stack.9.sql for Oracle 9, or p_stack.sql for later versions. If the `owa` package is not available, replace its usages by commented `chr` functions. If the views `V$SQL` or `V$SQLTEXT_WITH_NEWLINES` are not available, just remove those blocks. The source code of anonymous blocks won't be parsed in this case. But it's not required for most applications.
___
**Development notes:**

The file p_stack_tests.sql contains a simple set of unit tests.
___
# utl_call_stack
Oracle 12 provides `utl_call_stack` package for handy call stack traversal.
This repository contains a backport of `utl_call_stack` for Oracle 9, 10 and 11.
Also, it can be useful for Oracle 12 which lacks method `unit_type` (appeared in later versions).

Methods `current_edition` and `actual_edition` aren't implemented (always return `null`).

The implementation depends on `p_stack` package. Each call to backported `utl_call_stack` functions leads to program unit source code parsing. Package `p_stack` allows to store parsed results and traverse them for output (so, the parsing is done only once).

Also, there is one additional method `backtrace_subprogram` which allows to print the chain of all inner procedures on the backtrace stack. Use it in conjunction with `concatenate_substring` method.

Oracle 9 has no `dbms_utility.format_error_backtrace` method. So, it's impossible to implement backtrace processing methods in `p_stack`. It leads to the fact that backtrace processing methods in Oracle 9 version of `utl_call_stack` aren't implemented. `backtrace_depth` always returns 0. `backtrace_unit`, `backtrace_subprogram` and `backtrace_line` always raise `BAD_DEPTH_INDICATOR` exception.

The code of `BAD_DEPTH_INDICATOR` exception is kept the same as in Oracle 12 (equals to -64610) for compatibility. It has no human-readable error message in Oracle versions prior to 12. And it's out of scope of user defined exceptions (20000-20999), so `raise_application_error` cannot be called. So, if the requested depth is out of range, you will see the following error message:
```
ORA-64610: Message 64610 not found; product=RDBMS; facility=ORA
```
Don't be scared: it just means that the requested depth is out of range.

[This page](https://oracle-base.com/articles/12c/utl-call-stack-12cr1) has good examples of `utl_call_stack` usage.
___
**Installation notes:**

First, compile `p_stack` as described above. Then compile utl_call_stack.9.sql for Oracle 9, or utl_call_stack.sql for later versions.
___
# String aggregation
String aggregation techniques are described in details [here](http://oracle-base.com/articles/misc/string-aggregation-techniques.php).
The main properties of the methods described are:
- Least Oracle version that supports the method.
- One-liner call (no need for nested subqueries).
- Support of strings longer than 4000 characters (CLOB).
- Distinguishability of elements aggregated ("distinct" keyword).
- Lexicographical ordering of elements.
- Ordering of elements that uses other fields of query.

The methods are:

**Specific function.** Since: Oracle 8. One-liner: yes. CLOB support: yes. Distinguishability: yes. Ordering: yes.
A PL/SQL function that performs additional query inside to retrieve aggregated string. Should be written again and again for every new query.

**Generic function.** Since: Oracle 8. One-liner: yes. CLOB support: yes. Distinguishability: yes. Ordering: yes.
A PL/SQL function that performs a *dynamic* query inside. Should be written once. But it cannot be performed on sophisticated query.
It takes table name and field name as arguments. It can be expanded to take varchar2 query as argument. This would lead to code duplication.
It is described in Tom Kyte's [blog](https://asktom.oracle.com/pls/asktom/f?p=100:11:::::P11_QUESTION_ID:229614022562).

**Ref Cursor function.** Since: Oracle 8. One-liner: no. CLOB support: yes. Distinguishability: yes. Ordering: yes.
A PL/SQL function that accepts [cursor expression](https://docs.oracle.com/cd/A87860_01/doc/server.817/a85397/expressi.htm#1002754) as an argument. Leads to code duplication. [Described here](https://oracle-base.com/articles/misc/string-aggregation-techniques#generic_function_using_ref_cursor).

**SYS_CONNECT_BY_PATH.** Since: Oracle 9. One-liner: no. CLOB support: no. Distinguishability: no. Ordering: yes.

**HIERARCHY.** Since: Oracle 9. One-liner: no. CLOB support: yes. Distinguishability: no. Ordering: yes.
A package with syntax similar to SYS_CONNECT_BY_PATH. See: [this thread](https://community.oracle.com/thread/965324).

**STRING_AGG.** Since: Oracle 9. One-liner: yes. CLOB support: no. Distinguishability: yes. Ordering: no.
This is a user-defined function. See: string_agg.sql. It is a slightly modified version of Tom Kyte's [function](https://asktom.oracle.com/pls/apex/f?p=100:11:0::::P11_QUESTION_ID:2196162600402).
The original one produced an error when the aggregated string exceeds 4000 characters. Modified function cuts the output.

**CLOB_AGG.** Since: Oracle 9. One-liner: yes. CLOB support: yes. Distinguishability: yes. Ordering: no.
This is an overloaded version of string_agg for CLOB argument. See: clob_agg.sql.

**XMLAgg.** Since: Oracle 9. One-liner: yes, verbose. CLOB support: yes. Distinguishability: no. Ordering: yes.

**WM_CONCAT.** Since: Oracle 10. One-liner: yes. CLOB support: since 10.2.0.5.0. Distinguishability: yes. Ordering: no.
Unofficial. Undocumented. Removed since Oracle 12. It's better to use string_agg or clob_agg instead.

**COLLECT.** Since: Oracle 10. One-liner: yes. CLOB support: yes for output, no for input. Distinguishability: no. Ordering: no.

**LISTAGG.** Since: Oracle 11. One-liner: yes. CLOB support: no. Distinguishability: since 19. Ordering: yes.

Here is the table:

Method | Min. version | One-liner | CLOB | Distinct | Sorting | Notes
:-- | :--: | :--: | :--: | :--: | :--: | :--
Specific function | 8 | + | + | + | + | Should be written for each query
Generic function | 8 | + | + | + | + | Uses dynamic SQL - either very limited or requires query to be duplicated
Ref Cursor function | 8 | - | + | + | + | Requires query to be duplicated
SYS_CONNECT_BY_PATH | 9 | - | - | - | + |
HIERARCHY | 9 | - | + | - | + |
STRING_AGG / CLOB_AGG | 9 | + | + | + | - |
XMLAgg | 9 | + | + | - | + |
WM_CONCAT | 10 | + | Since 10.2.0.5.0 | + | - | Unofficial, undocumented, removed in 12
COLLECT | 10 | + | For output only | - | - |
LISTAGG | 11 | + | - | Since 19 | + |

So, there's no ideal method. But some disadvantages can be avoided.

Distinguishability.

1. It can be achieved by subquery with 'distinct' keyword.
2. Also, there's a regex solution described [here](http://dba.stackexchange.com/questions/696/eliminate-duplicates-in-listagg-oracle). But it requires input to be ordered lexicographically.
3. A comma-separated string can be split into values inside a PL/SQL procedure and then concatenated ignoring duplicates
(in linear time and memory using associative arrays).

Ordering.

1. It can be achieved by subquery with ordering.
2. A lexicographical ordering can be performed inside PL/SQL procedure
by splitting comma-separated string, ordering and concatenating results back.

We cannot get results ordered by other query fields: only with a subquery or with a built-in syntax of aggregation function.
So, ideal candidate method should be one-liner with CLOB and ordering support. The only such method is XMLAgg.

How to add distinguishability to it? Use `p_utils.distinguishXML` - it leaves only distinct XML nodes of the aggregated input.

Also, you may need [dbms_xmlgen.convert](https://docs.oracle.com/cd/B19306_01/appdev.102/b14258/d_xmlgen.htm#i1013100) to unescape special characters in resulting string.

Example:
```sql
with EMPLOYEES as (
  select 'Sales' as DEPARTMENT, 'John' as NAME, 'Butler' as SURNAME from dual union all
  select 'Sales', 'John', 'Kelly' from dual union all
  select 'Sales', 'Jane', 'Kelly' from dual union all
  select 'Devs', 'Ruth', 'Ostin' from dual union all
  select 'Devs', 'Gareth', 'Pink' from dual union all
  select 'Devs', 'Cli''igan', 'Moorney' from dual union all
  select 'Devs', 'Ruth', 'Zack' from dual
)
select DEPARTMENT,
       dbms_xmlgen.convert(
         substr(
           replace(
             replace(
               p_utils.distinguishXML(
                 XMLAgg(
                   XMLElement( "elem", NAME )
                   order by SURNAME
                 )
               ).getStringVal(), '</elem>'
             ), '<elem>', ', '
           ), 3
         ), 1
       ) as NAMES
from EMPLOYEES
group by DEPARTMENT
order by DEPARTMENT
```

Result:

DEPARTMENT | NAMES
:-- | :--
Devs | Cli'igan, Ruth, Gareth
Sales | John, Jane

Employees are ordered by surname and only distinct names are left. Use `getClobVal` instead of `getStringVal` if you expect long results.
___
# Links to other packages from various authors
[XT_REGEXP](https://github.com/xtender/XT_REGEXP) from Sayan Malakshinov aka XTender. This package lets using of Java regular expressions inside SQL. Java regular expressions are more powerful than built-in functions regexp_substr, regexp_replace etc.

[STK](http://www.oracle-developer.net/content/utilities/stk.sql) from Adrian Billington. This package provides call stack trace information. Useful for logging purposes.

[Hierarchy](https://community.oracle.com/thread/965324) from Solomon Yakobson. This package contains methods analogous to SYS_CONNECT_BY_PATH for CLOB datatype.
