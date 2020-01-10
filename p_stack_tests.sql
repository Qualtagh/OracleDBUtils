create or replace procedure assert_eq( tActual in varchar2, tExpected in varchar2 ) is
  tExpectedReplaced varchar2( 4000 ) := replace( tExpected, '<USER>', user );
begin
  if tActual = tExpectedReplaced or tActual is null and tExpectedReplaced is null then
    return;
  end if;
  raise_application_error( -20001, 'assertion failed: ' || chr( 10 ) || tActual || chr( 10 ) || tExpectedReplaced );
end;
/
create or replace package APCKG is
  procedure PROC;
end;
/
create or replace package body APCKG is
  procedure PROC is
    procedure "INNER/proc" is
    begin
      assert_eq( p_stack.whoAmI, '5: <USER>.PACKAGE BODY APCKG.PROCEDURE PROC.PROCEDURE "INNER/proc"' );
      assert_eq( p_stack.getSubprogram( p_stack.whoAmI ), 'INNER/proc' );
      assert_eq( p_stack.getConcatenatedSubprograms( p_stack.whoAmI ), 'APCKG.PROC."INNER/proc"' );
      assert_eq( p_stack.whoCalledMe, '11: <USER>.PACKAGE BODY APCKG.PROCEDURE PROC' );
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
/
declare
  procedure inner_proc is
  begin
    assert_eq( p_stack.whoAmI, '4: <USER>.ANONYMOUS BLOCK.PROCEDURE INNER_PROC' );
  end;
begin
  inner_proc;
end;
/
declare
  procedure outer_proc is
    procedure inner_proc is
      tCallStack varchar2( 4000 );
      tCallLine varchar2( 4000 );
    begin
      tCallStack := p_stack.getCallStack;
      assert_eq( p_stack.getDynamicDepth( tCallStack ), 4 );
      
      tCallLine := p_stack.getCallStackLine( tCallStack, 1 );
      assert_eq( p_stack.getLexicalDepth( tCallLine ), 1 );
      assert_eq( p_stack.getProgramType( tCallLine ), 'PACKAGE BODY' );
      assert_eq( p_stack.getProgram( tCallLine ), 'P_STACK' );
      assert_eq( p_stack.getSubprogramType( tCallLine ), 'FUNCTION' );
      assert_eq( p_stack.getSubprogram( tCallLine ), 'GETCALLSTACK' );
      assert_eq( p_stack.getConcatenatedSubprograms( tCallLine ), 'P_STACK.GETCALLSTACK' );
      
      tCallLine := p_stack.getCallStackLine( tCallStack, 2 );
      assert_eq( p_stack.getUnitLine( tCallLine ), 7 );
      assert_eq( p_stack.getOwner( tCallLine ), '<USER>' );
      assert_eq( p_stack.getLexicalDepth( tCallLine ), 2 );
      assert_eq( p_stack.getProgramType( tCallLine ), 'ANONYMOUS BLOCK' );
      assert_eq( p_stack.getProgram( tCallLine ), '' );
      assert_eq( p_stack.getSubprogramType( tCallLine ), 'PROCEDURE' );
      assert_eq( p_stack.getSubprogram( tCallLine ), 'INNER_PROC' );
      assert_eq( p_stack.getConcatenatedSubprograms( tCallLine ), 'ANONYMOUS BLOCK.OUTER_PROC.INNER_PROC' );
      
      tCallLine := p_stack.getCallStackLine( tCallStack, 3 );
      assert_eq( p_stack.getOwner( tCallLine ), '<USER>' );
      assert_eq( p_stack.getLexicalDepth( tCallLine ), 1 );
      assert_eq( p_stack.getProgramType( tCallLine ), 'ANONYMOUS BLOCK' );
      assert_eq( p_stack.getProgram( tCallLine ), '' );
      assert_eq( p_stack.getSubprogramType( tCallLine ), 'PROCEDURE' );
      assert_eq( p_stack.getSubprogram( tCallLine ), 'OUTER_PROC' );
      assert_eq( p_stack.getConcatenatedSubprograms( tCallLine ), 'ANONYMOUS BLOCK.OUTER_PROC' );
      
      tCallLine := p_stack.getCallStackLine( tCallStack, 4 );
      assert_eq( p_stack.getOwner( tCallLine ), '<USER>' );
      assert_eq( p_stack.getLexicalDepth( tCallLine ), 0 );
      assert_eq( p_stack.getProgramType( tCallLine ), 'ANONYMOUS BLOCK' );
      assert_eq( p_stack.getProgram( tCallLine ), '' );
      assert_eq( p_stack.getSubprogramType( tCallLine ), 'ANONYMOUS BLOCK' );
      assert_eq( p_stack.getSubprogram( tCallLine ), '' );
      assert_eq( p_stack.getConcatenatedSubprograms( tCallLine ), 'ANONYMOUS BLOCK' );
      
      tCallLine := p_stack.getCallStackLine( tCallStack, 5 );
      assert_eq( p_stack.getUnitLine( tCallLine ), null );
      assert_eq( p_stack.getOwner( tCallLine ), null );
      assert_eq( p_stack.getLexicalDepth( tCallLine ), 0 );
      assert_eq( p_stack.getProgramType( tCallLine ), 'PACKAGE' );
      assert_eq( p_stack.getProgram( tCallLine ), null );
      assert_eq( p_stack.getSubprogramType( tCallLine ), null );
      assert_eq( p_stack.getSubprogram( tCallLine ), null );
      assert_eq( p_stack.getConcatenatedSubprograms( tCallLine ), null );
    end;
  begin
    inner_proc;
  end;
begin
  outer_proc;
end;
/
create or replace package JAVA_PKG is
  procedure begin_test;
  procedure test_java is
    language java name 'TestClass.Method1()';
  procedure end_test;
end;
/
create or replace package body JAVA_PKG is
  procedure begin_test is
  begin
    assert_eq( p_stack.whoAmI, '4: <USER>.PACKAGE BODY JAVA_PKG.PROCEDURE BEGIN_TEST' );
  end;
  procedure test_java_1 is
    language java name 'TestClass.Method1()';
  procedure test_java_2 is
    language java name 'TestClass.Method2(java.lang.String)';
  procedure end_test is
  begin
    assert_eq( p_stack.whoAmI, '12: <USER>.PACKAGE BODY JAVA_PKG.PROCEDURE END_TEST' );
  end;
end;
/
begin
  JAVA_PKG.begin_test;
  JAVA_PKG.end_test;
end;
/
drop package JAVA_PKG;
/
create or replace package EMPTY_DECLARE_PKG is
  procedure GOOD;
  procedure BAD;
end;
/
create or replace package body EMPTY_DECLARE_PKG is
  procedure GOOD is
    tCallStack varchar2( 4000 );
  begin
    declare
      t number;
    begin
      null;
    end;
    tCallStack := p_stack.getCallStack(2);
    assert_eq( p_stack.getConcatenatedSubprograms( tCallStack ), 'EMPTY_DECLARE_PKG.GOOD' );
  end;

  procedure BAD is
    tCallStack varchar2( 4000 );
  begin
    declare
    begin
      null;
    end;
    tCallStack := p_stack.getCallStack(2);
    assert_eq( p_stack.getConcatenatedSubprograms( tCallStack ), 'EMPTY_DECLARE_PKG.BAD' );
  end;
end;
/
begin
  EMPTY_DECLARE_PKG.GOOD;
  EMPTY_DECLARE_PKG.BAD;
end;
/
drop package EMPTY_DECLARE_PKG;
/
drop procedure assert_eq;
