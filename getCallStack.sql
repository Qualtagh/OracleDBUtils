create or replace function getCallStack return varchar2 is
  tOwner varchar2( 255 );
  tName varchar2( 255 );
  tLine number;
  tType varchar2( 255 );
  s varchar2( 4000 );
  t varchar2( 4000 );
  c char;
  pos pls_integer;
  len pls_integer;
  tSpaceCharacters constant varchar2( 4 ) := ' ' || chr( 13 ) || chr( 10 ) || chr( 9 );
  tCommented pls_integer := 0;
  tIdentifier pls_integer := 0;
  tIdentifierName varchar2( 30 );
  tIdentifiers dbms_sql.varchar2_table;
  tMaxIdentifier pls_integer := 0;
  tQuoteDelimiter char;
  tString pls_integer := 0;
  tToken varchar2( 4000 );
  tTokenType pls_integer;
  tPreviousTokenType pls_integer;
  tTokensQueue str_table := str_table( '', '', '' );
  tCallStack str_table := str_table( '' );
  tLast pls_integer;
  tLookForDefinition pls_integer;
  tPrevToken varchar2( 4000 );
  tPrevPrevToken varchar2( 4000 );
  tCallStackLine varchar2( 4000 );
begin
  owa_util.who_called_me( tOwner, tName, tLine, tType );
  for rec in ( select rtrim( ltrim( TEXT, tSpaceCharacters ), tSpaceCharacters ) as TEXT,
                      case when LINE = tLine then 1 else 0 end as LAST_LINE
               from ALL_SOURCE
               where OWNER = tOwner
                 and NAME = tName
                 and TYPE = tType
                 and LINE <= tLine
               order by LINE ) loop
    t := '';
    s := rec.TEXT;
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
            tQuoteDelimiter := '';
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
              pos := pos + 2;
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
          pos := pos + 1;
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
                            or c = chr( 9 )
                            or c = chr( 10 )
                            or c = chr( 13 )
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
            exit when rec.LAST_LINE = 1 and tToken = 'GETCALLSTACK';
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
                  if tCallStack( tCallStack.count ) = 'BEGIN' then
                    tCallStack.trim;
                  end if;
                end if;
              end if;
            elsif tToken in ( 'IS', 'AS' ) then
              if tLookForDefinition = 1 then
                tLookForDefinition := 0;
              end if;
            elsif tToken = 'END' then
              if tCallStack( tCallStack.count ) = 'CASEEXPR' then
                tCallStack.trim;
              end if;
            elsif tPrevToken in ( 'TRIGGER', 'FUNCTION', 'PROCEDURE' )
              or tPrevToken = 'BODY' and tPrevPrevToken in ( 'PACKAGE', 'TYPE' ) then
              if tPrevToken in ( 'FUNCTION', 'PROCEDURE' ) then
                tLookForDefinition := 1;
              end if;
              tCallStack.extend;
              tCallStack( tCallStack.count ) := case
                                                  when tPrevToken = 'TRIGGER' then '-TRI'
                                                  when tPrevToken = 'FUNCTION' then '-FUN'
                                                  when tPrevToken = 'PROCEDURE' then '-PRO'
                                                  when tPrevPrevToken = 'PACKAGE' then '-PAC'
                                                  else '-TYP'
                                                end || tToken;
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
  tCallStackLine := '';
  for i in 2 .. tCallStack.count loop
    tToken := case substr( tCallStack( i ), 2, 3 )
                when 'TRI' then 'TRIGGER '
                when 'FUN' then 'FUNCTION '
                when 'PRO' then 'PROCEDURE '
                when 'PAC' then 'PACKAGE BODY '
                when 'TYP' then 'TYPE BODY '
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
  return tLine || ': ' || tOwner || '.' || tCallStackLine;
end;
