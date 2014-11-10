create or replace package p_admin is

-- Kill a session specified by SID (V$SESSION).
procedure killSession( tSid in number );
-- Kill all sessions except system and a current one.
procedure killAllSessions;
-- Kill sessions of all users who are logged in with their accounts (OSUSER != SYSTEM).
procedure killDevelopersSessions;
-- Kill sessions of current user (OSUSER).
procedure killUserSessions;
-- Kill Test Window (PL/SQL Developer) sessions of current user (OSUSER).
procedure killUserTestSessions;
-- Kill a job (USER_JOBS) specified by identifier.
procedure killJob( tJob in number );
-- Kill a job if it's running and schedule it to launch at min( sysdate + tMax, max( sysdate + tMin, NEXT_DATE + tIncr ) ).
-- Default behavior: kill a job and schedule it to launch in 10 minutes.
procedure pauseJob( tJob in number, tMin in number default 1 / 144, tMax in number default null, tIncr in number default null );
-- Kill all jobs and schedule them to launch later.
procedure pauseAllJobs( tMin in number default 1 / 144, tMax in number default null, tIncr in number default null );
-- Kill jobs selected by a mask and schedule them to launch later.
procedure pauseJobsLike( tLikeCondition in varchar2, tMin in number default 1 / 144, tMax in number default null, tIncr in number default null, tJob in number default null );

end;
/
create or replace package body p_admin is

-- Kill a session specified by SID (V$SESSION).
procedure killSession( tSid in number ) is
  tSpidn number;
  tInstanceName varchar2( 16 );
begin
  select p.SPID
  into tSpidn
  from V$SESSION s,
       V$PROCESS p
  where s.SID = tSid
    and s.PADDR = p.ADDR
	and s.USERNAME = user;
  if dbms_utility.port_string like '%WIN%' then
    select INSTANCE_NAME
	into tInstanceName
	from V$INSTANCE;
    runCommand( 'orakill.exe ' || tInstanceName || ' ' || tSpidn );
  else
    runCommand( 'kill -9 ' || tSpidn );
  end if;
exception
  when NO_DATA_FOUND then
    null;
  when OTHERS then
    raise;
end;

-- Kill all sessions except system and a current one.
procedure killAllSessions is
  tAudSid number := sys_context( 'userenv', 'sessionid' );
begin
  for rec in ( select SID
               from V$SESSION
               where AUDSID not in ( 0, tAudSid )
                 and SCHEMANAME != 'SYS' ) loop
    killSession( rec.SID );
  end loop;
end;

-- Kill sessions of all users who are logged in with their accounts (OSUSER != SYSTEM).
procedure killDevelopersSessions is
  tAudSid number := sys_context( 'userenv', 'sessionid' );
begin
  for rec in ( select SID
               from V$SESSION
               where AUDSID not in ( 0, tAudSid )
                 and SCHEMANAME != 'SYS'
                 and OSUSER != 'SYSTEM' ) loop
    killSession( rec.SID );
  end loop;
end;

-- Kill sessions of current user (OSUSER).
procedure killUserSessions is
  tAudSid number := sys_context( 'userenv', 'sessionid' );
  tOsUser varchar2( 30 ) := sys_context( 'userenv', 'os_user' );
begin
  for rec in ( select SID
               from V$SESSION
               where AUDSID not in ( 0, tAudSid )
                 and SCHEMANAME != 'SYS'
                 and OSUSER = tOsUser ) loop
    killSession( rec.SID );
  end loop;
end;

-- Kill Test Window (PL/SQL Developer) sessions of current user (OSUSER).
procedure killUserTestSessions is
  tAudSid number := sys_context( 'userenv', 'sessionid' );
  tOsUser varchar2( 30 ) := sys_context( 'userenv', 'os_user' );
begin
  for rec in ( select SID
               from V$SESSION
               where AUDSID not in ( 0, tAudSid )
                 and SCHEMANAME != 'SYS'
                 and OSUSER = tOsUser
                 and lower( ACTION ) like '%test%' ) loop
    killSession( rec.SID );
  end loop;
end;

-- Kill a job (USER_JOBS) specified by identifier.
procedure killJob( tJob in number ) is
  tSid number;
begin
  select SID
  into tSid
  from V$LOCK
  where TYPE = 'JQ'
    and ID2 = tJob;
  killSession( tSid );
exception
  when NO_DATA_FOUND then
    raise_application_error( -20001, 'Job ' || job || ' is not running' );
  when OTHERS then
    raise;
end;

-- Kill a job if it's running and schedule it to launch at min( sysdate + tMax, max( sysdate + tMin, NEXT_DATE + tIncr ) ).
-- Default behavior: kill a job and schedule it to launch in 10 minutes.
procedure pauseJob( tJob in number, tMin in number default 1 / 144, tMax in number default null, tIncr in number default null ) is
begin
  pauseJobsLike( '%', tMin, tMax, tIncr, tJob );
end;

-- Kill all jobs and schedule them to launch later.
procedure pauseAllJobs( tMin in number default 1 / 144, tMax in number default null, tIncr in number default null ) is
begin
  pauseJobsLike( '%', tMin, tMax, tIncr );
end;

-- Kill jobs selected by a mask and schedule them to launch later.
procedure pauseJobsLike( tLikeCondition in varchar2, tMin in number default 1 / 144, tMax in number default null, tIncr in number default null, tJob in number default null ) is
  tRunning number( 1 );
  tNextDate date;
begin
  loop
    tRunning := 0;
    for rec in ( select JOB, WHAT, INTERVAL, NEXT_DATE
                 from USER_JOBS
                 where WHAT like tLikeCondition
                   and ( tJob is null
                         or JOB = tJob ) ) loop
      tNextDate := rec.NEXT_DATE + nvl( tIncr, 0 );
      if tMin is not null then
        tNextDate := greatest( tNextDate, sysdate + tMin );
      end if;
      if tMax is not null then
        tNextDate := least( tNextDate, sysdate + tMax );
      end if;
      begin
        dbms_job.change( job => rec.JOB,
                         what => rec.WHAT,
                         next_date => tNextDate,
                         interval => rec.INTERVAL );
        commit;
      exception
        when OTHERS then
          if sqlerrm not like '%PLS-00905%' then
            raise;
          end if;
      end;
      begin
        killJob( rec.JOB );
        tRunning := 1;
      exception
        when OTHERS then
          if sqlcode != -20001 then
            raise;
          end if;
      end;
    end loop;
    commit;
    exit when tRunning = 0;
    dbms_lock.sleep( 1 );
  end loop;
  commit;
end;

end;
/
