CREATE OR REPLACE TYPE t_clob_agg AS OBJECT
(
  g_clob  CLOB,

  STATIC FUNCTION ODCIAggregateInitialize(sctx  IN OUT  t_clob_agg)
    RETURN NUMBER,

  MEMBER FUNCTION ODCIAggregateIterate(self   IN OUT  t_clob_agg,
                                       value  IN      VARCHAR2 )
     RETURN NUMBER,

  MEMBER FUNCTION ODCIAggregateTerminate(self         IN   t_clob_agg,
                                         returnValue  OUT  CLOB,
                                         flags        IN   NUMBER)
    RETURN NUMBER,

  MEMBER FUNCTION ODCIAggregateMerge(self  IN OUT  t_clob_agg,
                                     ctx2  IN      t_clob_agg)
    RETURN NUMBER
)
/
CREATE OR REPLACE TYPE BODY t_clob_agg IS
  STATIC FUNCTION ODCIAggregateInitialize(sctx  IN OUT  t_clob_agg)
    RETURN NUMBER IS
  BEGIN
    sctx := t_clob_agg(NULL);
    RETURN ODCIConst.Success;
  END;

  MEMBER FUNCTION ODCIAggregateIterate(self   IN OUT  t_clob_agg,
                                       value  IN      VARCHAR2 )
    RETURN NUMBER IS
  BEGIN
    SELF.g_clob := self.g_clob || ',' || value;
    RETURN ODCIConst.Success;
  END;

  MEMBER FUNCTION ODCIAggregateTerminate(self         IN   t_clob_agg,
                                         returnValue  OUT  CLOB,
                                         flags        IN   NUMBER)
    RETURN NUMBER IS
  BEGIN
    returnValue := RTRIM(LTRIM(SELF.g_clob, ','), ',');
    RETURN ODCIConst.Success;
  END;

  MEMBER FUNCTION ODCIAggregateMerge(self  IN OUT  t_clob_agg,
                                     ctx2  IN      t_clob_agg)
    RETURN NUMBER IS
  BEGIN
    SELF.g_clob := SELF.g_clob || ',' || ctx2.g_clob;
    RETURN ODCIConst.Success;
  END;
END;
/
CREATE OR REPLACE FUNCTION clob_agg (p_input VARCHAR2)
RETURN CLOB
PARALLEL_ENABLE AGGREGATE USING t_clob_agg;
/
