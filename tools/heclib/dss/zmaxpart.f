      SUBROUTINE ZMAXPART (IFLTAB, IMXPART)
C
C     Gets the maximum lengths for parts.
C     Used in generating a sort file for cataloging.
C
      INTEGER IFLTAB(*), IMXPART(6)
C
      INCLUDE 'zdsskz.h'
C
C
      CALL ZRDPRM(IFLTAB, .FALSE.)
      DO 40 I=1,6
         CALL GETHOL(IFLTAB(KMXPRT), I, IMXPART(I))
 40   CONTINUE
C
      RETURN
      END
