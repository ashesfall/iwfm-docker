      SUBROUTINE ZRITSXD (IFLTAB, CPATH, JULS, ISTIME, JULE, IETIME,
     * ITIMES, DVALUES, KVALS, NVALS, IBDATE, IQUAL, LQUAL, LQREAD,
     * CUNITS, CTYPE, IUHEAD, KUHEAD, NUHEAD, INFLAG, ISTAT)
C
C
C
      INTEGER IFLTAB(*), IQUAL(*), ITIMES(*), IUHEAD(*), ICDESC(6)
      REAL SVALUES(1)
      LOGICAL LQUAL, LQREAD
C
      CHARACTER CPATH*(*), CUNITS*(*), CTYPE*(*)
C
      LOGICAL LFILDOB, LCOORDS
      DOUBLE PRECISION DVALUES(*), COORDS(3)
C
C
      CALL ZRITSI (IFLTAB, CPATH, JULS, ISTIME, JULE, IETIME,
     * .TRUE., LFILDOB, ITIMES, SVALUES, DVALUES, KVALS, NVALS,
     * IBDATE, IQUAL, LQUAL, LQREAD, CUNITS, CTYPE, IUHEAD,
     * KUHEAD, NUHEAD, COORDS, ICDESC, LCOORDS, INFLAG, ISTAT)
C
C
      RETURN
C
      END
