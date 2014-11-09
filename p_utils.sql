create or replace package p_utils is

-- Standard to_char( 0.23 ) returns '.23' (zero omitted), this function adds zero when needed ('0.23' for the example above).
-- See: http://stackoverflow.com/questions/6695604/oracle-why-does-the-leading-zero-of-a-number-disappear-when-converting-it-to-c
function numberToChar( tNumber in number ) return varchar2;

-- Create a set from an array of keys.
function getAssociativeArray( tKeys in num_table ) return dbms_sql.number_table;

-- Create a map from an array of keys and an array of values.
function getAssociativeArray( tKeys in num_table, tValues in num_table ) return dbms_sql.number_table;
function getAssociativeArray( tKeys in num_table, tValues in date_table ) return dbms_sql.date_table;
function getAssociativeArray( tKeys in num_table, tValues in str_table ) return dbms_sql.varchar2_table;

-- Get an array of keys from a given map.
function getAssociativeArrayKeys( tMap in dbms_sql.number_table ) return num_table;
function getAssociativeArrayKeys( tMap in dbms_sql.date_table ) return num_table;
function getAssociativeArrayKeys( tMap in dbms_sql.varchar2_table ) return num_table;

-- Get an array of values from a given map.
function getAssociativeArrayValues( tMap in dbms_sql.number_table ) return num_table;
function getAssociativeArrayValues( tMap in dbms_sql.date_table ) return date_table;
function getAssociativeArrayValues( tMap in dbms_sql.varchar2_table ) return str_table;

-- Trunc timestamp to date.
-- cast( ts as date ) rounds (half up) value before Oracle 11 and truncates value starting from Oracle 11.
function truncToSeconds( tTimestamp in timestamp ) return date;

-- Leave only distinct XML nodes of a document.
function distinguishXML( xml in XMLType ) return XMLType;

-- Evaluate arithmetic expression.
function calculate( expression in varchar2 ) return number is language java name
 'org.quinto.math.Fraction.calculate( java.lang.String ) return java.lang.Double';

end;
/
create or replace package body p_utils is

-- Standard to_char( 0.23 ) returns '.23', this function adds zero when needed ('0.23' for the example above).
-- See: http://stackoverflow.com/questions/6695604/oracle-why-does-the-leading-zero-of-a-number-disappear-when-converting-it-to-c
function numberToChar( tNumber in number ) return varchar2 is
begin
  if tNumber > 0 and tNumber < 1 then
    return '0' || to_char( tNumber );
  elsif tNumber > -1 and tNumber < 0 then
    return '-0' || to_char( -tNumber );
  else
    return to_char( tNumber );
  end if;
end;

-- Create a set from an array of keys.
function getAssociativeArray( tKeys in num_table ) return dbms_sql.number_table is
  ret dbms_sql.number_table;
  tCnt pls_integer;
begin
  if tKeys is not null then
    tCnt := tKeys.count;
    for i in 1 .. tCnt loop
      ret( tKeys( i ) ) := null;
    end loop;
  end if;
  return ret;
end;

-- Create a map from an array of keys and an array of values.
function getAssociativeArray( tKeys in num_table, tValues in num_table ) return dbms_sql.number_table is
  ret dbms_sql.number_table;
  tCnt pls_integer;
begin
  if tKeys is not null and tValues is not null then
    tCnt := least( tKeys.count, tValues.count );
    for i in 1 .. tCnt loop
      ret( tKeys( i ) ) := tValues( i );
    end loop;
  end if;
  return ret;
end;

-- Create a map from an array of keys and an array of values.
function getAssociativeArray( tKeys in num_table, tValues in date_table ) return dbms_sql.date_table is
  ret dbms_sql.date_table;
  tCnt pls_integer;
begin
  if tKeys is not null and tValues is not null then
    tCnt := least( tKeys.count, tValues.count );
    for i in 1 .. tCnt loop
      ret( tKeys( i ) ) := tValues( i );
    end loop;
  end if;
  return ret;
end;

-- Create a map from an array of keys and an array of values.
function getAssociativeArray( tKeys in num_table, tValues in str_table ) return dbms_sql.varchar2_table is
  ret dbms_sql.varchar2_table;
  tCnt pls_integer;
  tValue varchar2( 4000 );
begin
  if tKeys is not null and tValues is not null then
    tCnt := least( tKeys.count, tValues.count );
    for i in 1 .. tCnt loop
      tValue := tValues( i );
      if length( tValue ) > 2000 then
        tValue := substr( tValue, 1, 2000 );
      end if;
      ret( tKeys( i ) ) := tValue;
    end loop;
  end if;
  return ret;
end;

-- Get an array of keys from a given map.
function getAssociativeArrayKeys( tMap in dbms_sql.number_table ) return num_table is
  ret num_table := num_table();
  tKey number := tMap.first;
  i number := 1;
begin
  ret.extend( tMap.count );
  while tKey is not null loop
    ret( i ) := tKey;
    i := i + 1;
    tKey := tMap.next( tKey );
  end loop;
  return ret;
end;

-- Get an array of keys from a given map.
function getAssociativeArrayKeys( tMap in dbms_sql.date_table ) return num_table is
  ret num_table := num_table();
  tKey number := tMap.first;
  i number := 1;
begin
  ret.extend( tMap.count );
  while tKey is not null loop
    ret( i ) := tKey;
    i := i + 1;
    tKey := tMap.next( tKey );
  end loop;
  return ret;
end;

-- Get an array of keys from a given map.
function getAssociativeArrayKeys( tMap in dbms_sql.varchar2_table ) return num_table is
  ret num_table := num_table();
  tKey number := tMap.first;
  i number := 1;
begin
  ret.extend( tMap.count );
  while tKey is not null loop
    ret( i ) := tKey;
    i := i + 1;
    tKey := tMap.next( tKey );
  end loop;
  return ret;
end;

-- Get an array of values from a given map.
function getAssociativeArrayValues( tMap in dbms_sql.number_table ) return num_table is
  ret num_table := num_table();
  tKey number := tMap.first;
  i number := 1;
begin
  ret.extend( tMap.count );
  while tKey is not null loop
    ret( i ) := tMap( tKey );
    i := i + 1;
    tKey := tMap.next( tKey );
  end loop;
  return ret;
end;

-- Get an array of values from a given map.
function getAssociativeArrayValues( tMap in dbms_sql.date_table ) return date_table is
  ret date_table := date_table();
  tKey number := tMap.first;
  i number := 1;
begin
  ret.extend( tMap.count );
  while tKey is not null loop
    ret( i ) := tMap( tKey );
    i := i + 1;
    tKey := tMap.next( tKey );
  end loop;
  return ret;
end;

-- Get an array of values from a given map.
function getAssociativeArrayValues( tMap in dbms_sql.varchar2_table ) return str_table is
  ret str_table := str_table();
  tKey number := tMap.first;
  i number := 1;
begin
  ret.extend( tMap.count );
  while tKey is not null loop
    ret( i ) := tMap( tKey );
    i := i + 1;
    tKey := tMap.next( tKey );
  end loop;
  return ret;
end;

-- Trunc timestamp to date.
-- cast( ts as date ) rounds (half up) value before Oracle 11 and truncates value starting from Oracle 11.
function truncToSeconds( tTimestamp in timestamp ) return date is
begin
  return tTimestamp;
end;

-- Leave only distinct XML nodes of a document.
function distinguishXML( xml in XMLType ) return XMLType is
  type stringSet is table of pls_integer index by varchar2( 4000 );
  idx stringSet;
  text varchar2( 4000 );
  ret XMLType;
  nodes XMLSequenceType;
  retNodes XMLSequenceType := XMLSequenceType();
  capacity pls_integer := 32;
  j pls_integer := 1;
begin
  select XMLSequence( xml )
  into nodes
  from dual;
  retNodes.extend( capacity );
  for i in 1 .. nodes.count loop
    text := nodes( i ).getStringVal();
    if not idx.exists( text ) then
      idx( text ) := null;
      if j > capacity then
        retNodes.extend( capacity / 2 );
        capacity := capacity * 3 / 2;
      end if;
      retNodes( j ) := nodes( i );
      j := j + 1;
    end if;
  end loop;
  retNodes.trim( capacity - j + 1 );
  select XMLAgg( value( t ) )
  into ret
  from table( retNodes ) t;
  return ret;
end;

end;
/
