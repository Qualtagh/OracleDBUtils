create or replace package p_math is

function calculate_j( expression in varchar2 ) return number is language java name
 'org.quinto.math.Fraction.calculate( java.lang.String ) return double';
function calculate( expression in varchar2 ) return number;

end p_math;
/
create or replace package body p_math is

function calculate( expression in varchar2 ) return number is
begin
  return case when trim( expression ) is null then null else calculate_j( expression ) end;
end;

end p_math;
/
