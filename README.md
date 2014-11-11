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
Only current schema sessions killing is allowed (you can modify the source code to avoid this restriction).
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
This method pauses (kills and reschedules) a job by a given identifier.
___
```pl-sql
procedure pauseJobsLike( tLikeCondition in varchar2, tMin in number default 1 / 144, tMax in number default null, tIncr in number default null, tJob in number default null );
```
This is the most generic method of jobs delaying.
It takes a mask as argument (tLikeCondition). This mask affects WHAT column of USER_JOBS view.
All jobs that suit the mask condition would be killed (if needed) and rescheduled. Example:
```pl-sql
pauseJobsLike( 'my_schema.my_package.%' );
```
This call will guarantee that all jobs starting from 'my_schema.my_package.' would wait at least 10 minutes before next run.
The condition is simple: where WHAT like tLikeCondition. So wildcards like '%' and '_' are acceptable.
___
**Installation notes:**

First, compile runCommand.sql under sys. Grant appropriate Java right to access files if needed as described [here][shell commands].
It's not recommended to grant rights on runCommand procedure to someone else except sys.
Then, compile p_admin.sql under sys and grant rights/add synonym to target user scheme.
The target user may also need an access to V$SESSION view to find SID of hanged session.
___
#p_utils
A package for various tasks: collections manipulation, numeric utilities.
___
```pl-sql
function numberToChar( tNumber in number ) return varchar2;
```
Standard to_char( 0.23 ) returns '.23' (zero omitted), this function adds zero when needed ('0.23' for the example above).
A detailed explanation of the problem on [StackOverflow][zero omitted]. Examples:
[zero omitted]:http://stackoverflow.com/questions/6695604/oracle-why-does-the-leading-zero-of-a-number-disappear-when-converting-it-to-c
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
```pl-sql
function getAssociativeArray( tKeys in num_table ) return dbms_sql.number_table;
```
Create a set from an array of keys. num_table is user defined type (see types.sql). All values of the returned associative array are null.
[Click here][associative arrays] for more information on associative arrays in Oracle.
[associative arrays]:http://oracle-base.com/articles/9i/associative-arrays-9i.php
___
```pl-sql
function getAssociativeArray( tKeys in num_table, tValues in num_table ) return dbms_sql.number_table;
function getAssociativeArray( tKeys in num_table, tValues in date_table ) return dbms_sql.date_table;
function getAssociativeArray( tKeys in num_table, tValues in str_table ) return dbms_sql.varchar2_table;
```
Create a map from an array of keys and an array of corresponding values. Example:
```pl-sql
declare
  map dbms_sql.number_table := p_utils.getAssociativeArray( num_table( 1, 2, 5 ), num_table( 10, 20, 50 ) );
begin
  dbms_output.put_line( map( 5 ) );
end;
```
Output is "50". This code is equivalent to:
```pl-sql
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
```pl-sql
function getAssociativeArrayKeys( tMap in dbms_sql.number_table ) return num_table;
function getAssociativeArrayKeys( tMap in dbms_sql.date_table ) return num_table;
function getAssociativeArrayKeys( tMap in dbms_sql.varchar2_table ) return num_table;
```
Get an array of keys from a given map.
___
```pl-sql
function getAssociativeArrayValues( tMap in dbms_sql.number_table ) return num_table;
function getAssociativeArrayValues( tMap in dbms_sql.date_table ) return date_table;
function getAssociativeArrayValues( tMap in dbms_sql.varchar2_table ) return str_table;
```
Get an array of values from a given map.
___
```pl-sql
function truncToSeconds( tTimestamp in timestamp ) return date;
```
Oracle rounds (half up) timestamp to date when using cast( ts as date ) in versions prior to 11 and truncates in version 11.
[More on this issue][timestamp rounding] on StackOverflow.
This function always truncates timestamp to date.
[timestamp rounding]:http://stackoverflow.com/questions/1712208/oracle-casttimestamp-as-date
___
```pl-sql
function distinguishXML( xml in XMLType ) return XMLType;
```
Leave only distinct XML nodes of a document. This method is useful for string aggregation (see section below).
___
```pl-sql
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
#String aggregation
String aggregation techniques are described in details [here][string aggregation].
[string aggregation]:http://oracle-base.com/articles/misc/string-aggregation-techniques.php
The main properties of the methods described are:
- Least Oracle version that supports the method.
- One-liner call (no need for nested subqueries).
- Support of strings longer than 4000 characters (CLOB).
- Distinguishability of elements aggregated ("distinct" keyword).
- Lexicographical ordering of elements.
- Ordering of elements that uses other fields of query.

The methods are:

**LISTAGG.** Since: Oracle 11. One-liner: yes. CLOB support: no. Distinguishability: no. Ordering: yes.

**WM_CONCAT.** Since: Oracle 10. One-liner: yes. CLOB support: since 10.2.0.5.0. Distinguishability: yes. Ordering: no.
Unofficial. Undocumented. It's better to use string_agg or clob_agg instead.

**STRING_AGG.** Since: Oracle 9. One-liner: yes. CLOB support: no. Distinguishability: yes. Ordering: no.
This is a user-defined function. See: string_agg.sql. It is a slightly modified version of Tom Kyte's [function][string_agg].
The original one produced an error when the aggregated string exceeds 4000 characters. Modified function cuts the output.
[string_agg]:https://asktom.oracle.com/pls/apex/f?p=100:11:0::::P11_QUESTION_ID:2196162600402

**CLOB_AGG.** Since: Oracle 9. One-liner: yes. CLOB support: yes. Distinguishability: yes. Ordering: no.
This is an overloaded version of string_agg for CLOB argument. See: clob_agg.sql.

**Specific function.** Since: Oracle 8. One-liner: yes. CLOB support: yes. Distinguishability: yes. Ordering: yes.
A PL/SQL function that performs additional query inside to retrieve aggregated string. Should be written again and again for every new query.

**Generic function.** Since: Oracle 8. One-liner: yes. CLOB support: yes. Distinguishability: yes. Ordering: yes.
A PL/SQL function that performs a *dynamic* query inside. Should be written once. But it cannot be performed on sophisticated query.
It takes table name and field name as arguments. It can be expanded to take varchar2 query as argument. This would lead to code duplication.
It is described in Tom Kyte's [blog][generic aggregation function].
[generic aggregation function]:https://asktom.oracle.com/pls/asktom/f?p=100:11:::::P11_QUESTION_ID:229614022562

**SYS_CONNECT_BY_PATH.** Since: Oracle 9. One-liner: no. CLOB support: no. Distinguishability: no. Ordering: yes.

**HIERARCHY.** Since: Oracle 9. One-liner: no. CLOB support: yes. Distinguishability: no. Ordering: yes.
A package with syntax similar to SYS_CONNECT_BY_PATH. See: [this thread][hierarchy package].
[hierarchy package]:https://community.oracle.com/thread/965324

**COLLECT.** Since: Oracle 10. One-liner: yes. CLOB support: yes for output, no for input. Distinguishability: no. Ordering: no.

**XMLAgg.** Since: Oracle 9. One-liner: yes, verbose. CLOB support: yes. Distinguishability: no. Ordering: yes.

So, there's no ideal method. But some disadvantages can be avoided.

Distinguishability.

1. It can be achieved by subquery with 'distinct' keyword.
2. Also, there's a regex solution described [here][distinct listagg]. But it requires input to be ordered lexicographically.
3. A comma-separated string can be splitted into values inside a PL/SQL procedure and then concatenated ignoring duplicates
(in linear time and memory using associative arrays).
[distinct listagg]:http://dba.stackexchange.com/questions/696/eliminate-duplicates-in-listagg-oracle

Ordering.

1. It can be achieved by subquery with ordering.
2. A lexicographical ordering can be performed inside PL/SQL procedure
by splitting comma-separated string, ordering and concatenating results back.

We cannot get results ordered by other query fields: only with a subquery or with a built-in syntax of aggregation function.
So, ideal candidate method should be one-liner with CLOB and ordering support. The only such method is XMLAgg.
How to add distinguishability to it?
```sql
select substr( replace( replace( XMLAgg( XMLElement( "elem", DUMMY ) ).getStringVal(), '</elem>' ), '<elem>', ', ' ), 3 ) from dual
```
This is a simple use case of XMLAgg. Let's add some ordering to it:
```sql
select substr( replace( replace( XMLAgg( XMLElement( "elem", DUMMY ) order by DUMMY ).getStringVal(), '</elem>' ), '<elem>', ', ' ), 3 ) from dual
```
Note that we can use other fields in order clause, not only the aggregated one. An example with distinguishability using p_utils package:
```sql
select substr( replace( replace( p_utils.distinguishXML( XMLAgg( XMLElement( "elem", DUMMY ) order by DUMMY ) ).getStringVal(), '</elem>' ), '<elem>', ', ' ), 3 ) from dual
```
p_utils.distinguishXML leaves only distinct XML nodes of the aggregated input. Then we get string value of it (or CLOB using getClobVal instead of getStringVal).
___
#Links to other packages from various authors
[XT_REGEXP] from Sayan Malakshinov aka XTender. This package lets using of Java regular expressions inside SQL.
Java regular expressions are more powerful than built-in functions regexp_substr, regexp_replace etc.
[XT_REGEXP]:https://github.com/xtender/XT_REGEXP
[STK] from Adrian Billington. This package provides call stack trace information. Useful for logging purposes.
[STK]:http://www.oracle-developer.net/content/utilities/stk.sql
[Hierarchy][hierarchy package] from Solomon Yakobson. This package contains methods analogous to SYS_CONNECT_BY_PATH for CLOB datatype.