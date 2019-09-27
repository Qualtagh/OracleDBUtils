CREATE OR REPLACE PACKAGE utl_call_stack IS

  /*
    Exception: BAD_DEPTH_INDICATOR

    This exception is raised when a provided depth is out of bounds.
        - Dynamic and lexical depth are positive integer values.
        - Error and backtrace depths are non-negative integer values
        and are zero only in the absence of an exception.

  */
  BAD_DEPTH_INDICATOR EXCEPTION;
    pragma EXCEPTION_INIT(BAD_DEPTH_INDICATOR, -64610);

  /*
    Type: UNIT_QUALIFIED_NAME

    This data structure is a varray whose individual elements are, in order,
    the unit name, any lexical parents of the subprogram, and the subprogram
    name.

    For example, consider the following contrived PL/SQL procedure.

    > procedure topLevel is
    >   function localFunction(...) returns varchar2 is
    >     function innerFunction(...) returns varchar2 is
    >       begin
    >         declare
    >           localVar pls_integer;
    >         begin
    >           ... (1)
    >         end;
    >       end;
    >   begin
    >     ...
    >   end;

   The unit qualified name at (1) would be

   >    ["topLevel", "localFunction", "innerFunction"]

   Note that the block enclosing (1) does not figure in the unit qualified
   name.

   If the unit were an anonymous block, the unit name would be "__anonymous_block"

  */
  TYPE UNIT_QUALIFIED_NAME IS VARRAY(256) OF VARCHAR2(32767);

  /*
    Function: subprogram

    Returns the unit-qualified name of the subprogram at the specified dynamic
    depth.

    Parameters:

      dynamic_depth - The depth in the call stack.

    Returns:

      The unit-qualified name of the subprogram at the specified dynamic depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>
   */
  FUNCTION subprogram(dynamic_depth IN PLS_INTEGER) RETURN UNIT_QUALIFIED_NAME;

  /*
    Function: concatenate_subprogram

    Convenience function to concatenate a unit-qualified name, a varray, into
    a varchar2 comprising the names in the unit-qualified name, separated by
    dots.

    Parameters:

      qualified_name - A unit-qualified name.

    Returns:

      A string of the form "UNIT.SUBPROGRAM.SUBPROGRAM...LOCAL_SUBPROGRAM".

   */
  FUNCTION concatenate_subprogram(qualified_name IN UNIT_QUALIFIED_NAME)
           RETURN VARCHAR2;

  /*
    Function: owner

    Returns the owner name of the unit of the subprogram at the specified
    dynamic depth.

    Parameters:

      dynamic_depth - The depth in the call stack.

    Returns:

      The owner name of the unit of the subprogram at the specified dynamic
      depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>.
   */
  FUNCTION owner(dynamic_depth IN PLS_INTEGER) RETURN VARCHAR2;

  /*
    Function: current_edition
    
    Warning: not implemented. Always returns null.

    Returns the current edition name of the unit of the subprogram at the
    specified dynamic depth.

    Parameters:

      dynamic_depth - The depth in the call stack.

    Returns:

      The current edition name of the unit of the subprogram at the specified
      dynamic depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>.
   */
  FUNCTION current_edition(dynamic_depth IN PLS_INTEGER) RETURN VARCHAR2;

  /*
    Function: actual_edition

    Returns the name of the edition in which the unit of the subprogram at the
    specified dynamic depth is actual.

    Parameters:

      dynamic_depth - The depth in the call stack.

    Returns:

      The name of the edition in which the unit of the subprogram at the
      specified dynamic depth is actual.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>.
   */
  FUNCTION actual_edition(dynamic_depth IN PLS_INTEGER) RETURN VARCHAR2;

  /*
    Function: unit_line

    Returns the line number of the unit of the subprogram at the specified
    dynamic depth.

    Parameters:

      dynamic_depth - The depth in the call stack.

    Returns:

      The line number of the unit of the subprogram at the specified dynamic
      depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>.
   */
  FUNCTION unit_line(dynamic_depth IN PLS_INTEGER) RETURN PLS_INTEGER;

  /*
    Function: unit_type

    Returns the type of the unit of the subprogram at the specified dynamic
    depth.

    Parameters:

      dynamic_depth - The depth in the call stack.

    Returns:

      The type of the unit of the subprogram at the specified dynamic depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>.
   */
  FUNCTION unit_type(dynamic_depth IN PLS_INTEGER) RETURN VARCHAR2;

  /*
    Function: dynamic_depth

    Returns the number of subprograms on the call stack.

    Parameters:

    Returns:

      The number of subprograms on the call stack.

   */
  FUNCTION dynamic_depth RETURN PLS_INTEGER;

  /*
    Function: lexical_depth

    Returns the lexical nesting depth of the subprogram at the specified dynamic
    depth.

    Parameters:

      dynamic_depth - The depth in the call stack.

    Returns:

      The lexical nesting depth of the subprogram at the specified dynamic
      depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>.
   */
  FUNCTION lexical_depth(dynamic_depth IN PLS_INTEGER) RETURN PLS_INTEGER;

  /*
    Function: error_depth

    Returns the number of errors on the error stack.

    Parameters:

    Returns:

      The number of errors on the error stack.

   */
  FUNCTION error_depth RETURN PLS_INTEGER;

  /*
    Function: error_number

    Returns the error number of the error at the specified error depth.

    Parameters:

      error_depth - The depth in the error stack.

    Returns:

      The error number of the error at the specified error depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>.
   */
  FUNCTION error_number(error_depth IN PLS_INTEGER) RETURN PLS_INTEGER;

  /*
    Function: error_msg

    Returns the error message of the error at the specified error depth.

    Parameters:

      error_depth - The depth in the error stack.

    Returns:

      The error message of the error at the specified error depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>.
   */
  FUNCTION error_msg(error_depth IN PLS_INTEGER) RETURN VARCHAR2;

  /*
    Function: backtrace_depth
    
    Warning: not implemented. Always returns 0.

    Returns the number of backtrace items in the backtrace.

    Parameters:

    Returns:

      The number of backtrace items in the backtrace, zero in the absence of
      an exception.

   */
  FUNCTION backtrace_depth RETURN PLS_INTEGER;

  /*
    Function: backtrace_unit
    
    Warning: not implemented. Always raises <BAD_DEPTH_INDICATOR>.

    Returns the name of the unit at the specified backtrace depth.

    Parameters:

      backtrace_depth - The depth in the backtrace.

    Returns:

      The name of the unit at the specified backtrace depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>. Note that backtrace_unit(0); always raises
      this exception.

   */
  FUNCTION backtrace_unit(backtrace_depth IN PLS_INTEGER) RETURN VARCHAR2;

  /*
    Function: backtrace_line
    
    Warning: not implemented. Always raises <BAD_DEPTH_INDICATOR>.

    Returns the line number of the unit at the specified backtrace depth.

    Parameters:

      backtrace_depth - The depth in the backtrace.

    Returns:

      The line number of the unit at the specified backtrace depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>. Note that backtrace_line(0); always raises
      this exception.
   */
  FUNCTION backtrace_line(backtrace_depth IN PLS_INTEGER) RETURN PLS_INTEGER;

  /*
    Function: backtrace_subprogram
    
    Warning: not implemented. Always raises <BAD_DEPTH_INDICATOR>.

    Returns the unit-qualified name of the subprogram at the specified backtrace
    depth.

    Parameters:

      backtrace_depth - The depth in the backtrace.

    Returns:

      The unit-qualified name of the subprogram at the specified backtrace depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>. Note that backtrace_line(0); always raises
      this exception.
   */
  FUNCTION backtrace_subprogram(backtrace_depth IN PLS_INTEGER) RETURN UNIT_QUALIFIED_NAME;

END;
/
CREATE OR REPLACE PACKAGE BODY utl_call_stack IS

CHAR_NEW_LINE constant char := chr( 10 );

  FUNCTION get_subprograms( tCallLine in varchar2 ) RETURN UNIT_QUALIFIED_NAME IS
    ret UNIT_QUALIFIED_NAME := UNIT_QUALIFIED_NAME();
    tmp str_table;
  BEGIN
    tmp := p_stack.getSubprograms( tCallLine );
    ret.extend( tmp.count + 1 );
    if p_stack.getProgramType( tCallLine ) = 'ANONYMOUS BLOCK' then
      ret( 1 ) := '__anonymous_block';
    else
      ret( 1 ) := p_stack.getProgram( tCallLine );
    end if;
    for i in 1 .. tmp.count loop
      ret( i + 1 ) := tmp( i );
    end loop;
    return ret;
  END;
  
  PROCEDURE check_dynamic_depth( dynamic_depth in pls_integer ) IS
  BEGIN
    if dynamic_depth is null or dynamic_depth <= 0 or dynamic_depth > p_stack.getDynamicDepth - 3 then
      raise BAD_DEPTH_INDICATOR;
    end if;
  END;

  /*
    Function: subprogram

    Returns the unit-qualified name of the subprogram at the specified dynamic
    depth.

    Parameters:

      dynamic_depth - The depth in the call stack.

    Returns:

      The unit-qualified name of the subprogram at the specified dynamic depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>
   */
  FUNCTION subprogram(dynamic_depth IN PLS_INTEGER) RETURN UNIT_QUALIFIED_NAME IS
  BEGIN
    check_dynamic_depth( dynamic_depth );
    return get_subprograms( p_stack.getCallStack( dynamic_depth + 2 ) );
  END;

  /*
    Function: concatenate_subprogram

    Convenience function to concatenate a unit-qualified name, a varray, into
    a varchar2 comprising the names in the unit-qualified name, separated by
    dots.

    Parameters:

      qualified_name - A unit-qualified name.

    Returns:

      A string of the form "UNIT.SUBPROGRAM.SUBPROGRAM...LOCAL_SUBPROGRAM".

   */
  FUNCTION concatenate_subprogram(qualified_name IN UNIT_QUALIFIED_NAME)
           RETURN VARCHAR2 IS
    ret varchar2( 4000 );
    idx pls_integer := qualified_name.first;
  BEGIN
    while idx is not null loop
      if ret is not null then
        ret := ret || '.';
      end if;
      ret := ret || qualified_name( idx );
      idx := qualified_name.next( idx );
    end loop;
    return ret;
  END;

  /*
    Function: owner

    Returns the owner name of the unit of the subprogram at the specified
    dynamic depth.

    Parameters:

      dynamic_depth - The depth in the call stack.

    Returns:

      The owner name of the unit of the subprogram at the specified dynamic
      depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>.
   */
  FUNCTION owner(dynamic_depth IN PLS_INTEGER) RETURN VARCHAR2 IS
  BEGIN
    check_dynamic_depth( dynamic_depth );
    return p_stack.getOwner( p_stack.getCallStack( dynamic_depth + 2 ) );
  END;

  /*
    Function: current_edition
    
    Warning: not implemented. Always returns null.

    Returns the current edition name of the unit of the subprogram at the
    specified dynamic depth.

    Parameters:

      dynamic_depth - The depth in the call stack.

    Returns:

      The current edition name of the unit of the subprogram at the specified
      dynamic depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>.
   */
  FUNCTION current_edition(dynamic_depth IN PLS_INTEGER) RETURN VARCHAR2 IS
  BEGIN
    check_dynamic_depth( dynamic_depth );
    -- Not implemented.
    return '';
  END;

  /*
    Function: actual_edition

    Returns the name of the edition in which the unit of the subprogram at the
    specified dynamic depth is actual.

    Parameters:

      dynamic_depth - The depth in the call stack.

    Returns:

      The name of the edition in which the unit of the subprogram at the
      specified dynamic depth is actual.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>.
   */
  FUNCTION actual_edition(dynamic_depth IN PLS_INTEGER) RETURN VARCHAR2 IS
  BEGIN
    check_dynamic_depth( dynamic_depth );
    -- Not implemented.
    return '';
  END;

  /*
    Function: unit_line

    Returns the line number of the unit of the subprogram at the specified
    dynamic depth.

    Parameters:

      dynamic_depth - The depth in the call stack.

    Returns:

      The line number of the unit of the subprogram at the specified dynamic
      depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>.
   */
  FUNCTION unit_line(dynamic_depth IN PLS_INTEGER) RETURN PLS_INTEGER IS
  BEGIN
    check_dynamic_depth( dynamic_depth );
    return p_stack.getUnitLine( p_stack.getCallStack( dynamic_depth + 2 ) );
  END;

  /*
    Function: unit_type

    Returns the type of the unit of the subprogram at the specified dynamic
    depth.

    Parameters:

      dynamic_depth - The depth in the call stack.

    Returns:

      The type of the unit of the subprogram at the specified dynamic depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>.
   */
  FUNCTION unit_type(dynamic_depth IN PLS_INTEGER) RETURN VARCHAR2 IS
  BEGIN
    check_dynamic_depth( dynamic_depth );
    return p_stack.getProgramType( p_stack.getCallStack( dynamic_depth + 2 ) );
  END;

  /*
    Function: dynamic_depth

    Returns the number of subprograms on the call stack.

    Parameters:

    Returns:

      The number of subprograms on the call stack.

   */
  FUNCTION dynamic_depth RETURN PLS_INTEGER IS
  BEGIN
    return p_stack.getDynamicDepth - 2;
  END;

  /*
    Function: lexical_depth

    Returns the lexical nesting depth of the subprogram at the specified dynamic
    depth.

    Parameters:

      dynamic_depth - The depth in the call stack.

    Returns:

      The lexical nesting depth of the subprogram at the specified dynamic
      depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>.
   */
  FUNCTION lexical_depth(dynamic_depth IN PLS_INTEGER) RETURN PLS_INTEGER IS
  BEGIN
    check_dynamic_depth( dynamic_depth );
    return p_stack.getLexicalDepth( p_stack.getCallStack( dynamic_depth + 2 ) );
  END;
  
  PROCEDURE check_error_depth( error_depth in pls_integer ) IS
  BEGIN
    if error_depth is null or error_depth <= 0 or error_depth > p_stack.getErrorDepth then
      raise BAD_DEPTH_INDICATOR;
    end if;
  END;

  /*
    Function: error_depth

    Returns the number of errors on the error stack.

    Parameters:

    Returns:

      The number of errors on the error stack.

   */
  FUNCTION error_depth RETURN PLS_INTEGER IS
  BEGIN
    return p_stack.getErrorDepth;
  END;

  /*
    Function: error_number

    Returns the error number of the error at the specified error depth.

    Parameters:

      error_depth - The depth in the error stack.

    Returns:

      The error number of the error at the specified error depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>.
   */
  FUNCTION error_number(error_depth IN PLS_INTEGER) RETURN PLS_INTEGER IS
  BEGIN
    check_error_depth( error_depth );
    return p_stack.getErrorCode( p_stack.getErrorStack( error_depth ) );
  END;

  /*
    Function: error_msg

    Returns the error message of the error at the specified error depth.

    Parameters:

      error_depth - The depth in the error stack.

    Returns:

      The error message of the error at the specified error depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>.
   */
  FUNCTION error_msg(error_depth IN PLS_INTEGER) RETURN VARCHAR2 IS
  BEGIN
    check_error_depth( error_depth );
    return p_stack.getErrorMessage( p_stack.getErrorStack( error_depth ) ) || CHAR_NEW_LINE;
  END;

  /*
    Function: backtrace_depth
    
    Warning: not implemented. Always returns 0.

    Returns the number of backtrace items in the backtrace.

    Parameters:

    Returns:

      The number of backtrace items in the backtrace, zero in the absence of
      an exception.

   */
  FUNCTION backtrace_depth RETURN PLS_INTEGER IS
  BEGIN
    -- Not implemented.
    return 0;
  END;

  /*
    Function: backtrace_unit
    
    Warning: not implemented. Always raises <BAD_DEPTH_INDICATOR>.

    Returns the name of the unit at the specified backtrace depth.

    Parameters:

      backtrace_depth - The depth in the backtrace.

    Returns:

      The name of the unit at the specified backtrace depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>. Note that backtrace_unit(0); always raises
      this exception.

   */
  FUNCTION backtrace_unit(backtrace_depth IN PLS_INTEGER) RETURN VARCHAR2 IS
  BEGIN
    -- Not implemented.
    raise BAD_DEPTH_INDICATOR;
  END;

  /*
    Function: backtrace_line
    
    Warning: not implemented. Always raises <BAD_DEPTH_INDICATOR>.

    Returns the line number of the unit at the specified backtrace depth.

    Parameters:

      backtrace_depth - The depth in the backtrace.

    Returns:

      The line number of the unit at the specified backtrace depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>. Note that backtrace_line(0); always raises
      this exception.
   */
  FUNCTION backtrace_line(backtrace_depth IN PLS_INTEGER) RETURN PLS_INTEGER IS
  BEGIN
    -- Not implemented.
    raise BAD_DEPTH_INDICATOR;
  END;

  /*
    Function: backtrace_subprogram
    
    Warning: not implemented. Always raises <BAD_DEPTH_INDICATOR>.

    Returns the unit-qualified name of the subprogram at the specified backtrace
    depth.

    Parameters:

      backtrace_depth - The depth in the backtrace.

    Returns:

      The unit-qualified name of the subprogram at the specified backtrace depth.

    Exception:

      Raises <BAD_DEPTH_INDICATOR>. Note that backtrace_line(0); always raises
      this exception.
   */
  FUNCTION backtrace_subprogram(backtrace_depth IN PLS_INTEGER) RETURN UNIT_QUALIFIED_NAME IS
  BEGIN
    -- Not implemented.
    raise BAD_DEPTH_INDICATOR;
  END;

END;
/
