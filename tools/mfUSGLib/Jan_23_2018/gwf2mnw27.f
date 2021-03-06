      MODULE GWFMNW2MODULE
        INTEGER,SAVE,POINTER  ::NMNW2,MNWMAX,NMNWVL,IWL2CB,MNWPRNT
        INTEGER,SAVE,POINTER  ::NODTOT,INTTOT,NTOTNOD
        DOUBLE PRECISION, SAVE,POINTER :: SMALL
        CHARACTER(LEN=20),SAVE, DIMENSION(:),   POINTER     ::WELLID
        CHARACTER(LEN=16),SAVE, DIMENSION(:),   POINTER     ::MNWAUX
        DOUBLE PRECISION, SAVE, DIMENSION(:,:), POINTER     ::MNW2
        DOUBLE PRECISION, SAVE, DIMENSION(:,:), POINTER     ::MNWNOD
        DOUBLE PRECISION, SAVE, DIMENSION(:,:), POINTER     ::MNWINT
        DOUBLE PRECISION, SAVE, DIMENSION(:,:,:), POINTER     ::CapTable
      TYPE GWFMNWTYPE
        INTEGER,POINTER  ::NMNW2,MNWMAX,NMNWVL,IWL2CB,MNWPRNT
        INTEGER,POINTER  ::NODTOT,INTTOT,NTOTNOD
        DOUBLE PRECISION, POINTER :: SMALL
        CHARACTER(LEN=20), DIMENSION(:),   POINTER     ::WELLID
        CHARACTER(LEN=16), DIMENSION(:),   POINTER     ::MNWAUX
        DOUBLE PRECISION,  DIMENSION(:,:), POINTER     ::MNW2
        DOUBLE PRECISION,  DIMENSION(:,:), POINTER     ::MNWNOD
        DOUBLE PRECISION,  DIMENSION(:,:), POINTER     ::MNWINT
        DOUBLE PRECISION,  DIMENSION(:,:,:), POINTER     ::CapTable
      END TYPE
      TYPE(GWFMNWTYPE), SAVE:: GWFMNWDAT(10)
      END MODULE GWFMNW2MODULE


      SUBROUTINE GWF2MNW27AR(IN,IGRID)
C     ******************************************************************
C     ALLOCATE ARRAY STORAGE FOR MNW2 PACKAGE.
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IOUT,NLAY
      USE GWFMNW2MODULE, ONLY:NMNW2,MNWMAX,NMNWVL,IWL2CB,MNWPRNT,
     1                       NODTOT,INTTOT,MNWAUX,MNW2,MNWNOD,MNWINT,
     2                       CapTable,SMALL,NTOTNOD,WELLID
C
      CHARACTER*200 LINE
C     ------------------------------------------------------------------
C
C1------Allocate scalar variables, which makes it possible for multiple
C1------grids to be defined.
      ALLOCATE(NMNW2,MNWMAX,NTOTNOD,IWL2CB,MNWPRNT,NODTOT,INTTOT,SMALL,
     1 NMNWVL)
C
C2------IDENTIFY PACKAGE AND INITIALIZE NMNW2.
      WRITE(IOUT,1)IN
    1 format(/,1x,'MNW2 -- MULTI-NODE WELL 2 PACKAGE, VERSION 7,',
     +' 12/18/2009.',/,4X,'INPUT READ FROM UNIT ',i3)
      NMNW2=0
      ntotnod=0
C
C3------READ MAXIMUM NUMBER OF MNW2 WELLS, UNIT OR FLAG FOR
C3------CELL-BY-CELL FLOW TERMS, AND PRINT FLAG
      CALL URDCOM(IN,IOUT,LINE)
      LLOC=1
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,MNWMAX,R,IOUT,IN)
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IWL2CB,R,IOUT,IN)
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,MNWPRNT,R,IOUT,IN)
c
      write(iout,3) MNWMAX
    3 format(1h ,'MAXIMUM OF',i5,' ACTIVE MULTI-NODE WELLS AT ONE TIME')
      write(iout,*)
      if(IWL2CB.gt.0) write(iout,9) IWL2CB
    9 format(1x, 'CELL-BY-CELL FLOWS WILL BE RECORDED ON UNIT', i3)
      if(IWL2CB.lt.0) write(iout,*) 'IWL2CB = ',IWL2CB
      if(IWL2CB.lt.0) write(iout,8)
    8 format(1x,'CELL-BY-CELL FLOWS WILL BE PRINTED WHEN ICBCFL NOT 0')
      write(iout,*) 'MNWPRNT = ',MNWPRNT
cdebug NoMoIter can be set here and used to force the solution to stop after
cdebug a certain amount of flow solution iterations (used for debugging)
c      NoMoIter=9999
c      write(iout,7) NoMoIter
c    7 format(1x,'Flow rates will not be estimated after the',i4,'th',
c     +          ' iteration')
c
C4------READ AUXILIARY VARIABLES
      ALLOCATE (MNWAUX(20))
      NAUX=0
   10 CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,IN)
c      IF(LINE(ISTART:ISTOP).EQ.'CBCALLOCATE' .OR.
c     1   LINE(ISTART:ISTOP).EQ.'CBC') THEN
c         IMNWAL=1
c         WRITE(IOUT,11)
c   11    FORMAT(1X,'MEMORY IS ALLOCATED FOR CELL-BY-CELL BUDGET TERMS')
c         GO TO 10
      IF(LINE(ISTART:ISTOP).EQ.'AUXILIARY' .OR.
     1        LINE(ISTART:ISTOP).EQ.'AUX') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,IN)
         IF(NAUX.LT.5) THEN
            NAUX=NAUX+1
            MNWAUX(NAUX)=LINE(ISTART:ISTOP)
            WRITE(IOUT,12) MNWAUX(NAUX)
   12       FORMAT(1X,'AUXILIARY MNW2 VARIABLE: ',A)
         END IF
         GO TO 10
      END IF
C
C5------ALLOCATE SPACE FOR MNW2 ARRAYS.
C5------FOR EACH WELL, THERE ARE 30 DATA VALUES PLUS THE AUXILIARY VARIABLES
      NMNWVL=30+NAUX
      ALLOCATE (MNW2(NMNWVL,MNWMAX))
C5------FOR EACH NODE, THERE ARE 31 DATA VALUES
c approximate number of nodes= max mnw wells * number of layers, this works well
c if all are mostly vertical wells.  add 10*nlay+25 for extra room.  ispmnwn is
c passed out to RP routine to check allocation while reading actual # nodes used
      NODTOT=(MNWMAX*NLAY)+(10*NLAY)+25
      ALLOCATE (MNWNOD(34,NODTOT))
C5------FOR EACH INTERVAL, THERE ARE 11 DATA VALUES
      ALLOCATE (MNWINT(11,NODTOT))
C5------FOR Capacity Table,
c  27 is the hard-wired number of entries allowed in the Capacity Table (CapTable)
c  2 is the number of fields in the Capacity Table (CapTable): Lift (1) and Q (2)
      ALLOCATE (CapTable(mnwmax,27,2))
C5------FOR WELLID array, add an extra spot
      ALLOCATE (WELLID(mnwmax+1))
C
C7------SAVE POINTERS TO DATA AND RETURN.
      CALL SGWF2MNW2PSV(IGRID)
      RETURN
      END
C
      SUBROUTINE GWF2MNW27DA(IGRID)
C  Deallocate MNW MEMORY
      USE GWFMNW2MODULE
C
        CALL SGWF2MNW2PNT(IGRID)
        DEALLOCATE(NMNW2)
        DEALLOCATE(MNWMAX)
        DEALLOCATE(NMNWVL)
        DEALLOCATE(IWL2CB)
        DEALLOCATE(MNWPRNT)
        DEALLOCATE(NODTOT)
        DEALLOCATE(INTTOT)
        DEALLOCATE(NTOTNOD)
        DEALLOCATE(SMALL)
        DEALLOCATE(WELLID)
        DEALLOCATE(MNWAUX)
        DEALLOCATE(MNW2)
        DEALLOCATE(MNWNOD)
        DEALLOCATE(MNWINT)
        DEALLOCATE(CapTable)
C
      RETURN
      END
      SUBROUTINE SGWF2MNW2PNT(IGRID)
C  Change MNW data to a different grid.
      USE GWFMNW2MODULE
C
        NMNW2=>GWFMNWDAT(IGRID)%NMNW2
        MNWMAX=>GWFMNWDAT(IGRID)%MNWMAX
        NMNWVL=>GWFMNWDAT(IGRID)%NMNWVL
        IWL2CB=>GWFMNWDAT(IGRID)%IWL2CB
        MNWPRNT=>GWFMNWDAT(IGRID)%MNWPRNT
        NODTOT=>GWFMNWDAT(IGRID)%NODTOT
        INTTOT=>GWFMNWDAT(IGRID)%INTTOT
        NTOTNOD=>GWFMNWDAT(IGRID)%NTOTNOD
        SMALL=>GWFMNWDAT(IGRID)%SMALL
        WELLID=>GWFMNWDAT(IGRID)%WELLID
        MNWAUX=>GWFMNWDAT(IGRID)%MNWAUX
        MNW2=>GWFMNWDAT(IGRID)%MNW2
        MNWNOD=>GWFMNWDAT(IGRID)%MNWNOD
        MNWINT=>GWFMNWDAT(IGRID)%MNWINT
        CapTable=>GWFMNWDAT(IGRID)%CapTable
C
      RETURN
      END
      SUBROUTINE SGWF2MNW2PSV(IGRID)
C  Save MNW2 data for a grid.
      USE GWFMNW2MODULE
C
        GWFMNWDAT(IGRID)%NMNW2=>NMNW2
        GWFMNWDAT(IGRID)%MNWMAX=>MNWMAX
        GWFMNWDAT(IGRID)%NMNWVL=>NMNWVL
        GWFMNWDAT(IGRID)%IWL2CB=>IWL2CB
        GWFMNWDAT(IGRID)%MNWPRNT=>MNWPRNT
        GWFMNWDAT(IGRID)%NODTOT=>NODTOT
        GWFMNWDAT(IGRID)%INTTOT=>INTTOT
        GWFMNWDAT(IGRID)%NTOTNOD=>NTOTNOD
        GWFMNWDAT(IGRID)%SMALL=>SMALL
        GWFMNWDAT(IGRID)%WELLID=>WELLID
        GWFMNWDAT(IGRID)%MNWAUX=>MNWAUX
        GWFMNWDAT(IGRID)%MNW2=>MNW2
        GWFMNWDAT(IGRID)%MNWNOD=>MNWNOD
        GWFMNWDAT(IGRID)%MNWINT=>MNWINT
        GWFMNWDAT(IGRID)%CapTable=>CapTable
C
      RETURN
      END
