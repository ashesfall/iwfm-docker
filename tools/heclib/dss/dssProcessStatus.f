      SUBROUTINE DSSPROCESSSTATUS (TOTALNUMB, CURRENTNUMB,
     * NUMB_ERRORS)
C	
C
      INTEGER CURRENTNUMB, TOTALNUMB, NUMB_ERRORS
C	
      COMMON /ZSTATUS/ TOTAL_NUMB,  CURRENT_NUMB,
     *                 INTERRUPT, NERROR, MAXERROR
      INTEGER TOTAL_NUMB, CURRENT_NUMB, INTERRUPT
      INTEGER NERROR, MAXERROR
C
      TOTALNUMB = TOTAL_NUMB
      CURRENTNUMB = CURRENT_NUMB
	NUMB_ERRORS = NERROR
C
      RETURN
      END
