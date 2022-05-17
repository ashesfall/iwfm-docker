C-----------------------------------------------------------------------
      SUBROUTINE GWT2STO1BD(KSTP,KPER,ICOMP,ISS)
C     ******************************************************************
C     CALCULATE MASS BUDGET TERMS FOR ALL TRANSPORT CELLS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,   ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,BUFF,NODES,IUNSTR,
     1  AMAT,IA,JA,TOP,BOT,AREA,Sn,So,NEQS,INCLN
      USE CLN1MODULE, ONLY: ACLNNDS,NCLNNDS
      USE GWFBASMODULE,ONLY:MSUM,ISPCFL,IAUXSV,DELT,PERTIM,TOTIM,DELT
      USE GWTBCTMODULE, ONLY: ICBUND,CONC,MSUMT,VBVLT,VBNMT,IBCTCB,
     1 IADSORB,ADSORB,FLICH,PRSITY,CONCO,ICT
C
      CHARACTER*16 TEXT(2)
      DOUBLE PRECISION RATIN,RATOUT,QQ,VODT,ADSTERM,FL,CW,CWO,ALENG,
     *  DTERMS,RTERMS,VOLU
      DATA TEXT(1) /'    MASS STORAGE'/
      DATA TEXT(2) /'CLN MASS STORAGE'/
C     ------------------------------------------------------------------
C
C1------CLEAR RATIN AND RATOUT ACCUMULATORS, AND SET CELL-BY-CELL
C1------BUDGET FLAG.
      ZERO=0.
      RATIN=ZERO
      RATOUT=ZERO
      IBD=0
      IF(IBCTCB.LT.0 .AND. ISPCFL.NE.0) IBD=-1
      IF(IBCTCB.GT.0) IBD=ISPCFL
      IBDLBL=0
C
C2------CLEAR THE BUFFER.
      DO 50 N=1,NEQS
      BUFF(N)=ZERO
50    CONTINUE
C
C3------LOOP THROUGH EACH NODE AND CALCULATE STORAGE
      DO 100 N=1,NEQS
C
C4-----IF THE CELL IS NOT PCB OR WRONG COMPONENT SPECIES, IGNORE IT.
      IF(ICBUND(N).EQ.0)GO TO 99
C
      IF(N.LE.NODES)THEN
        ALENG = TOP(N) - BOT(N)
      ELSE
        ALENG = ACLNNDS(N-NODES,4)
      ENDIF
      VOLU = AREA(N) * ALENG
      VODT = VOLU / DELT
      QQ = 0.0
      IF(ICT.EQ.0)THEN
C5-------STORAGE TERM ON SOIL
        IF(N.LE.NODES.AND.IADSORB.EQ.1)THEN
          ADSTERM = ADSORB(N,ICOMP) * VODT
          QQ = ADSTERM * (CONC(N,ICOMP) - CONCO(N,ICOMP))
        ELSEIF(N.LE.NODES.AND.IADSORB.EQ.2)THEN
          ADSTERM = ADSORB(N,ICOMP) * VODT
          FL = FLICH(N,ICOMP)
          CW = 0.0
          CWO = 0.0
          IF(CONC(N,ICOMP).GT.0.0) CW = CONC(N,ICOMP)
          IF(CONCO(N,ICOMP).GT.0.0) CWO = CONCO(N,ICOMP)
          QQ = ADSTERM * (CW**FL - CWO**FL)
        ENDIF
C-----------------------------------------------------
C6-------STORAGE TERM IN WATER
        DTERMS = 0.0
        RTERMS = 0.0
        CALL GWT2BCT1STOW(N,ICOMP,DTERMS,RTERMS,VODT,VOLU,ALENG,ISS)
        QQ = QQ - DTERMS * CONC(N,ICOMP) + RTERMS
      ELSE   !-----------------------TOTAL CONCENTRATION FORMULATION
C7-------NET STORAGE TERM FOR TOTAL CONCENTRATION FORMULATION
        QQ = QQ + VODT * CONC(N,ICOMP)
     *          - VODT * CONCO(N,ICOMP)
      ENDIF
      QQ = - QQ  ! STORAGE TERM NEGATIVE IS INFLOW AS PER MODFLOW CONVENTION
      Q = QQ
C
C8------PRINT FLOW RATE IF REQUESTED.
      IF(IBD.LT.0) THEN
         IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT(1),KPER,KSTP
   61    FORMAT(1X,/1X,A,'   PERIOD ',I4,'   STEP ',I3)
        IF(IUNSTR.EQ.0.AND.N.LE.NODES)THEN
          IL = (N-1) / (NCOL*NROW) + 1
          IJ = N - (IL-1)*NCOL*NROW
          IR = (IJ-1)/NCOL + 1
          IC = IJ - (IR-1)*NCOL
           WRITE(IOUT,62) IL,IR,IC,Q
   62    FORMAT(1X,'   LAYER ',I5,'   ROW ',I6,'   COL ',I6,
     1       '   FLUX ',1PG15.6)
        ELSE
           WRITE(IOUT,63) N,Q
   63    FORMAT(1X,'    NODE ',I8,'   FLUX ',1PG15.6)
        ENDIF
        IBDLBL=1
      END IF
C
C9------ADD FLOW RATE TO BUFFER.
      BUFF(N)=BUFF(N)+QQ
C
C10-----SEE IF FLUX IS POSITIVE OR NEGATIVE.
      IF(QQ.GE.ZERO) THEN
C
C11-----POSITIVE FLOW RATE. ADD IT TO RATIN
        RATIN=RATIN+QQ
      ELSE
C
C12-----NEGATIVE FLOW RATE. ADD IT TO RATOUT
        RATOUT=RATOUT-QQ
      END IF
   99 CONTINUE
C
100   CONTINUE
C
C13------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A 3-D ARRAY,
C13------CALL UBUDSV TO SAVE THEM.
      IF(IBD.EQ.1)THEN
        IF(IUNSTR.EQ.0)THEN
          CALL UBUDSV(KSTP,KPER,TEXT(1),IBCTCB,BUFF,NCOL,NROW,
     1                          NLAY,IOUT)
        ELSE
          CALL UBUDSVU(KSTP,KPER,TEXT(1),IBCTCB,BUFF,NODES,
     1                          IOUT,PERTIM,TOTIM)
        ENDIF
        IF(INCLN.GT.0)THEN
           CALL UBUDSVU(KSTP,KPER,TEXT(2),IBCTCB,BUFF(NODES+1:NEQS),
     1                 NCLNNDS,IOUT,PERTIM,TOTIM)
        ENDIF
      ENDIF
C
C14------MOVE RATES, VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 RIN=RATIN
      ROUT=RATOUT
      VBVLT(3,MSUMT,ICOMP)=RIN
      VBVLT(4,MSUMT,ICOMP)=ROUT
      VBVLT(1,MSUMT,ICOMP)=VBVLT(1,MSUMT,ICOMP)+RATIN*DELT
      VBVLT(2,MSUMT,ICOMP)=VBVLT(2,MSUMT,ICOMP)+RATOUT*DELT
      VBNMT(MSUMT,ICOMP)=TEXT(1)
C
C15------INCREMENT BUDGET TERM COUNTER(MSUM).
      MSUMT=MSUMT+1
C
C16------RETURN
      RETURN
      END
C-----------------------------------------------------------------------
      SUBROUTINE GWT2DCY1BD(KSTP,KPER,ICOMP)
C     ******************************************************************
C     CALCULATE MASS DECAY TERMS FOR ALL TRANSPORT CELLS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,   ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,BUFF,NODES,IUNSTR,
     1  AMAT,IA,JA,TOP,BOT,AREA,Sn,So,NEQS,INCLN
      USE CLN1MODULE, ONLY: ACLNNDS,NCLNNDS
      USE GWFBASMODULE,ONLY:MSUM,ISPCFL,IAUXSV,DELT,PERTIM,TOTIM,DELT
      USE GWTBCTMODULE, ONLY: ICBUND,CONC,MSUMT,VBVLT,VBNMT,IBCTCB,
     1 IADSORB,ADSORB,FLICH,PRSITY,CONCO,ICT,IZOD,IFOD,ZODRW,FODRW,
     1  ZODRS,FODRS
C
      CHARACTER*16 TEXT(2)
      DOUBLE PRECISION RATIN,RATOUT,QQ,VOLU,ADSTERM,FL,CW,CWO,ALENG,X,Y,
     1  CEPS,EPS,CT
      DATA TEXT(1) /'      MASS DECAY'/
      DATA TEXT(2) /'  CLN MASS DECAY'/
C     ------------------------------------------------------------------
C1------RETURN IF NO DECAY IN SIMULATION
      IF(IZOD.EQ.0.AND.IFOD.EQ.0) RETURN
C2------CLEAR RATIN AND RATOUT ACCUMULATORS, AND SET CELL-BY-CELL
C2------BUDGET FLAG.
      ZERO=0.
      RATIN=ZERO
      RATOUT=ZERO
      IBD=0
      IF(IBCTCB.LT.0 .AND. ISPCFL.NE.0) IBD=-1
      IF(IBCTCB.GT.0) IBD=ISPCFL
      IBDLBL=0
C
C3------CLEAR THE BUFFER.
      DO 50 N=1,NEQS
      BUFF(N)=ZERO
50    CONTINUE
C
C4------LOOP THROUGH EACH NODE AND CALCULATE STORAGE
      DO 100 N=1,NEQS
C
C5-----IF THE CELL IS NOT PCB OR WRONG COMPONENT SPECIES, IGNORE IT.
      IF(ICBUND(N).EQ.0)GO TO 99
C
      IF(N.LE.NODES)THEN
        ALENG = TOP(N) - BOT(N)
      ELSE
        ALENG = ACLNNDS(N-NODES,4)
      ENDIF
      VOLU = AREA(N) * ALENG
      QQ = 0.0
C-----------------------------------------------------------------------------
      IF(ICT.EQ.0)THEN  !----------WATER PHASE CONCENTRATION FORMULATION
C-----------------------------------------------------------------------------
C6-------DECAY TERM ON SOIL (NO ADSORPTION ON CLN)
        IF(N.LE.NODES)THEN
C
C7---------ZERO ORDER DECAY ON SOIL
          IF(IZOD.GE.2.AND.IADSORB.GT.0)THEN
            CT = - VOLU * ZODRS(N,ICOMP)
            EPS = 0.01
            CEPS = MAX(0.0,CONC(N,ICOMP))
            X = CEPS /EPS
            CALL SMOOTH(X,Y)
            QQ =  CT * Y
          ENDIF
C
C8---------FIRST ORDER DECAY ON SOIL
          IF(IFOD.GE.2.AND.IADSORB.GT.0)THEN
            CT = -ADSORB(N,ICOMP) * VOLU * FODRS(N,ICOMP)
            IF(IADSORB.EQ.1)THEN
C9--------------FOR LINEAR ADSORPTION
              QQ = QQ + CT * CONC(N,ICOMP)
            ELSE
C10--------------FOR NON-LINEAR ADSORPTION FILL AS NEWTON
              ETA = FLICH(N,ICOMP)
              QQ =  CT * CONC(N,ICOMP) ** ETA
            ENDIF
          ENDIF
        ENDIF
C-----------------------------------------------------------------------------
C11-------DECAY TERM IN WATER
C-----------------------------------------------------------------------------
C12-------ZERO ORDER DECAY IN WATER
        IF(IZOD.EQ.1.OR.IZOD.EQ.3)THEN
          CT = -Sn(N)* VOLU * ZODRW(N,ICOMP)
          EPS = 0.01
          CEPS = MAX(0.0,CONC(N,ICOMP))
          X = CEPS /EPS
          CALL SMOOTH(X,Y)
          QQ =  QQ + CT * Y
        ENDIF
C
C13-------FIRST ORDER DECAY IN WATER
        IF(IFOD.EQ.1.OR.IFOD.EQ.3)THEN
          CT =  -Sn(N)* VOLU * FODRW(N,ICOMP)
          QQ = QQ + CT * CONC(N,ICOMP)
        ENDIF
      ELSE
CSP FINISH TOTAL CONCENTRATION FORMULATION
      ENDIF
      Q = QQ
C
C14-----PRINT FLOW RATE IF REQUESTED.
      IF(IBD.LT.0) THEN
         IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT(1),KPER,KSTP
   61    FORMAT(1X,/1X,A,'   PERIOD ',I4,'   STEP ',I3)
        IF(IUNSTR.EQ.0.AND.N.LE.NODES)THEN
          IL = (N-1) / (NCOL*NROW) + 1
          IJ = N - (IL-1)*NCOL*NROW
          IR = (IJ-1)/NCOL + 1
          IC = IJ - (IR-1)*NCOL
           WRITE(IOUT,62) L,IL,IR,IC,Q
   62    FORMAT(1X,'CBC  ',I6,'   LAYER ',I3,'   ROW ',I5,'   COL ',I5,
     1       '  DECAY ',1PG15.6)
        ELSE
           WRITE(IOUT,63) L,N,Q
   63    FORMAT(1X,'CBC  ',I6,'    NODE ',I8,'  DECAY ',1PG15.6)
        ENDIF
        IBDLBL=1
      END IF
C
C15-----ADD FLOW RATE TO BUFFER.
      BUFF(N)=BUFF(N)+Q
C
C16-----SEE IF FLUX IS POSITIVE OR NEGATIVE.
      IF(QQ.GE.ZERO) THEN
C
C17-----POSITIVE FLOW RATE. ADD IT TO RATIN
        RATIN=RATIN+QQ
      ELSE
C
C18-----NEGATIVE FLOW RATE. ADD IT TO RATOUT
        RATOUT=RATOUT-QQ
      END IF
   99 CONTINUE
C
100   CONTINUE
C
C19------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A 3-D ARRAY,
C19------CALL UBUDSV TO SAVE THEM.
      IF(IBD.EQ.1)THEN
        IF(IUNSTR.EQ.0)THEN
          CALL UBUDSV(KSTP,KPER,TEXT(1),IBCTCB,BUFF,NCOL,NROW,
     1                          NLAY,IOUT)
        ELSE
          CALL UBUDSVU(KSTP,KPER,TEXT(1),IBCTCB,BUFF,NODES,
     1                          IOUT,PERTIM,TOTIM)
        ENDIF
        IF(INCLN.GT.0)THEN
           CALL UBUDSVU(KSTP,KPER,TEXT(2),IBCTCB,BUFF(NODES+1:NEQS),
     1                 NCLNNDS,IOUT,PERTIM,TOTIM)
        ENDIF
      ENDIF
C
C20------MOVE RATES, VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 RIN=RATIN
      ROUT=RATOUT
      VBVLT(3,MSUMT,ICOMP)=RIN
      VBVLT(4,MSUMT,ICOMP)=ROUT
      VBVLT(1,MSUMT,ICOMP)=VBVLT(1,MSUMT,ICOMP)+RATIN*DELT
      VBVLT(2,MSUMT,ICOMP)=VBVLT(2,MSUMT,ICOMP)+RATOUT*DELT
      VBNMT(MSUMT,ICOMP)=TEXT(1)
C
C21------INCREMENT BUDGET TERM COUNTER(MSUM).
      MSUMT=MSUMT+1
C
C22------RETURN
      RETURN
      END 
C-----------------------------------------------------------------------
      SUBROUTINE GWT2FMBE1BD(KSTP,KPER,ICOMP)
C     ******************************************************************
C     CALCULATE MASS BUDGET TERMS FOR ALL TRANSPORT CELLS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,   ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,BUFF,NODES,IUNSTR,
     1  NEQS,INCLN,IFMBC,FMBE
      USE CLN1MODULE, ONLY: ACLNNDS,NCLNNDS
      USE GWFBASMODULE,ONLY:MSUM,ISPCFL,IAUXSV,DELT,PERTIM,TOTIM,DELT
      USE GWTBCTMODULE, ONLY: ICBUND,CONC,MSUMT,VBVLT,VBNMT,CONCO
C
      CHARACTER*16 TEXT(2)
      DOUBLE PRECISION RATIN,RATOUT,QQ,VODT 
      DATA TEXT(1) /'   TRNSP FMB ERR'/
      DATA TEXT(2) /'TRNSP CLN FMBERR'/
C     ------------------------------------------------------------------
C
C1------CLEAR RATIN AND RATOUT ACCUMULATORS, AND SET CELL-BY-CELL
C1------BUDGET FLAG.
      ZERO=0.
      RATIN=ZERO
      RATOUT=ZERO
      IBD=0
      IF(IFMBC.LT.0 .AND. ISPCFL.NE.0) IBD=-1
      IF(IFMBC.GT.0) IBD=ISPCFL
      IBDLBL=0
C
C2------CLEAR THE BUFFER.
      DO 50 N=1,NEQS
      BUFF(N)=ZERO
50    CONTINUE
C
C3------LOOP THROUGH EACH NODE AND CALCULATE ERROR
      amaxerr = 0.0 
      nmax = 0
      DO 100 N=1,NEQS
C
C4-----IF THE CELL IS NOT PCB OR WRONG COMPONENT SPECIES, IGNORE IT.
      IF(ICBUND(N).EQ.0)GO TO 99
C
      QQ = -FMBE(N) * CONC(N,ICOMP)
      Q = QQ
      aerr = abs(qq )
      if(aerr.gt.amaxerr) then
          amaxerr = aerr
          nmax = n
      endif 
C
C8------PRINT FLOW RATE IF REQUESTED.
      IF(IBD.LT.0) THEN
         IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT(1),KPER,KSTP
   61    FORMAT(1X,/1X,A,'   PERIOD ',I4,'   STEP ',I3)
        IF(IUNSTR.EQ.0.AND.N.LE.NODES)THEN
          IL = (N-1) / (NCOL*NROW) + 1
          IJ = N - (IL-1)*NCOL*NROW
          IR = (IJ-1)/NCOL + 1
          IC = IJ - (IR-1)*NCOL
           WRITE(IOUT,62) IL,IR,IC,Q
   62    FORMAT(1X,'   LAYER ',I5,'   ROW ',I6,'   COL ',I6,
     1       '  ERROR ',1PG15.6)
        ELSE
           WRITE(IOUT,63) N,Q
   63    FORMAT(1X,'    NODE ',I8,'ERROR ',1PG15.6)
        ENDIF
        IBDLBL=1
      END IF
C
C9------ADD FLOW RATE TO BUFFER.
      BUFF(N)=BUFF(N)+QQ
C
C10-----SEE IF FLUX IS POSITIVE OR NEGATIVE.
      IF(QQ.GE.ZERO) THEN
C
C11-----POSITIVE FLOW RATE. ADD IT TO RATIN
        RATIN=RATIN+QQ
      ELSE
C
C12-----NEGATIVE FLOW RATE. ADD IT TO RATOUT
        RATOUT=RATOUT-QQ
      END IF
   99 CONTINUE
C
100      CONTINUE
       write(iout,*)'max transport fmbe and n are',amaxerr,nmax
C
C13------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A 3-D ARRAY,
C13------CALL UBUDSV TO SAVE THEM.
      IF(IBD.EQ.1)THEN
        IF(IUNSTR.EQ.0)THEN
          CALL SGWF2BAS7TE(KSTP,KPER,IPFLG,ISA)
        ELSE
          CALL SGWF2BAS7TEU(KSTP,KPER,IPFLG,ISA)  
        ENDIF
        IF(INCLN.GT.0)THEN
          CALL SCLN1TE(KSTP,KPER,IPFLG,ISA)
        ENDIF
      ENDIF
C
C14------MOVE RATES, VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 RIN=RATIN
      ROUT=RATOUT
      VBVLT(3,MSUMT,ICOMP)=RIN
      VBVLT(4,MSUMT,ICOMP)=ROUT
      VBVLT(1,MSUMT,ICOMP)=VBVLT(1,MSUMT,ICOMP)+RATIN*DELT
      VBVLT(2,MSUMT,ICOMP)=VBVLT(2,MSUMT,ICOMP)+RATOUT*DELT
      VBNMT(MSUMT,ICOMP)=TEXT(1)
C
C15------INCREMENT BUDGET TERM COUNTER(MSUM).
      MSUMT=MSUMT+1
C
C16------RETURN
      RETURN
      END
      SUBROUTINE SGWF2BAS7TEU(KSTP,KPER,IPFLG,ISA)
C     ******************************************************************
C     PRINT AND RECORD TRANSPORT MASS BALANCE ERROR FOR UNSTRUCTURED GWF GRID
C     RESULTING FROM FLOW BALANCE ERROR      
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,      ONLY:NCOL,NROW,NLAY,IXSEC,FMBE,NODLAY,
     1                      IBOUND,IOUT,NODES,BUFF,
     1   IFMBC,MBEGWUNF,MBEGWUNT,MBECLNUNF,MBECLNUNT             
      USE GWFBASMODULE,ONLY:PERTIM,TOTIM,IHEDFM,IHEDUN,LBHDSV,
     2                      CHEDFM,IOFLG
C
      CHARACTER*16 TEXT
      DATA TEXT /'    TRNS BAL ERR'/
C     ------------------------------------------------------------------
C
C4------FOR EACH LAYER: DETERMINE IF FMBE SHOULD BE PRINTED.
C4------IF SO THEN CALL ULAPRU TO PRINT FMBE.
      IF(ISA.NE.0) THEN
         IF(IXSEC.EQ.0) THEN
           DO 69 K=1,NLAY
           KK=K
           IF(IOFLG(K,1).EQ.0) GO TO 69
           NNDLAY = NODLAY(K)
           NSTRT = NODLAY(K-1)+1
           CALL ULAPRU(BUFF,TEXT,KSTP,KPER,
     1           NSTRT,NNDLAY,KK,IABS(IHEDFM),IOUT,PERTIM,TOTIM,NODES)
           IPFLG=1
   69      CONTINUE
C
C4A-----PRINT FMBE FOR CROSS SECTION.
         ELSE
           IF(IOFLG(1,1).NE.0) THEN
           CALL ULAPRU(BUFF,TEXT,KSTP,KPER,
     1           NSTRT,NNDLAY,-1,IABS(IHEDFM),IOUT,PERTIM,TOTIM,NODES)
             IPFLG=1
C
           END IF
         END IF
      END IF
C
C5------FOR EACH LAYER: DETERMINE IF FMBE SHOULD BE SAVED ON DISK.
C5------IF SO THEN CALL ULASAV OR ULASV2 TO SAVE FMBE.
      IFIRST=1
      IF(MBEGWUNT.LE.0) GO TO 80
      IF(IXSEC.EQ.0) THEN
        DO 79 K=1,NLAY
        KK=K
        IF(IOFLG(K,3).EQ.0) GO TO 79
        NNDLAY = NODLAY(K)
        NSTRT = NODLAY(K-1)+1
        IF(IFIRST.EQ.1) WRITE(IOUT,74) MBEGWUNT,KSTP,KPER
   74   FORMAT(1X,/1X,'FMBE WILL BE SAVED ON UNIT ',I8,
     1      ' AT END OF TIME STEP ',I8,', STRESS PERIOD ',I8)
        IFIRST=0
        IF(CHEDFM.EQ.' ') THEN
           CALL ULASAVU(BUFF,TEXT,KSTP,KPER,PERTIM,TOTIM,NSTRT,
     1                NNDLAY,KK,MBEGWUNT,NODES)
        ELSE
           CALL ULASV2U(BUFF,TEXT,KSTP,KPER,PERTIM,TOTIM,NSTRT,
     1             NNDLAY,KK,MBEGWUNT,CHEDFM,LBHDSV,IBOUND(NSTRT),NODES)
        END IF
c        IPFLG=1
   79   CONTINUE
C
C5A-----SAVE FMBE FOR CROSS SECTION.
      ELSE
        IF(IOFLG(1,3).NE.0) THEN
          WRITE(IOUT,74) MBEGWUNT,KSTP,KPER
          IF(CHEDFM.EQ.' ') THEN
             CALL ULASAVU(BUFF,TEXT,KSTP,KPER,PERTIM,TOTIM,NSTRT,
     1                NNDLAY,-1,MBEGWUNT,NODES)
          ELSE
             CALL ULASV2U(BUFF,TEXT,KSTP,KPER,PERTIM,TOTIM,NSTRT,
     1                  NNDLAY,-1,MBEGWUNT,CHEDFM,LBHDSV,IBOUND,NODES)
          END IF
c          IPFLG=1
        END IF
      END IF
C
C6------RETURN.
   80 CONTINUE
      RETURN
C
      END
      SUBROUTINE SGWF2BAS7TE(KSTP,KPER,IPFLG,ISA)
C     ******************************************************************
C     PRINT AND RECORD TRANSPORT MASS BALANCE ERROR FOR STRUCTURED GWF GRID
C     RESULTING FROM FLOW BALANCE ERROR 
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,      ONLY:NCOL,NROW,NLAY,IXSEC,FMBE,NODLAY,
     1                      IBOUND,IOUT,
     1   IFMBC,MBEGWUNF,MBEGWUNT,MBECLNUNF,MBECLNUNT        
      USE GWFBASMODULE,ONLY:PERTIM,TOTIM,IHEDFM,IHEDUN,LBHDSV,
     2                      CHEDFM,IOFLG
C
      REAL,          SAVE,    DIMENSION(:,:,:),    ALLOCATABLE ::BUFF
      CHARACTER*16 TEXT
      DATA TEXT /'    TRNS BAL ERR'/
C     ------------------------------------------------------------------
      ALLOCATE(BUFF(NCOL,NROW,NLAY))
C
C4------FOR EACH LAYER: DETERMINE IF FMBE SHOULD BE PRINTED.
C4------IF SO THEN CALL ULAPRS OR ULAPRW TO PRINT FMBE.
      IF(ISA.NE.0) THEN
         IF(IXSEC.EQ.0) THEN
           DO 69 K=1,NLAY
           KK=K
           IF(IOFLG(K,1).EQ.0) GO TO 69
           IF(IHEDFM.LT.0) CALL ULAPRS(BUFF(1,1,K),TEXT,KSTP,KPER,
     1               NCOL,NROW,KK,-IHEDFM,IOUT)
           IF(IHEDFM.GE.0) CALL ULAPRW(BUFF(1,1,K),TEXT,KSTP,KPER,
     1               NCOL,NROW,KK,IHEDFM,IOUT)
           IPFLG=1
   69      CONTINUE
C
C4A-----PRINT FMBE FOR CROSS SECTION.
         ELSE
           IF(IOFLG(1,1).NE.0) THEN
             IF(IHEDFM.LT.0) CALL ULAPRS(BUFF,TEXT,KSTP,KPER,
     1                 NCOL,NLAY,-1,-IHEDFM,IOUT)
             IF(IHEDFM.GE.0) CALL ULAPRW(BUFF,TEXT,KSTP,KPER,
     1                 NCOL,NLAY,-1,IHEDFM,IOUT)
             IPFLG=1
           END IF
         END IF
      END IF
C
C5------FOR EACH LAYER: DETERMINE IF FMBE SHOULD BE SAVED ON DISK.
C5------IF SO THEN CALL ULASAV OR ULASV2 TO SAVE FMBE.
      IFIRST=1
      IF(MBEGWUNT.LE.0) GO TO 80
      IF(IXSEC.EQ.0) THEN
        DO 79 K=1,NLAY
        NSTRT = NODLAY(K-1)+1
        KK=K
        IF(IOFLG(K,3).EQ.0) GO TO 79
        IF(IFIRST.EQ.1) WRITE(IOUT,74) MBEGWUNT,KSTP,KPER
   74   FORMAT(1X,/1X,'FMBE WILL BE SAVED ON UNIT ',I4,
     1      ' AT END OF TIME STEP ',I4,', STRESS PERIOD ',I4)
        IFIRST=0
        IF(CHEDFM.EQ.' ') THEN
           CALL ULASAV(BUFF(1,1,K),TEXT,KSTP,KPER,PERTIM,TOTIM,NCOL,
     1                NROW,KK,MBEGWUNT)
        ELSE
           CALL ULASV2(BUFF(1,1,K),TEXT,KSTP,KPER,PERTIM,TOTIM,NCOL,
     1                NROW,KK,MBEGWUNT,CHEDFM,LBHDSV,IBOUND(NSTRT))
        END IF
   79   CONTINUE
C
C5A-----SAVE FMBE FOR CROSS SECTION.
      ELSE
        IF(IOFLG(1,3).NE.0) THEN
          WRITE(IOUT,74) MBEGWUNT,KSTP,KPER
          IF(CHEDFM.EQ.' ') THEN
             CALL ULASAV(BUFF,TEXT,KSTP,KPER,PERTIM,TOTIM,NCOL,
     1                NLAY,-1,MBEGWUNT)
          ELSE
             CALL ULASV2(BUFF,TEXT,KSTP,KPER,PERTIM,TOTIM,NCOL,
     1                  NLAY,-1,MBEGWUNT,CHEDFM,LBHDSV,IBOUND)
          END IF
        END IF
      END IF
80    CONTINUE
      DEALLOCATE(BUFF)
C
C6------RETURN.
      RETURN
      END
      SUBROUTINE SCLN1TE(KSTP,KPER,IPFLG,ISA)
C     ******************************************************************
C     PRINT AND RECORD TRANSPORT MASS BALANCE ERROR IN CLN CELLS
C     RESULTING FROM FLOW BALANCE ERROR 
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,      ONLY:FMBE,IBOUND,IOUT,NODES,
     1   IFMBC,MBEGWUNF,MBEGWUNT,MBECLNUNF,MBECLNUNT      
      USE CLN1MODULE, ONLY:  NCLNNDS,ICLNHD
      USE GWFBASMODULE,ONLY:PERTIM,TOTIM,IHEDFM,IHEDUN,LBDDSV,
     2                      CHEDFM,CDDNFM,IOFLG
C
      CHARACTER*16 TEXT
      DOUBLE PRECISION SSTRT
      REAL,          SAVE,    DIMENSION(:),    ALLOCATABLE ::BUFF
C
      DATA TEXT /'CLN TRNS BAL ERR'/
C     ------------------------------------------------------------------
      ALLOCATE(BUFF(NCLNNDS))
C
C1------FOR EACH CLN NODE PUT FMBE IN BUFF IF PRINT OR SAVE IS REQUESTED.
      DO 59 N=1,NCLNNDS
C
C2------Save FMBE in buffer array BUFF
        NG = N+NODES
        BUFF(N)=FMBE(NG)
   59 CONTINUE
C
C3------CALL ULAPRS OR ULAPRW TO PRINT FMBE.
      IF(ISA.NE.0) THEN
        IF(IOFLG(1,1).NE.0) THEN
          IF(IHEDFM.LT.0) CALL ULAPRS(BUFF(1),TEXT,KSTP,KPER,
     1                  NCLNNDS,1,1,-IHEDFM,IOUT)
          IF(IHEDFM.GE.0) CALL ULAPRW(BUFF(1),TEXT,KSTP,KPER,
     1                  NCLNNDS,1,1,IHEDFM,IOUT)
          IPFLG=1
        ENDIF
C
      END IF
C
C4------DETERMINE IF FMBE SHOULD BE SAVED.
C4------IF SO THEN CALL A ULASAV OR ULASV2 TO RECORD FMBE.
      IFIRST=1
      IF(MBECLNUNT.LE.0) GO TO 80
        NSTRT = NODES+1
        IF(IOFLG(1,3).EQ.0) GO TO 80
        IF(IFIRST.EQ.1) WRITE(IOUT,74) MBECLNUNT,KSTP,KPER
   74   FORMAT(1X,/1X,'CLN FMBE WILL BE SAVED ON UNIT ',I4,
     1      ' AT END OF TIME STEP ',I3,', STRESS PERIOD ',I4)
        IFIRST=0
        IF(CHEDFM.EQ.' ') THEN
           CALL ULASAV(BUFF(1),TEXT,KSTP,KPER,PERTIM,TOTIM,NCLNNDS,
     1                1,1,MBECLNUNT)
        ELSE
           CALL ULASV2(BUFF(1),TEXT,KSTP,KPER,PERTIM,TOTIM,NCLNNDS,
     1                1,1,MBECLNUNT,CHEDFM,LBDDSV,IBOUND(NSTRT))
        END IF
C
80    CONTINUE
      DEALLOCATE(BUFF)

C
C5------RETURN.
      RETURN
      END
C
C-----------------------------------------------------------------------
      MODULE GWTPCBMODULE
        INTEGER,SAVE,POINTER  ::NPCB,MXPCB,IPCBCB,NPCBVL,IPRPCB
        INTEGER,SAVE,POINTER  ::NPPCB,IPCBPB,NNPPCB
        CHARACTER(LEN=16),SAVE, DIMENSION(:),   ALLOCATABLE     ::PCBAUX
        REAL,             SAVE, DIMENSION(:,:), ALLOCATABLE     ::PCB
        REAL,       SAVE, DIMENSION(:,:), ALLOCATABLE  ::AMATDIAG,RHSKPT
      END MODULE GWTPCBMODULE
C
      SUBROUTINE GWT2PCB1AR(IN)
C     ******************************************************************
C     ALLOCATE ARRAY STORAGE FOR PRESCRIBED CONCENTRATION BOUNDARY PACKAGE
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,  ONLY:IOUT,NCOL,NROW,NLAY,IFREFM,NODES,IUNSTR,ITRNSP,
     1                  NEQS
      USE GWTPCBMODULE
      USE GWTBCTMODULE, ONLY: MCOMP
C
      CHARACTER*200 LINE
C     ------------------------------------------------------------------
C-----PCB REQUIRED ONLY IF TRANSPORT SIMULATION IS PERFORMED
      IF(ITRNSP.EQ.0)THEN
        IN = 0
        RETURN
      ENDIF
C     ------------------------------------------------------------------
      ALLOCATE(NPCB,MXPCB,IPCBCB,NPCBVL,IPRPCB)
      ALLOCATE(NPPCB,IPCBPB,NNPPCB)
C
C1------IDENTIFY PACKAGE AND INITIALIZE NPCB.
      WRITE(IOUT,1)IN
    1 FORMAT(1X,/1X,'PCB -- PRESCRIBED CONCENTRATION PACKAGE,',1X,
     1 'VERSION 7, 2/2/2010 INPUT READ FROM UNIT ',I4)
      NPCB=0
      NNPPCB=0
C
C2------READ MAXIMUM NUMBER OF PCBS AND UNIT OR FLAG FOR
C2------CELL-BY-CELL FLOW TERMS.
      CALL URDCOM(IN,IOUT,LINE)
      CALL UPARLSTAL(IN,IOUT,LINE,NPPCB,MXPW)
      IF(IFREFM.EQ.0) THEN
         READ(LINE,'(2I10)') MXPCB,IPCBCB
         LLOC=21
      ELSE
         LLOC=1
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,MXPCB,R,IOUT,IN)
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IPCBCB,R,IOUT,IN)
      END IF
      WRITE(IOUT,3) MXPCB
    3 FORMAT(1X,'MAXIMUM OF ',I6,' ACTIVE PRESCRIBED CONCS AT ONE TIME')
      IF(IPCBCB.LT.0) WRITE(IOUT,7)
    7 FORMAT(1X,'CELL-BY-CELL FLUXES WILL BE PRINTED WHEN ISPCFL NOT 0')
      IF(IPCBCB.GT.0) WRITE(IOUT,8) IPCBCB
    8 FORMAT(1X,'CELL-BY-CELL FLOXES WILL BE SAVED ON UNIT ',I4)
C
C3------READ PRINT FLAG.
      ALLOCATE(PCBAUX(20))
      IPRPCB=1
   10 CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,IN)
      IF(LINE(ISTART:ISTOP).EQ.'NOPRINT') THEN
         WRITE(IOUT,13)
   13    FORMAT(1X,'LIST OF PRESCRIBED CONC CELLS WILL NOT BE PRINTED')
         IPRPCB = 0
         GO TO 10
      END IF
C
C4------ALLOCATE SPACE FOR THE PCB DATA.
      IPCBPB=MXPCB+1
      MXPCB=MXPCB+MXPW
      IF(MXPCB.LT.1) THEN
         WRITE(IOUT,17)
   17    FORMAT(1X,
     1'Deactivating the PCBl Package because MXPCB=0')
         IN=0
      END IF
      NPCBVL = 5
      NAUX = 0
      ALLOCATE (PCB(NPCBVL,MXPCB))
      ALLOCATE (AMATDIAG(MXPCB,MCOMP),RHSKPT(MXPCB,MCOMP))
C
C5------READ NAMED PARAMETERS.
      WRITE(IOUT,18) NPPCB
   18 FORMAT(1X,//1X,I5,' PCB parameters')
      IF(NPPCB.GT.0) THEN
        LSTSUM=IPCBPB
        DO 120 K=1,NPPCB
          LSTBEG=LSTSUM
          CALL UPARLSTRP(LSTSUM,MXPCB,IN,IOUT,IP,'PCB','Q',1,
     &                   NUMINST)
          NLST=LSTSUM-LSTBEG
          IF(NUMINST.EQ.0) THEN
C5A-----READ PARAMETER WITHOUT INSTANCES.
            IF(IUNSTR.EQ.0)THEN
              CALL ULSTRD(NLST,PCB,LSTBEG,NPCBVL,MXPCB,1,IN,IOUT,
     &      '  PCB NO.  LAYER   ROW   COL   SPECIES NO.  STRESS FACTOR',
     &        PCBAUX,20,NAUX,IFREFM,NCOL,NROW,NLAY,5,5,IPRPCB)
            ELSE
             CALL ULSTRDU(NLST,PCB,LSTBEG,NPCBVL,MXPCB,1,IN,IOUT,
     &      '  PCB NO.  LAYER   ROW   COL   SPECIES NO.  STRESS FACTOR',
     &        PCBAUX,20,NAUX,IFREFM,NEQS,5,5,IPRPCB)
            ENDIF
          ELSE
C5B-----READ INSTANCES.
            NINLST=NLST/NUMINST
            DO 110 I=1,NUMINST
            CALL UINSRP(I,IN,IOUT,IP,IPRPCB)
            IF(IUNSTR.EQ.0)THEN
              CALL ULSTRD(NINLST,PCB,LSTBEG,NPCBVL,MXPCB,1,IN,IOUT,
     &      '  PCB NO.  LAYER   ROW   COL   SPECIES NO.  STRESS FACTOR',
     &        PCBAUX,20,NAUX,IFREFM,NCOL,NROW,NLAY,5,5,IPRPCB)
            ELSE
             CALL ULSTRDU(NINLST,PCB,LSTBEG,NPCBVL,MXPCB,1,IN,IOUT,
     &      '  PCB NO.  LAYER   ROW   COL   SPECIES NO.  STRESS FACTOR',
     &        PCBAUX,20,NAUX,IFREFM,NEQS,5,5,IPRPCB)
            ENDIF
            LSTBEG=LSTBEG+NINLST
  110       CONTINUE
          END IF
  120   CONTINUE
      END IF
C
C6------RETURN
      RETURN
      END
      SUBROUTINE GWT2PCB1RP(IN)
C     ******************************************************************
C     READ PRESCRIBED CONCENTRATION DATA FOR A STRESS PERIOD
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,      ONLY:IOUT,NCOL,NROW,NLAY,IFREFM,NODES,IUNSTR,NEQS
      USE GWTPCBMODULE, ONLY:NPCB,MXPCB,NPCBVL,IPRPCB,NPPCB,
     1                       IPCBPB,NNPPCB,PCBAUX,PCB
C
      CHARACTER*6 CPCB
C     ------------------------------------------------------------------
C
C1------IDENTIFY PACKAGE.
      WRITE(IOUT,1)IN
   1  FORMAT(1X,/1X,'PCB -- PRESCRIBED CONCENTRATION PACKAGE,',1X,
     1 'VERSION 7, 2/2/2010 INPUT READ FROM UNIT ',I4)
C
C2----READ NUMBER OF PCBS (OR FLAG SAYING REUSE PCB DATA).
C2----AND NUMBER OF PARAMETERS
      IF(NPPCB.GT.0) THEN
        IF(IFREFM.EQ.0) THEN
           READ(IN,'(2I10)') ITMP,NP
        ELSE
           READ(IN,*) ITMP,NP
        END IF
      ELSE
         NP=0
         IF(IFREFM.EQ.0) THEN
            READ(IN,'(I10)') ITMP
         ELSE
            READ(IN,*) ITMP
         END IF
      END IF
C
C3------Calculate some constants.
      NAUX=NPCBVL-5
      IOUTU = IOUT
      IF (IPRPCB.EQ.0) IOUTU=-IOUTU
C
C4-----IF ITMP LESS THAN ZERO REUSE NON-PARAMETER DATA. PRINT MESSAGE.
C4-----IF ITMP=>0, SET NUMBER OF NON-PARAMETER PCBS EQUAL TO ITMP.
      IF(ITMP.LT.0) THEN
         WRITE(IOUT,6)
    6    FORMAT(1X,/
     1    1X,'REUSING NON-PARAMETER PCBS FROM LAST STRESS PERIOD')
      ELSE
         NNPPCB=ITMP
      END IF
C
C5-----IF THERE ARE NEW NON-PARAMETER PCBs, READ THEM.
      MXPCB=IPCBPB-1
      IF(ITMP.GT.0) THEN
         IF(NNPPCB.GT.MXPCB) THEN
            WRITE(IOUT,99) NNPPCB,MXPCB
   99       FORMAT(1X,/1X,'THE NUMBER OF ACTIVE PCBs (',I6,
     1                     ') IS GREATER THAN MXPCB(',I6,')')
            CALL USTOP(' ')
         END IF
         IF(IUNSTR.EQ.0)THEN
           CALL ULSTRD(NNPPCB,PCB,1,NPCBVL,MXPCB,0,IN,IOUT,
     &      'PCB  NO.  LAYER   ROW   COL  COMPONENT NO.  STRESS RATE',
     2             PCBAUX,20,NAUX,IFREFM,NCOL,NROW,NLAY,5,5,IPRPCB)
          ELSE
             CALL ULSTRDU(NNPPCB,PCB,1,NPCBVL,MXPCB,0,IN,IOUT,
     &      'PCB  NO.  LAYER   ROW   COL  COMPONENT NO.  STRESS FACTOR',
     &        PCBAUX,20,NAUX,IFREFM,NEQS,5,5,IPRPCB)
          ENDIF
      END IF
      NPCB=NNPPCB
C
C6-----IF THERE ARE ACTIVE PCB PARAMETERS, READ THEM AND SUBSTITUTE
      CALL PRESET('Q')
      NREAD=NPCBVL-1
      IF(NP.GT.0) THEN
         DO 30 N=1,NP
         CALL UPARLSTSUB(IN,'PCB',IOUTU,'Q',PCB,NPCBVL,MXPCB,NREAD,
     1                MXPCB,NPCB,5,5,
     &      'PCB  NO.  LAYER   ROW   COL  COMPONENT NO.  STRESS RATE',
     3            PCBAUX,20,NAUX)
   30    CONTINUE
      END IF
C
C7------PRINT NUMBER OF PCBS IN CURRENT STRESS PERIOD.
      CPCB=' PCBs '
      IF(NPCB.EQ.1) CPCB=' PCBS '
      WRITE(IOUT,101) NPCB,CPCB
  101 FORMAT(1X,/1X,I6,A)
C
C8-------FOR STRUCTURED GRID, CALCULATE NODE NUMBER AND PLACE IN LAYER LOCATION
      IF(ITMP.GT.0.AND.IUNSTR.EQ.0)THEN
        DO L=1,NPCB
          IR=PCB(2,L)
          IC=PCB(3,L)
          IL=PCB(1,L)
          N = IC + NCOL*(IR-1) + (IL-1)* NROW*NCOL
          PCB(1,L) = N
        ENDDO
      ENDIF
C
C9------RETURN
      RETURN
      END
      SUBROUTINE GWT2PCB1FM(ICOMP)
C     ******************************************************************
C     PRESCRIBE CONCENTRATIONS AT PCB CELLS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IBOUND,RHS,IA,JA,AMAT
      USE GWTPCBMODULE, ONLY:NPCB,PCB,AMATDIAG,RHSKPT
      USE GWTBCTMODULE, ONLY: ICBUND,CONC
      DOUBLE PRECISION BIG,Co
C     ------------------------------------------------------------------
C
C1------IF NUMBER OF PCBs <= 0 THEN RETURN.
      IF(NPCB.LE.0) RETURN
      BIG = 1.0E20
C
C2------PROCESS EACH PCB IN THE LIST.
      DO 100 L=1,NPCB
      N=PCB(1,L)
      IC=PCB(4,L)
      Co=PCB(5,L)
C
C2A-----IF THE CELL IS INACTIVE OR WRONG COMPONENT SPECIES THEN BYPASS PROCESSING.
      IF(ICBUND(N).EQ.0.OR.IC.NE.ICOMP) GO TO 100
C
C2B-----IF THE CELL IS PRESCRIBED CONCENTRATION THEN PROCESS
        AMATDIAG(L,ICOMP) = AMAT(IA(N))
        RHSKPT(L,ICOMP) = RHS(N)
        AMAT(IA(N)) = -1.0 * BIG
        RHS(N) = -Co * BIG
  100 CONTINUE
C
C3------RETURN
      RETURN
      END
C-----------------------------------------------------------------------
      SUBROUTINE GWT2PCB1BD(KSTP,KPER,ICOMP)
C     ******************************************************************
C     CALCULATE MASS BUDGET FOR PCB CELLS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,   ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,BUFF,NODES,IUNSTR,
     1              AMAT,IA,JA
      USE GWFBASMODULE,ONLY:MSUM,ISPCFL,IAUXSV,DELT,PERTIM,TOTIM
      USE GWTPCBMODULE,ONLY:NPCB,IPCBCB,PCB,NPCBVL,PCBAUX,
     *  AMATDIAG,RHSKPT
      USE GWTBCTMODULE, ONLY: ICBUND,CONC,MSUMT,VBVLT,VBNMT,IPCBFLAG
C
      CHARACTER*16 TEXT
      DOUBLE PRECISION RATIN,RATOUT,QQ,CDIFF
      DATA TEXT /'PRESCRIBED CONCS'/
C     ------------------------------------------------------------------
C
C1------CLEAR RATIN AND RATOUT ACCUMULATORS, AND SET CELL-BY-CELL
C1------BUDGET FLAG.
      ZERO=0.
      RATIN=ZERO
      RATOUT=ZERO
      IBD=0
      IF(IPCBCB.LT.0 .AND. ISPCFL.NE.0) IBD=-1
      IF(IPCBCB.GT.0) IBD=ISPCFL
      IBDLBL=0
C
C2-----IF CELL-BY-CELL FLOWS WILL BE SAVED AS A LIST, WRITE HEADER.
      IF(IBD.EQ.2) THEN
         NAUX=NPCBVL-5
         IF(IAUXSV.EQ.0) NAUX=0
         CALL UBDSV4(KSTP,KPER,TEXT,NAUX,PCBAUX,IPCBCB,NCOL,NROW,NLAY,
     1          NPCB,IOUT,DELT,PERTIM,TOTIM,ICBUND)
      END IF
C
C3------CLEAR THE BUFFER.
      DO 50 N=1,NODES
      BUFF(N)=ZERO
      IPCBFLAG(N) = 0
50    CONTINUE
C
C4------IF THERE ARE NO PCBs, DO NOT ACCUMULATE
      IF(NPCB.EQ.0) GO TO 200
C
C5------LOOP THROUGH EACH PCB CALCULATING MASS FLUX
      DO 100 L=1,NPCB
C
C5A-----GET NODE NUMBER OF CELL CONTAINING PCB.
      N=PCB(1,L)
      IC=PCB(4,L)
      QQ=ZERO
C
C5B-----IF THE CELL IS NOT PCB OR WRONG COMPONENT SPECIES, IGNORE IT.
      IF(ICBUND(N).EQ.0.OR.IC.NE.ICOMP)GO TO 99
      IPCBFLAG(N) = 1
C
C5C---BACK-CALCULATE MASS FLUX FOR PCB NODE.
      QQ = -AMATDIAG(L,ICOMP) * CONC(N,ICOMP)
      DO II = IA(N)+1,IA(N+1)-1
        JJ = JA(II)
        QQ = QQ - AMAT(II) * CONC(JJ,ICOMP)
      ENDDO
      QQ=QQ + RHSKPT(L,ICOMP)
      Q = QQ
C
C5D-----PRINT FLOW RATE IF REQUESTED.
      IF(IBD.LT.0) THEN
         IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT,KPER,KSTP
   61    FORMAT(1X,/1X,A,'   PERIOD ',I5,'   STEP ',I5)
        IF(IUNSTR.EQ.0)THEN
          IL = (N-1) / (NCOL*NROW) + 1
          IJ = N - (IL-1)*NCOL*NROW
          IR = (IJ-1)/NCOL + 1
          IC = IJ - (IR-1)*NCOL
           WRITE(IOUT,62) L,IL,IR,IC,Q
   62    FORMAT(1X,'PCB  ',I6,'   LAYER ',I3,'   ROW ',I5,'   COL ',I5,
     1       '   FLUX ',1PG15.6)
        ELSE
           WRITE(IOUT,63) L,N,Q
   63    FORMAT(1X,'PCB  ',I6,'    NODE ',I8,'   FLUX ',1PG15.6)
        ENDIF
         IBDLBL=1
      END IF
C
C5E-----ADD FLOW RATE TO BUFFER.
      BUFF(N)=BUFF(N)+Q
C
C5F-----SEE IF FLUX IS POSITIVE OR NEGATIVE.
      IF(QQ.GE.ZERO) THEN
C
C5G-----FLOW RATE IS POSITIVE (RECHARGE). ADD IT TO RATIN.
        RATIN=RATIN+QQ
      ELSE
C
C5H-----FLOW RATE IS NEGATIVE (DISCHARGE). ADD IT TO RATOUT.
        RATOUT=RATOUT-QQ
      END IF
C
C5I-----IF SAVING CELL-BY-CELL FLOWS IN A LIST, WRITE FLOW.  ALSO
C5I-----COPY FLOW TO PCB LIST.

   99 CONTINUE
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.2) CALL UBDSVB(IPCBCB,NCOL,NROW,IC,IR,IL,Q,
     1                  PCB(1,L),NPCBVL,NAUX,6,ICBUND,NLAY)
      ELSE
C        IF(IBD.EQ.2) CALL UBDSVBU(IPCBCB,NODES,N,Q,
C     1                  PCB(1,L),NPCBVL,NAUX,6,ICBUND)
      ENDIF
100   CONTINUE
C
C6------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A 3-D ARRAY,
C6------CALL UBUDSV TO SAVE THEM.
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.1)CALL UBUDSV(KSTP,KPER,TEXT,IPCBCB,BUFF(1),NCOL,NROW,
     1                          NLAY,IOUT)
      ELSE
        IF(IBD.EQ.1) CALL UBUDSVU(KSTP,KPER,TEXT,IPCBCB,BUFF(1),NODES,
     1                          IOUT,PERTIM,TOTIM)
      ENDIF
C
C7------MOVE RATES, VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 RIN=RATIN
      ROUT=RATOUT
      VBVLT(3,MSUMT,ICOMP)=RIN
      VBVLT(4,MSUMT,ICOMP)=ROUT
      VBVLT(1,MSUMT,ICOMP)=VBVLT(1,MSUMT,ICOMP)+RATIN*DELT
      VBVLT(2,MSUMT,ICOMP)=VBVLT(2,MSUMT,ICOMP)+RATOUT*DELT
      VBNMT(MSUMT,ICOMP)=TEXT
C
C8------INCREMENT BUDGET TERM COUNTER(MSUM).
      MSUMT=MSUMT+1
C
C9------RETURN
      RETURN
      END
      SUBROUTINE GWT2PCB1DA
C  Deallocate PCB MEMORY
      USE GWTPCBMODULE
C
        DEALLOCATE(NPCB)
        DEALLOCATE(MXPCB)
        DEALLOCATE(NPCBVL)
        DEALLOCATE(IPCBCB)
        DEALLOCATE(IPRPCB)
        DEALLOCATE(NPPCB)
        DEALLOCATE(IPCBPB)
        DEALLOCATE(NNPPCB)
        DEALLOCATE(PCBAUX)
        DEALLOCATE(PCB)
        DEALLOCATE(AMATDIAG)
        DEALLOCATE(RHSKPT)
C
      RETURN
      END
C----------------------------------------------------------------------------
      SUBROUTINE GWT2PHB1FM(ICOMP)
C     ******************************************************************
C     FORMULATE BOUNDARY CONDITION FOR TRANSPORT AT PRESCRIBED HEAD NODES
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IBOUND,RHS,IA,JA,AMAT,NODES,IUNIT,NEQS
      USE GWTBCTMODULE, ONLY: ICBUND,CBCH
      USE GWFCHDMODULE,ONLY:NCHDS,MXCHD,NCHDVL,IPRCHD,NPCHD,ICHDPB,
     1                      NNPCHD,CHDAUX,CHDS

      DOUBLE PRECISION Co,Q
C     ------------------------------------------------------------------
C-----INITIALIZE CONSTANTS AND FLAGS
      BIG = 1.0E20
      IF(IUNIT(20).GT.0)THEN  ! READ FROM chd FILE IF CHD IS USED
        NAUX = NCHDVL- 5
        CALL CONCIAUX(ICOMP,NAUX,CHDAUX,IAUX)
      ENDIF
C
C1------PROCESS EACH NODE IN THE LIST.
      L = 0
      DO 100 N=1,NEQS
C
C2------IF THE CELL IS INACTIVE OR NOT PRESCRIBED HEAD NODE, BYPASS PROCESSING.
      IF(ICBUND(N).EQ.0.OR.IBOUND(N).GE.0) GO TO 100
        Q = CBCH(N)
        Co= 0.0
C3--------IF CHD IS ON THEN READ CONCENTRATION FROM CHD FILE SEQUENTIALLY
C3--------NOTE THAT IF CHD IS ON THEN SHOULD NOT HAVE IBOUND=0 AS WELL DEFINING OTHER NODES
        IF(IUNIT(20).GT.0)THEN
          IF(NCHDVL.GT.5)THEN
            L = L + 1
            Co = CHDS(5+IAUX,L)
          ENDIF
        ENDIF
C
C4------IF THE CELL IS OUTFLOW, PUT Q ON LHS DIAGONAL
        IF(Q.LE.0.0)THEN
          AMAT(IA(N)) = AMAT(IA(N)) + Q
        ELSE
C5--------IF THE CELL IS INFLOW, PUT Q*Co ON RHS
          RHS(N) = RHS(N) -Co * Q
        ENDIF
C
  100 CONTINUE
C
C6------RETURN
      RETURN
      END
C-----------------------------------------------------------------------
      SUBROUTINE GWT2PHB1BD(KSTP,KPER,ICOMP)
C     ******************************************************************
C     CALCULATE MASS BUDGET FOR TRANSPORT AT PRESCRIBED HEAD NODES
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,   ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,BUFF,NODES,IUNSTR,
     1              AMAT,IA,JA,IUNIT
      USE GWFBASMODULE,ONLY:MSUM,ISPCFL,IAUXSV,DELT,PERTIM,TOTIM
      USE GWTBCTMODULE,ONLY: ICBUND,CONC,MSUMT,VBVLT,VBNMT,CBCH,IPCBFLAG
      USE GWFBCFMODULE,ONLY:IBCFCB
      USE GWFCHDMODULE,ONLY:CHDS,NCHDVL,CHDAUX
C
      CHARACTER*16 TEXT
      DOUBLE PRECISION RATIN,RATOUT,QQ,BIG,CDIFF,Co,QF
      DATA TEXT /'CNST H MASS FLUX'/
C     ------------------------------------------------------------------
C
C1------CLEAR RATIN AND RATOUT ACCUMULATORS, AND SET CELL-BY-CELL
C1------BUDGET FLAG.
      ZERO=0.
      RATIN=ZERO
      RATOUT=ZERO
      IBD=0
      IF(IBCFCB.LT.0 .AND. ISPCFL.NE.0) IBD=-1
      IF(IBCFCB.GT.0) IBD=ISPCFL
      IBDLBL=0
      IF(IUNIT(20).GT.0)THEN
        NAUX = NCHDVL- 5
        CALL CONCIAUX(ICOMP,NAUX,CHDAUX,IAUX)
      ENDIF  
C
C2------CLEAR THE BUFFER.
      DO 50 N=1,NODES
      BUFF(N)=ZERO
50    CONTINUE
C
C3------LOOP THROUGH EACH PCB CALCULATING MASS FLUX
      L = 0
      DO 100 N=1,NODES
C
C4------IF THE CELL IS INACTIVE OR NOT PRESCRIBED HEAD NODE, IGNORE IT.
      IF(ICBUND(N).EQ.0.OR.IBOUND(N).GE.0.OR.IPCBFLAG(N).EQ.1)GO TO 99
C
C5------COMPUTE MASS FLUX AT RPESCRIBED HEAD BOUNDARY
        QF = CBCH(N)
        Co= 0.0
C6--------IF CHD IS ON THEN READ CONCENTRATION FROM CHD FILE SEQUENTIALLY
C6--------NOTE THAT IF CHD IS ON THEN SHOULD NOT HAVE IBOUND=0 AS WELL DEFINING OTHER NODES
          IF(IUNIT(20).GT.0)THEN
            IF(NCHDVL.GT.5)THEN
              L = L + 1
              Co = CHDS(5+IAUX,L)
            ENDIF
          ENDIF         
C
C7------IF THE CELL IS OUTFLOW, MASS IS Q * CONC
        IF(QF.LE.0.0)THEN
          QQ = QF * CONC(N,ICOMP)
        ELSE
C8--------IF THE CELL IS INFLOW, MASS IS Q*Co        
          QQ = QF * Co
        ENDIF
        Q = QQ
C
C9------PRINT FLOW RATE IF REQUESTED.
        IF(IBD.LT.0) THEN
          IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT,KPER,KSTP
   61     FORMAT(1X,/1X,A,'   PERIOD ',I4,'   STEP ',I3)
          IF(IUNSTR.EQ.0)THEN
            IL = (N-1) / (NCOL*NROW) + 1
            IJ = N - (IL-1)*NCOL*NROW
            IR = (IJ-1)/NCOL + 1
            IC = IJ - (IR-1)*NCOL
            WRITE(IOUT,62) L,IL,IR,IC,Q
   62       FORMAT(1X,'PHB  ',I6,'   LAYER ',I3,'   ROW ',I5,'   COL ',
     1       I5, '   FLUX ',1PG15.6)
          ELSE
            WRITE(IOUT,63) L,N,Q
   63       FORMAT(1X,'PHB  ',I6,'    NODE ',I8,'   FLUX ',1PG15.6)
          ENDIF
          IBDLBL=1
        END IF
C
C10-----ADD FLOW RATE TO BUFFER.
        BUFF(N)=BUFF(N)+Q
C
C11-----SEE IF FLUX IS POSITIVE OR NEGATIVE.
        IF(QQ.GE.ZERO) THEN
C
C12-------FLOW RATE IS POSITIVE (RECHARGE). ADD IT TO RATIN.
          RATIN=RATIN+QQ
        ELSE
C
C13-------FLOW RATE IS NEGATIVE (DISCHARGE). ADD IT TO RATOUT.
          RATOUT=RATOUT-QQ
        END IF
C
C14-----IF SAVING CELL-BY-CELL FLOWS IN A LIST, WRITE FLOW.  ALSO
C14-----COPY FLOW TO CONSANT HEAD LIST.

   99 CONTINUE
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.2) CALL UBDSVB(IBCFCB,NCOL,NROW,IC,IR,IL,Q,
     1                  CBCH,1,NAUX,6,ICBUND,NLAY)
      ELSE
C        IF(IBD.EQ.2) CALL UBDSVBU(IBCFCB,NODES,N,Q,
C     1                  CBCH,1,NAUX,6,ICBUND)
      ENDIF
100   CONTINUE
C
C15------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A 3-D ARRAY,
C15------CALL UBUDSV TO SAVE THEM.
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.1) CALL UBUDSV(KSTP,KPER,TEXT,IBCFCB,BUFF,NCOL,NROW,
     1                          NLAY,IOUT)
      ELSE
        IF(IBD.EQ.1) CALL UBUDSVU(KSTP,KPER,TEXT,IBCFCB,BUFF,NODES,
     1                          IOUT,PERTIM,TOTIM)
      ENDIF
C
C16------MOVE RATES, VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 RIN=RATIN
      ROUT=RATOUT
      VBVLT(3,MSUMT,ICOMP)=RIN
      VBVLT(4,MSUMT,ICOMP)=ROUT
      VBVLT(1,MSUMT,ICOMP)=VBVLT(1,MSUMT,ICOMP)+RATIN*DELT
      VBVLT(2,MSUMT,ICOMP)=VBVLT(2,MSUMT,ICOMP)+RATOUT*DELT
      VBNMT(MSUMT,ICOMP)=TEXT
C
C17------INCREMENT BUDGET TERM COUNTER(MSUM).
      MSUMT=MSUMT+1
C
C18------RETURN
      RETURN
      END
C----------------------------------------------------------------------------
      SUBROUTINE GWT2WEL1FM(ICOMP)
C     ******************************************************************
C     FORMULATE WELL TRANSPORT BOUNDARY CONDITION
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IBOUND,RHS,IA,JA,AMAT
      USE GWFWELMODULE, ONLY:NWELLS,WELL,NWELVL,WELAUX
      USE GWTBCTMODULE, ONLY: ICBUND
      DOUBLE PRECISION Co,Q
C     ------------------------------------------------------------------
C
C1------IF NUMBER OF WELLS <= 0 THEN RETURN.
      IF(NWELLS.LE.0) RETURN
      BIG = 1.0E20
      NAUX =NWELVL - 5
      CALL CONCIAUX(ICOMP,NAUX,WELAUX,IAUX)
C
C2------PROCESS EACH WELL IN THE LIST.
      DO 100 L=1,NWELLS
      N=WELL(1,L)
C
C2A-----IF THE CELL IS INACTIVE THEN BYPASS PROCESSING.
      IF(ICBUND(N).EQ.0) GO TO 100
        Q = WELL(NWELVL,L)
C
C2B-----IF THE CELL IS OUTFLOW, PUT Q ON LHS DIAGONAL
        IF(Q.LE.0.0)THEN
          AMAT(IA(N)) = AMAT(IA(N)) + Q
        ELSE
C2C-------IF THE CELL IS INFLOW, PUT Q*Co ON RHS
          Co=WELL(4+IAUX,L)  
          RHS(N) = RHS(N) -Co * Q
        ENDIF
C
  100 CONTINUE
C
C3------RETURN
      RETURN
      END
C-----------------------------------------------------------------------
      SUBROUTINE GWT2WEL1BD(KSTP,KPER,ICOMP)
C     ******************************************************************
C     CALCULATE MASS BUDGET FOR WELL TRANSPORT BOUNDARY CONDITIONS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,   ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,BUFF,NODES,IUNSTR,
     1              AMAT,IA,JA
      USE GWFBASMODULE,ONLY:MSUM,ISPCFL,IAUXSV,DELT,PERTIM,TOTIM
      USE GWFWELMODULE,ONLY:NWELLS,MXWELL,NWELVL,IWELCB,IPRWEL,NPWEL,
     1                       IWELPB,NNPWEL,WELAUX,WELL
      USE GWTBCTMODULE, ONLY: ICBUND,CONC,MSUMT,VBVLT,VBNMT,IPCBFLAG
C
      CHARACTER*16 TEXT
      DOUBLE PRECISION RATIN,RATOUT,QQ,BIG,CDIFF,QF
      DATA TEXT /'  WELL MASS FLUX'/
C     ------------------------------------------------------------------
C
C1------CLEAR RATIN AND RATOUT ACCUMULATORS, AND SET CELL-BY-CELL
C1------BUDGET FLAG.
      ZERO=0.
      RATIN=ZERO
      RATOUT=ZERO
      IBD=0
      IF(IWELCB.LT.0 .AND. ISPCFL.NE.0) IBD=-1
      IF(IWELCB.GT.0) IBD=ISPCFL
      IBDLBL=0
      NAUX =NWELVL - 5
      CALL CONCIAUX(ICOMP,NAUX,WELAUX,IAUX)
C
C2-----IF CELL-BY-CELL FLOWS WILL BE SAVED AS A LIST, WRITE HEADER.
      IF(IBD.EQ.2) THEN
         NAUX=NWELVL-5
         IF(IAUXSV.EQ.0) NAUX=0
         CALL UBDSV4(KSTP,KPER,TEXT,NAUX,WELAUX,IWELCB,NCOL,NROW,NLAY,
     1          NWELLS,IOUT,DELT,PERTIM,TOTIM,ICBUND)
      END IF
C
C3------CLEAR THE BUFFER.
      DO 50 N=1,NODES
      BUFF(N)=ZERO
50    CONTINUE
C
C4------IF THERE ARE NO WELLS, DO NOT ACCUMULATE
      IF(NWELLS.EQ.0) GO TO 200
C
C5------LOOP THROUGH EACH WELL CALCULATING MASS FLUX
      DO 100 L=1,NWELLS
C
C6-----GET NODE NUMBER OF CELL CONTAINING WELL.
      N=WELL(1,L)
      QQ=ZERO
C
C7-----IF THE CELL IS INACTIVE OR PCB, IGNORE IT.
      IF(ICBUND(N).EQ.0.OR.IPCBFLAG(N).EQ.1)GO TO 99
C
C8-----COMPUTE MASS FLUX AT WELL BOUNDARY
        QF = WELL(NWELVL,L)
C
C9-----IF THE CELL IS OUTFLOW, MASS IS Q * CONC
        IF(QF.LE.0.0)THEN
          QQ = QF * CONC(N,ICOMP)
        ELSE
C10-------IF THE CELL IS INFLOW, MASS IS Q*Co
          Co=WELL(4+IAUX,L)  
          QQ = QF * Co
        ENDIF
        Q = QQ
C
C11-----PRINT FLOW RATE IF REQUESTED.
        IF(IBD.LT.0) THEN
          IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT,KPER,KSTP
   61     FORMAT(1X,/1X,A,'   PERIOD ',I4,'   STEP ',I3)
          IF(IUNSTR.EQ.0)THEN
            IL = (N-1) / (NCOL*NROW) + 1
            IJ = N - (IL-1)*NCOL*NROW
            IR = (IJ-1)/NCOL + 1
            IC = IJ - (IR-1)*NCOL
            WRITE(IOUT,62) L,IL,IR,IC,Q
   62       FORMAT(1X,'WEL  ',I6,'   LAYER ',I3,'   ROW ',I5,'   COL ',
     1       I5, '   FLUX ',1PG15.6)
          ELSE
            WRITE(IOUT,63) L,N,Q
   63       FORMAT(1X,'WEL  ',I6,'    NODE ',I8,'   FLUX ',1PG15.6)
          ENDIF
          IBDLBL=1
        END IF
C
C12-----ADD FLOW RATE TO BUFFER.
        BUFF(N)=BUFF(N)+QQ
C
C13-----SEE IF FLUX IS POSITIVE OR NEGATIVE.
        IF(QQ.GE.ZERO) THEN
C
C14-------FLOW RATE IS POSITIVE (RECHARGE). ADD IT TO RATIN.
          RATIN=RATIN+QQ
        ELSE
C
C15-------FLOW RATE IS NEGATIVE (DISCHARGE). ADD IT TO RATOUT.
          RATOUT=RATOUT-QQ
        END IF
C
C16-----IF SAVING CELL-BY-CELL FLOWS IN A LIST, WRITE FLOW.  ALSO
C16-----COPY FLOW TO WELL LIST.

   99 CONTINUE
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.2) CALL UBDSVB(IWELCB,NCOL,NROW,IC,IR,IL,Q,
     1                  WELL(1,L),NWELVL,NAUX,6,ICBUND,NLAY)
      ELSE
C        IF(IBD.EQ.2) CALL UBDSVBU(IWELCB,NODES,N,Q,
C     1                  WELL(1,L),NWELVL,NAUX,6,ICBUND)
      ENDIF
100   CONTINUE
C
C17------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A 3-D ARRAY,
C17------CALL UBUDSV TO SAVE THEM.
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.1)CALL UBUDSV(KSTP,KPER,TEXT,IWELCB,BUFF(1),NCOL,NROW,
     1                          NLAY,IOUT)
      ELSE
        IF(IBD.EQ.1) CALL UBUDSVU(KSTP,KPER,TEXT,IWELCB,BUFF(1),NODES,
     1                          IOUT,PERTIM,TOTIM)
      ENDIF
C
C18------MOVE RATES, VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 RIN=RATIN
      ROUT=RATOUT
      VBVLT(3,MSUMT,ICOMP)=RIN
      VBVLT(4,MSUMT,ICOMP)=ROUT
      VBVLT(1,MSUMT,ICOMP)=VBVLT(1,MSUMT,ICOMP)+RATIN*DELT
      VBVLT(2,MSUMT,ICOMP)=VBVLT(2,MSUMT,ICOMP)+RATOUT*DELT
      VBNMT(MSUMT,ICOMP)=TEXT
C
C19------INCREMENT BUDGET TERM COUNTER(MSUM).
      MSUMT=MSUMT+1
C
C20------RETURN
      RETURN
      END
C----------------------------------------------------------------------------
      SUBROUTINE GWT2GHB1FM(ICOMP)
C     ******************************************************************
C     FORMULATE GHB TRANSPORT BOUNDARY CONDITION
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IBOUND,RHS,IA,JA,AMAT
      USE GWFGHBMODULE, ONLY:NBOUND,BNDS,NGHBVL,GHBAUX
      USE GWTBCTMODULE, ONLY: ICBUND
      DOUBLE PRECISION Co,Q
C     ------------------------------------------------------------------
C
C1------IF NUMBER OF GHBS <= 0 THEN RETURN.
      IF(NBOUND.LE.0) RETURN
      BIG = 1.0E20
      NAUX=NGHBVL-6
      CALL CONCIAUX(ICOMP,NAUX,GHBAUX,IAUX)
C
C2------PROCESS EACH GHB IN THE LIST.
      DO 100 L=1,NBOUND
      N=BNDS(1,L)
C
C2A-----IF THE CELL IS INACTIVE THEN BYPASS PROCESSING.
      IF(ICBUND(N).EQ.0) GO TO 100
        Q = BNDS(NGHBVL,L)
C
C2B-----IF THE CELL IS OUTFLOW, PUT Q ON LHS DIAGONAL
        IF(Q.LE.0.0)THEN
          AMAT(IA(N)) = AMAT(IA(N)) + Q
        ELSE
C2C-------IF THE CELL IS INFLOW, PUT Q*Co ON RHS
          Co= BNDS(5+IAUX,L)  
          RHS(N) = RHS(N) -Co * Q
        ENDIF
C
  100 CONTINUE
C
C3------RETURN
      RETURN
      END
C-----------------------------------------------------------------------
      SUBROUTINE GWT2GHB1BD(KSTP,KPER,ICOMP)
C     ******************************************************************
C     CALCULATE MASS BUDGET FOR GHB TRANSPORT BOUNDARY CONDITIONS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,   ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,BUFF,NODES,IUNSTR,
     1              AMAT,IA,JA
      USE GWFBASMODULE,ONLY:MSUM,ISPCFL,IAUXSV,DELT,PERTIM,TOTIM
      USE GWFGHBMODULE,ONLY:NBOUND,IGHBCB,BNDS,NGHBVL,GHBAUX
      USE GWTBCTMODULE, ONLY: ICBUND,CONC,MSUMT,VBVLT,VBNMT,IPCBFLAG
C
      CHARACTER*16 TEXT
      DOUBLE PRECISION RATIN,RATOUT,QQ,BIG,CDIFF
      DATA TEXT /'   GHB MASS FLUX'/
C     ------------------------------------------------------------------
C
C1------CLEAR RATIN AND RATOUT ACCUMULATORS, AND SET CELL-BY-CELL
C1------BUDGET FLAG.
      ZERO=0.
      RATIN=ZERO
      RATOUT=ZERO
      IBD=0
      IF(IGHBCB.LT.0 .AND. ISPCFL.NE.0) IBD=-1
      IF(IGHBCB.GT.0) IBD=ISPCFL
      IBDLBL=0
      NAUX=NGHBVL-6
      CALL CONCIAUX(ICOMP,NAUX,GHBAUX,IAUX)
C
C2-----IF CELL-BY-CELL FLOWS WILL BE SAVED AS A LIST, WRITE HEADER.
      IF(IBD.EQ.2) THEN
         NAUX=NGHBVL-5
         IF(IAUXSV.EQ.0) NAUX=0
         CALL UBDSV4(KSTP,KPER,TEXT,NAUX,GHBAUX,IGHBCB,NCOL,NROW,NLAY,
     1          NBOUND,IOUT,DELT,PERTIM,TOTIM,ICBUND)
      END IF
C
C3------CLEAR THE BUFFER.
      DO 50 N=1,NODES
      BUFF(N)=ZERO
50    CONTINUE
C
C4------IF THERE ARE NO GHBs, DO NOT ACCUMULATE
      IF(NBOUND.EQ.0) GO TO 200
C
C5------LOOP THROUGH EACH GHB CALCULATING MASS FLUX
      DO 100 L=1,NBOUND
C
C6-----GET NODE NUMBER OF CELL CONTAINING GHB.
      N=BNDS(1,L)
      QQ=ZERO
C
C7-----IF THE CELL IS INACTIVE OR PCB, IGNORE IT.
      IF(ICBUND(N).EQ.0.OR.IPCBFLAG(N).EQ.1)GO TO 99
C
C8-----COMPUTE MASS FLUX AT GHB BOUNDARY
        QF = BNDS(NGHBVL,L)
C
C9-----IF THE CELL IS OUTFLOW, MASS IS Q * CONC
        IF(QF.LE.0.0)THEN
          QQ = QF * CONC(N,ICOMP)
        ELSE
C10-------IF THE CELL IS INFLOW, MASS IS Q*Co
          Co = BNDS(5+IAUX,L)  
          QQ = QF * Co
        ENDIF
        Q = QQ
C
C11-----PRINT FLOW RATE IF REQUESTED.
        IF(IBD.LT.0) THEN
          IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT,KPER,KSTP
   61     FORMAT(1X,/1X,A,'   PERIOD ',I4,'   STEP ',I3)
          IF(IUNSTR.EQ.0)THEN
            IL = (N-1) / (NCOL*NROW) + 1
            IJ = N - (IL-1)*NCOL*NROW
            IR = (IJ-1)/NCOL + 1
            IC = IJ - (IR-1)*NCOL
            WRITE(IOUT,62) L,IL,IR,IC,Q
   62       FORMAT(1X,'GHB  ',I6,'   LAYER ',I3,'   ROW ',I5,'   COL ',
     1       I5, '   FLUX ',1PG15.6)
          ELSE
            WRITE(IOUT,63) L,N,Q
   63       FORMAT(1X,'GHB  ',I6,'    NODE ',I8,'   FLUX ',1PG15.6)
          ENDIF
          IBDLBL=1
        END IF
C
C12-----ADD FLOW RATE TO BUFFER.
        BUFF(N)=BUFF(N)+Q
C
C13-----SEE IF FLUX IS POSITIVE OR NEGATIVE.
        IF(QQ.GE.ZERO) THEN
C
C14-------FLOW RATE IS POSITIVE (RECHARGE). ADD IT TO RATIN.
          RATIN=RATIN+QQ
        ELSE
C
C15-------FLOW RATE IS NEGATIVE (DISCHARGE). ADD IT TO RATOUT.
          RATOUT=RATOUT-QQ
        END IF
C
C16-----IF SAVING CELL-BY-CELL FLOWS IN A LIST, WRITE FLOW.  ALSO
C16-----COPY FLOW TO GHB LIST.

   99 CONTINUE
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.2) CALL UBDSVB(IGHBCB,NCOL,NROW,IC,IR,IL,Q,
     1                  BNDS(1,L),NGHBVL,NAUX,6,ICBUND,NLAY)
      ELSE
C        IF(IBD.EQ.2) CALL UBDSVBU(IGHBCB,NODES,N,Q,
C     1                  BNDS(1,L),NGHBVL,NAUX,6,ICBUND)
      ENDIF
100   CONTINUE
C
C17------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A 3-D ARRAY,
C17------CALL UBUDSV TO SAVE THEM.
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.1)CALL UBUDSV(KSTP,KPER,TEXT,IGHBCB,BUFF(1),NCOL,NROW,
     1                          NLAY,IOUT)
      ELSE
        IF(IBD.EQ.1) CALL UBUDSVU(KSTP,KPER,TEXT,IGHBCB,BUFF(1),NODES,
     1                          IOUT,PERTIM,TOTIM)
      ENDIF
C
C18------MOVE RATES, VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 RIN=RATIN
      ROUT=RATOUT
      VBVLT(3,MSUMT,ICOMP)=RIN
      VBVLT(4,MSUMT,ICOMP)=ROUT
      VBVLT(1,MSUMT,ICOMP)=VBVLT(1,MSUMT,ICOMP)+RATIN*DELT
      VBVLT(2,MSUMT,ICOMP)=VBVLT(2,MSUMT,ICOMP)+RATOUT*DELT
      VBNMT(MSUMT,ICOMP)=TEXT
C
C19------INCREMENT BUDGET TERM COUNTER(MSUM).
      MSUMT=MSUMT+1
C
C20------RETURN
      RETURN
      END
C----------------------------------------------------------------------------
      SUBROUTINE GWT2DRN1FM(ICOMP)
C     ******************************************************************
C     FORMULATE DRAIN TRANSPORT BOUNDARY CONDITION
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IBOUND,RHS,IA,JA,AMAT
      USE GWFDRNMODULE, ONLY:NDRAIN,DRAI,NDRNVL
      USE GWTBCTMODULE, ONLY: ICBUND
      DOUBLE PRECISION Co,Q
C     ------------------------------------------------------------------
C
C1------IF NUMBER OF DRAINS <= 0 THEN RETURN.
      IF(NDRAIN.LE.0) RETURN
      BIG = 1.0E20
C
C2------PROCESS EACH DRAIN IN THE LIST.
      DO 100 L=1,NDRAIN
      N=DRAI(1,L)
C
C2A-----IF THE CELL IS INACTIVE THEN BYPASS PROCESSING.
      IF(ICBUND(N).EQ.0) GO TO 100
        Q = DRAI(NDRNVL,L)
C
C2B-----IDRAIN IS ALWAYS OUTFLOW OUTFLOW, PUT Q ON LHS DIAGONAL
        AMAT(IA(N)) = AMAT(IA(N)) + Q
C
  100 CONTINUE
C
C3------RETURN
      RETURN
      END
C-----------------------------------------------------------------------
      SUBROUTINE GWT2DRN1BD(KSTP,KPER,ICOMP)
C     ******************************************************************
C     CALCULATE MASS BUDGET FOR DRAIN TRANSPORT BOUNDARY CONDITIONS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,   ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,BUFF,NODES,IUNSTR,
     1              AMAT,IA,JA
      USE GWFBASMODULE,ONLY:MSUM,ISPCFL,IAUXSV,DELT,PERTIM,TOTIM
      USE GWFDRNMODULE,ONLY:NDRAIN,IDRNCB,DRAI,NDRNVL,DRNAUX
      USE GWTBCTMODULE, ONLY: ICBUND,CONC,MSUMT,VBVLT,VBNMT,IPCBFLAG
C
      CHARACTER*16 TEXT
      DOUBLE PRECISION RATIN,RATOUT,QQ,BIG,CDIFF
      DATA TEXT /'   DRN MASS FLUX'/
C     ------------------------------------------------------------------
C
C1------CLEAR RATIN AND RATOUT ACCUMULATORS, AND SET CELL-BY-CELL
C1------BUDGET FLAG.
      ZERO=0.
      RATIN=ZERO
      RATOUT=ZERO
      IBD=0
      IF(IDRNCB.LT.0 .AND. ISPCFL.NE.0) IBD=-1
      IF(IDRNCB.GT.0) IBD=ISPCFL
      IBDLBL=0
C
C2-----IF CELL-BY-CELL FLOWS WILL BE SAVED AS A LIST, WRITE HEADER.
      IF(IBD.EQ.2) THEN
         NAUX=NDRNVL-5
         IF(IAUXSV.EQ.0) NAUX=0
         CALL UBDSV4(KSTP,KPER,TEXT,NAUX,DRNAUX,IDRNCB,NCOL,NROW,NLAY,
     1          NDRAIN,IOUT,DELT,PERTIM,TOTIM,ICBUND)
      END IF
C
C3------CLEAR THE BUFFER.
      DO 50 N=1,NODES
      BUFF(N)=ZERO
50    CONTINUE
C
C4------IF THERE ARE NO DRNs, DO NOT ACCUMULATE
      IF(NDRAIN.EQ.0) GO TO 200
C
C5------LOOP THROUGH EACH DRN CALCULATING MASS FLUX
      DO 100 L=1,NDRAIN
C
C6-----GET NODE NUMBER OF CELL CONTAINING DRN.
      N=DRAI(1,L)
      QQ=ZERO
C
C7-----IF THE CELL IS INACTIVE OR PCB, IGNORE IT.
      IF(ICBUND(N).EQ.0.OR.IPCBFLAG(N).EQ.1)GO TO 99
C
C8-----COMPUTE MASS FLUX AT DRAIN BOUNDARY
        QF = DRAI(NDRNVL,L)
C
C9-----DRAIN IS ALWAYS OUTFLOW, MASS IS Q * CONC
        QQ = QF * CONC(N,ICOMP)
         Q = QQ
C
C10-----PRINT FLOW RATE IF REQUESTED.
        IF(IBD.LT.0) THEN
          IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT,KPER,KSTP
   61     FORMAT(1X,/1X,A,'   PERIOD ',I4,'   STEP ',I3)
          IF(IUNSTR.EQ.0)THEN
            IL = (N-1) / (NCOL*NROW) + 1
            IJ = N - (IL-1)*NCOL*NROW
            IR = (IJ-1)/NCOL + 1
            IC = IJ - (IR-1)*NCOL
            WRITE(IOUT,62) L,IL,IR,IC,Q
   62       FORMAT(1X,'DRN  ',I6,'   LAYER ',I3,'   ROW ',I5,'   COL ',
     1       I5, '   FLUX ',1PG15.6)
          ELSE
            WRITE(IOUT,63) L,N,Q
   63       FORMAT(1X,'DRN  ',I6,'    NODE ',I8,'   FLUX ',1PG15.6)
          ENDIF
          IBDLBL=1
        END IF
C
C11-----ADD FLOW RATE TO BUFFER.
        BUFF(N)=BUFF(N)+Q
C
C12-----SEE IF FLUX IS POSITIVE OR NEGATIVE.
        IF(QQ.GE.ZERO) THEN
C
C13-------FLOW RATE IS POSITIVE (RECHARGE). ADD IT TO RATIN.
          RATIN=RATIN+QQ
        ELSE
C
C14-------FLOW RATE IS NEGATIVE (DISCHARGE). ADD IT TO RATOUT.
          RATOUT=RATOUT-QQ
        END IF
C
C15-----IF SAVING CELL-BY-CELL FLOWS IN A LIST, WRITE FLOW.  ALSO
C15-----COPY FLOW TO DRN LIST.

   99 CONTINUE
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.2) CALL UBDSVB(IDRNCB,NCOL,NROW,IC,IR,IL,Q,
     1                  DRAI(1,L),NDRNVL,NAUX,6,ICBUND,NLAY)
      ELSE
C        IF(IBD.EQ.2) CALL UBDSVBU(IDRNCB,NODES,N,Q,
C     1                  DRAI(1,L),NDRNVL,NAUX,6,ICBUND)
      ENDIF
100   CONTINUE
C
C16------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A 3-D ARRAY,
C16------CALL UBUDSV TO SAVE THEM.
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.1)CALL UBUDSV(KSTP,KPER,TEXT,IDRNCB,BUFF(1),NCOL,NROW,
     1                          NLAY,IOUT)
      ELSE
        IF(IBD.EQ.1) CALL UBUDSVU(KSTP,KPER,TEXT,IDRNCB,BUFF(1),NODES,
     1                          IOUT,PERTIM,TOTIM)
      ENDIF
C
C17------MOVE RATES, VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 RIN=RATIN
      ROUT=RATOUT
      VBVLT(3,MSUMT,ICOMP)=RIN
      VBVLT(4,MSUMT,ICOMP)=ROUT
      VBVLT(1,MSUMT,ICOMP)=VBVLT(1,MSUMT,ICOMP)+RATIN*DELT
      VBVLT(2,MSUMT,ICOMP)=VBVLT(2,MSUMT,ICOMP)+RATOUT*DELT
      VBNMT(MSUMT,ICOMP)=TEXT
C
C18------INCREMENT BUDGET TERM COUNTER(MSUM).
      MSUMT=MSUMT+1
C
C19------RETURN
      RETURN
      END
C----------------------------------------------------------------------------
      SUBROUTINE GWT2DRT1FM(ICOMP)
C     ******************************************************************
C     FORMULATE DRT TRANSPORT BOUNDARY CONDITION
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IBOUND,RHS,IA,JA,AMAT
      USE GWFDRTMODULE, ONLY:NDRTCL,DRTF,NDRTVL,IDRTFL
      USE GWTBCTMODULE, ONLY: ICBUND,CONC
      DOUBLE PRECISION Co,Q,QIN
C     ------------------------------------------------------------------
C
C1------IF NUMBER OF DRT CELLS <= 0 THEN RETURN.
      IF(NDRTCL.LE.0) RETURN
      BIG = 1.0E20
C
C2------PROCESS EACH DRAIN-RETURN CELL IN THE LIST.
      DO 100 L=1,NDRTCL
      ND=DRTF(1,L)
C
C3------IF THE CELL IS INACTIVE THEN BYPASS PROCESSING.
      IF(ICBUND(ND).EQ.0) GO TO 100
        Q = DRTF(NDRTVL,L)
C
C4--------DRAIN IS OUTFLOW OUTFLOW, PUT Q ON LHS DIAGONAL
        AMAT(IA(ND)) = AMAT(IA(ND)) + Q
C
C5--------TAKE CARE OF RETURN FLOW TERM
        IF (IDRTFL.GT.0) THEN
          INR = DRTF(6,L)
          IF (INR.NE.0) THEN
            IF (ICBUND(INR) .GT. 0) THEN
              Co = CONC(ND,ICOMP)
              QIN = DRTF(NDRTVL-1,L)
              RHS(INR) = RHS(INR) - QIN * Co
            ENDIF
          ENDIF
        ENDIF
C
  100 CONTINUE
C
C3------RETURN
      RETURN
      END
C-----------------------------------------------------------------------
      SUBROUTINE GWT2DRT1BD(KSTP,KPER,ICOMP)
C     ******************************************************************
C     CALCULATE MASS BUDGET FOR DRT TRANSPORT BOUNDARY CONDITIONS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,   ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,BUFF,NODES,IUNSTR,
     1              AMAT,IA,JA
      USE GWFBASMODULE,ONLY:MSUM,ISPCFL,IAUXSV,DELT,PERTIM,TOTIM
      USE GWFDRTMODULE,ONLY:NDRTCL,IDRTCB,DRTF,NDRTVL,DRTAUX,IDRTFL,
     1                      NRFLOW
      USE GWTBCTMODULE, ONLY: ICBUND,CONC,MSUMT,VBVLT,VBNMT,IPCBFLAG
C
      CHARACTER*16 TEXT
      DOUBLE PRECISION RATIN,RATOUT,QQ,BIG,CDIFF,QFIN,QQIN,QF
      DATA TEXT /'   DRT MASS FLUX'/
C     ------------------------------------------------------------------
C
C1------CLEAR RATIN AND RATOUT ACCUMULATORS, AND SET CELL-BY-CELL
C1------BUDGET FLAG.
      ZERO=0.
      RATIN=ZERO
      RATOUT=ZERO
      IBD=0
      IF(IDRTCB.LT.0 .AND. ISPCFL.NE.0) IBD=-1
      IF(IDRTCB.GT.0) IBD=ISPCFL
      IBDLBL=0
C
C2-----IF CELL-BY-CELL FLOWS WILL BE SAVED AS A LIST, WRITE HEADER.
      IF(IBD.EQ.2) THEN
         NAUX=NDRTVL-5-2
         IF(IAUXSV.EQ.0) NAUX=0
         CALL UBDSV4(KSTP,KPER,TEXT,NAUX,DRTAUX,IDRTCB,NCOL,NROW,NLAY,
     1          NDRTCL+NRFLOW,IOUT,DELT,PERTIM,TOTIM,ICBUND)
      END IF
C
C3------CLEAR THE BUFFER.
      DO 50 N=1,NODES
      BUFF(N)=ZERO
50    CONTINUE
C
C4------IF THERE ARE NO DRTs, DO NOT ACCUMULATE
      IF(NDRTCL.EQ.0) GO TO 200
C
C5------LOOP THROUGH EACH DRN CALCULATING MASS FLUX
      DO 100 L=1,NDRTCL
C
C6-----GET NODE NUMBER OF CELL CONTAINING DRN.
      ND=DRTF(1,L)
      QQ=ZERO
C
C7-----IF THE CELL IS INACTIVE OR PCB, IGNORE IT.
      IF(ICBUND(ND).EQ.0.OR.IPCBFLAG(ND).EQ.1)GO TO 99
C
C8-----COMPUTE MASS FLUX AT DRAIN BOUNDARY
        QF = DRTF(NDRTVL,L)
C
C9-----DRAIN IS OUTFLOW, MASS IS Q * CONC
        Co = CONC(ND,ICOMP)
        QQ = QF * Co
        Q = QQ
        RATOUT=RATOUT-QQ
C
C10-----COMPUTE MASS FLUX AT RETURN FLOW NODE BOUNDARY
        IF (IDRTFL.GT.0) THEN
          INR = DRTF(6,L)
          IF (INR.NE.0) THEN
            IF (ICBUND(INR) .GT. 0) THEN
              QFIN = DRTF(NDRTVL-1,L)
              QQIN = QFIN * Co
              QIN = QQIN
              RATIN=RATIN+QQIN
            ENDIF
          ENDIF
        ENDIF
C ------------------------------------------------------------------------
C11-----PRINT FLOW RATE IF REQUESTED.
        IF(IBD.LT.0) THEN
          IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT,KPER,KSTP
   61     FORMAT(1X,/1X,A,'   PERIOD ',I4,'   STEP ',I3)
C11A--------PRINT FOR STRUCTURED GRID
          IF(IUNSTR.EQ.0)THEN
            IL = (ND-1) / (NCOL*NROW) + 1
            IJ = ND - (IL-1)*NCOL*NROW
            IR = (IJ-1)/NCOL + 1
            IC = IJ - (IR-1)*NCOL
            WRITE(IOUT,62) L,IL,IR,IC,Q
   62       FORMAT(1X,'DRT  ',I6,'   LAYER ',I3,'   ROW ',I5,'   COL ',
     1       I5, '   FLUX ',1PG15.6)
C11B-----PRINT FOR RETURN FLOW
            IF(INR.NE.0)THEN
              IL = (INR-1) / (NCOL*NROW) + 1
              IJ = INR - (IL-1)*NCOL*NROW
              IR = (IJ-1)/NCOL + 1
              IC = IJ - (IR-1)*NCOL
              WRITE(IOUT,64) L,IL,IR,IC,QIN
   64         FORMAT(1X,'RETURN ',I6,'   LAYER ',I3,'   ROW ',I5,
     1         '   COL ',I5, '   FLUX ',1PG15.6)
            ENDIF
C11C--------PRINT FOR UNSTRUCTURED GRID
          ELSE
            WRITE(IOUT,63) L,ND,Q
   63       FORMAT(1X,'DRT  ',I6,'    NODE ',I8,'   FLUX ',1PG15.6)
          ENDIF
C11D-----PRINT FOR RETURN FLOW
          IF(INR.NE.0)THEN
            WRITE(IOUT,65) L,INR,QIN
   65       FORMAT(1X,'DRT  ',I6,'    NODE ',I8,'   FLUX ',1PG15.6)
          ENDIF
          IBDLBL=1
        END IF
C ------------------------------------------------------------------------
C
C11-----ADD FLOW RATE TO BUFFER.
        BUFF(ND)=BUFF(ND)+Q
        IF(INR.NE.0) BUFF(INR)=BUFF(INR)+QIN
C
C15-----IF SAVING CELL-BY-CELL FLOWS IN A LIST, WRITE FLOW.  ALSO
C15-----COPY FLOW TO DRN LIST.

   99 CONTINUE
      IF(IBD.EQ.2) THEN
        IF(IUNSTR.EQ.0)THEN
          CALL UBDSVB(IDRTCB,NCOL,NROW,IC,IR,IL,Q,
     1                  DRTF(1,L),NDRTVL,NAUX,10,ICBUND,NLAY)
          IF(INR.NE.0)THEN
            CALL UBDSVB(IDRTCB,NCOL,NROW,ICR,IRR,ILR,QIN,
     1                  DRTF(1,L),NDRTVL,NAUX,10,ICBUND,NLAY)
          ENDIF
        ELSE
          CALL UBDSVBU(IDRTCB,NEQS,ND,Q,
     1                  DRTF(1,L),NDRTVL,NAUX,10,ICBUND)
          IF(INR.NE.0)THEN
          CALL UBDSVBU(IDRTCB,NEQS,INR,QIN,
     1                  DRTF(1,L),NDRTVL,NAUX,10,ICBUND)
          ENDIF
        ENDIF
      ENDIF
100   CONTINUE
C
C16------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A 3-D ARRAY,
C16------CALL UBUDSV TO SAVE THEM.
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.1)CALL UBUDSV(KSTP,KPER,TEXT,IDRTCB,BUFF(1),NCOL,NROW,
     1                          NLAY,IOUT)
      ELSE
        IF(IBD.EQ.1) CALL UBUDSVU(KSTP,KPER,TEXT,IDRTCB,BUFF(1),NODES,
     1                          IOUT,PERTIM,TOTIM)
      ENDIF
C
C17------MOVE RATES, VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 RIN=RATIN
      ROUT=RATOUT
      VBVLT(3,MSUMT,ICOMP)=RIN
      VBVLT(4,MSUMT,ICOMP)=ROUT
      VBVLT(1,MSUMT,ICOMP)=VBVLT(1,MSUMT,ICOMP)+RATIN*DELT
      VBVLT(2,MSUMT,ICOMP)=VBVLT(2,MSUMT,ICOMP)+RATOUT*DELT
      VBNMT(MSUMT,ICOMP)=TEXT
C
C18------INCREMENT BUDGET TERM COUNTER(MSUM).
      MSUMT=MSUMT+1
C
C19------RETURN
      RETURN
      END
C----------------------------------------------------------------------------
      SUBROUTINE GWT2QRT1FM(ICOMP)
C     ******************************************************************
C     FORMULATE QRT TRANSPORT BOUNDARY CONDITION
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IBOUND,RHS,IA,JA,AMAT
      USE GWFQRTMODULE, ONLY:NQRTCL,QRTF,NQRTVL,IQRTFL,NodQRT,QRTFLOW
      USE GWTBCTMODULE, ONLY: ICBUND,CONC
      DOUBLE PRECISION Co,Q,QIN
C     ------------------------------------------------------------------
C
C1------IF NUMBER OF QRT CELLS <= 0 THEN RETURN.
      IF(NQRTCL.LE.0) RETURN
      BIG = 1.0E20
C
C2------PROCESS EACH CELL IN THE QRT LIST.
      IRT = 0                  !------------------! POINTER FOR LOCATION IN NodQRT ARRAY       
      DO 100 L=1,NQRTCL
      ND=QRTF(1,L)
C
C3------IF THE CELL IS INACTIVE THEN BYPASS PROCESSING.
      IF(ICBUND(ND).EQ.0) GO TO 100
        Q = QRTF(NQRTVL,L)
C
C4--------QRT's SINK IS OUTFLOW, REMOVE Q FROM LHS DIAGONAL
        AMAT(IA(ND)) = AMAT(IA(ND)) - Q
C
C5--------TAKE CARE OF RETURN FLOW TERM
        IF (IQRTFL.GT.0) THEN
          NumRT = QRTF(5,L)
          IF (NumRT.NE.0) THEN
            DO JJ = 1,NumRT
              IRT = IRT + 1
              INR = NodQRT(IRT)
              IF (ICBUND(INR) .GT. 0) THEN
                Co = CONC(ND,ICOMP)
                QIN = QRTFLOW(IRT)
                RHS(INR) = RHS(INR) - QIN * Co
              END IF
            ENDDO
          ENDIF
        ENDIF
C
  100 CONTINUE
C
C3------RETURN
      RETURN
      END
C-----------------------------------------------------------------------
      SUBROUTINE GWT2QRT1BD(KSTP,KPER,ICOMP)
C     ******************************************************************
C     CALCULATE MASS BUDGET FOR QRT TRANSPORT BOUNDARY CONDITIONS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,   ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,BUFF,NODES,IUNSTR,
     1              AMAT,IA,JA
      USE GWFBASMODULE,ONLY:MSUM,ISPCFL,IAUXSV,DELT,PERTIM,TOTIM
      USE GWFQRTMODULE,ONLY:NQRTCL,IQRTCB,QRTF,NQRTVL,QRTAUX,IQRTFL,
     1                      QRTFLOW,NodQRT
      USE GWTBCTMODULE, ONLY: ICBUND,CONC,MSUMT,VBVLT,VBNMT,IPCBFLAG
C
      CHARACTER*16 TEXT
      DOUBLE PRECISION RATIN,RATOUT,QQ,BIG,CDIFF,QFIN,QQIN,QF
      DATA TEXT /'   QRT MASS FLUX'/
C     ------------------------------------------------------------------
C
C1------CLEAR RATIN AND RATOUT ACCUMULATORS, AND SET CELL-BY-CELL
C1------BUDGET FLAG.
      ZERO=0.
      RATIN=ZERO
      RATOUT=ZERO
      IBD=0
      IF(IQRTCB.LT.0 .AND. ISPCFL.NE.0) IBD=-1
      IF(IQRTCB.GT.0) IBD=ISPCFL
      IBDLBL=0
C
C2-----IF CELL-BY-CELL FLOWS WILL BE SAVED AS A LIST, WRITE HEADER.
      IF(IBD.EQ.2) THEN
         NAUX=NDRTVL-5-2
         IF(IAUXSV.EQ.0) NAUX=0
         CALL UBDSV4(KSTP,KPER,TEXT,NAUX,QRTAUX,IQRTCB,NCOL,NROW,NLAY,
     1          NQRTCL,IOUT,DELT,PERTIM,TOTIM,ICBUND)
      END IF
C
C3------CLEAR THE BUFFER.
      DO 50 N=1,NODES
      BUFF(N)=ZERO
50    CONTINUE
C
C4------IF THERE ARE NO DQRTs, DO NOT ACCUMULATE
      IF(NQRTCL.EQ.0) GO TO 200
C
C5------LOOP THROUGH EACH QRN CALCULATING MASS FLUX
      IRT = 0   !------------------! INDEX FOR LOCATION IN NodQRT ARRA      
      DO 100 L=1,NQRTCL
C
C6-----GET NODE NUMBER OF CELL CONTAINING SINK.
      ND=QRTF(1,L)
      QQ=ZERO
C
C7-----IF THE CELL IS INACTIVE OR PCB, IGNORE IT.
      IF(ICBUND(ND).EQ.0.OR.IPCBFLAG(ND).EQ.1)GO TO 99
C
C8-----COMPUTE MASS FLUX AT SINK OF QRT BOUNDARY
        QF = QRTF(NQRTVL,L)
C
C9-----QRT SINK IS OUTFLOW, MASS IS Q * CONC
        Co = CONC(ND,ICOMP)
        QQ = -QF * Co
        Q = QQ
        RATOUT=RATOUT-QQ
C9A--------ADD FLOW RATE TO BUFFER.
        BUFF(ND)=BUFF(ND)+Q
C
C10-----COMPUTE MASS FLUX AT RETURN FLOW NODE BOUNDARY
        IF (IQRTFL.GT.0) THEN
          NumRT = QRTF(5,L)
          IF (NUMRT.NE.0) THEN
              
            DO JJ = 1,NumRT
              IRT = IRT + 1
              INR = NodQRT(IRT)
              IF (ICBUND(INR) .GT. 0) THEN
                QFIN = QRTFLOW(IRT)
                QQIN = QFIN * Co
                QIN = QQIN
                RATIN=RATIN+QQIN
C10A------------ADD FLOW RATE TO BUFFER.
                BUFF(INR)=BUFF(INR)+QIN                
              ENDIF                  
            ENDDO
          ENDIF
        ENDIF
C ------------------------------------------------------------------------
C11-----PRINT FLOW RATE IF REQUESTED.
        IF(IBD.LT.0) THEN
          IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT,KPER,KSTP
   61     FORMAT(1X,/1X,A,'   PERIOD ',I4,'   STEP ',I3)
C11A--------PRINT FOR STRUCTURED GRID
          IF(IUNSTR.EQ.0)THEN
            IL = (ND-1) / (NCOL*NROW) + 1
            IJ = ND - (IL-1)*NCOL*NROW
            IR = (IJ-1)/NCOL + 1
            IC = IJ - (IR-1)*NCOL
            WRITE(IOUT,62) L,IL,IR,IC,Q
   62       FORMAT(1X,'QRT  ',I6,'   LAYER ',I3,'   ROW ',I5,'   COL ',
     1       I5, '   FLUX ',1PG15.6)
C11B-----PRINT FOR RETURN FLOW
          IF (NumRT.NE.0) THEN
            DO I=IRT-NUMRT+1, IRT
              IL = (INR-1) / (NCOL*NROW) + 1
              IJ = INR - (IL-1)*NCOL*NROW
              IR = (IJ-1)/NCOL + 1
              IC = IJ - (IR-1)*NCOL
              WRITE(IOUT,64) L,IL,IR,IC,QRTFLOW(I)*Co
   64         FORMAT(1X,'RETURN ',I6,'   LAYER ',I3,'   ROW ',I5,
     1         '   COL ',I5, '   FLUX ',1PG15.6)
            ENDDO
          ENDIF
C11C--------PRINT FOR UNSTRUCTURED GRID
          ELSE
            WRITE(IOUT,63) L,ND,Q
   63       FORMAT(1X,'QRT  ',I6,'    NODE ',I8,'   FLUX ',1PG15.6)
          ENDIF
C11D-----PRINT FOR RETURN FLOW
          IF (NumRT.NE.0) THEN
            DO I=IRT-NUMRT+1, IRT
              WRITE(IOUT,550) L,NodQRT(I),QRTFLOW(I)*Co
            ENDDO
  550       FORMAT(1X,'SINK ',I6,
     *        ' RETURN:  NODE ',I10,'   FLUX ',1PG15.6)
          ENDIF
          IBDLBL=1
        END IF
C ------------------------------------------------------------------------
C
C15-----IF SAVING CELL-BY-CELL FLOWS IN A LIST, WRITE FLOW.  ALSO
C15-----COPY FLOW TO DRN LIST.

   99 CONTINUE
      IF(IBD.EQ.2) THEN
        IF(IUNSTR.EQ.0)THEN
          IL = (ND-1) / (NCOL*NROW) + 1
          IJ = ND - (IL-1)*NCOL*NROW
          IR = (IJ-1)/NCOL + 1
          IC = IJ - (IR-1)*NCOL
          CALL UBDSVB(IQRTCB,NCOL,NROW,IC,IR,IL,Q,
     1                  QRTF(1,L),NQRTVL,NAUX,10,ICBUND,NLAY)
          IF (NumRT.NE.0) THEN
            DO I=IRT-NUMRT+1, IRT
              ILR = (ND-1) / (NCOL*NROW) + 1
              IJR = ND - (ILR-1)*NCOL*NROW
              IRR = (IJR-1)/NCOL + 1
              ICR = IJR - (IRR-1)*NCOL
              CALL UBDSVB(IQRTCB,NCOL,NROW,ICR,IRR,ILR,QRTFLOW(I),
     &           QRTF(1,L),NQRTVL,NAUX,10,ICBUND,NLAY)
            ENDDO
          ENDIF
        ELSE
          CALL UBDSVBU(IQRTCB,NEQS,ND,Q,
     1                  QRTF(1,L),NQRTVL,NAUX,10,ICBUND)
          IF (NumRT.NE.0) THEN
            DO I=IRT-NUMRT+1, IRT
              AMASS = QRTFLOW(I)*Co
              CALL UBDSVBU(IQRTCB,NEQS,NodQRT(I),AMASS,QRTF(1,L),
     &                NQRTVL,NAUX,10,ICBUND)
            ENDDO
          ENDIF
        ENDIF
      ENDIF
100   CONTINUE
C
C16------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A 3-D ARRAY,
C16------CALL UBUDSV TO SAVE THEM.
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.1)CALL UBUDSV(KSTP,KPER,TEXT,IQRTCB,BUFF(1),NCOL,NROW,
     1                          NLAY,IOUT)
      ELSE
        IF(IBD.EQ.1) CALL UBUDSVU(KSTP,KPER,TEXT,IQRTCB,BUFF(1),NODES,
     1                          IOUT,PERTIM,TOTIM)
      ENDIF
C
C17------MOVE RATES, VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 RIN=RATIN
      ROUT=RATOUT
      VBVLT(3,MSUMT,ICOMP)=RIN
      VBVLT(4,MSUMT,ICOMP)=ROUT
      VBVLT(1,MSUMT,ICOMP)=VBVLT(1,MSUMT,ICOMP)+RATIN*DELT
      VBVLT(2,MSUMT,ICOMP)=VBVLT(2,MSUMT,ICOMP)+RATOUT*DELT
      VBNMT(MSUMT,ICOMP)=TEXT
C
C18------INCREMENT BUDGET TERM COUNTER(MSUM).
      MSUMT=MSUMT+1
C
C19------RETURN
      RETURN
      END
C----------------------------------------------------------------------------
      SUBROUTINE GWT2EVT1FM(ICOMP)
C     ******************************************************************
C     FORMULATE EVT TRANSPORT BOUNDARY CONDITION
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IBOUND,RHS,IA,JA,AMAT,FMBE,IFMBC
      USE GWFEVTMODULE, ONLY:EVTF,INIEVT,IEVT,IEVTCB,ETFACTOR
      USE GWTBCTMODULE, ONLY: ICBUND
      DOUBLE PRECISION Co,Q
C     ------------------------------------------------------------------
C
C1------IF NUMBER OF EVT CELLS <= 0 THEN RETURN.
      IF(INIEVT.LE.0) RETURN
      BIG = 1.0E20
C
C2------PROCESS EACH EVT NODE IN THE LIST.
      DO 100 L=1,INIEVT
      N=IEVT(L)
C
C2A-----IF THE CELL IS INACTIVE THEN BYPASS PROCESSING.
      IF(ICBUND(N).EQ.0) GO TO 100
        Q = EVTF(L)
C
C2B-----EVT IS ALWAYS OUTFLOW OUTFLOW, PUT Q ON LHS DIAGONAL
        AMAT(IA(N)) = AMAT(IA(N)) + Q * ETFACTOR(ICOMP)
C2C-----ADJUST FOR DRY CELLS WHERE ETRACTOR IS ZERO
        IF(IFMBC.NE.0)THEN
          IF(ABS(ETFACTOR(ICOMP)).LT.1.0E-5)THEN
            AMAT(IA(N)) = AMAT(IA(N)) + fmbe(n)  ! no correction on ET nodes (keeps diagonal zero for dry cells)
          ENDIF  
        ENDIF  
C
  100 CONTINUE
C
C3------RETURN
      RETURN
      END
C----------------------------------------------------------------------------
      SUBROUTINE GWT2ETS1FM(ICOMP)
C     ******************************************************************
C     FORMULATE ETS TRANSPORT BOUNDARY CONDITION
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IBOUND,RHS,IA,JA,AMAT
      USE GWFETSMODULE, ONLY:ETSF,INIETS,IETS,IETSCB,ESFACTOR
      USE GWTBCTMODULE, ONLY: ICBUND
      DOUBLE PRECISION Co,Q
C     ------------------------------------------------------------------
C
C1------IF NUMBER OF ETS CELLS <= 0 THEN RETURN.
      IF(INIETS.LE.0) RETURN
      BIG = 1.0E20
C
C2------PROCESS EACH ETS NODE IN THE LIST.
      DO 100 L=1,INIETS
      N=IETS(L)
C
C2A-----IF THE CELL IS INACTIVE THEN BYPASS PROCESSING.
      IF(ICBUND(N).EQ.0) GO TO 100
        Q = ETSF(L)
C
C2B-----ETS IS ALWAYS OUTFLOW OUTFLOW, PUT Q ON LHS DIAGONAL
        AMAT(IA(N)) = AMAT(IA(N)) + Q * ESFACTOR(ICOMP)
C
  100 CONTINUE
C
C3------RETURN
      RETURN
      END
C-----------------------------------------------------------------------
      SUBROUTINE GWT2EVT1BD(KSTP,KPER,ICOMP)
C     ******************************************************************
C     CALCULATE MASS BUDGET FOR EVT TRANSPORT BOUNDARY CONDITIONS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,   ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,BUFF,NODES,IUNSTR,
     1              AMAT,IA,JA
      USE GWFBASMODULE,ONLY:MSUM,ISPCFL,IAUXSV,DELT,PERTIM,TOTIM
      USE GWFEVTMODULE,ONLY:EVTF,INIEVT,IEVT,IEVTCB,ETFACTOR
      USE GWTBCTMODULE, ONLY: ICBUND,CONC,MSUMT,VBVLT,VBNMT,IPCBFLAG
C
      CHARACTER*16 TEXT
      DOUBLE PRECISION RATIN,RATOUT,QQ,BIG,CDIFF
      DATA TEXT /'   EVT MASS FLUX'/
C     ------------------------------------------------------------------
C
C1------CLEAR RATIN AND RATOUT ACCUMULATORS, AND SET CELL-BY-CELL
C1------BUDGET FLAG.
      ZERO=0.
      RATIN=ZERO
      RATOUT=ZERO
      IBD=0
      IF(IEVTCB.LT.0 .AND. ISPCFL.NE.0) IBD=-1
      IF(IEVTCB.GT.0) IBD=ISPCFL
      IBDLBL=0
C
C2------CLEAR THE BUFFER.
      DO 50 N=1,NODES
      BUFF(N)=ZERO
50    CONTINUE
C
C3------IF THERE ARE NO EVTs, DO NOT ACCUMULATE
      IF(INIEVT.EQ.0) GO TO 200
C
C4------LOOP THROUGH EACH EVT CALCULATING MASS FLUX
      DO 100 L=1,INIEVT
C
C5-----GET NODE NUMBER OF CELL CONTAINING EVT.
      N=IEVT(L)
      QQ=ZERO
C
C6-----IF THE CELL IS INACTIVE OR PCB, IGNORE IT.
      IF(ICBUND(N).EQ.0.OR.IPCBFLAG(N).EQ.1)GO TO 99
C
C7-----COMPUTE MASS FLUX AT EVT BOUNDARY
        QF = EVTF(L)
C
C8-----EVT IS ALWAYS OUTFLOW, MASS IS Q * CONC
        QQ = QF * CONC(N,ICOMP) * ETFACTOR(ICOMP)
         Q = QQ
C
C9-----PRINT FLOW RATE IF REQUESTED.
        IF(IBD.LT.0) THEN
          IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT,KPER,KSTP
   61     FORMAT(1X,/1X,A,'   PERIOD ',I4,'   STEP ',I3)
          IF(IUNSTR.EQ.0)THEN
            IL = (N-1) / (NCOL*NROW) + 1
            IJ = N - (IL-1)*NCOL*NROW
            IR = (IJ-1)/NCOL + 1
            IC = IJ - (IR-1)*NCOL
            WRITE(IOUT,62) L,IL,IR,IC,Q
   62       FORMAT(1X,'EVT  ',I6,'   LAYER ',I3,'   ROW ',I5,'   COL ',
     1       I5, '   FLUX ',1PG15.6)
          ELSE
            WRITE(IOUT,63) L,N,Q
   63       FORMAT(1X,'EVT  ',I6,'    NODE ',I8,'   FLUX ',1PG15.6)
          ENDIF
          IBDLBL=1
        END IF
C
C10-----ADD FLOW RATE TO BUFFER.
        BUFF(N)=BUFF(N)+Q
C
C11-----SEE IF FLUX IS POSITIVE OR NEGATIVE.
        IF(QQ.GE.ZERO) THEN
C
C12-------FLOW RATE IS POSITIVE (RECHARGE). ADD IT TO RATIN.
          RATIN=RATIN+QQ
        ELSE
C
C13-------FLOW RATE IS NEGATIVE (DISCHARGE). ADD IT TO RATOUT.
          RATOUT=RATOUT-QQ
        END IF
C
C14-----IF SAVING CELL-BY-CELL FLOWS IN A LIST, WRITE FLOW.  ALSO
C14-----COPY FLOW TO EVT LIST.

   99 CONTINUE
C
100   CONTINUE
C
C15------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A 3-D ARRAY,
C15------CALL UBUDSV TO SAVE THEM.
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.1) CALL UBUDSV(KSTP,KPER,TEXT,IEVTCB,BUFF,NCOL,NROW,
     1                          NLAY,IOUT)
      ELSE
        IF(IBD.EQ.1) CALL UBUDSVU(KSTP,KPER,TEXT,IEVTCB,BUFF,NODES,
     1                          IOUT,PERTIM,TOTIM)
      ENDIF
C
C16------MOVE RATES, VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 RIN=RATIN
      ROUT=RATOUT
      VBVLT(3,MSUMT,ICOMP)=RIN
      VBVLT(4,MSUMT,ICOMP)=ROUT
      VBVLT(1,MSUMT,ICOMP)=VBVLT(1,MSUMT,ICOMP)+RATIN*DELT
      VBVLT(2,MSUMT,ICOMP)=VBVLT(2,MSUMT,ICOMP)+RATOUT*DELT
      VBNMT(MSUMT,ICOMP)=TEXT
C
C17------INCREMENT BUDGET TERM COUNTER(MSUM).
      MSUMT=MSUMT+1
C
C18------RETURN
      RETURN
      END
C-----------------------------------------------------------------------
      SUBROUTINE GWT2ETS1BD(KSTP,KPER,ICOMP)
C     ******************************************************************
C     CALCULATE MASS BUDGET FOR ETS TRANSPORT BOUNDARY CONDITIONS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,   ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,BUFF,NODES,IUNSTR,
     1              AMAT,IA,JA
      USE GWFBASMODULE,ONLY:MSUM,ISPCFL,IAUXSV,DELT,PERTIM,TOTIM
      USE GWFETSMODULE,ONLY:ETSF,INIETS,IETS,IETSCB,ESFACTOR
      USE GWTBCTMODULE, ONLY: ICBUND,CONC,MSUMT,VBVLT,VBNMT,IPCBFLAG
C
      CHARACTER*16 TEXT
      DOUBLE PRECISION RATIN,RATOUT,QQ,BIG,CDIFF
      DATA TEXT /'   ETS MASS FLUX'/
C     ------------------------------------------------------------------
C
C1------CLEAR RATIN AND RATOUT ACCUMULATORS, AND SET CELL-BY-CELL
C1------BUDGET FLAG.
      ZERO=0.
      RATIN=ZERO
      RATOUT=ZERO
      IBD=0
      IF(IETSCB.LT.0 .AND. ISPCFL.NE.0) IBD=-1
      IF(IETSCB.GT.0) IBD=ISPCFL
      IBDLBL=0
C
C2------CLEAR THE BUFFER.
      DO 50 N=1,NODES
      BUFF(N)=ZERO
50    CONTINUE
C
C3------IF THERE ARE NO ETSs, DO NOT ACCUMULATE
      IF(INIETS.EQ.0) GO TO 200
C
C4------LOOP THROUGH EACH ETS CALCULATING MASS FLUX
      DO 100 L=1,INIETS
C
C5-----GET NODE NUMBER OF CELL CONTAINING ETS.
      N=IETS(L)
      QQ=ZERO
C
C6-----IF THE CELL IS INACTIVE OR PCB, IGNORE IT.
      IF(ICBUND(N).EQ.0.OR.IPCBFLAG(N).EQ.1)GO TO 99
C
C7-----COMPUTE MASS FLUX AT ETS BOUNDARY
        QF = ETSF(L)
C
C8-----ETS IS ALWAYS OUTFLOW, MASS IS Q * CONC
        QQ = QF * CONC(N,ICOMP) * ESFACTOR(ICOMP)
         Q = QQ
C
C9-----PRINT FLOW RATE IF REQUESTED.
        IF(IBD.LT.0) THEN
          IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT,KPER,KSTP
   61     FORMAT(1X,/1X,A,'   PERIOD ',I4,'   STEP ',I3)
          IF(IUNSTR.EQ.0)THEN
            IL = (N-1) / (NCOL*NROW) + 1
            IJ = N - (IL-1)*NCOL*NROW
            IR = (IJ-1)/NCOL + 1
            IC = IJ - (IR-1)*NCOL
            WRITE(IOUT,62) L,IL,IR,IC,Q
   62       FORMAT(1X,'ETS  ',I6,'   LAYER ',I3,'   ROW ',I5,'   COL ',
     1       I5, '   FLUX ',1PG15.6)
          ELSE
            WRITE(IOUT,63) L,N,Q
   63       FORMAT(1X,'ETS  ',I6,'    NODE ',I8,'   FLUX ',1PG15.6)
          ENDIF
          IBDLBL=1
        END IF
C
C10-----ADD FLOW RATE TO BUFFER.
        BUFF(N)=BUFF(N)+Q
C
C11-----SEE IF FLUX IS POSITIVE OR NEGATIVE.
        IF(QQ.GE.ZERO) THEN
C
C12-------FLOW RATE IS POSITIVE (RECHARGE). ADD IT TO RATIN.
          RATIN=RATIN+QQ
        ELSE
C
C13-------FLOW RATE IS NEGATIVE (DISCHARGE). ADD IT TO RATOUT.
          RATOUT=RATOUT-QQ
        END IF
C
C14-----IF SAVING CELL-BY-CELL FLOWS IN A LIST, WRITE FLOW.  ALSO
C14-----COPY FLOW TO ETS LIST.

   99 CONTINUE
C
100   CONTINUE
C
C15------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A 3-D ARRAY,
C15------CALL UBUDSV TO SAVE THEM.
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.1) CALL UBUDSV(KSTP,KPER,TEXT,IETSCB,BUFF,NCOL,NROW,
     1                          NLAY,IOUT)
      ELSE
        IF(IBD.EQ.1) CALL UBUDSVU(KSTP,KPER,TEXT,IETSCB,BUFF,NODES,
     1                          IOUT,PERTIM,TOTIM)
      ENDIF
C
C16------MOVE RATES, VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 RIN=RATIN
      ROUT=RATOUT
      VBVLT(3,MSUMT,ICOMP)=RIN
      VBVLT(4,MSUMT,ICOMP)=ROUT
      VBVLT(1,MSUMT,ICOMP)=VBVLT(1,MSUMT,ICOMP)+RATIN*DELT
      VBVLT(2,MSUMT,ICOMP)=VBVLT(2,MSUMT,ICOMP)+RATOUT*DELT
      VBNMT(MSUMT,ICOMP)=TEXT
C
C17------INCREMENT BUDGET TERM COUNTER(MSUM).
      MSUMT=MSUMT+1
C
C18------RETURN
      RETURN
      END
C----------------------------------------------------------------------------
      SUBROUTINE GWT2RCH1FM(ICOMP)
C     ******************************************************************
C     FORMULATE RCH TRANSPORT BOUNDARY CONDITION
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IBOUND,RHS,IA,JA,AMAT
      USE GWFRCHMODULE, ONLY:RCHF,INIRCH,IRCH,IRCHCB,
     &  RCHCONC,IRCHCONC
      USE GWTBCTMODULE, ONLY: ICBUND
      DOUBLE PRECISION Co,Q
C     ------------------------------------------------------------------
C
C1------IF NUMBER OF RCH CELLS <= 0 THEN RETURN.
      IF(INIRCH.LE.0) RETURN
      BIG = 1.0E20
C-------FIND COMPONENT NUMBER IF RECHARGE CONCENTRATIONS ARE READ     
      IF(IRCHCONC(ICOMP).EQ.1)THEN
          ICONCRCH = 0
          DO II=1,ICOMP
            ICONCRCH = ICONCRCH + IRCHCONC(II)
          ENDDO
        ENDIF
C
C2------PROCESS EACH RCH NODE IN THE LIST.
      DO 100 L=1,INIRCH
      N=IRCH(L)
C
C2A-----IF THE CELL IS INACTIVE THEN BYPASS PROCESSING.
      IF(ICBUND(N).EQ.0) GO TO 100
        Q = RCHF(L)
        Co= 0.0
        IF(IRCHCONC(ICOMP).EQ.1)THEN
          Co = RCHCONC(L,ICONCRCH)
        ENDIF  
C
C2B-----IF THE CELL IS OUTFLOW, PUT Q ON LHS DIAGONAL
        IF(Q.LT.0.0)THEN
          AMAT(IA(N)) = AMAT(IA(N)) + Q
        ELSE
C2C-------IF THE CELL IS INFLOW, PUT Q*Co ON RHS
          RHS(N) = RHS(N) -Co * Q
        ENDIF
C
  100 CONTINUE
C
C3------RETURN
      RETURN
      END
C-----------------------------------------------------------------------
      SUBROUTINE GWT2RCH1BD(KSTP,KPER,ICOMP)
C     ******************************************************************
C     CALCULATE MASS BUDGET FOR RCH TRANSPORT BOUNDARY CONDITIONS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,   ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,BUFF,NODES,IUNSTR,
     1              AMAT,IA,JA
      USE GWFBASMODULE,ONLY:MSUM,ISPCFL,IAUXSV,DELT,PERTIM,TOTIM
      USE GWFRCHMODULE,ONLY:RCHF,INIRCH,IRCH,IRCHCB,
     &  RCHCONC,IRCHCONC      
      USE GWTBCTMODULE, ONLY: ICBUND,CONC,MSUMT,VBVLT,VBNMT,IPCBFLAG
C
      CHARACTER*16 TEXT
      DOUBLE PRECISION RATIN,RATOUT,QQ,BIG,CDIFF
      DATA TEXT /'   RCH MASS FLUX'/
C     ------------------------------------------------------------------
C
C1------CLEAR RATIN AND RATOUT ACCUMULATORS, AND SET CELL-BY-CELL
C1------BUDGET FLAG.
      ZERO=0.
      RATIN=ZERO
      RATOUT=ZERO
      IBD=0
      IF(IRCHCB.LT.0 .AND. ISPCFL.NE.0) IBD=-1
      IF(IRCHCB.GT.0) IBD=ISPCFL
      IBDLBL=0
C
C2------CLEAR THE BUFFER.
      DO 50 N=1,NODES
      BUFF(N)=ZERO
50    CONTINUE
C
C3------IF THERE ARE NO RCHs, DO NOT ACCUMULATE
      IF(INIRCH.EQ.0) GO TO 200
C-------FIND COMPONENT NUMBER IF RECHARGE CONCENTRATIONS ARE READ     
      IF(IRCHCONC(ICOMP).EQ.1)THEN
          ICONCRCH = 0
          DO II=1,ICOMP
            ICONCRCH = ICONCRCH + IRCHCONC(II)
          ENDDO
        ENDIF
C
C4------LOOP THROUGH EACH RCH CALCULATING MASS FLUX
      DO 100 L=1,INIRCH
C
C5------GET NODE NUMBER OF CELL CONTAINING RCH.
      N=IRCH(L)
      QQ=ZERO
C
C6------IF THE CELL IS INACTIVE OR PCB, IGNORE IT.
      IF(ICBUND(N).EQ.0.OR.IPCBFLAG(N).EQ.1)GO TO 99
C
C7------COMPUTE MASS FLUX AT RCH BOUNDARY
        QF = RCHF(L)
        Co = 0.0
        IF(IRCHCONC(ICOMP).EQ.1)THEN
          Co = RCHCONC(L,ICONCRCH)
        ENDIF        
C
C8------IF THE CELL IS OUTFLOW, MASS IS Q * CONC
        IF(QF.LT.0.0)THEN
          QQ = QF * CONC(N,ICOMP)
        ELSE
C9--------IF THE CELL IS INFLOW, MASS IS Q*Co
          QQ = QF * Co
        ENDIF
        Q = QQ
C
C10-----PRINT FLOW RATE IF REQUESTED.
        IF(IBD.LT.0) THEN
          IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT,KPER,KSTP
   61     FORMAT(1X,/1X,A,'   PERIOD ',I4,'   STEP ',I3)
          IF(IUNSTR.EQ.0)THEN
            IL = (N-1) / (NCOL*NROW) + 1
            IJ = N - (IL-1)*NCOL*NROW
            IR = (IJ-1)/NCOL + 1
            IC = IJ - (IR-1)*NCOL
            WRITE(IOUT,62) L,IL,IR,IC,Q
   62       FORMAT(1X,'RCH  ',I6,'   LAYER ',I3,'   ROW ',I5,'   COL ',
     1       I5, '   FLUX ',1PG15.6)
          ELSE
            WRITE(IOUT,63) L,N,Q
   63       FORMAT(1X,'RCH  ',I6,'    NODE ',I8,'   FLUX ',1PG15.6)
          ENDIF
          IBDLBL=1
        END IF
C
C11-----ADD FLOW RATE TO BUFFER.
        BUFF(N)=BUFF(N)+Q
C
C12-----SEE IF FLUX IS POSITIVE OR NEGATIVE.
        IF(QQ.GE.ZERO) THEN
C
C13-------FLOW RATE IS POSITIVE (RECHARGE). ADD IT TO RATIN.
          RATIN=RATIN+QQ
        ELSE
C
C14-------FLOW RATE IS NEGATIVE (DISCHARGE). ADD IT TO RATOUT.
          RATOUT=RATOUT-QQ
        END IF
C
C15-----IF SAVING CELL-BY-CELL FLOWS IN A LIST, WRITE FLOW.  ALSO
C15-----COPY FLOW TO RCH LIST.

   99 CONTINUE
C
100   CONTINUE
C
C16------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A 3-D ARRAY,
C16------CALL UBUDSV TO SAVE THEM.
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.1) CALL UBUDSV(KSTP,KPER,TEXT,IRCHCB,BUFF,NCOL,NROW,
     1                          NLAY,IOUT)
      ELSE
        IF(IBD.EQ.1) CALL UBUDSVU(KSTP,KPER,TEXT,IRCHCB,BUFF,NODES,
     1                          IOUT,PERTIM,TOTIM)
      ENDIF
C
C17------MOVE RATES, VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 RIN=RATIN
      ROUT=RATOUT
      VBVLT(3,MSUMT,ICOMP)=RIN
      VBVLT(4,MSUMT,ICOMP)=ROUT
      VBVLT(1,MSUMT,ICOMP)=VBVLT(1,MSUMT,ICOMP)+RATIN*DELT
      VBVLT(2,MSUMT,ICOMP)=VBVLT(2,MSUMT,ICOMP)+RATOUT*DELT
      VBNMT(MSUMT,ICOMP)=TEXT
C
C18------INCREMENT BUDGET TERM COUNTER(MSUM).
      MSUMT=MSUMT+1
C
C19------RETURN
      RETURN
      END
C----------------------------------------------------------------------------
      SUBROUTINE GWT2RIV1FM(ICOMP)
C     ******************************************************************
C     FORMULATE RIV TRANSPORT BOUNDARY CONDITION
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,       ONLY:IBOUND,RHS,IA,JA,AMAT
      USE GWFRIVMODULE, ONLY:NRIVER,RIVR,NRIVVL,RIVAUX
      USE GWTBCTMODULE, ONLY: ICBUND
      DOUBLE PRECISION Co,Q
C     ------------------------------------------------------------------
C
C1------IF NUMBER OF RIV NODES <= 0 THEN RETURN.
      IF(NRIVER.LE.0) RETURN
      BIG = 1.0E20
      NAUX=NRIVVL-7
      CALL CONCIAUX(ICOMP,NAUX,RIVAUX,IAUX)
C
C2------PROCESS EACH RIV NODE IN THE LIST.
      DO 100 L=1,NRIVER
      N=RIVR(1,L)
C
C2A-----IF THE CELL IS INACTIVE THEN BYPASS PROCESSING.
      IF(ICBUND(N).EQ.0) GO TO 100
        Q = RIVR(NRIVVL,L)
C
C2B-----IF THE CELL IS OUTFLOW, PUT Q ON LHS DIAGONAL
        IF(Q.LE.0.0)THEN
          AMAT(IA(N)) = AMAT(IA(N)) + Q
        ELSE
C2C-------IF THE CELL IS INFLOW, PUT Q*Co ON RHS
          Co= RIVR(6+IAUX,L)  
          RHS(N) = RHS(N) -Co * Q
        ENDIF
C
  100 CONTINUE
C
C3------RETURN
      RETURN
      END
C-----------------------------------------------------------------------
      SUBROUTINE GWT2RIV1BD(KSTP,KPER,ICOMP)
C     ******************************************************************
C     CALCULATE MASS BUDGET FOR RIV TRANSPORT BOUNDARY CONDITIONS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,   ONLY:IOUT,NCOL,NROW,NLAY,IBOUND,BUFF,NODES,IUNSTR,
     1              AMAT,IA,JA
      USE GWFBASMODULE,ONLY:MSUM,ISPCFL,IAUXSV,DELT,PERTIM,TOTIM
      USE GWFRIVMODULE,ONLY:NRIVER,IRIVCB,RIVR,NRIVVL,RIVAUX
      USE GWTBCTMODULE, ONLY: ICBUND,CONC,MSUMT,VBVLT,VBNMT,IPCBFLAG
C
      CHARACTER*16 TEXT
      DOUBLE PRECISION RATIN,RATOUT,QQ,BIG,CDIFF
      DATA TEXT /'   RIV MASS FLUX'/
C     ------------------------------------------------------------------
C
C1------CLEAR RATIN AND RATOUT ACCUMULATORS, AND SET CELL-BY-CELL
C1------BUDGET FLAG.
      ZERO=0.
      RATIN=ZERO
      RATOUT=ZERO
      IBD=0
      IF(IRIVCB.LT.0 .AND. ISPCFL.NE.0) IBD=-1
      IF(IRIVCB.GT.0) IBD=ISPCFL
      IBDLBL=0
      NAUX=NRIVVL-7
      CALL CONCIAUX(ICOMP,NAUX,RIVAUX,IAUX)
C
C2-----IF CELL-BY-CELL FLOWS WILL BE SAVED AS A LIST, WRITE HEADER.
      IF(IBD.EQ.2) THEN
         NAUX=NRIVVL-5
         IF(IAUXSV.EQ.0) NAUX=0
         CALL UBDSV4(KSTP,KPER,TEXT,NAUX,RIVAUX,IRIVCB,NCOL,NROW,NLAY,
     1          NBOUND,IOUT,DELT,PERTIM,TOTIM,ICBUND)
      END IF
C
C3------CLEAR THE BUFFER.
      DO 50 N=1,NODES
      BUFF(N)=ZERO
50    CONTINUE
C
C4------IF THERE ARE NO RIVs, DO NOT ACCUMULATE
      IF(NRIVER.EQ.0) GO TO 200
C
C5------LOOP THROUGH EACH RIV CALCULATING MASS FLUX
      DO 100 L=1,NRIVER
C
C6-----GET NODE NUMBER OF CELL CONTAINING RIV.
      N=RIVR(1,L)
      QQ=ZERO
C
C7-----IF THE CELL IS INACTIVE OR PCB, IGNORE IT.
      IF(ICBUND(N).EQ.0.OR.IPCBFLAG(N).EQ.1)GO TO 99
C
C8-----COMPUTE MASS FLUX AT RIVER BOUNDARY
        QF = RIVR(NRIVVL,L)
C
C9-----IF THE CELL IS OUTFLOW, MASS IS Q * CONC
        IF(QF.LE.0.0)THEN
          QQ = QF * CONC(N,ICOMP)
        ELSE
C10-------IF THE CELL IS INFLOW, MASS IS Q*Co
          Co = RIVR(6+IAUX,L)
          QQ = QF * Co
        ENDIF
        Q = QQ
C
C11-----PRINT FLOW RATE IF REQUESTED.
        IF(IBD.LT.0) THEN
          IF(IBDLBL.EQ.0) WRITE(IOUT,61) TEXT,KPER,KSTP
   61     FORMAT(1X,/1X,A,'   PERIOD ',I4,'   STEP ',I3)
          IF(IUNSTR.EQ.0)THEN
            IL = (N-1) / (NCOL*NROW) + 1
            IJ = N - (IL-1)*NCOL*NROW
            IR = (IJ-1)/NCOL + 1
            IC = IJ - (IR-1)*NCOL
            WRITE(IOUT,62) L,IL,IR,IC,Q
   62       FORMAT(1X,'RIV  ',I6,'   LAYER ',I3,'   ROW ',I5,'   COL ',
     1       I5, '   FLUX ',1PG15.6)
          ELSE
            WRITE(IOUT,63) L,N,Q
   63       FORMAT(1X,'RIV  ',I6,'    NODE ',I8,'   FLUX ',1PG15.6)
          ENDIF
          IBDLBL=1
        END IF
C
C12-----ADD FLOW RATE TO BUFFER.
        BUFF(N)=BUFF(N)+Q
C
C13-----SEE IF FLUX IS POSITIVE OR NEGATIVE.
        IF(QQ.GE.ZERO) THEN
C
C14-------FLOW RATE IS POSITIVE (RECHARGE). ADD IT TO RATIN.
          RATIN=RATIN+QQ
        ELSE
C
C15-------FLOW RATE IS NEGATIVE (DISCHARGE). ADD IT TO RATOUT.
          RATOUT=RATOUT-QQ
        END IF
C
C16-----IF SAVING CELL-BY-CELL FLOWS IN A LIST, WRITE FLOW.  ALSO
C16-----COPY FLOW TO RIVER LIST.

   99 CONTINUE
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.2) CALL UBDSVB(IRIVCB,NCOL,NROW,IC,IR,IL,Q,
     1                  RIVR(1,L),NRIVVL,NAUX,6,ICBUND,NLAY)
      ELSE
C        IF(IBD.EQ.2) CALL UBDSVBU(IRIVCB,NODES,N,Q,
C     1                  RIVR(1,L),NRIVVL,NAUX,6,ICBUND)
      ENDIF
100   CONTINUE
C
C17------IF CELL-BY-CELL FLOWS WILL BE SAVED AS A 3-D ARRAY,
C17------CALL UBUDSV TO SAVE THEM.
      IF(IUNSTR.EQ.0)THEN
        IF(IBD.EQ.1)CALL UBUDSV(KSTP,KPER,TEXT,IRIVCB,BUFF(1),NCOL,NROW,
     1                          NLAY,IOUT)
      ELSE
        IF(IBD.EQ.1) CALL UBUDSVU(KSTP,KPER,TEXT,IRIVCB,BUFF(1),NODES,
     1                          IOUT,PERTIM,TOTIM)
      ENDIF
C
C18------MOVE RATES, VOLUMES & LABELS INTO ARRAYS FOR PRINTING.
  200 RIN=RATIN
      ROUT=RATOUT
      VBVLT(3,MSUMT,ICOMP)=RIN
      VBVLT(4,MSUMT,ICOMP)=ROUT
      VBVLT(1,MSUMT,ICOMP)=VBVLT(1,MSUMT,ICOMP)+RATIN*DELT
      VBVLT(2,MSUMT,ICOMP)=VBVLT(2,MSUMT,ICOMP)+RATOUT*DELT
      VBNMT(MSUMT,ICOMP)=TEXT
C
C19------INCREMENT BUDGET TERM COUNTER(MSUM).
      MSUMT=MSUMT+1
C
C20------RETURN
      RETURN
      END
C----------------------------------------------------------------------------
      SUBROUTINE CONCIAUX(ICOMP,NAUX,BNDAUX,IAUX)
C     ******************************************************************
C     GET INDEX FOR AUXILIARY VARIABLE FOR COMPONENT ICOMP
C     ******************************************************************
C
C        SPECIFICATIONS:
      CHARACTER*4 BNDAUX(4),BAUX
C     ------------------------------------------------------------------
      BAUX = BNDAUX(1)
      DO I=1,NAUX
        IF(BNDAUX(I).EQ.'C01 '.AND.ICOMP.EQ.1)THEN
          IAUX = 1
          RETURN  
        ELSEIF(BNDAUX(I).EQ.'C02 '.AND.ICOMP.EQ.2)THEN
          IAUX = 2
          RETURN  
        ELSEIF(BNDAUX(I).EQ.'C03 '.AND.ICOMP.EQ.3)THEN
          IAUX = 3
          RETURN  
        ELSEIF(BNDAUX(I).EQ.'C04 '.AND.ICOMP.EQ.4)THEN
          IAUX = 4
          RETURN  
        ELSEIF(BNDAUX(I).EQ.'C05 '.AND.ICOMP.EQ.5)THEN
          IAUX = 5
          RETURN  
        ELSEIF(BNDAUX(I).EQ.'C06 '.AND.ICOMP.EQ.6)THEN
          IAUX = 6
          RETURN  
        ELSEIF(BNDAUX(I).EQ.'C07 '.AND.ICOMP.EQ.7)THEN
          IAUX = 7
          RETURN  
        ELSEIF(BNDAUX(I).EQ.'C08 '.AND.ICOMP.EQ.8)THEN
          IAUX = 8
          RETURN  
        ELSEIF(BNDAUX(I).EQ.'C09 '.AND.ICOMP.EQ.9)THEN
          IAUX = 9
          RETURN  
        ELSEIF(BNDAUX(I).EQ.'C10 '.AND.ICOMP.EQ.10)THEN
          IAUX = 10
          RETURN  
        ELSEIF (BNDAUX(I).EQ.'C11 '.AND.ICOMP.EQ.11)THEN
          IAUX = 11
          RETURN 
         ELSEIF (BNDAUX(I).EQ.'C12 '.AND.ICOMP.EQ.12)THEN
          IAUX = 12
          RETURN 
        ELSEIF (BNDAUX(I).EQ.'C13 '.AND.ICOMP.EQ.13)THEN
          IAUX = 13
          RETURN   
        ELSEIF (BNDAUX(I).EQ.'C14 '.AND.ICOMP.EQ.14)THEN
          IAUX = 14
          RETURN
        ELSEIF (BNDAUX(I).EQ.'C15 '.AND.ICOMP.EQ.15)THEN
          IAUX = 15
          RETURN
        ELSEIF (BNDAUX(I).EQ.'C16 '.AND.ICOMP.EQ.16)THEN
          IAUX = 16
          RETURN
        ELSEIF (BNDAUX(I).EQ.'C17 '.AND.ICOMP.EQ.17)THEN
          IAUX = 17
          RETURN  
        ELSEIF (BNDAUX(I).EQ.'C18 '.AND.ICOMP.EQ.18)THEN
          IAUX = 18
          RETURN 
        ELSEIF (BNDAUX(I).EQ.'C19 '.AND.ICOMP.EQ.19)THEN
          IAUX = 19
          RETURN 
        ELSEIF (BNDAUX(I).EQ.'C20 '.AND.ICOMP.EQ.20)THEN
          IAUX = 20
          RETURN   
        ENDIF  
      ENDDO    
C
C ------RETURN
      RETURN
      END
C----------------------------------------------------------------------------      