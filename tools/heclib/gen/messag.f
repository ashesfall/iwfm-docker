      INTEGER FUNCTION MESSAG (IUNIT,IOUT,CNAME)
C
C     ROUTINE TO WRITE REQUESTED MESSAGE
C     IUNIT- FILE CONTAINING MESSAGES
C     IOUT-UNIT TO WRITE MESSAGES ON
C     CNAME - NAME OF MESSAGE
      CHARACTER CNAME*(*)
      CHARACTER CLINE*80, CBEG*8, CEND*8
C
      DATA CBEG /'#MESS   '/
      DATA CEND /'#ENDMESS'/
C
C
      NC = LEN (CNAME)
      REWIND IUNIT
      MESSAG=0
   10 CONTINUE
      READ (IUNIT,20,END=100) CLINE
 20   FORMAT (A)
      IF (CLINE(1:5).NE.CBEG(1:5)) GO TO 10
      J = NINDX ( CLINE(7:30), ' ' ) + 6
      IF (J .LT. 7) GO TO 10
      IF ( CLINE(J:J+NC-1) .NE. CNAME ) GO TO 10
C
 30   CALL CHRBLK (CLINE)
      READ (IUNIT,20,END=100) CLINE
      IF (CLINE(1:8).EQ.CEND) RETURN
      MESSAG = MESSAG + 1
      NLEN = MAX(NINDXR(CLINE,' '),1)
      WRITE (IOUT,40) CLINE(1:NLEN)
 40   FORMAT (1X,A)
      GO TO 30
C
  100 RETURN
      END