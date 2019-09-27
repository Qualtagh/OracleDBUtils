create or replace package p_stack authid current_user is

-- Returns a call stack. The call of this procedure is included and is at the first line.
-- tDepth: which line of stack to show. Lesser numbers are most recent calls. Numeration starts from 1.
-- The call of this procedure has depth = 1.
-- If tDepth is null then the whole stack is returned as a string where lines are delimited by "new line" symbol.
-- Output format: LINE || ': ' || OWNER || '.' || PROGRAM TYPE || [ ' ' || PROGRAM NAME ]? || [ '.' || SUBPROGRAM TYPE || ' ' || SUBPROGRAM NAME ]*
-- LINE is a source code line number as returned by dbms_utility.format_call_stack.
-- OWNER is an owner of program unit being called, or parsing schema name for anonymous blocks.
-- If the parsing schema name could not be retrieved then OWNER equals to current schema name.
-- PROGRAM TYPE is one of ANONYMOUS BLOCK, PACKAGE, PACKAGE BODY, TYPE BODY, TRIGGER, PROCEDURE, FUNCTION.
-- It's the type of outermost program unit.
-- PROGRAM NAME is the name of program unit being called as returned by dbms_utility.format_call_stack.
-- It's absent for anonymous blocks.
-- It's double quoted if the source code contains its name in double quotes.
-- SUBPROGRAM TYPE is one of PROCEDURE or FUNCTION.
-- It's the type of inner subprogram.
-- SUBPROGRAM NAME is the name of inner subprogram.
-- If there are several inner units then all of them are separated by dots.
function getCallStack( tDepth in number default null ) return varchar2;

-- Returns the stack information of a current program unit.
-- See output format description of function getCallStack.
function whoAmI return varchar2;

-- Returns the stack information of a program unit which has called currently executing code.
-- See output format description of function getCallStack.
function whoCalledMe return varchar2;

-- Returns one stack line at a given depth.
-- See output format description of function getCallStack.
-- tCallStack: information returned by getCallStack.
-- tDepth: number of requested line. If tDepth is out of bounds then null is returned.
function getCallStackLine( tCallStack in varchar2, tDepth in number ) return varchar2;

-- Returns current stack depth including the call of this function.
-- tCallStack: information returned by getCallStack. Can be omitted.
-- See: utl_call_stack.dynamic_depth
function getDynamicDepth( tCallStack in varchar2 default '' ) return number;

-- Returns a depth of a current program unit.
-- Stored procedures, functions, packages and their bodies, type bodies, triggers and anonymous blocks have a depth equal to 0.
-- Inner procedures and functions have depth equal to 1 + depth of parent program unit.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
-- See: utl_call_stack.lexical_depth
function getLexicalDepth( tCallStack in varchar2, tDepth in number default null ) return number;

-- Returns a source line number as returned by dbms_utility.format_call_stack.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
-- See: utl_call_stack.unit_line
function getUnitLine( tCallStack in varchar2, tDepth in number default null ) return number;

-- Returns owner of a requested program unit, or a parsing schema for an anonymous block.
-- If the parsing schema name could not be retrieved then OWNER equals to current schema name.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
-- See: utl_call_stack.owner
function getOwner( tCallStack in varchar2, tDepth in number default null ) return varchar2;

-- Returns name of a requested stored procedure. Empty string for anonymous block.
-- The name returned won't contain double quotes.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
function getProgram( tCallStack in varchar2, tDepth in number default null ) return varchar2;

-- Returns a type of a requested stored procedure. One of:
-- ANONYMOUS BLOCK, PROCEDURE, FUNCTION, TRIGGER, PACKAGE, PACKAGE BODY, TYPE BODY.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
function getProgramType( tCallStack in varchar2, tDepth in number default null ) return varchar2;

-- Returns a name of a requested innermost subprogram.
-- Example: package "outer" contains procedure "inner" which contains function "inner_function".
-- getCallStack and subsequent getSubprogram are called inside the function.
-- "inner_function" would be returned (without double quotes).
-- If getCallStack and getSubprogram are called inside package body then empty string is returned.
-- The name returned never contains double quotes.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
-- See: utl_call_stack.subprogram
function getSubprogram( tCallStack in varchar2, tDepth in number default null ) return varchar2;

-- Returns a type of requested innermost subprogram.
-- See example in getSubprogram describing the concept of innermost subprogram.
-- Value returned is one of PROCEDURE or FUNCTION.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
function getSubprogramType( tCallStack in varchar2, tDepth in number default null ) return varchar2;

-- Returns a table of names of requested subprograms.
-- Example: package "outer" contains procedure "inner" which contains function "inner_function".
-- getCallStack and subsequent getSubprograms are called inside the function.
-- An array [ "inner", "inner_function" ] would be returned (without double quotes).
-- If getCallStack and getSubprograms are called inside package body then an empty table is returned.
-- The names returned never contain double quotes.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
-- See: utl_call_stack.subprogram
function getSubprograms( tCallStack in varchar2, tDepth in number default null ) return str_table;

-- Returns a table of types of requested subprograms.
-- Example: package "outer" contains procedure "inner" which contains function "inner_function".
-- getCallStack and subsequent getSubprogramsTypes are called inside the function.
-- An array [ "PROCEDURE", "FUNCTION" ] would be returned (without double quotes).
-- If getCallStack and getSubprogramsTypes are called inside package body then an empty table is returned.
-- Each value in the returned array is one of PROCEDURE or FUNCTION.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
function getSubprogramsTypes( tCallStack in varchar2, tDepth in number default null ) return str_table;

-- Returns the hierarchy of names separated by dot from outermost to innermost program unit.
-- Example: package "outer" contains procedure "inner" which contains function "inner_function".
-- getCallStack and subsequent getSubprogram are called inside the function.
-- "outer.inner.inner_function" would be returned (without double quotes).
-- If one of program units in this hierarchy has double quotes in its name, they would be preserved.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
-- See: utl_call_stack.concatenate_subprogram
function getConcatenatedSubprograms( tCallStack in varchar2, tDepth in number default null ) return varchar2;

-- Returns an error stack as a string.
-- tDepth: number of requested stack line. Lesser numbers are most recent errors. Numeration starts from 1.
-- If omitted then the full stack is concatenated via newline character.
-- The full stack output equals to dbms_utility.format_call_stack.
-- See: dbms_utility.format_call_stack
function getErrorStack( tDepth in number default null ) return varchar2;

-- Returns current error stack depth.
-- tErrorStack: information returned by getErrorStack. Can be omitted.
-- See: utl_call_stack.error_depth
function getErrorDepth( tErrorStack in varchar2 default '' ) return number;

-- Returns error code at a given depth.
-- tErrorStack: information returned by getErrorStack.
-- tDepth: number of requested stack line if tErrorStack = getErrorStack, null otherwise.
-- See: utl_call_stack.error_number
function getErrorCode( tErrorStack in varchar2, tDepth in number default null ) return number;

-- Returns error message at a given depth.
-- tErrorStack: information returned by getErrorStack.
-- tDepth: number of requested stack line if tErrorStack = getErrorStack, null otherwise.
-- See: utl_call_stack.error_msg
function getErrorMessage( tErrorStack in varchar2, tDepth in number default null ) return varchar2;

-- Returns a backtrace stack as a string.
-- It shows program units and line numbers where the last error has occurred.
-- The output format is the same as in getCallStack.
-- See getCallStack documentation to get more information about the output format.
-- tDepth: number of requested stack line. Lesser numbers are most recent calls. Numeration starts from 1.
-- The order equals to the order returned by dbms_utility.format_error_backtrace.
-- Also, the order equals to the order returned by getCallStack.
-- But it doesn't equal to the order returned by utl_call_stack.backtrace_unit which is reversed.
-- If tDepth is omitted then the full stack is concatenated via newline character.
-- See: dbms_utility.format_error_backtrace
function getBacktraceStack( tDepth in number default null ) return varchar2;

-- Returns backtrace stack depth.
-- tBacktraceStack: information returned by getBacktraceStack. Can be omitted.
-- See: utl_call_stack.backtrace_depth
function getBacktraceDepth( tBacktraceStack in varchar2 default '' ) return number;

end;
/
create or replace package body p_stack is

CHAR_BACKSPACE constant char := owa.BS_CHAR; -- chr( 8 );
CHAR_TAB constant char := owa.HT_CHAR; -- chr( 9 );
CHAR_NEW_LINE constant char := owa.NL_CHAR; -- chr( 10 );
CHAR_CARRIAGE_RETURN constant char := chr( 13 );
UNKNOWN_OWNER constant varchar2( 4 ) := 'NULL';
PACKAGE_NAME constant varchar2( 7 ) := 'P_STACK';
SOURCE_CURSOR constant pls_integer := 0;
SOURCE_CLOB constant pls_integer := 1;
SOURCE_PREPROCESSOR constant pls_integer := 2;

cursor getSource( tOwner in varchar2, tName in varchar2, tType in varchar2, tLine in number ) is
  select TEXT, LINE
  from ALL_SOURCE
  where OWNER = tOwner
    and NAME = tName
    and TYPE = tType
    and LINE <= tLine
  order by LINE;

-- Retrieves info from one line of dbms_utility.format_call_stack output
-- tCallPositionsLine: one line of dbms_utility.format_call_stack output
-- tHandle: CHILD_ADDRESS of source code in V$SQL view
-- tLine: line number in source code
-- tType: program type (see available values in getProgramType description)
-- tOwner: schema of stored procedure
-- tName: name of stored procedure
-- Private function.
procedure parseCallStackLine( tCallPositionsLine in varchar2, tHandle out raw, tLine out number, tType out varchar2, tOwner out varchar2, tName out varchar2 ) is
  pos pls_integer;
  tCallLine varchar2( 255 ) := tCallPositionsLine;
begin
  pos := instr( tCallLine, ' ' );
  if pos > 0 then
    tHandle := hextoraw( lpad( replace( substr( tCallLine, 1, pos - 1 ), '0x', '' ), 16, '0' ) );
    tCallLine := ltrim( substr( tCallLine, pos ) );
  else
    tHandle := null;
  end if;
  pos := instr( tCallLine, ' ' );
  if pos > 0 then
    tLine := to_number( substr( tCallLine, 1, pos - 1 ) );
    tCallLine := ltrim( substr( tCallLine, pos ) );
  else
    tLine := null;
  end if;
  tType := case substr( tCallLine, 1, 3 )
             when 'pro' then 'PROCEDURE'
             when 'fun' then 'FUNCTION'
             when 'tri' then 'TRIGGER'
             when 'typ' then 'TYPE BODY'
             when 'pac' then case when tCallLine like 'package body%' then 'PACKAGE BODY' else 'PACKAGE' end
             else 'ANONYMOUS BLOCK'
           end;
  tCallLine := substr( tCallLine, length( tType ) + 2 );
  pos := instr( tCallLine, '.' );
  if pos > 0 then
    tOwner := substr( tCallLine, 1, pos - 1 );
    tName := substr( tCallLine, pos + 1 );
  else
    tOwner := '';
    tName := '';
  end if;
end;

-- A private method for parsing an input in format of dbms_utility.format_call_stack.
-- Used in getCallStack and getBacktraceStack.
function getCallStack( tFormatCallStack in varchar2, tDepth in number default null ) return varchar2 is
  tCallPositions varchar2( 4000 );
  tCallPositionsLine varchar2( 255 );
  tReached pls_integer;
  tHandle raw( 16 );
  tOwner varchar2( 255 );
  tName varchar2( 255 );
  tLine number;
  tCurrentLine number;
  tType varchar2( 255 );
  tSourceType pls_integer;
  tPreprocessed dbms_preprocessor.source_lines_t;
  tSqlFullText clob;
  s varchar2( 4000 );
  t varchar2( 4000 );
  c char;
  pos pls_integer;
  len pls_integer;
  tCommented pls_integer;
  tIdentifier pls_integer;
  tIdentifierName varchar2( 30 );
  tIdentifiers dbms_sql.varchar2_table;
  tMaxIdentifier pls_integer;
  tQuoteDelimiter char;
  tString pls_integer;
  tToken varchar2( 4000 );
  tTokenType pls_integer;
  tPreviousTokenType pls_integer;
  tTokensQueue str_table;
  tCallStack str_table;
  tLast pls_integer;
  tLookForDefinition pls_integer;
  tPrevToken varchar2( 4000 );
  tPrevPrevToken varchar2( 4000 );
  tCallStackLine varchar2( 4000 );
  ret varchar2( 4000 );
begin
  tCallPositions := tFormatCallStack;
  tReached := 0;
  loop
    pos := instr( tCallPositions, CHAR_NEW_LINE );
    exit when pos is null or pos = 0;
    tCallPositionsLine := substr( tCallPositions, 1, pos - 1 );
    tCallPositions := substr( tCallPositions, pos + 1 );
    if tReached = 0 or tDepth != tReached then
      goto NEXT_CALL_POSITION;
    end if;
    parseCallStackLine( tCallPositionsLine, tHandle, tLine, tType, tOwner, tName );
    tSourceType := case when tType = 'ANONYMOUS BLOCK' then SOURCE_CLOB else SOURCE_CURSOR end;
    tCommented := 0;
    tIdentifier := 0;
    tString := 0;
    tMaxIdentifier := 0;
    tQuoteDelimiter := null;
    tLookForDefinition := 0;
    tIdentifiers.delete;
    tTokensQueue := str_table( '', '', '' );
    if tSourceType = SOURCE_CURSOR then
      begin
        select SOURCE_PREPROCESSOR
        into tSourceType
        from ALL_SOURCE
        where OWNER = tOwner
          and NAME = tName
          and TYPE = tType
          and LINE <= tLine
          and TEXT like '%$%'
          and rownum = 1;
        tPreprocessed := dbms_preprocessor.get_post_processed_source( tType, tOwner, tName );
        tCurrentLine := 0;
      exception
        when NO_DATA_FOUND then
          if getSource%isopen then
            close getSource;
          end if;
          open getSource( tOwner, tName, tType, tLine );
      end;
      tCallStack := str_table( '' );
    else
      if tHandle is null then
        tSqlFullText := null;
      else
        begin
          select SQL_FULLTEXT, PARSING_SCHEMA_NAME
          into tSqlFullText, tOwner
          from V$SQL
          where CHILD_ADDRESS = tHandle;
        exception
          when NO_DATA_FOUND then
            tSqlFullText := null;
        end;
      end if;
      tCurrentLine := 0;
      tCallStack := str_table( '', 'ANON' );
      if tSqlFullText like '%$%' then
        tSourceType := SOURCE_PREPROCESSOR;
        loop
          pos := instr( tSqlFullText, CHAR_NEW_LINE );
          if pos > 0 then
            s := substr( tSqlFullText, 1, pos );
            tSqlFullText := substr( tSqlFullText, pos + 1 );
          elsif pos = 0 then
            s := tSqlFullText;
            tSqlFullText := null;
          else
            exit;
          end if;
          tCurrentLine := tCurrentLine + 1;
          tPreprocessed( tCurrentLine ) := s;
        end loop;
        tCurrentLine := 0;
        tPreprocessed := dbms_preprocessor.get_post_processed_source( tPreprocessed );
      end if;
    end if;
    loop
      if tSourceType = SOURCE_CURSOR then
        fetch getSource into s, tCurrentLine;
        exit when getSource%notfound;
      elsif tSourceType = SOURCE_CLOB then
        exit when tCurrentLine = tLine;
        pos := instr( tSqlFullText, CHAR_NEW_LINE );
        if pos > 0 then
          s := substr( tSqlFullText, 1, pos - 1 );
          tSqlFullText := substr( tSqlFullText, pos + 1 );
        elsif pos = 0 then
          s := tSqlFullText;
          tSqlFullText := null;
        else
          exit;
        end if;
        tCurrentLine := tCurrentLine + 1;
      else
        exit when tCurrentLine = tLine;
        tCurrentLine := tCurrentLine + 1;
        s := tPreprocessed( tCurrentLine );
      end if;
      t := '';
      len := length( s );
      if len is null then
        goto NEXT_LINE;
      end if;
      pos := 1;
      loop
        c := substr( s, pos, 1 );
        if tCommented = 1 then
          case c
            when '*' then
              if substr( s, pos + 1, 1 ) = '/' then
                pos := pos + 1;
                tCommented := 0;
              end if;
            else
              null;
          end case;
          goto NEXT_CHAR;
        end if;
        if tIdentifier = 1 then
          case c
            when '"' then
              tIdentifier := 0;
              tMaxIdentifier := tMaxIdentifier + 1;
              while upper( s ) like '%ID' || tMaxIdentifier || '%' loop
                tMaxIdentifier := tMaxIdentifier + 1;
              end loop;
              tIdentifiers( tMaxIdentifier ) := tIdentifierName;
              t := t || 'ID' || tMaxIdentifier || ' ';
              tIdentifierName := '';
            else
              tIdentifierName := tIdentifierName || c;
          end case;
          goto NEXT_CHAR;
        end if;
        if tString = 1 then
          if tQuoteDelimiter is null then
            if c = '''' then
              if substr( s, pos + 1, 1 ) = '''' then
                pos := pos + 1;
              else
                tString := 0;
              end if;
            end if;
          elsif c = tQuoteDelimiter then
            if substr( s, pos + 1, 1 ) = '''' then
              tString := 0;
              tQuoteDelimiter := null;
              pos := pos + 1;
            end if;
          end if;
          goto NEXT_CHAR;
        end if;
        c := upper( c );
        case c
          when '/' then
            if substr( s, pos + 1, 1 ) = '*' then
              pos := pos + 1;
              tCommented := 1;
              c := ' ';
            end if;
          when '-' then
            if substr( s, pos + 1, 1 ) = '-' then
              goto NEXT_LINE;
            end if;
          when '"' then
            tIdentifier := 1;
            c := ' ';
          when 'N' then
            case upper( substr( s, pos + 1, 1 ) )
              when 'Q' then
                if substr( s, pos + 2, 1 ) = '''' then
                  tQuoteDelimiter := substr( s, pos + 3, 1 );
                  tQuoteDelimiter := case tQuoteDelimiter when '(' then ')' when '[' then ']' when '<' then '>' when '{' then '}' else tQuoteDelimiter end;
                  tString := 1;
                  pos := pos + 3;
                  t := t || ' STRING ';
                  goto NEXT_CHAR;
                end if;
              when '''' then
                tString := 1;
                pos := pos + 1;
                t := t || ' STRING ';
                goto NEXT_CHAR;
              else
                null;
            end case;
          when 'Q' then
            if substr( s, pos + 1, 1 ) = '''' then
              tQuoteDelimiter := substr( s, pos + 2, 1 );
              tQuoteDelimiter := case tQuoteDelimiter when '(' then ')' when '[' then ']' when '<' then '>' when '{' then '}' else tQuoteDelimiter end;
              tString := 1;
              pos := pos + 2;
              t := t || ' STRING ';
              goto NEXT_CHAR;
            end if;
          when '''' then
            tString := 1;
            t := t || ' STRING ';
            goto NEXT_CHAR;
          else
            null;
        end case;
        t := t || c;
        <<NEXT_CHAR>>
        pos := pos + 1;
        exit when pos > len;
      end loop;
      <<NEXT_LINE>>
      s := t;
      len := length( s );
      if len is not null then
        tToken := '';
        pos := 1;
        tPreviousTokenType := 3;
        loop
          if pos > len then
            tTokenType := 3;
          else
            c := substr( s, pos, 1 );
            tTokenType := case
                            when c = '$'
                              or c = '_'
                              or c = '#'
                              or c between '0' and '9'
                              or c between 'A' and 'Z'
                            then 1
                            when c = ';'
                            then 2
                            when c = ' '
                              or c = CHAR_BACKSPACE
                              or c = CHAR_TAB
                              or c = CHAR_NEW_LINE
                              or c = CHAR_CARRIAGE_RETURN
                            then 3
                            else 4
                          end;
          end if;
          if tTokenType != tPreviousTokenType then
            if tPreviousTokenType != 3 then
              tTokensQueue.delete( tTokensQueue.first );
              tTokensQueue.extend;
              tLast := tTokensQueue.last;
              tTokensQueue( tLast ) := tToken;
              exit when tCurrentLine = tLine and tToken = PACKAGE_NAME;
              tPrevToken := tTokensQueue( tLast - 1 );
              tPrevPrevToken := tTokensQueue( tLast - 2 );
              if tToken = 'CASE' then
                if tPrevToken in ( '>>', ';', 'BEGIN', 'LOOP' )
                  or tPrevToken in ( 'ELSE', 'THEN' ) and tCallStack( tCallStack.count ) in ( 'IF', 'CASEBLOCK' ) then
                  tCallStack.extend;
                  tCallStack( tCallStack.count ) := 'CASEBLOCK';
                elsif tPrevToken is null or tPrevToken != 'END' then
                  tCallStack.extend;
                  tCallStack( tCallStack.count ) := 'CASEEXPR';
                end if;
              elsif tToken = 'LOOP' then
                if tPrevToken is null or tPrevToken != 'END' then
                  tCallStack.extend;
                  tCallStack( tCallStack.count ) := 'LOOP';
                end if;
              elsif tToken = 'IF' then
                if tPrevToken in ( '>>', 'THEN', 'ELSE', ';', 'BEGIN', 'LOOP' ) then
                  tCallStack.extend;
                  tCallStack( tCallStack.count ) := 'IF';
                end if;
              elsif tToken = 'BEGIN' then
                if tPrevToken in ( '>>', 'THEN', 'ELSE', ';', 'IS', 'AS', 'BEGIN', 'LOOP' ) then
                  if tCallStack( tCallStack.count ) like '-%' then
                    tCallStack( tCallStack.count ) := '+' || substr( tCallStack( tCallStack.count ), 2 );
                  else
                    tCallStack.extend;
                    tCallStack( tCallStack.count ) := 'BEGIN';
                  end if;
                end if;
              elsif tToken = ';' then
                if tLookForDefinition = 1 then
                  tCallStack.trim;
                  tLookForDefinition := 0;
                elsif tPrevPrevToken = 'END' and tPrevToken in ( 'IF', 'LOOP', 'CASE' ) then
                  case tPrevToken
                    when 'IF' then
                      if tCallStack( tCallStack.count ) = 'IF' then
                        tCallStack.trim;
                      end if;
                    when 'LOOP' then
                      if tCallStack( tCallStack.count ) = 'LOOP' then
                        tCallStack.trim;
                      end if;
                    else
                      if tCallStack( tCallStack.count ) = 'CASEBLOCK' then
                        tCallStack.trim;
                      end if;
                  end case;
                elsif tPrevPrevToken = 'END' or tPrevToken = 'END' then
                  if tCallStack( tCallStack.count ) like '+%' then
                    tCallStack.trim;
                  elsif tPrevToken = 'END' then
                    if tCallStack( tCallStack.count ) in ( 'BEGIN', 'CASEEXPR' ) then
                      tCallStack.trim;
                    end if;
                  end if;
                end if;
              elsif tPrevToken = 'END' then
                if tCallStack( tCallStack.count ) = 'CASEEXPR' then
                  tCallStack.trim;
                end if;
              elsif tPrevToken in ( 'TRIGGER', 'FUNCTION', 'PROCEDURE' )
                or tPrevToken = 'PACKAGE' and tToken != 'BODY'
                or tPrevToken = 'BODY' and tPrevPrevToken in ( 'PACKAGE', 'TYPE' ) then
                if tPrevToken in ( 'FUNCTION', 'PROCEDURE' ) then
                  tLookForDefinition := 1;
                end if;
                tCallStack.extend;
                tCallStack( tCallStack.count ) := case
                                                    when tPrevToken = 'TRIGGER' then '-TRI'
                                                    when tPrevToken = 'FUNCTION' then '-FUN'
                                                    when tPrevToken = 'PROCEDURE' then '-PRO'
                                                    when tPrevToken = 'PACKAGE' then '-PAC'
                                                    when tPrevPrevToken = 'PACKAGE' then '-PCB'
                                                    else '-TYP'
                                                  end || tToken;
              end if;
              if tLookForDefinition = 1 and tPrevToken in ( 'IS', 'AS' ) and tToken not in ( 'NOT', 'NULL', 'LANGUAGE' ) then
                tLookForDefinition := 0;
              end if;
            end if;
            tToken := '';
          end if;
          tToken := tToken || c;
          tPreviousTokenType := tTokenType;
          <<NEXT_TOKEN_CHAR>>
          pos := pos + 1;
          exit when pos > len + 1;
        end loop;
      end if;
    end loop;
    if tSourceType = SOURCE_CURSOR then
      close getSource;
    end if;
    tCallStackLine := '';
    for i in 2 .. tCallStack.count loop
      tToken := case substr( tCallStack( i ), 2, 3 )
                  when 'TRI' then 'TRIGGER '
                  when 'FUN' then 'FUNCTION '
                  when 'PRO' then 'PROCEDURE '
                  when 'PAC' then 'PACKAGE '
                  when 'PCB' then 'PACKAGE BODY '
                  when 'TYP' then 'TYPE BODY '
                  when 'NON' then 'ANONYMOUS BLOCK'
                end;
      if tToken is not null then
        if tCallStackLine is not null then
          tCallStackLine := tCallStackLine || '.';
        end if;
        tCallStackLine := tCallStackLine || tToken;
        tToken := substr( tCallStack( i ), 5 );
        if tToken like 'ID%' and tIdentifiers.exists( to_number( substr( tToken, 3 ) ) ) then
          tToken := '"' || tIdentifiers( to_number( substr( tToken, 3 ) ) ) || '"';
        end if;
        tCallStackLine := tCallStackLine || tToken;
      end if;
    end loop;
    if ret is not null then
      ret := ret || CHAR_NEW_LINE;
    end if;
    if tOwner is null then
      tOwner := user; -- UNKNOWN_OWNER;
    end if;
    ret := ret || tLine || ': ' || tOwner || '.' || tCallStackLine;
    exit when tDepth = tReached;
    <<NEXT_CALL_POSITION>>
    if tReached > 0 then
      tReached := tReached + 1;
    elsif tCallPositionsLine like '%handle%number%name%' then
      tReached := 1;
    end if;
  end loop;
  return ret;
end;

-- Returns a call stack. The call of this procedure is included and is at the first line.
-- tDepth: which line of stack to show. Lesser numbers are most recent calls. Numeration starts from 1.
-- The call of this procedure has depth = 1.
-- If tDepth is null then the whole stack is returned as a string where lines are delimited by "new line" symbol.
-- Output format: LINE || ': ' || OWNER || '.' || PROGRAM TYPE || [ ' ' || PROGRAM NAME ]? || [ '.' || SUBPROGRAM TYPE || ' ' || SUBPROGRAM NAME ]*
-- LINE is a source code line number as returned by dbms_utility.format_call_stack.
-- OWNER is an owner of program unit being called, or parsing schema name for anonymous blocks.
-- If the parsing schema name could not be retrieved then OWNER equals to current schema name.
-- PROGRAM TYPE is one of ANONYMOUS BLOCK, PACKAGE, PACKAGE BODY, TYPE BODY, TRIGGER, PROCEDURE, FUNCTION.
-- It's the type of outermost program unit.
-- PROGRAM NAME is the name of program unit being called as returned by dbms_utility.format_call_stack.
-- It's absent for anonymous blocks.
-- It's double quoted if the source code contains its name in double quotes.
-- SUBPROGRAM TYPE is one of PROCEDURE or FUNCTION.
-- It's the type of inner subprogram.
-- SUBPROGRAM NAME is the name of inner subprogram.
-- If there are several inner units then all of them are separated by dots.
function getCallStack( tDepth in number default null ) return varchar2 is
begin
  return getCallStack( dbms_utility.format_call_stack, tDepth );
end;

-- Returns the stack information of a current program unit.
-- See output format description of function getCallStack.
function whoAmI return varchar2 is
begin
  return getCallStack( 3 );
end;

-- Returns the stack information of a program unit which has called currently executing code.
-- See output format description of function getCallStack.
function whoCalledMe return varchar2 is
begin
  return getCallStack( 4 );
end;

-- Returns one stack line at a given depth.
-- See output format description of function getCallStack.
-- tCallStack: information returned by getCallStack.
-- tDepth: number of requested line. If tDepth is out of bounds then null is returned.
function getCallStackLine( tCallStack in varchar2, tDepth in number ) return varchar2 is
  pos pls_integer;
  depth pls_integer;
  tCallLine varchar2( 4000 ) := tCallStack;
begin
  if tDepth is null or tDepth <= 0 or tDepth > 4000 then
    return '';
  end if;
  depth := 1;
  loop
    pos := instr( tCallLine, CHAR_NEW_LINE );
    if pos is null or pos = 0 then
      return case when tDepth = depth then tCallLine end;
    elsif tDepth = depth then
      return substr( tCallLine, 1, pos - 1 );
    elsif tDepth < depth then
      return '';
    else
      tCallLine := substr( tCallLine, pos + 1 );
      depth := depth + 1;
    end if;
  end loop;
end;

-- Returns current stack depth including the call of this function.
-- tCallStack: information returned by getCallStack. Can be omitted.
-- See: utl_call_stack.dynamic_depth
function getDynamicDepth( tCallStack in varchar2 default '' ) return number is
  tCallPositions varchar2( 4000 );
begin
  if tCallStack is null then
    $if not dbms_db_version.ver_le_10 $then
      $if not dbms_db_version.ver_le_11 $then
        return utl_call_stack.dynamic_depth;
      $end
    $end
    tCallPositions := dbms_utility.format_call_stack;
    return greatest( nvl( length( tCallPositions ) - length( replace( tCallPositions, CHAR_NEW_LINE ) ) - 3, 0 ), 0 );
  else
    return greatest( nvl( length( tCallStack ) - length( replace( tCallStack, CHAR_NEW_LINE ) ) + 1, 0 ), 0 );
  end if;
end;

-- Returns a depth of a current program unit.
-- Stored procedures, functions, packages and their bodies, type bodies, triggers and anonymous blocks have a depth equal to 0.
-- Inner procedures and functions have depth equal to 1 + depth of parent program unit.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
-- See: utl_call_stack.lexical_depth
function getLexicalDepth( tCallStack in varchar2, tDepth in number default null ) return number is
  tCallLine varchar2( 4000 ) := case when tDepth is null then tCallStack else getCallStackLine( tCallStack, tDepth ) end;
begin
  if tCallLine like '%"%' then
    tCallLine := regexp_replace( tCallLine, '"[^"]*"' );
  end if;
  return greatest( nvl( length( tCallLine ) - length( replace( tCallLine, '.' ) ) - 1, 0 ), 0 );
end;

-- Returns a source line number as returned by dbms_utility.format_call_stack.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
-- See: utl_call_stack.unit_line
function getUnitLine( tCallStack in varchar2, tDepth in number default null ) return number is
  tCallLine varchar2( 4000 ) := case when tDepth is null then tCallStack else getCallStackLine( tCallStack, tDepth ) end;
  pos pls_integer;
begin
  pos := instr( tCallLine, ':' );
  if pos is null or pos = 0 then
    return null;
  end if;
  return to_number( substr( tCallLine, 1, pos - 1 ) );
end;

-- Returns owner of a requested program unit, or a parsing schema for an anonymous block.
-- If the parsing schema name could not be retrieved then OWNER equals to current schema name.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
-- See: utl_call_stack.owner
function getOwner( tCallStack in varchar2, tDepth in number default null ) return varchar2 is
  tCallLine varchar2( 4000 ) := case when tDepth is null then tCallStack else getCallStackLine( tCallStack, tDepth ) end;
  pos pls_integer;
begin
  pos := instr( tCallLine, ':' );
  if pos > 0 then
    tCallLine := substr( tCallLine, pos + 2 );
  end if;
  pos := instr( tCallLine, '.' );
  if pos > 0 then
    return nullif( substr( tCallLine, 1, pos - 1 ), UNKNOWN_OWNER );
  end if;
  return '';
end;

-- Returns name of a requested stored procedure. Empty string for anonymous block.
-- The name returned won't contain double quotes.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
function getProgram( tCallStack in varchar2, tDepth in number default null ) return varchar2 is
  tCallLine varchar2( 4000 ) := case when tDepth is null then tCallStack else getCallStackLine( tCallStack, tDepth ) end;
  pos pls_integer;
  posTo pls_integer;
begin
  pos := instr( tCallLine, '.' );
  if pos > 0 then
    tCallLine := substr( tCallLine, pos + 1 );
  end if;
  posTo := nvl( instr( tCallLine, '.' ), 0 );
  if posTo = 0 then
    posTo := length( tCallLine ) + 1;
  end if;
  pos := nvl( instr( tCallLine, '"' ), 0 );
  if posTo > pos and pos > 0 then
    posTo := nvl( instr( tCallLine, '"', pos + 1 ), posTo );
  elsif tCallLine like 'ANON%' then
    pos := length( 'ANONYMOUS BLOCK' );
  elsif tCallLine like 'PROC%' then
    pos := length( 'PROCEDURE ' );
  elsif tCallLine like 'FUNC%' then
    pos := length( 'FUNCTION ' );
  elsif tCallLine like 'TRIG%' then
    pos := length( 'TRIGGER ' );
  elsif tCallLine like 'TYPE%' then
    pos := length( 'TYPE BODY ' );
  elsif tCallLine like 'PACKAGE B%' then
    pos := length( 'PACKAGE BODY ' );
  else
    pos := length( 'PACKAGE ' );
  end if;
  return substr( tCallLine, pos + 1, posTo - pos - 1 );
end;

-- Returns a type of a requested stored procedure. One of:
-- ANONYMOUS BLOCK, PROCEDURE, FUNCTION, TRIGGER, PACKAGE, PACKAGE BODY, TYPE BODY.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
function getProgramType( tCallStack in varchar2, tDepth in number default null ) return varchar2 is
  tCallLine varchar2( 4000 ) := case when tDepth is null then tCallStack else getCallStackLine( tCallStack, tDepth ) end;
  pos pls_integer;
begin
  pos := instr( tCallLine, '.' );
  if pos > 0 then
    tCallLine := substr( tCallLine, pos + 1 );
  end if;
  if tCallLine like 'ANON%' then
    return 'ANONYMOUS BLOCK';
  elsif tCallLine like 'PROC%' then
    return 'PROCEDURE';
  elsif tCallLine like 'FUNC%' then
    return 'FUNCTION';
  elsif tCallLine like 'TRIG%' then
    return 'TRIGGER';
  elsif tCallLine like 'TYPE%' then
    return 'TYPE BODY';
  elsif tCallLine like 'PACKAGE B%' then
    return 'PACKAGE BODY';
  else
    return 'PACKAGE';
  end if;
end;

-- Returns a name of a requested innermost subprogram.
-- Example: package "outer" contains procedure "inner" which contains function "inner_function".
-- getCallStack and subsequent getSubprogram are called inside the function.
-- "inner_function" would be returned (without double quotes).
-- If getCallStack and getSubprogram are called inside package body then empty string is returned.
-- The name returned never contains double quotes.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
-- See: utl_call_stack.subprogram
function getSubprogram( tCallStack in varchar2, tDepth in number default null ) return varchar2 is
  tCallLine varchar2( 4000 ) := case when tDepth is null then tCallStack else getCallStackLine( tCallStack, tDepth ) end;
  pos pls_integer;
begin
  if getLexicalDepth( tCallLine ) = 0 then
    return '';
  end if;
  if tCallLine like '%"' then
    pos := instr( tCallLine, '"', -2 );
    return substr( tCallLine, pos + 1, length( tCallLine ) - pos - 1 );
  elsif tCallLine like '%.ANONYMOUS BLOCK' then
    return '';
  else
    pos := instr( tCallLine, ' ', -1 );
    return substr( tCallLine, pos + 1 );
  end if;
end;

-- Returns a type of requested innermost subprogram.
-- See example in getSubprogram describing the concept of innermost subprogram.
-- Value returned is one of PROCEDURE or FUNCTION.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
function getSubprogramType( tCallStack in varchar2, tDepth in number default null ) return varchar2 is
  tCallLine varchar2( 4000 ) := case when tDepth is null then tCallStack else getCallStackLine( tCallStack, tDepth ) end;
  pos pls_integer;
begin
  if tCallLine like '%"' then
    pos := instr( tCallLine, '"', -2 ) - 2;
  elsif tCallLine like '%.ANONYMOUS BLOCK' then
    pos := length( tCallLine );
  else
    pos := instr( tCallLine, ' ', -1 ) - 1;
  end if;
  tCallLine := substr( tCallLine, 1, pos );
  pos := instr( tCallLine, '.', -1 );
  return substr( tCallLine, pos + 1 );
end;

-- Returns a table of names of requested subprograms.
-- Example: package "outer" contains procedure "inner" which contains function "inner_function".
-- getCallStack and subsequent getSubprograms are called inside the function.
-- An array [ "inner", "inner_function" ] would be returned (without double quotes).
-- If getCallStack and getSubprograms are called inside package body then an empty table is returned.
-- The names returned never contain double quotes.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
-- See: utl_call_stack.subprogram
function getSubprograms( tCallStack in varchar2, tDepth in number default null ) return str_table is
  tCallLine varchar2( 4000 ) := case when tDepth is null then tCallStack else getCallStackLine( tCallStack, tDepth ) end;
  pos pls_integer;
  dqpos pls_integer;
  tLexicalDepth pls_integer;
  tSubprogram varchar2( 4000 );
  ret str_table := str_table();
begin
  if getLexicalDepth( tCallLine ) = 0 then
    return ret;
  end if;
  tLexicalDepth := 0;
  loop
    dqpos := instr( tCallLine, '"' );
    pos := instr( tCallLine, '.' );
    if dqpos > 0 and dqpos < pos then
      dqpos := instr( tCallLine, '"', dqpos + 1 );
      while pos > 0 and pos < dqpos loop
        pos := instr( tCallLine, '.', pos + 1 );
      end loop;
    end if;
    if tLexicalDepth >= 2 then
      if pos > 0 then
        tSubprogram := substr( tCallLine, 1, pos - 1 );
      else
        tSubprogram := tCallLine;
      end if;
      if tSubprogram like 'FUNCTION %' then
        tSubprogram := substr( tSubprogram, 10 );
      elsif tSubprogram like 'PROCEDURE %' then
        tSubprogram := substr( tSubprogram, 11 );
      end if;
      if tSubprogram like '%"%' then
        tSubprogram := translate( tSubprogram, ' "', ' ' );
      end if;
      ret.extend;
      ret( ret.count ) := tSubprogram;
    end if;
    if pos > 0 then
      tCallLine := substr( tCallLine, pos + 1 );
      tLexicalDepth := tLexicalDepth + 1;
    else
      exit;
    end if;
  end loop;
  return ret;
end;

-- Returns a table of types of requested subprograms.
-- Example: package "outer" contains procedure "inner" which contains function "inner_function".
-- getCallStack and subsequent getSubprogramsTypes are called inside the function.
-- An array [ "PROCEDURE", "FUNCTION" ] would be returned (without double quotes).
-- If getCallStack and getSubprogramsTypes are called inside package body then an empty table is returned.
-- Each value in the returned array is one of PROCEDURE or FUNCTION.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
function getSubprogramsTypes( tCallStack in varchar2, tDepth in number default null ) return str_table is
  tCallLine varchar2( 4000 ) := case when tDepth is null then tCallStack else getCallStackLine( tCallStack, tDepth ) end;
  pos pls_integer;
  dqpos pls_integer;
  tLexicalDepth pls_integer;
  tSubprogram varchar2( 4000 );
  ret str_table := str_table();
begin
  if getLexicalDepth( tCallLine ) = 0 then
    return ret;
  end if;
  tLexicalDepth := 0;
  loop
    dqpos := instr( tCallLine, '"' );
    pos := instr( tCallLine, '.' );
    if dqpos > 0 and dqpos < pos then
      dqpos := instr( tCallLine, '"', dqpos + 1 );
      while pos > 0 and pos < dqpos loop
        pos := instr( tCallLine, '.', pos + 1 );
      end loop;
    end if;
    if tLexicalDepth >= 2 then
      if pos > 0 then
        tSubprogram := substr( tCallLine, 1, pos - 1 );
      else
        tSubprogram := tCallLine;
      end if;
      ret.extend;
      if tSubprogram like 'FUNCTION %' then
        ret( ret.count ) := 'FUNCTION';
      elsif tSubprogram like 'PROCEDURE %' then
        ret( ret.count ) := 'PROCEDURE';
      end if;
    end if;
    if pos > 0 then
      tCallLine := substr( tCallLine, pos + 1 );
      tLexicalDepth := tLexicalDepth + 1;
    else
      exit;
    end if;
  end loop;
  return ret;
end;

-- Returns the hierarchy of names separated by dot from outermost to innermost program unit.
-- Example: package "outer" contains procedure "inner" which contains function "inner_function".
-- getCallStack and subsequent getSubprogram are called inside the function.
-- "outer.inner.inner_function" would be returned (without double quotes).
-- If one of program units in this hierarchy has double quotes in its name, they would be preserved.
-- tCallStack: information returned by getCallStack if tDepth is set or information returned by getCallStackLine.
-- tDepth: number of requested line if tCallStack = getCallStack, null otherwise.
-- See: utl_call_stack.concatenate_subprogram
function getConcatenatedSubprograms( tCallStack in varchar2, tDepth in number default null ) return varchar2 is
  tCallLine varchar2( 4000 ) := case when tDepth is null then tCallStack else getCallStackLine( tCallStack, tDepth ) end;
  pos pls_integer;
begin
  pos := instr( tCallLine, '.' );
  tCallLine := substr( tCallLine, pos );
  tCallLine := replace( tCallLine, '.PACKAGE BODY ', '.' );
  tCallLine := replace( tCallLine, '.PACKAGE ', '.' );
  tCallLine := replace( tCallLine, '.TYPE BODY ', '.' );
  tCallLine := replace( tCallLine, '.TRIGGER ', '.' );
  tCallLine := replace( tCallLine, '.PROCEDURE ', '.' );
  tCallLine := replace( tCallLine, '.FUNCTION ', '.' );
  return substr( tCallLine, 2 );
end;

-- Returns an error stack as a string.
-- tDepth: number of requested stack line. Lesser numbers are most recent errors. Numeration starts from 1.
-- If omitted then the full stack is concatenated via newline character.
-- If tDepth is out of bounds then null is returned.
-- The full stack output equals to dbms_utility.format_call_stack.
-- See: dbms_utility.format_call_stack
function getErrorStack( tDepth in number default null ) return varchar2 is
  tErrorStack varchar2( 4000 ) := dbms_utility.format_error_stack;
begin
  if tErrorStack is null then
    tErrorStack := CHAR_NEW_LINE;
  end if;
  if tDepth is null then
    return tErrorStack;
  else
    return getCallStackLine( tErrorStack, tDepth ) || CHAR_NEW_LINE;
  end if;
end;

-- Returns current error stack depth.
-- tErrorStack: information returned by getErrorStack. Can be omitted.
-- See: utl_call_stack.error_depth
function getErrorDepth( tErrorStack in varchar2 default '' ) return number is
  nErrorStack varchar2( 4000 );
begin
  if tErrorStack is null then
    $if not dbms_db_version.ver_le_10 $then
      $if not dbms_db_version.ver_le_11 $then
        return utl_call_stack.error_depth;
      $end
    $end
    nErrorStack := getErrorStack;
  else
    nErrorStack := tErrorStack;
  end if;
  return greatest( nvl( length( nErrorStack ) - length( replace( nErrorStack, CHAR_NEW_LINE ) ), 0 ), 0 );
end;

-- Returns error code at a given depth.
-- tErrorStack: information returned by getErrorStack.
-- tDepth: number of requested stack line if tErrorStack = getErrorStack, null otherwise.
-- See: utl_call_stack.error_number
function getErrorCode( tErrorStack in varchar2, tDepth in number default null ) return number is
  tErrorLine varchar2( 4000 ) := getCallStackLine( tErrorStack, nvl( tDepth, 1 ) );
  pos pls_integer;
begin
  pos := instr( tErrorLine, ':' );
  if pos is null or pos = 0 then
    return null;
  end if;
  tErrorLine := substr( tErrorLine, 1, pos - 1 );
  if tErrorLine like 'ORA-%' then
    tErrorLine := substr( tErrorLine, 5 );
  end if;
  return to_number( tErrorLine );
end;

-- Returns error message at a given depth.
-- tErrorStack: information returned by getErrorStack.
-- tDepth: number of requested stack line if tErrorStack = getErrorStack, null otherwise.
-- See: utl_call_stack.error_msg
function getErrorMessage( tErrorStack in varchar2, tDepth in number default null ) return varchar2 is
  tErrorLine varchar2( 4000 ) := getCallStackLine( tErrorStack, nvl( tDepth, 1 ) );
  pos pls_integer;
begin
  pos := instr( tErrorLine, ':' );
  if pos is null or pos = 0 then
    return null;
  end if;
  return substr( tErrorLine, pos + 2 );
end;

-- Returns CHILD_ADDRESS field of V$SQL view for current executing program.
-- Private function.
function getCurrentSqlChildAddress return varchar2 is
  ret varchar( 4000 ) := dbms_utility.format_call_stack;
  pos pls_integer;
begin
  if ret like '%anonymous block' || CHAR_NEW_LINE then
    pos := instr( ret, CHAR_NEW_LINE, -2 );
    if pos > 0 then
      ret := substr( ret, pos + 1 );
      pos := instr( ret, ' ' );
      if pos > 0 then
        return substr( ret, 1, pos - 1 );
      end if;
    end if;
  end if;
  return '';
end;

-- Returns a backtrace stack as a string.
-- It shows program units and line numbers where the last error has occurred.
-- The output format is the same as in getCallStack.
-- See getCallStack documentation to get more information about the output format.
-- tDepth: number of requested stack line. Lesser numbers are most recent calls. Numeration starts from 1.
-- The order equals to the order returned by dbms_utility.format_error_backtrace.
-- Also, the order equals to the order returned by getCallStack.
-- But it doesn't equal to the order returned by utl_call_stack.backtrace_unit which is reversed.
-- If tDepth is omitted then the full stack is concatenated via newline character.
-- See: dbms_utility.format_error_backtrace
function getBacktraceStack( tDepth in number default null ) return varchar2 is
  tBacktrace varchar2( 4000 ) := dbms_utility.format_error_backtrace;
  ret varchar2( 4000 ) :=
    '----- PL/SQL Call Stack -----' || CHAR_NEW_LINE ||
    '  object      line  object' || CHAR_NEW_LINE ||
    '  handle    number  name' || CHAR_NEW_LINE;
  pos pls_integer;
  tLineNumber pls_integer;
  tUnitName varchar2( 4000 );
  tUnitType varchar2( 255 );
  tOwner varchar2( 255 );
  tHandle varchar2( 255 );
begin
  loop
    pos := instr( tBacktrace, 'at ' );
    if pos > 0 then
      tBacktrace := substr( tBacktrace, pos + 3 );
      tUnitName := '';
      if tBacktrace like '"%' then
        pos := instr( tBacktrace, '"', 2 );
        if pos > 0 then
          tUnitName := substr( tBacktrace, 2, pos - 2 );
          pos := instr( tBacktrace, 'line ', pos + 1 );
        else
          pos := instr( tBacktrace, 'line ', 2 );
        end if;
      else
        pos := instr( tBacktrace, 'line ' );
      end if;
      tLineNumber := 0;
      if pos > 0 then
        tBacktrace := substr( tBacktrace, pos + 5 );
        pos := instr( tBacktrace, CHAR_NEW_LINE );
        begin
          if pos > 0 then
            tLineNumber := to_number( substr( tBacktrace, 1, pos - 1 ) );
          else
            tLineNumber := to_number( tBacktrace );
          end if;
        exception
          when VALUE_ERROR then
            null;
        end;
      else
        pos := instr( tBacktrace, CHAR_NEW_LINE );
      end if;
      if pos > 0 then
        tBacktrace := substr( tBacktrace, pos + 1 );
      end if;
      if tUnitName is null then
        tUnitName := 'anonymous block';
        tHandle := getCurrentSqlChildAddress;
      else
        pos := instr( tUnitName, '.' );
        if pos > 0 then
          tOwner := substr( tUnitName, 1, pos - 1 );
          tUnitName := substr( tUnitName, pos + 1 );
        else
          tOwner := user;
        end if;
        begin
          select lower( OBJECT_TYPE ) as OBJECT_TYPE
          into tUnitType
          from ALL_OBJECTS
          where OWNER = tOwner
            and OBJECT_NAME = tUnitName
            and OBJECT_TYPE in ( 'FUNCTION', 'PROCEDURE', 'PACKAGE BODY', 'TYPE BODY', 'TRIGGER' );
        exception
          when NO_DATA_FOUND then
            tUnitType := '';
          when TOO_MANY_ROWS then
            tUnitType := '';
        end;
        tUnitName := tOwner || '.' || tUnitName;
        if tUnitType is not null then
          tUnitName := tUnitType || ' ' || tUnitName;
        end if;
        tHandle := '00000000';
      end if;
      ret := ret || tHandle || lpad( to_char( tLineNumber ), 10 ) || '  ' || tUnitName || CHAR_NEW_LINE;
    else
      exit;
    end if;
  end loop;
  return getCallStack( ret, tDepth );
end;

-- Returns backtrace stack depth.
-- tBacktraceStack: information returned by getBacktraceStack. Can be omitted.
-- See: utl_call_stack.backtrace_depth
function getBacktraceDepth( tBacktraceStack in varchar2 default '' ) return number is
  tCallPositions varchar2( 4000 );
begin
  if tBacktraceStack is null then
    $if not dbms_db_version.ver_le_10 $then
      $if not dbms_db_version.ver_le_11 $then
        return utl_call_stack.backtrace_depth;
      $end
    $end
    tCallPositions := dbms_utility.format_error_backtrace;
    return greatest( nvl( length( tCallPositions ) - length( replace( tCallPositions, CHAR_NEW_LINE ) ), 0 ), 0 );
  else
    return greatest( nvl( length( tBacktraceStack ) - length( replace( tBacktraceStack, CHAR_NEW_LINE ) ) + 1, 0 ), 0 );
  end if;
end;

end;
/
