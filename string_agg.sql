CREATE OR REPLACE TYPE t_string_agg AS OBJECT
(
  g_string  VARCHAR2(4000),

  STATIC FUNCTION ODCIAggregateInitialize(sctx  IN OUT  t_string_agg)
    RETURN NUMBER,

  MEMBER FUNCTION ODCIAggregateIterate(self   IN OUT  t_string_agg,
                                       value  IN      VARCHAR2 )
     RETURN NUMBER,

  MEMBER FUNCTION ODCIAggregateTerminate(self         IN   t_string_agg,
                                         returnValue  OUT  VARCHAR2,
                                         flags        IN   NUMBER)
    RETURN NUMBER,

  MEMBER FUNCTION ODCIAggregateMerge(self  IN OUT  t_string_agg,
                                     ctx2  IN      t_string_agg)
    RETURN NUMBER
)
/
CREATE OR REPLACE TYPE BODY t_string_agg IS
  STATIC FUNCTION ODCIAggregateInitialize(sctx  IN OUT  t_string_agg)
    RETURN NUMBER IS
  BEGIN
    sctx := t_string_agg(NULL);
    RETURN ODCIConst.Success;
  END;

  MEMBER FUNCTION ODCIAggregateIterate(self   IN OUT  t_string_agg,
                                       value  IN      VARCHAR2 )
    RETURN NUMBER IS
    curlen number := nvl( length( self.g_string ), 0 );
  BEGIN
    if curlen < 4000 then
      SELF.g_string := self.g_string || ',' || substr( value, 1, 3999 - curlen );
    end if;
    RETURN ODCIConst.Success;
  END;

  MEMBER FUNCTION ODCIAggregateTerminate(self         IN   t_string_agg,
                                         returnValue  OUT  VARCHAR2,
                                         flags        IN   NUMBER)
    RETURN NUMBER IS
  BEGIN
    returnValue := RTRIM(LTRIM(SELF.g_string, ','), ',');
    RETURN ODCIConst.Success;
  END;

  MEMBER FUNCTION ODCIAggregateMerge(self  IN OUT  t_string_agg,
                                     ctx2  IN      t_string_agg)
    RETURN NUMBER IS
    curlen number := nvl( length( self.g_string ), 0 );
  BEGIN
    if curlen < 4000 then
      SELF.g_string := SELF.g_string || ',' || substr( ctx2.g_string, 1, 3999 - curlen );
    end if;
    RETURN ODCIConst.Success;
  END;
END;
/
CREATE OR REPLACE FUNCTION string_agg (p_input VARCHAR2)
RETURN VARCHAR2
PARALLEL_ENABLE AGGREGATE USING t_string_agg;
/
