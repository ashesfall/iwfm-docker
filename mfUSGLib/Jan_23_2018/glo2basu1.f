      SUBROUTINE GLO2BAS8AR(INUNIT,CUNIT,VERSION,IUDIS,IUZON,IUMLT,
     1   MAXUNIT,IUOC,HEADNG,IUPVAL,MFVNAM,IUCLN,IUGNC,IUGNC2,IUGNCn)
c      call glo2bas8ar(mf_iin,CUNIT,VERSION,24,31,32,maxunit,12,headng,26,MFVNAM,29,27,30,36)
C     ******************************************************************************
C     ALLOCATE AND READ BASIC AND DISCRETIZATION INFORMATION FOR ALL PROCESS DOMAINS
C     ******************************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL, ONLY:NCOL,NROW,NLAY,NPER,ITMUNI,NJA,NJAS,NJAG,
     1  IVSD,LENUNI,IXSEC,ITRSS,INBAS,IFREFM,NODES,IOUT,FMBE,
     2  IUNIT,NIUNIT,HNEW,LAYHDT,LAYHDS,NODLAY,NBOTM,INDDF,IFMBC,
     3  PERLEN,NSTP,TSMULT,ISSFLG,IUNSTR,MXNODLAY,NCNFBD,DDREF,
     4  HOLD,IBOUND,RHS,AMAT,BUFF,STRT,IPRCONN,IDSYMRD,ILAYCON4,
     5  IDEALLOC_LPF,IDEALLOC_HY,INCLN,INGNC,INGNC2,INGNCn,IDPF,IDPT,
     6  INSGB,ITRNSP,Sn,So,NEQS,ISYMFLG,WADIEPS,IWADI,IWADICLN,iunsat
      USE PARAMMODULE,ONLY:MXPAR,MXCLST,MXINST,ICLSUM,IPSUM,
     1                     INAMLOC,NMLTAR,NZONAR,NPVAL,
     2                     B,IACTIVE,IPLOC,IPCLST,PARNAM,PARTYP,
     3                     ZONNAM,MLTNAM,INAME
      USE GWFBASMODULE,ONLY:MSUM,IHEDFM,IHEDUN,IDDNFM,IDDNUN,IBOUUN,
     1                 LBHDSV,LBDDSV,LBBOSV,IBUDFL,ICBCFL,IHDDFL,ISPCFL,
     2                 IAUXSV,IBDOPT,IPRTIM,IPEROC,ITSOC,ICHFLG,IFRCNVG,
     3                 DELT,PERTIM,TOTIM,HNOFLO,CHEDFM,CDDNFM,CBOUFM,
     4                 VBVL,VBNM,ISPCFM,ISPCUN,CSPCFM,IDDREF,IDDREFNEW
C
      CHARACTER*4 CUNIT(NIUNIT)
      CHARACTER*(*) VERSION
      CHARACTER*80 HEADNG(2)
      CHARACTER*(*) MFVNAM
      CHARACTER*200 LINE
c      INTEGER INUNIT
C
      INTEGER, DIMENSION(:,:,:),    ALLOCATABLE  ::ITMP
      REAL, DIMENSION(:,:,:),ALLOCATABLE  ::HTMP
      REAL, DIMENSION(:),ALLOCATABLE  ::HTMP1
      CHARACTER*24 ANAME(2)
      DATA ANAME(1) /'          BOUNDARY ARRAY'/
      DATA ANAME(2) /'            INITIAL HEAD'/
C     ------------------------------------------------------------------
C1------Allocate scalar variables.
      allocate(iunsat)
      iunsat = 0 ! full unsat formulation is on when this is made unity
      ALLOCATE(NCOL,NROW,NLAY,NPER,NBOTM,NCNFBD,ITMUNI,LENUNI,ITRSS)
      ALLOCATE(NJA,NJAS,NJAG,ILAYCON4,WADIEPS,IWADI,IWADICLN,IDPF,IDPT,
     1 INSGB)
      ALLOCATE(IXSEC,INBAS,IFREFM,NODES,IOUT,MXNODLAY,IUNSTR,IVSD)
      ALLOCATE(IDEALLOC_LPF,IDEALLOC_HY,ITRNSP,NEQS,IDSYMRD,IPRCONN)
      ALLOCATE(INCLN,INGNC,INGNC2,INGNCn,ISYMFLG,IDDREF,IDDREFNEW,INDDF)
      INCLN = 0
      INDDF = 0
      INGNC = 0
      INGNC2 = 0
      INGNCn = 0
      IDEALLOC_HY = 0
      IDEALLOC_LPF = 0
      IWADI = 0
      IWADICLN = 0
      IDPF = 0
      IDPT = 0
      INSGB = 0
      IDDREF=0
      IDDREFNEW=0
      ALLOCATE(IUNIT(NIUNIT))
C
      ALLOCATE(ICLSUM,IPSUM,INAMLOC,NMLTAR,NZONAR,NPVAL)
      ALLOCATE (B(MXPAR))
      ALLOCATE (IACTIVE(MXPAR))
      ALLOCATE (IPLOC(4,MXPAR))
      ALLOCATE (IPCLST(14,MXCLST))
      ALLOCATE (PARNAM(MXPAR))
      ALLOCATE (PARTYP(MXPAR))
      ALLOCATE (INAME(MXINST))
C
      ALLOCATE(MSUM,IHEDFM,IHEDUN,IDDNFM,IDDNUN,IBOUUN,LBHDSV,LBDDSV,
     1         LBBOSV,ISPCFM,ISPCUN)
      ALLOCATE(IBUDFL,ICBCFL,IHDDFL,ISPCFL,IAUXSV,IBDOPT,IPRTIM,IPEROC,
     1         ITSOC,ICHFLG,IFRCNVG)
      ALLOCATE(DELT,PERTIM,TOTIM,HNOFLO)
      ALLOCATE(CHEDFM,CDDNFM,CBOUFM,CSPCFM)

C
C2------Open all files in name file.
      CALL SGWF2BAS8OPEN(INUNIT,IOUT,IUNIT,CUNIT,NIUNIT,
     &                 VERSION,INBAS,MAXUNIT,MFVNAM)
C
C3------PRINT A MESSAGE IDENTIFYING THE BASIC PACKAGE.
      WRITE(IOUT,1)MFVNAM,VERSION,INBAS
    1 FORMAT(1X,/1X,'BAS -- BASIC PACKAGE',A,A,
     2' INPUT READ FROM UNIT ',I4)
C
C4------Initialize parameter definition variables.
      !IF(IUNIT(27).GT.0) INSGB = 1
      ITRNSP=0
      !IF(IUNIT(15). GT. 0) ITRNSP=1
      IPSUM=0
      ICLSUM=0
      INAMLOC=1
      DO 10 N=1,MXPAR
        PARNAM(N)=' '
        PARTYP(N)=' '
        IPLOC(1,N)=0
        IPLOC(2,N)=0
        IACTIVE(N)=0
   10 CONTINUE
C
C5------Read first lines of BAS Package file and identify grid type and options.
C5A-----READ AND PRINT COMMENTS.  SAVE THE FIRST TWO COMMENTS IN HEADNG.
      HEADNG(1)=' '
      HEADNG(2)=' '
      WRITE(IOUT,*)
      READ(INBAS,'(A)') LINE
      IF(LINE(1:1).NE.'#') GO TO 20
      HEADNG(1)=LINE(1:80)
      WRITE(IOUT,'(1X,A)') HEADNG(1)
      READ(INBAS,'(A)') LINE
      IF(LINE(1:1).NE.'#') GO TO 20
      HEADNG(2)=LINE(1:80)
      WRITE(IOUT,'(1X,A)') HEADNG(2)
      CALL URDCOM(INBAS,IOUT,LINE)
C
C5B-----LOOK FOR OPTIONS IN THE FIRST ITEM AFTER THE HEADING.
   20 IXSEC=0
      ICHFLG=0
      IFREFM=0
      IPRTIM=0
      IUNSTR=0
      IFRCNVG=0
      LLOC=1
      IPRCONN=0
   25 CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INBAS)
      IF(LINE(ISTART:ISTOP).EQ.'XSECTION') THEN
         IXSEC=1
      ELSE IF(LINE(ISTART:ISTOP).EQ.'CHTOCH') THEN
         ICHFLG=1
      ELSE IF(LINE(ISTART:ISTOP).EQ.'FREE') THEN
         IFREFM=1
         WRITE(IOUT,26)
   26    FORMAT (1X,'THE FREE FORMAT OPTION HAS BEEN SELECTED')
      ELSEIF(LINE(ISTART:ISTOP).EQ.'PRINTTIME') THEN
         IPRTIM=1
         WRITE(IOUT,7)
    7    FORMAT(1X,'THE PRINTTIME OPTION HAS BEEN SELECTED')
      ELSEIF(LINE(ISTART:ISTOP).EQ.'UNSTRUCTURED') THEN
         IUNSTR=1
      ELSEIF(LINE(ISTART:ISTOP).EQ.'PRINTFV') THEN
         IPRCONN=1
      ELSEIF(LINE(ISTART:ISTOP).EQ.'CONVERGE') THEN
         IFRCNVG=1
      ELSEIF(LINE(ISTART:ISTOP).EQ.'RICHARDS') THEN
         IUNSat=1
      END IF
      IF(LLOC.LT.200) GO TO 25
C5C-------SET UNSTRUCTURED FLAG IF DISU IS USED
      INDIS=IUDIS
      IF(IUNIT(IUDIS+1).GT.0) THEN
        IUNSTR=1
        INDIS=IUDIS+1
      ENDIF
C
C5D-----PRINT A MESSAGE SHOWING OPTIONS.
      IF(IXSEC.NE.0) WRITE(IOUT,61)
   61 FORMAT(1X,'CROSS SECTION OPTION IS SPECIFIED')
      IF(ICHFLG.NE.0) WRITE(IOUT,62)
   62 FORMAT(1X,'CALCULATE FLOW BETWEEN ADJACENT CONSTANT-HEAD CELLS')
      IF(IUNSTR.NE.0) WRITE(IOUT,63)
   63 FORMAT(1X,'THE UNSTRUCTURED GRID OPTION HAS BEEN SELECTED')

C----------------------------------------------------------------------------------------
C6------ALLOCATE AND READ DISCRETIZATION DATA FOR ALL PROCESS DOMAINS,
C6------SET GLOBAL PARAMETERS, CONNECTIVITIES AND GEOMETRIC ARRAYS.
C----------------------------------------------------------------------------------------
      CALL SGLO2BAS8ARDIS(INDIS,IOUT,IUCLN,IUGNC,IUGNC2,IUGNCn)
C----------------------------------------------------------------------------------------
C7-----Allocate space for remaining global arrays.
      ALLOCATE (HNEW(NEQS))
      ALLOCATE (HOLD(NEQS))
      ALLOCATE (IFMBC)
      IFMBC = 0
      ALLOCATE (FMBE(NEQS))
      ALLOCATE (Sn(NEQS),So(NEQS))
      Sn = 1.0
      So = 1.0
      ALLOCATE (RHS(NEQS))
      ALLOCATE (BUFF(NEQS))
      ALLOCATE (STRT(NEQS))
      DDREF=>STRT
      ALLOCATE (LAYHDT(NLAY))
      ALLOCATE (LAYHDS(NLAY))
      WRITE(IOUT,'(//)')
C
C8----Initialize head-dependent thickness indicator to code that
C8----indicates layer is undefined.
      DO 100 I=1,NLAY
        LAYHDT(I)=-1
        LAYHDS(I)=-1
  100 CONTINUE
C9------INITIALIZE TOTAL ELAPSED TIME
      TOTIM=0.
C
C------------------------------------------------------------------------
C10------Read rest of groundwater BAS Package file (IBOUND and initial heads)
      IF(IUNSTR.EQ.0)THEN
C10A-------FOR STRUCTURED GRIDS
        CALL SGWF2BAS8SR
      ELSE
C10B-------FOR UNSTRUCTURED GRIDS
        CALL SGWF2BAS8UR
      ENDIF
C
C-----------------------------------------------------------------------
C11-----SET UP OUTPUT CONTROL.
      CALL SGWF2BAS7I(NLAY,IUNIT(IUOC),IOUT,IFREFM,NIUNIT,IUNIT(15),
     1  IUNIT(IUCLN))
C
C12-----INITIALIZE VOLUMETRIC BUDGET ACCUMULATORS TO ZERO.
  590 ZERO=0.
      DO 600 I=1,NIUNIT
      DO 600 J=1,4
      VBVL(J,I)=ZERO
  600 CONTINUE
C
C13-----Allocate and read Zone and Multiplier arrays
      CALL SGWF2BAS7U1ARMZ(IUNIT(IUZON),IUNIT(IUMLT))
C
C14-----READ PARAMETER VALUES FILE.
      CALL SGWF2BAS7U1ARPVAL(IUPVAL)
C15-----return
      RETURN
      END
C--------------------------------------------------------------------------------
      SUBROUTINE SGWF2BAS8OPEN(INUNIT,IOUT,IUNIT,CUNIT,
     1              NIUNIT,VERSION,INBAS,MAXUNIT,MFVNAM)
C     ******************************************************************
C     OPEN FILES.
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      INCLUDE 'openspec.inc'
      DIMENSION IUNIT(NIUNIT)
      CHARACTER*4 CUNIT(NIUNIT)
      CHARACTER*7 FILSTAT
      CHARACTER*20 FILACT, FMTARG, ACCARG
      CHARACTER*(*) VERSION,MFVNAM
      CHARACTER*40 SPACES
      CHARACTER*300 LINE, FNAME
      CHARACTER*20 FILTYP
      LOGICAL LOP
C     ---------------------------------------------------------------
C
C1------INITIALIZE CONSTANTS.
      INBAS=0
      NFILE=0
      IOUT=0
      DO 5 I=1,NIUNIT
      IUNIT(I)=0
5     CONTINUE
      SPACES=' '
      LENVER=LEN_TRIM(VERSION)
      INDENT=40-(LENVER+8)/2
C
C2------READ A LINE; IGNORE BLANK LINES AND PRINT COMMENT LINES.
10    READ(INUNIT,'(A)',END=1000) LINE
      IF(LINE.EQ.' ') GO TO 10
      IF(LINE(1:1).EQ.'#') THEN
        IF(NFILE.NE.0 .AND. IOUT.NE.0) WRITE(IOUT,'(A)') LINE
        GO TO 10
      END IF
C
C3------DECODE THE FILE TYPE, UNIT NUMBER, AND NAME.
      LLOC=1
      CALL URWORD(LINE,LLOC,ITYP1,ITYP2,1,N,R,IOUT,INUNIT)
      FILTYP=LINE(ITYP1:ITYP2)
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IU,R,IOUT,INUNIT)
      CALL URWORD(LINE,LLOC,INAM1,INAM2,0,N,R,IOUT,INUNIT)
      IFLEN=INAM2-INAM1+1
      FNAME(1:IFLEN)=LINE(INAM1:INAM2)
      INQUIRE(UNIT=IU,OPENED=LOP)
      IF(LOP) THEN
         IF(IOUT.EQ.0) THEN
            WRITE(*,11) FNAME(1:IFLEN),IU
   11       FORMAT(1X,/1X,'CANNOT OPEN ',A,' ON UNIT',I4,
     1              ' BECAUSE UNIT IS ALREADY BEING USED')
         ELSE
            WRITE(IOUT,11) FNAME(1:IFLEN),IU
         END IF
         CALL USTOP(' ')
      END IF
C
C4------KEEP TRACK OF LARGEST UNIT NUMBER
      IF (IU.GT.MAXUNIT) MAXUNIT = IU
C
C5------SET DEFAULT FILE ATTRIBUTES.
      FMTARG='FORMATTED'
      ACCARG='SEQUENTIAL'
      FILSTAT='UNKNOWN'
      FILACT=' '
C
C6------SPECIAL CHECK FOR 1ST FILE.
      IF(NFILE.EQ.0) THEN
        IF(FILTYP.EQ.'LIST') THEN
          IOUT=IU
          ! Changed for Texture2Par
          !OPEN(UNIT=IU,FILE=FNAME(1:IFLEN),STATUS='REPLACE',
          OPEN(UNIT=IU,FILE='t2p_modflow.lst',STATUS='REPLACE',
     1          FORM='FORMATTED',ACCESS='SEQUENTIAL')
          WRITE(IOUT,60) MFVNAM,SPACES(1:INDENT),VERSION(1:LENVER)
60        FORMAT(34X,'USG-TRANSPORT ',A,/,
     &             6X,' FURTHER  DEVELOPMENTS BASED ON MODFLOW-USG',/,
     &             A,'VERSION ',A,/)
          WRITE(IOUT,78) FNAME(1:IFLEN),IOUT
78        FORMAT(1X,'LIST FILE: ',A,/25X,'UNIT ',I4)
        ELSE
          WRITE(*,*)
     1       ' FIRST ENTRY IN NAME FILE MUST BE "LIST".'
          CALL USTOP(' ')
        END IF
C7  Get next file name
        NFILE=1
        GO TO 10
      END IF
C
C8------CHECK FOR "BAS" FILE TYPE.
      IF(FILTYP.EQ.'BAS6') THEN
         INBAS=IU
         FILSTAT='OLD    '
         FILACT=ACTION(1)
C
C9------CHECK FOR "UNFORMATTED" FILE TYPE.
      ELSE IF(FILTYP.EQ.'DATA(BINARY)' .OR.
     1        FILTYP.EQ.'DATAGLO(BINARY)') THEN
         FMTARG=FORM
         ACCARG=ACCESS
C
C10-----CHECK FOR "FORMATTED" FILE TYPE.
      ELSE IF(LINE(ITYP1:ITYP2).EQ.'DATA' .OR.
     1        LINE(ITYP1:ITYP2).EQ.'DATAGLO') THEN
         FMTARG='FORMATTED'
         ACCARG='SEQUENTIAL'
C
C11-----CHECK FOR MAJOR OPTIONS.
      ELSE
        DO 20 I=1,NIUNIT
           IF(LINE(ITYP1:ITYP2).EQ.CUNIT(I)) THEN
                IUNIT(I)=IU
              FILSTAT='OLD    '
              FILACT=ACTION(1)
              GO TO 30
           END IF
20      CONTINUE
        ! LS for Texture2Par
        ! Don't care if it's an file type we don't know, just don't open it
        WRITE(IOUT,'(A)') 
        WRITE(IOUT,21) LINE(ITYP1:ITYP2)
21      FORMAT(1X,'Texture2Par - Ignoring File: ',A, '(not needed)')
        GO TO 10
        !CALL USTOP(' ')  
        
30      CONTINUE
      END IF
C
C12-----FOR DATA FILES, CHECK FOR "REPLACE" OR "OLD" OPTION
      IF (FILSTAT.EQ.'UNKNOWN') THEN
        CALL URWORD(LINE,LLOC,IOPT1,IOPT2,1,N,R,IOUT,INUNIT)
        IF (LINE(IOPT1:IOPT2).EQ.'REPLACE' .OR.
     &      LINE(IOPT1:IOPT2).EQ.'OLD')
     &      FILSTAT = LINE(IOPT1:IOPT2)
      ENDIF
      IF (FILACT.EQ.' ') FILACT=ACTION(2)
C
C13-----WRITE THE FILE NAME AND OPEN IT.
      WRITE(IOUT,50) FNAME(1:IFLEN),
     1     LINE(ITYP1:ITYP2),IU,FILSTAT,FMTARG,ACCARG
50    FORMAT(1X,/1X,'OPENING ',A,/
     &  1X,'FILE TYPE:',A,'   UNIT ',I4,3X,'STATUS:',A,/
     &  1X,'FORMAT:',A,3X,'ACCESS:',A)
      OPEN(UNIT=IU,FILE=FNAME(1:IFLEN),FORM=FMTARG,
     1      ACCESS=ACCARG,STATUS=FILSTAT,ACTION=FILACT,ERR=2000)
      NFILE=NFILE+1
      GO TO 10
C
C14-----END OF NAME FILE.  RETURN PROVIDED THAT LISTING FILE AND BAS
C14-----FILES HAVE BEEN OPENED.
1000  IF(NFILE.EQ.0) THEN
         WRITE(*,*) ' NAME FILE IS EMPTY.'
         CALL USTOP(' ')
      ELSE IF(INBAS.EQ.0) THEN
         WRITE(IOUT,*) ' BAS PACKAGE FILE HAS NOT BEEN OPENED.'
         CALL USTOP(' ')
      END IF
      CLOSE (UNIT=INUNIT)
C
      RETURN
C
C15-----ERROR OPENING FILE.
 2000 CONTINUE
      WRITE(*,2010)FNAME(1:IFLEN),IU,FILSTAT,FMTARG,ACCARG,FILACT
      WRITE(IOUT,2010)FNAME(1:IFLEN),IU,FILSTAT,FMTARG,ACCARG,FILACT
 2010 FORMAT(/,1X,'*** ERROR OPENING FILE "',A,'" ON UNIT ',I5,/,
     &7X,'SPECIFIED FILE STATUS: ',A,/
     &7X,'SPECIFIED FILE FORMAT: ',A,/
     &7X,'SPECIFIED FILE ACCESS: ',A,/
     &7X,'SPECIFIED FILE ACTION: ',A,/
     &2X,'-- STOP EXECUTION (SGWF2BAS7OPEN)')
      CALL USTOP(' ')
C
      END
C-----------------------------------------------------------------------
      SUBROUTINE SGLO2BAS8ARDIS(IUDIS,IOUT,IUCLN,IUGNC,IUGNC2,IUGNCn)
C     *****************************************************************
C     ALLOCATE AND READ DISCRETIZATION DATA FOR ALL PROCESS DOMAINS,
C     SET GLOBAL PARAMETERS, CONNECTIVITIES AND GEOMETRIC ARRAYS.
C     *****************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL, ONLY:NPER,NCNFBD,ITMUNI,IXSEC,INGNC,INGNC2,INGNCn,
     1            INCLN,LENUNI,IUNIT,ITRSS,NODES,NODLAY,LAYCBD,INBAS,
     2            PERLEN,NSTP,TSMULT,ISSFLG,BOT,TOP,IUNSTR,AMAT,AREA,
     3            IVC,IA,JA,JAS,ISYM,NJA,NJAG,IVSD,DELC,DELR,IPRCONN,
     4            IBOUND,MXNODLAY,ICONCV,NOCVCO,NEQS,IFREFM,IDSYMRD,
     5            IATMP,NJATMP,IAG,PGF,FAHL,NJAS,NLAY,JAFL,LAYNOD
      USE CLN1MODULE, ONLY: NCLNNDS,IA_CLN
      USE SPARSEMODULE
      TYPE(SPARSEMATRIX) :: SMAT
      INTEGER,ALLOCATABLE,DIMENSION(:) :: ROWMAXNNZ
C
      CHARACTER*200 LINE
      CHARACTER*24 ANAME
      DATA ANAME /'VERT CONNECT INDEX ARRAY'/
C
C     --------------------------------------------------------------------------------
C1----READ GLOBAL PARAMETERS, UNSTRUCTURED GRID DIMENSIONING AND CONFINING INFORMATION
C    ---------------------------------------------------------------------------------
      CALL SDIS2GLO8AR (IUDIS,IOUT)
C----------------------------------------------------------------------------
C2------READ CONNECTED LINE NETWORK (CLN) DIMENSIONING AND CONNECTIVITY INPUT
C----------------------------------------------------------------------------
      NEQS = NODES
      INCLN = IUNIT(IUCLN)
      INBCT = IUNIT(IUBCT)
      IF(INCLN.NE.0) THEN
        CALL SDIS2CLN1AR(IUCLN,INBCT)
        NEQS = NEQS + NCLNNDS
      ENDIF

C---------------------------------------------------------------------
C3-----READ GNC PACKAGE INPUT  (CONNECTIVITIES AND FRACTIONS)
C---------------------------------------------------------------------
      INGNC = IUNIT(IUGNC)
csp      IF(INGNC.GT.0) THEN
csp        CALL GNC2DISU1AR(IUGNC)
csp      ENDIF
      INGNC2 = IUNIT(IUGNC2)
csp      IF(INGNC2.GT.0) THEN
csp        CALL GNCT2DISU1AR(IUGNC2)
csp      ENDIF
      INGNCn = IUNIT(IUGNCn)
      IF(INGNCn.GT.0) THEN
        CALL GNCn2DISU1AR(IUGNCn)
      ENDIF
C--------------------------------------------------------------------------------------
C4-------REIDENTIFY MAIN PACKAGE AFTER READING BASIC INFORMATION FOR ALL PROCESS DOMAINS
C--------------------------------------------------------------------------------------
      INDIS=IUNIT(IUDIS)
      WRITE(IOUT,11) INDIS
   11 FORMAT(1X,/1X,'DIS -- UNSTRUCTURED GRID DISCRETIZATION PACKAGE,',
     1  ' VERSION 1 : 5/17/2010 - INPUT READ FROM UNIT ',I4)
C--------------------------------------------------------------------------------------
C5------ALLOCATE SPACE FOR PARAMETERS AND FLAGS.
      ALLOCATE(IA(NEQS+1))
      ALLOCATE (IBOUND(NEQS))
      ALLOCATE(AREA(NEQS))
      IA = 0
C
C-------------------------------------------------------------------------
C6-------FILL NODLAY ARRAY AND READ GEOMETRIC PARAMETERS
C6-------AND MATRIX CONNECTIVITY FOR THE 3-D SUBSURFACE DOMAIN
      IF(IUNSTR.EQ.0)THEN
C6A-----...FOR STRUCTURED 3-D GRID with MF2005 INPUT STRUCTURE
        CALL SGWF2DIS8SR(IOUT,INDIS)
      ELSE
C6B-----...FOR UNSTRUCTURED 3-D GRID
        CALL SGWF2DIS8UR(IOUT,INDIS)
      ENDIF
C6C----FILL LAYNOD ARRAY WITH LAYER NUMBER FOR EACH NODE
      ALLOCATE(LAYNOD(NODES))
      DO K = 1,NLAY
          NNDLAY = NODLAY(K)
          NSTRT = NODLAY(K-1)+1
          DO N=NSTRT,NNDLAY
            LAYNOD(N) = K
          ENDDO
      ENDDO
C
C---------------------------------------------------------------------------------
C7-------NEED NEW IA JA MATRICES WHEN CONNECTIVITY IS EXPANDED DUE TO CLN OR GNC
C---------------------------------------------------------------------------------
C7A------WHEN CONNECTIVITY IS EXPANDED, THEN SAVE BASIC SUBSURFACE DOMAIN IA IN IAG
C7A------(CONNECTIVITY IS EXPANDED WHEN OTHER PROCESS DOMAINS EXIST OR IF GNC IS USED)
      IF(INCLN.NE.0.OR.INGNC.NE.0.OR.INGNC2.NE.0.OR.INGNCn.NE.0) THEN
        ALLOCATE(IAG(NODES+1))
        DO I=1,NODES+1
          IAG(I) = IA(I)
        ENDDO
C7A1------ALSO ALLOCATE SPACE FOR ORIGINAL JA REQUIRED TO SORT C-B-C OUTPUT
        ALLOCATE (JAFL(NJA+1))
        DO I=1,NJA
          JAFL(I) = JA(I)
        ENDDO
C---------------------------------------------------------------------------------
C7B-------INITIALIZE SPARSEMODULE DATA STRUCTURES FOR CREATING NEW IA AND JA
        ALLOCATE(ROWMAXNNZ(NEQS))
C7B1--------STORE NUMBER OF CONNECTIONS IN ROWMAXNNZ TO INITIALIZE AMAT SIZE
        DO N=1,NODES
          ROWMAXNNZ(N)=IA(N+1)-IA(N)
        ENDDO
C7B2--------ALSO FOR CLN NODES
        IF(INCLN.NE.0) THEN
        DO N=1,NCLNNDS
          IEQ = N + NODES
          ROWMAXNNZ(IEQ)=IA_CLN(N+1)-IA_CLN(N)
        ENDDO
        ENDIF
        CALL SMAT%INIT(NEQS, NEQS, ROWMAXNNZ)
        DEALLOCATE(ROWMAXNNZ)
C7B3--------ADD EXISTING GW IA/JA PATTERN TO SPARSEMODULE DATA STRUCTURE
        DO N=1,NEQS
          DO JJ=IA(N),IA(N+1)-1
              M=JA(JJ)
              CALL SMAT%ADDCONNECTION(N,M,1)
          ENDDO
        ENDDO
C7B4-----DEALLOCATE THE JA ARRAY
        DEALLOCATE(JA)
C--------------------------------------------------------------------
C7C-------IF CLN DOMAIN IS ACTIVE THEN ADD ITS NODES TO THE SPARSEMODULE DATA STRUCTURE
        IF(INCLN.NE.0) THEN
          CALL ADDIAJA_CLN (SMAT)
        ENDIF
C---------------------------------------------------------------------------------
C7D-------IF GNC DOMAIN IS ACTIVE THEN ADD ITS CONNECTIONS TO IA AND JA
csp        IF(INGNC.NE.0) THEN
csp          CALL ADDIAJA_GNC
csp        ENDIF
csp        IF(INGNC2.NE.0) THEN
csp          CALL ADDIAJA_GNCT
csp        ENDIF
        IF(INGNCn.NE.0) THEN
          CALL ADDIAJA_GNCn (SMAT)
        ENDIF
C------------------------------------------------------------------------------------
C7E------ALLOCATE JA AND FILL THE IA AND JA ARRAYS AFTER ALL SPARSEMODULE DATA STRUCTURES ARE FILLED
        NJA=SMAT%NNZ
        ALLOCATE(JA(NJA))
        CALL SMAT%FILLIAJA(IA,JA,IERR)
C
C7F------DESTROY THE SPARSEROW MATRIX
        CALL SMAT%DESTROY
C--------------------------------------------------------------------------------
C7G-------PRINT NEW IA AND JA INFORMATION IF PRINTFV OPTION IS SET
        IF(IPRCONN.NE.0)THEN
          WRITE(IOUT,54)NEQS,NJA
54        FORMAT(1X,'NEQS = ',I10,';  NJA = ',I10,';')
          WRITE(IOUT,*)'IA IS BELOW, 40I10'
          WRITE(IOUT,55)(IA(I),I=1,NEQS+1)
          WRITE(IOUT,*)'JA IS BELOW, 40I10'
          WRITE(IOUT,55)(JA(J),J=1,NJA)
55        FORMAT(40I10)
        ENDIF
      ELSE
        JAFL => JA
      ENDIF
C--------------------------------------------------------------------------
C7H------PREPARE IDXGLO ARRAY FOR CLN DOMAIN
      IF(INCLN.NE.0)THEN
        CALL FILLIDXGLO_CLN
      ENDIF
C--------------------------------------------------------------------------
C7I------PREPARE AND STORE ALPHA_BAR IN COEFFICIENT LOCATION IF ALPHA IS READ.
C7I------ALSO FIND AND STORE LOCATION OF NODE J IN ROWS N AND M.
      IF(INGNCn.NE.0) THEN
        CALL SGNCn2DISU1MC
      ENDIF
C---------------------------------------------------------------------------------
C-------MAKE DIAGONALS OF JA POSITIVE  ***** SHOULD ALREADY BE POSITIVE.
C      DO N=1,NODES
C        IDIAG = IA(N)
C        JA(IDIAG) = IABS (JA(IDIAG))
C      ENDDO
C
C8-------ALLOCATE ISYM AND FILL ISYM AND JAS
      ALLOCATE(ISYM(NJA))
      CALL FILLISYM
C9------ALLOCATE SYMMETRIC AND UNSYMMETRIC GLOBAL ARRAYS
      ALLOCATE(PGF(NJAS),FAHL(NJAS))
      PGF=0.0
      FAHL=0.0
      ALLOCATE(IVC(NJAS))
      IVC = 0
      ALLOCATE (AMAT(NJA))
      AMAT = 0.0
      IF(NJA.EQ.NJAG)THEN
        IATMP => IA
        NJATMP=> NJA
      ELSE
        IATMP => IAG
        NJATMP=> NJAG
      ENDIF
C------------------------------------------------------------------------
C10-----FILL VERTICAL CONNECTION ARRAY IVC.
      IF(IVSD.LE.0)THEN
C10A------compute IVC for IVSD. LE. 0
        DO K=1,NLAY
          NNDLAY = NODLAY(K)
          NSTRT = NODLAY(K-1)+1
          DO N=NSTRT,NNDLAY
C10A1-----LOOP OVER CONNECTIONS OF NODE N AND FILL
          DO II = IA(N)+1,IA(N+1)-1
            JJ = JA(II)
            IIS = JAS(II)
            IF(JJ.LE.N.OR.JJ.GT.NODES) CYCLE
            IF(JJ.GT.NNDLAY)THEN
              IVC(IIS) = 1  ! LAYER IS BELOW
            ELSE
              IVC(IIS) = 0
            ENDIF
          ENDDO
          ENDDO
        ENDDO
      ELSE
C10B----read IVC, for IVSD. GT. 0.
        CALL U1DINTNJA(IVC,IATMP,ANAME,NJATMP,INDIS,IOUT,IDSYMRD)
      ENDIF
C
C--------------------------------------------------------------------------
C11------FILL PROPERTIES OF CONNECTIONS IN RESPECTIVE ARRAYS
C--------------------------------------------------------------------------
      IF(IUNSTR.EQ.0)THEN
C11A---FILL GEOMETRIC FACTOR AND PL, CL1, CL2 ARRAYS FOR STRUCTURED GRID
        CALL FILLGFS(IOUT)
      ELSE
C11B---READ PL, CL1, CL2 ARRAYS AND FILL GEOMETRIC FACTOR FOR UNSTRUCTURED GRID
        CALL FILLGFU(INDIS,IOUT)
      ENDIF
C
C------------------------------------------------------------------------
C12-----READ AND WRITE LENGTH OF STRESS PERIOD, NUMBER OF TIME STEPS,
C12-----TIME STEP MULTIPLIER, AND STEADY-STATE FLAG..
      WRITE(IOUT,161)
  161 FORMAT(1X,//1X,'STRESS PERIOD     LENGTH       TIME STEPS',
     1            '     MULTIPLIER FOR DELT    SS FLAG',/1X,76('-'))
      ISS=0
      ITR=0
      DO 200 N=1,NPER
      READ(INDIS,'(A)') LINE
      LLOC=1
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,3,I,PERLEN(N),IOUT,INDIS)
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NSTP(N),R,IOUT,INDIS)
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,3,I,TSMULT(N),IOUT,INDIS)
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,I,R,IOUT,INDIS)
      IF (LINE(ISTART:ISTOP).EQ.'TR') THEN
         ISSFLG(N)=0
         ITR=1
      ELSE IF (LINE(ISTART:ISTOP).EQ.'SS') THEN
         ISSFLG(N)=1
         ISS=1
      ELSE
         WRITE(IOUT,162)
  162    FORMAT(' SSFLAG MUST BE EITHER "SS" OR "TR"',
     1      ' -- STOP EXECUTION (SGWF2BAS7U1ARDIS)')
         CALL USTOP(' ')
      END IF
      WRITE (IOUT,163) N,PERLEN(N),NSTP(N),TSMULT(N),LINE(ISTART:ISTOP)
  163 FORMAT(1X,I8,1PG21.7,I7,0PF25.3,A11)
C
C13-----STOP IF NSTP LE 0, PERLEN EQ 0 FOR TRANSIENT STRESS PERIODS,
C13-----TSMULT LE 0, OR PERLEN LT 0..
      IF(NSTP(N).LE.0) THEN
         WRITE(IOUT,164)
  164    FORMAT(1X,/1X,
     1  'THERE MUST BE AT LEAST ONE TIME STEP IN EVERY STRESS PERIOD')
         CALL USTOP(' ')
      END IF
      ZERO=0.
      IF(PERLEN(N).EQ.ZERO .AND. ISSFLG(N).EQ.0) THEN
         WRITE(IOUT,165)
  165    FORMAT(1X,/1X,
     1  'PERLEN MUST NOT BE 0.0 FOR TRANSIENT STRESS PERIODS')
         CALL USTOP(' ')
      END IF
      IF(TSMULT(N).LE.ZERO) THEN
         WRITE(IOUT,170)
  170    FORMAT(1X,/1X,'TSMULT MUST BE GREATER THAN 0.0')
         CALL USTOP(' ')
      END IF
      IF(PERLEN(N).LT.ZERO) THEN
         WRITE(IOUT,175)
  175    FORMAT(1X,/1X,
     1  'PERLEN CANNOT BE LESS THAN 0.0 FOR ANY STRESS PERIOD')
         CALL USTOP(' ')
      END IF
  200 CONTINUE
C
C14-----Assign ITRSS.
      IF(ISS.EQ.0 .AND. ITR.NE.0) THEN
         ITRSS=1
         WRITE(IOUT,270)
  270    FORMAT(/,1X,'TRANSIENT SIMULATION')
      ELSE IF(ISS.NE.0 .AND. ITR.EQ.0) THEN
         ITRSS=0
         WRITE(IOUT,275)
  275    FORMAT(/,1X,'STEADY-STATE SIMULATION')
      ELSE
         ITRSS=-1
         WRITE(IOUT,280)
  280    FORMAT(/,1X,'COMBINED STEADY-STATE AND TRANSIENT SIMULATION')
      END IF
C
C15-----RETURN.
      RETURN
      END
C---------------------------------------------------------------------
      SUBROUTINE FILLISYM
C     ******************************************************************
C     FIND SYMMETRIC LOCATION OF CONNECTIVITY MATRIX AND FILL ISYM.
C     ALSO FILL  JAS SYMMETRIC STORAGE POINTER ARRAY
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL, ONLY:  NODES,IA,JA,NJA,ISYM,NEQS,JAS,NJAS,IOUT
      LOGICAL :: FOUND
C
C1------FILL SYMMETRIC LOCATION INDEX ARRAY ISYM
      NASYM=0
      DO I=1,NEQS
          if(i.eq.10026.OR.I.EQ.10025)then
              yo=1
          endif
        DO II=IA(I),IA(I+1)-1
          J = JA(II)
          IF(J.NE.I)THEN !FIND LOCATION OF I IN ROW J
            FOUND = .FALSE.
            DO JJ=IA(J),IA(J+1)-1
              IF(JA(JJ).EQ.I)THEN !FOUND LOCATION
                ILOC = JJ
                ISYM(II) = ILOC
                FOUND = .TRUE.
                EXIT
              ENDIF
            ENDDO
            IF(.NOT. FOUND) THEN
              WRITE (IOUT,'(A,I0,A,I0,A)') 'NODE ',I,' CONNECTED TO ',J,
     *          ' BUT NO SYMMETRIC CONNECTION'
              NASYM = NASYM + 1
            ENDIF
          ENDIF
        ENDDO
      ENDDO
      IF(NASYM.GT.0) THEN
        WRITE(IOUT,'(A,A,I0,A)') 'ERROR. JA IS NOT SYMMETRIC.',
     1     ' FOUND ',NASYM,' ASYMMETRIC CONNECTIONS.'
        CALL USTOP ('')
      ENDIF
C2------ALLOCATE SYMMETRIC INDEX POINTER ARRAY JAS
      ALLOCATE(NJAS)
      NJAS = (NJA-NEQS) / 2
      ALLOCATE(JAS(NJA))
C3------FILL JAS WITH LOCATION VARIABLE IN SYMMETRIC ARRAY
      JAS = 0
C3A-----FIRST FILL UPPER TRIANGLE LOCATION IN JAS
      ILOC = 1
      DO N=1,NEQS
        DO II=IA(N)+1,IA(N+1)-1
          J = JA(II)
          IF(J.GT.N)THEN
            JAS(II) = ILOC
            ILOC = ILOC + 1
          ENDIF
        ENDDO
      ENDDO
C3B-------NEXT FILL LOWER TRIANGLE LOCATION AS REFLECTION
      DO N=1,NEQS
        DO II=IA(N),IA(N+1)-1
          J = JA(II)
          IF(J.LT.N)THEN
            JAS(II) = JAS(ISYM(II))
          ENDIF
        ENDDO
      ENDDO
C
C4-------RETURN.
      RETURN
      END
C----------------------------------------------------------------------
      SUBROUTINE SGWF2BAS7I(NLAY,INOC,IOUT,IFREFM,NIUNIT,ITRUNIT,ICUNIT)
C     ******************************************************************
C     SET UP OUTPUT CONTROL.
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL, ONLY: ITRNSP,NSTP,ISSFLG,NPER,INCLN
      USE GWFBASMODULE, ONLY: IHEDFM,IDDNFM,IHEDUN,IDDNUN,IPEROC,ITSOC,
     1    CHEDFM,CDDNFM,IBDOPT,LBHDSV,LBDDSV,IBOUUN,LBBOSV,CBOUFM,
     3    IAUXSV,IOFLG,VBVL,VBNM,ISPCFM,ISPCUN,CSPCFM,IATS,NPTIMES,
     4    NPSTPS,DELTAT,TMINAT,TMAXAT,TADJAT,TCUTAT,IBUDFLAT,ICBCFLAT,
     5    IHDDFLAT,IDDREF,IDDREFNEW,ISPCFLAT,
     6    IFAST,ISPFAST,ITSFAST,IUGFAST,IUCFAST
      USE CLN1MODULE, ONLY: ICLNHD, ICLNDD, ICLNIB
      CHARACTER*200 LINE
C     ------------------------------------------------------------------
C
C1-----ALLOCATE SPACE FOR IOFLG, VBVL, AND VBNM ARRAYS.
      ALLOCATE (IOFLG(NLAY,7))
      ALLOCATE (VBVL(4,NIUNIT))
      ALLOCATE (VBNM(NIUNIT))
      IDDREF=0
      IDDREFNEW=0
C
C1A------ASSIGN DEFAULT VALUES.
      CHEDFM=' '
      CDDNFM=' '
      CSPCFM=' '
      CBOUFM='(20I4)'
      IHEDFM=0
      IDDNFM=0
      ISPCFM=0
      IHEDUN=0
      IDDNUN=0
      ISPCUN=0
      IBOUUN=0
      IBDOPT=1
      LBHDSV=0
      LBDDSV=0
      LBBOSV=0
      IAUXSV=0
C
C2------TEST OUTPUT CONTROL INPUT UNIT TO SEE IF OUTPUT CONTROL IS
C2------ACTIVE.
      IF(INOC.LE.0) THEN
C
C2A-----OUTPUT CONTROL IS INACTIVE. PRINT A MESSAGE LISTING DEFAULTS.
         WRITE(IOUT, 41)
   41    FORMAT(1X,/1X,'DEFAULT OUTPUT CONTROL',/1X,
     1   'THE FOLLOWING OUTPUT COMES AT THE END OF EACH STRESS PERIOD:')
         WRITE(IOUT, 42)
   42    FORMAT(1X,'TOTAL VOLUMETRIC BUDGET')
         WRITE(IOUT, 43)
   43    FORMAT(1X,10X,'HEAD')
C
C2B-----SET DEFAULT FLAGS IN IOFLG SO THAT HEAD IS PRINTED FOR
C2B-----EVERY LAYER.
         DO 80 K=1,NLAY
         IOFLG(K,1)=1
         IOFLG(K,2)=0
         IOFLG(K,3)=0
         IOFLG(K,4)=0
         IOFLG(K,5)=0
         IOFLG(K,6)=0
         IOFLG(K,7)=0
   80    CONTINUE
         GO TO 1000
      END IF
C
C3------OUTPUT CONTROL IS ACTIVE.  READ FIRST RECORD AND DECODE FIRST
C3------WORD.  MUST USE URWORD IN CASE FIRST WORD IS ALPHABETIC.
      CALL URDCOM(INOC,IOUT,LINE)
C--------------------------------------------------------------------------------
C3A------CHECK FOR OPTIONS
      ALLOCATE(IATS,NPTIMES,NPSTPS,IBUDFLAT,ICBCFLAT,IHDDFLAT,ISPCFLAT)
      ALLOCATE(DELTAT,TMINAT,TMAXAT,TADJAT,TCUTAT)
      ALLOCATE(IFAST,ISPFAST,ITSFAST,IUGFAST,IUCFAST)
      IATS=0
      NPTIMES=0
      NPSTPS=0
      IFAST=0
      ISPFAST=0
      ITSFAST=0
      IUGFAST=0
      IUCFAST=0
      LLOC = 1
   10 CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,IN)
      IF(LINE(ISTART:ISTOP).EQ.'ATS'.OR.
     1   LINE(ISTART:ISTOP).EQ.'ATSA') THEN
C3B------READ KEYWORD OPTION ATS FOR ADAPTIVE TIME STEPPING.
         IATS = 1
      ELSEIF(LINE(ISTART:ISTOP).EQ.'NPTIMES') THEN
C3C------IS KEWORD OPTION FOR NUMBER OF PRINT TIMES
        CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NPTIMES,R,IOUT,INOC)
      ELSEIF(LINE(ISTART:ISTOP).EQ.'NPSTPS') THEN
C3C------IS KEWORD OPTION FOR NUMBER OF PRINT TIMES
        CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NPSTPS,R,IOUT,INOC)
        WRITE(IOUT,14) NPSTPS
14      FORMAT(/1X,'OUTPUT PROVIDED EVERY', I8,' TIME STEPS (NPSTPS)')
      ELSEIF(LINE(ISTART:ISTOP).EQ.'FASTFORWARD') THEN
        IFAST = 1
C3C------IS KEWORD OPTION FOR BOOTSTRAPPING THE NEW ESTIMATE FOR HEAD AT FIRST ITERATION FROM SEPARATE FILE
        CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,ISPFAST,R,IOUT,INOC)
        CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,ITSFAST,R,IOUT,INOC)
        CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IUGFAST,R,IOUT,INOC)
        WRITE(IOUT,15) ISPFAST,ITSFAST,IUGFAST
15      FORMAT(/1X,'FASTFORWARDING TO STRESS PERIOD,',I10,
     1    'AND TIME-STEP',I10
     1     /10X,'READING FASTFORWARD GWF HEADS FROM UNIT',I5)
        IF(INCLN.GT.0)THEN
          CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IUCFAST,R,IOUT,INOC)
          WRITE(IOUT,16) IUCFAST
16        FORMAT(10X,'READING FASTFORWARD CLN HEADS FROM UNIT',I5)
        ENDIF
      END IF
      IF(LLOC.LT.200) GO TO 10
C-------SET DEFAULTS FOR ADAPTIVE TIME STEPPING
      IF(NPSTPS.GT.0.OR.NPTIMES.GT.0) IATS=1
      IF(NPSTPS.EQ.0) NPSTPS=100000000
      IF(IATS.EQ.1)THEN
        WRITE(IOUT,13)
   13   FORMAT(/1X,'ADAPTIVE TIME STEPPING PERFORMED. ATS',
     1      ' VARIABLES WILL BE READ.'/1X,61('-'))
        DO K=1,NPER
          IF(ISSFLG(K).EQ.1.AND.ITRUNIT.EQ.0) THEN
            NSTP(K) = 1
          ELSE
            NSTP(K) = 1000000
          ENDIF
        ENDDO
        DELTAT = 1.0
        TMINAT = 1.0E-10
        TMAXAT = 1.0E10
        TADJAT = 2.0
        TCUTAT = 5.0
      ENDIF
C------------------------------------------------------------------------------
      LLOC=1
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
C
C4------TEST FOR NUMERIC OUTPUT CONTROL.  FIRST WORD WILL NOT BE
C4------"PERIOD", "HEAD", "DRAWDOWN", OR "COMPACT" OR CONC OR CONCENTRATION.
      IF(LINE(ISTART:ISTOP).NE.'PERIOD' .AND. LINE(ISTART:ISTOP).NE.
     1     'HEAD' .AND. LINE(ISTART:ISTOP).NE.'DRAWDOWN' .AND.
     2     LINE(ISTART:ISTOP).NE.'COMPACT' .AND.
     3     LINE(ISTART:ISTOP).NE.'IBOUND'.AND.
     3     LINE(ISTART:ISTOP).NE.'CONC'.AND.
     3     LINE(ISTART:ISTOP).NE.'CONCENTRATION'.AND.
     4     LINE(ISTART:ISTOP).NE.'ATSA') THEN
C4A-----NUMERIC OUTPUT CONTROL.  DECODE THE INITIAL RECORD ACCORDINGLY.
         WRITE(IOUT,102)
  102    FORMAT(1X,/1X,'OUTPUT CONTROL IS SPECIFIED EVERY TIME STEP')
         IF(ITRUNIT.EQ.0)THEN
           IF(IFREFM.EQ.0) THEN
              READ(LINE,'(4I10)') IHEDFM,IDDNFM,IHEDUN,IDDNUN
           ELSE
              LLOC=1
              CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IHEDFM,R,IOUT,INOC)
              CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IDDNFM,R,IOUT,INOC)
              CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IHEDUN,R,IOUT,INOC)
              CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IDDNUN,R,IOUT,INOC)
           END IF
           WRITE(IOUT,103) IHEDFM,IDDNFM
  103     FORMAT(1X,'HEAD PRINT FORMAT CODE IS',I4,
     1       '    DRAWDOWN PRINT FORMAT CODE IS',I4)
           WRITE(IOUT,104) IHEDUN,IDDNUN
  104      FORMAT(1X,'HEADS WILL BE SAVED ON UNIT ',I4,
     1       '    DRAWDOWNS WILL BE SAVED ON UNIT ',I4)
         ELSE
           IF(IFREFM.EQ.0) THEN
            READ(LINE,'(6I10)')IHEDFM,IDDNFM,IHEDUN,IDDNUN,ISPCFM,ISPCUN
           ELSE
              LLOC=1
              CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IHEDFM,R,IOUT,INOC)
              CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IDDNFM,R,IOUT,INOC)
              CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IHEDUN,R,IOUT,INOC)
              CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IDDNUN,R,IOUT,INOC)
              CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,ISPCFM,R,IOUT,INOC)
              CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,ISPCUN,R,IOUT,INOC)
           END IF
           WRITE(IOUT,113) IHEDFM,IDDNFM,ISPCFM
  113     FORMAT(1X,'HEAD PRINT FORMAT CODE IS',I4,
     1       '    DRAWDOWN PRINT FORMAT CODE IS',I4,
     1       '        CONC PRINT FORMAT CODE IS',I4)
           WRITE(IOUT,114) IHEDUN,IDDNUN,ISPCUN
  114      FORMAT(1X,'HEADS WILL BE SAVED ON UNIT ',I4,
     1       '    DRAWDOWNS WILL BE SAVED ON UNIT ',I4,
     1       '         CONC WILL BE SAVED ON UNIT ',I4)
         ENDIF
         IPEROC=-1
         ITSOC=-1
C4B---READ OUTPUT TIME SERIES VECTOR
         IF(NPTIMES.GT.0) CALL PTIMES1RP(INOC,IOUT)
      ELSE
C----------------------------------------------------------------------------------------
C4C---FOR ALPHABETIC OC, READ OUTPUT TIME SERIES VECTOR FIRST
         IF(NPTIMES.GT.0) CALL PTIMES1RP(INOC,IOUT)
C4D-----ALPHABETIC OUTPUT CONTROL.  CALL MODULE TO READ INITIAL RECORDS.
         CALL SGWF2BAS7J(INOC,IOUT,LINE,LLOC,ISTART,ISTOP)
      ENDIF
      IF(ICUNIT.GT.0) THEN
      IF(ICLNHD.LT.0) ICLNHD = IHEDUN
      IF(ICLNDD.LT.0) ICLNDD = IDDNUN
      IF(ICLNIB.LT.0) ICLNIB = IBOUUN
      ENDIF
C
C5------RETURN.
 1000 RETURN
      END
      SUBROUTINE PTIMES1RP(INOC,IOUT)
C     ******************************************************************
C     READ PRINT TIME ARRAY.
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL, ONLY: NSTP
      USE GWFBASMODULE, ONLY: TIMOT,ITIMOT,DELTAT,TMINAT,TMAXAT,TADJAT,
     1    TCUTAT,NPTIMES,NPSTPS
C
      CHARACTER*200 LINE
C     ------------------------------------------------------------------
C
C1------READ PRINT TIME ARRAY
      ALLOCATE(TIMOT(NPTIMES+1))
      ALLOCATE(ITIMOT)
      ITIMOT=1
C
      WRITE(IOUT,11)NPTIMES
11    FORMAT(/10X,  'OUTPUT WILL BE PRINTED AT FOLLOWING',I8,' TIMES'/
     1        10X,  50('-'))
C
      READ(INOC,*) (TIMOT(IT),IT=1,NPTIMES)
      WRITE(IOUT,'(10(1PG15.7))') (TIMOT(IT),IT=1,NPTIMES)
      TIMOT(NPTIMES+1) = 1.0E20
C2------PERFORM CONSISTENCY CHECKS
      DO IT=1,NPTIMES-1
        IF(TIMOT(IT+1)-TIMOT(IT).LE.TMINAT) THEN
          WRITE(IOUT,12)
12        FORMAT( 'PRINT TIMES ARE NOT SEQUENTIALLY INCREASING',
     1    ' OR ARE LESS THAN TMINAT APART')
        ENDIF
      ENDDO
C
C2------RETURN.
 1000 RETURN
      END
      SUBROUTINE SGWF2BAS7J(INOC,IOUT,LINE,LLOC,ISTART,ISTOP)
C     ******************************************************************
C     READ INITIAL ALPHABETIC OUTPUT CONTROL RECORDS.
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL, ONLY: ITRNSP
      USE GWFBASMODULE, ONLY: IHEDFM,IDDNFM,IHEDUN,IDDNUN,IPEROC,ITSOC,
     1                CHEDFM,CDDNFM,IBDOPT,LBHDSV,LBDDSV,IATS,IDDREFNEW,
     2                IBOUUN,LBBOSV,CBOUFM,IAUXSV,ISPCFM,ISPCUN,CSPCFM
C
      CHARACTER*200 LINE
C     ------------------------------------------------------------------
C
C1------ALPHABETIC OUTPUT CONTROL.  WRITE MESSAGE AND SET INITIAL VALUES
C1------FOR IPEROC AND ITSOC.
      WRITE(IOUT,91)
   91 FORMAT(1X,/1X,'OUTPUT CONTROL IS SPECIFIED ONLY AT TIME STEPS',
     1    ' FOR WHICH OUTPUT IS DESIRED')
      IPEROC=9999
      ITSOC=9999
C
C2------LOOK FOR ALPHABETIC WORDS:
C2A-----LOOK FOR "PERIOD", WHICH INDICATES THE END OF INITIAL OUTPUT
C2A-----CONTROL DATA.  IF FOUND, DECODE THE PERIOD NUMBER AND TIME
C2A-----STEP NUMBER FOR LATER USE.
  100 IF(LINE(ISTART:ISTOP).EQ.'PERIOD') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IPEROC,R,IOUT,INOC)
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
C2Ai-------SKIP TIME STEP IF ADAPTIVE TIME STEPPING
         IF(IATS.NE.0) GO TO 20
         IF(LINE(ISTART:ISTOP).NE.'STEP') GO TO 2000
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,ITSOC,R,IOUT,INOC)
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
20       CONTINUE
         IF(ITRNSP.EQ.0)THEN
           WRITE(IOUT,101) IHEDFM,IDDNFM
  101      FORMAT(1X,'HEAD PRINT FORMAT CODE IS',I4,
     1          '    DRAWDOWN PRINT FORMAT CODE IS',I4)
           WRITE(IOUT,102) IHEDUN,IDDNUN
  102      FORMAT(1X,'HEADS WILL BE SAVED ON UNIT ',I4,
     1          '    DRAWDOWNS WILL BE SAVED ON UNIT ',I4)
         ELSE
           WRITE(IOUT,113) IHEDFM,IDDNFM,ISPCFM
  113      FORMAT(1X,'HEAD PRINT FORMAT CODE IS',I4,
     1          '    DRAWDOWN PRINT FORMAT CODE IS',I4,
     2          '        CONC PRINT FORMAT CODE IS',I4)
           WRITE(IOUT,122) IHEDUN,IDDNUN,ISPCUN
  122      FORMAT(1X,'HEADS WILL BE SAVED ON UNIT ',I4,
     1          '    DRAWDOWNS WILL BE SAVED ON UNIT ',I4,
     2          '        CONCS WILL BE SAVED ON UNIT ',I4)
         ENDIF
C2Aii------READ DDREFERENCE FLAG
         IF(LINE(ISTART:ISTOP).EQ.'DDREFERENCE') THEN
           IDDREFNEW=1
         ELSE
           IDDREFNEW=0
         END IF
C
         GO TO 1000
C
C2B-----LOOK FOR "HEAD PRINT ..." AND "HEAD SAVE ...".  IF
C2B-----FOUND, SET APPROPRIATE FLAGS.
      ELSE IF(LINE(ISTART:ISTOP).EQ.'HEAD') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
         IF(LINE(ISTART:ISTOP).EQ.'PRINT') THEN
            CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
            IF(LINE(ISTART:ISTOP).NE.'FORMAT') GO TO 2000
            CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IHEDFM,R,IOUT,INOC)
         ELSE IF(LINE(ISTART:ISTOP).EQ.'SAVE') THEN
            CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
            IF(LINE(ISTART:ISTOP).EQ.'UNIT') THEN
               CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IHEDUN,R,IOUT,
     1            INOC)
            ELSE IF(LINE(ISTART:ISTOP).EQ.'FORMAT') THEN
               CALL URWORD(LINE,LLOC,ISTART,ISTOP,0,N,R,IOUT,INOC)
               CHEDFM=LINE(ISTART:ISTOP)
               WRITE(IOUT,103) CHEDFM
  103          FORMAT(1X,'HEADS WILL BE SAVED WITH FORMAT: ',A)
               CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
               IF(LINE(ISTART:ISTOP).EQ.'LABEL') THEN
                  LBHDSV=1
                  WRITE(IOUT,104)
  104             FORMAT(1X,'SAVED HEADS WILL BE LABELED')
               END IF
            ELSE
               GO TO 2000
            END IF
         ELSE
            GO TO 2000
         END IF
C
C2C-----LOOK FOR "DRAWDOWN PRINT ..." AND "DRAWDOWN SAVE ...".
C2C-----IF FOUND, SET APPROPRIATE FLAGS
      ELSE IF(LINE(ISTART:ISTOP).EQ.'DRAWDOWN') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
         IF(LINE(ISTART:ISTOP).EQ.'PRINT') THEN
            CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
            IF(LINE(ISTART:ISTOP).NE.'FORMAT') GO TO 2000
            CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IDDNFM,R,IOUT,INOC)
         ELSE IF(LINE(ISTART:ISTOP).EQ.'SAVE') THEN
            CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
            IF(LINE(ISTART:ISTOP).EQ.'UNIT') THEN
               CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IDDNUN,R,IOUT,
     1                   INOC)
            ELSE IF(LINE(ISTART:ISTOP).EQ.'FORMAT') THEN
               CALL URWORD(LINE,LLOC,ISTART,ISTOP,0,N,R,IOUT,INOC)
               CDDNFM=LINE(ISTART:ISTOP)
               WRITE(IOUT,105) CDDNFM
  105          FORMAT(1X,'DRAWDOWN WILL BE SAVED WITH FORMAT: ',A)
               CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
               IF(LINE(ISTART:ISTOP).EQ.'LABEL') THEN
                  LBDDSV=1
                  WRITE(IOUT,106)
  106             FORMAT(1X,'SAVED DRAWDOWN WILL BE LABELED')
               END IF
            ELSE
               GO TO 2000
            END IF
         ELSE
            GO TO 2000
         END IF
C
C2B-----LOOK FOR "CONC PRINT ..." AND "CONC SAVE ...".  IF
C2B-----FOUND, SET APPROPRIATE FLAGS.
      ELSE IF(LINE(ISTART:ISTOP).EQ.'CONC'.OR.LINE(ISTART:ISTOP)
     1   .EQ.'CONCENTRATION') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
         IF(LINE(ISTART:ISTOP).EQ.'PRINT') THEN
            CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
            IF(LINE(ISTART:ISTOP).NE.'FORMAT') GO TO 2000
            CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,ISPCFM,R,IOUT,INOC)
         ELSE IF(LINE(ISTART:ISTOP).EQ.'SAVE') THEN
            CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
            IF(LINE(ISTART:ISTOP).EQ.'UNIT') THEN
               CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,ISPCUN,R,IOUT,
     1            INOC)
            ELSE IF(LINE(ISTART:ISTOP).EQ.'FORMAT') THEN
               CALL URWORD(LINE,LLOC,ISTART,ISTOP,0,N,R,IOUT,INOC)
               CSPCFM=LINE(ISTART:ISTOP)
               WRITE(IOUT,115) CSPCFM
  115          FORMAT(1X,'CONCS WILL BE SAVED WITH FORMAT: ',A)
               CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
               IF(LINE(ISTART:ISTOP).EQ.'LABEL') THEN
                  LBHDSV=1
                  WRITE(IOUT,116)
  116             FORMAT(1X,'SAVED CONCS WILL BE LABELED')
               END IF
            ELSE
               GO TO 2000
            END IF
         ELSE
            GO TO 2000
         END IF
C
C2D-----LOOK FOR "COMPACT BUDGET FILES" -- "COMPACT" IS SUFFICIENT.
C2D-----IF FOUND, SET APPROPRIATE FLAG.
      ELSE IF(LINE(ISTART:ISTOP).EQ.'COMPACT') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
         IF(LINE(ISTART:ISTOP).EQ.'BUDGET') THEN
            IBDOPT=2
            WRITE(IOUT,107)
  107       FORMAT(1X,
     1      'COMPACT CELL-BY-CELL BUDGET FILES WILL BE WRITTEN')
            CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
            IF(LINE(ISTART:ISTOP).EQ.'AUXILIARY' .OR.
     1         LINE(ISTART:ISTOP).EQ.'AUX') THEN
               IAUXSV=1
               WRITE(IOUT,108)
  108          FORMAT(1X,
     1     'AUXILIARY DATA WILL BE SAVED IN CELL-BY-CELL BUDGET FILES')
            END IF
         ELSE
            GO TO 2000
         END IF
C
C2E-----LOOK FOR  "IBOUND SAVE ...".  IF FOUND, SET APPROPRIATE FLAGS.
      ELSE IF(LINE(ISTART:ISTOP).EQ.'IBOUND') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
         IF(LINE(ISTART:ISTOP).EQ.'SAVE') THEN
            CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
            IF(LINE(ISTART:ISTOP).EQ.'UNIT') THEN
               CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IBOUUN,R,IOUT,
     1            INOC)
               WRITE(IOUT,111) IBOUUN
  111          FORMAT(1X,'IBOUND WILL BE SAVED ON UNIT ',I4)
            ELSE IF(LINE(ISTART:ISTOP).EQ.'FORMAT') THEN
               CALL URWORD(LINE,LLOC,ISTART,ISTOP,0,N,R,IOUT,INOC)
               CBOUFM=LINE(ISTART:ISTOP)
               WRITE(IOUT,112) CBOUFM
  112          FORMAT(1X,'IBOUND WILL BE SAVED WITH FORMAT: ',A)
               CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
               IF(LINE(ISTART:ISTOP).EQ.'LABEL') THEN
                  LBBOSV=1
                  WRITE(IOUT,109)
  109             FORMAT(1X,'SAVED IBOUND WILL BE LABELED')
               END IF
            ELSE
               GO TO 2000
            END IF
         ELSE
            GO TO 2000
         END IF
C2F-------FOR ADAPTIVE TIME STEPPING WITH ALPHABTIC INPUT READ NEXT RECORD
      ELSE IF(LINE(ISTART:ISTOP).EQ.'ATSA') THEN
            GO TO 110
C
C2F-----ERROR IF UNRECOGNIZED WORD.
      ELSE
         GO TO 2000
      END IF
C
C3------FINISHED READING A RECORD.  READ NEXT RECORD, IGNORING BLANK
C3------LINES.  GO BACK AND DECODE IT.
  110 READ(INOC,'(A)',END=1000) LINE
      IF(LINE.EQ.' ') GO TO 110
      LLOC=1
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
      GO TO 100
C
C4------RETURN.
 1000 RETURN
C
C5------ERROR DECODING INPUT DATA.
 2000 WRITE(IOUT,2001) LINE
 2001 FORMAT(1X,/1X,'ERROR READING OUTPUT CONTROL INPUT DATA:'/1X,A80)
      CALL USTOP(' ')
      END
      SUBROUTINE SGWF2BAS7U1ARMZ(INZONE,INMULT)
C     ******************************************************************
C     ALLOCATE AND READ MULTIPLIER AND ZONE ARRAYS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,     ONLY:NCOL,NROW,IOUT,MXNODLAY,IUNSTR
      USE PARAMMODULE,ONLY:NZONAR,NMLTAR,ZONNAM,MLTNAM,IZON,RMLT
C
      CHARACTER*20 RW
      CHARACTER*1 COP
      CHARACTER*24 ANAME
      CHARACTER*10 CTMP1,CTMP2
      CHARACTER*200 LINE
C     ------------------------------------------------------------------
C------SET NROW AND NCOL APPROPRIATELY FOR UNSTRUCTURED GRID
       IF(IUNSTR.NE.0)THEN
         NCOL = MXNODLAY
         NROW = 1
       ENDIF
C
C1------Read Number of Zone Arrays if Zone Option is active.
      NZONAR=0
      IF(INZONE.GT.0) THEN
         WRITE(IOUT,1) INZONE
    1    FORMAT(1X,/1X,'ZONE OPTION, INPUT READ FROM UNIT ',I4)
         CALL URDCOM(INZONE,IOUT,LINE)
         LLOC=1
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NZONAR,R,IOUT,INZONE)
         WRITE(IOUT,2) NZONAR
    2    FORMAT(1X,I5,' ZONE ARRAYS')
         IF(NZONAR.LT.0) NZONAR=0
      END IF
C
C2------Allocate memory for zone arrays.  Allocate one array element if
C2------there are no zone arrays.
      IF(NZONAR.GT.0) THEN
        ALLOCATE (ZONNAM(NZONAR))
        ALLOCATE (IZON(NCOL,NROW,NZONAR))
      ELSE
        ALLOCATE (ZONNAM(1))
        ALLOCATE (IZON(1,1,1))
      ENDIF
C
C3------Read Number of Multiplier Arrays if Multiplier Option is active.
      NMLTAR=0
      IF(INMULT.GT.0) THEN
         WRITE(IOUT,11) INMULT
   11    FORMAT(1X,/1X,'MULTIPLIER OPTION, INPUT READ FROM UNIT ',I4)
         CALL URDCOM(INMULT,IOUT,LINE)
         LLOC=1
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NMLTAR,R,IOUT,INMULT)
         WRITE(IOUT,12) NMLTAR
   12    FORMAT(1X,I3,' MULTIPLIER ARRAYS')
         IF(NMLTAR.LT.0) NMLTAR=0
      END IF
C
C4------Allocate memory for multiplier arrays.  Allocate one array element if
C4------there are no multiplier arrays.
      IF(NMLTAR.GT.0) THEN
        ALLOCATE (MLTNAM(NMLTAR))
        ALLOCATE (RMLT(NCOL,NROW,NMLTAR))
      ELSE
        ALLOCATE (MLTNAM(1))
        ALLOCATE (RMLT(1,1,1))
      ENDIF
C
C5------Initialize names of zones, multipliers, and parameters.
      IF(NZONAR.GT.0) THEN
        DO 10 I=1,NZONAR
        ZONNAM(I)=' '
10      CONTINUE
      END IF
      IF(NMLTAR.GT.0) THEN
        DO 20 I=1,NMLTAR
        MLTNAM(I)=' '
20      CONTINUE
      END IF
C
C6------Define the multiplier arrays.
      IF(NMLTAR.GT.0) THEN
        DO 2000 M=1,NMLTAR
C
C6A-----Read a line describing a multiplier array.
          READ (INMULT,'(A)') LINE
C
C6B-----Get the name of the new array
          LLOC=1
          CALL URWORD(LINE,LLOC,ISTART,ISTOP,0,N,R,IOUT,INMULT)
C
C6C-----Add new multiplier name into list.
          MLTNAM(M)=LINE(ISTART:ISTOP)
          CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INMULT)
          IF(LINE(ISTART:ISTOP).NE.'FUNCTION') THEN
C
C6D-----Define array using array reader.
             ANAME=' MULT. ARRAY: '//MLTNAM(M)
             CALL U2DREL(RMLT(1,1,M),ANAME,NROW,NCOL,0,INMULT,IOUT)
          ELSE
C
C6E-----Define array as aritmetic combination of other multiplier arrays.
C6E-----Start by initializing the array to 0.
             WRITE(IOUT,30) MLTNAM(M)
   30        FORMAT(1X,/1X,'Calculated multiplier array: ',A)
             DO 40 I=1,NROW
             DO 40 J=1,NCOL
             RMLT(J,I,M)=0.
   40        CONTINUE
C
C6E1----Get the names of the multipliers and the operands.
             READ (INMULT,'(A)') LINE
             LLOC=1
             NOP=0
C
C6E2----Get the operator.
   45        IF(NOP.EQ.0) THEN
C
C6E2A---No operator is specified before the first operand -- define it to be " "
                COP=' '
             ELSE
C
C6E2B---Get the operator that precedes each operand after the first operand.
                CALL URWORD(LINE,LLOC,ISTART,ISTOP,0,N,R,IOUT,INMULT)
                IF(LINE(ISTART:ISTOP).EQ.'+' .OR.
     1             LINE(ISTART:ISTOP).EQ.'-' .OR.
     2             LINE(ISTART:ISTOP).EQ.'*' .OR.
     3             LINE(ISTART:ISTOP).EQ.'/') THEN
                   COP=LINE(ISTART:ISTOP)
                ELSE
                   GO TO 1000
                END IF
             END IF
             NOP=NOP+1
C
C6E3----Get the operand.
             CALL URWORD(LINE,LLOC,ISTART,ISTOP,0,N,R,IOUT,INMULT)
             WRITE(IOUT,47 ) COP,LINE(ISTART:ISTOP)
   47        FORMAT(1X,'                        ',A,' ARRAY ',A)
C
C6E4----Lookup the operand in the list of existing multipliers
             DO 50 MM=1,M
               CTMP1=MLTNAM(MM)
               CALL UPCASE(CTMP1)
               CTMP2=LINE(ISTART:ISTOP)
               CALL UPCASE(CTMP2)
               IF(CTMP1.EQ.CTMP2) GO TO 60
   50        CONTINUE
             WRITE(IOUT,51) LINE(ISTART:ISTOP)
   51        FORMAT(1X,
     1        'ARRAY OPERAND HAS NOT BEEN PREVIOUSLY DEFINED:',A)
             CALL USTOP(' ')
C
C6E5----Apply the + operator.
   60        IF(COP.EQ.'+' .OR. COP.EQ.' ') THEN
                DO 100 I = 1, NROW
                DO 100 J = 1, NCOL
                  RMLT(J,I,M) = RMLT(J,I,M)+ RMLT(J,I,MM)
  100           CONTINUE
             ELSE IF(COP.EQ.'-') THEN
                DO 200 I = 1, NROW
                DO 200 J = 1, NCOL
                  RMLT(J,I,M) = RMLT(J,I,M)- RMLT(J,I,MM)
  200           CONTINUE
             ELSE IF(COP.EQ.'*') THEN
                DO 300 I = 1, NROW
                DO 300 J = 1, NCOL
                  RMLT(J,I,M) = RMLT(J,I,M)* RMLT(J,I,MM)
  300           CONTINUE
             ELSE
                DO 400 I = 1, NROW
                DO 400 J = 1, NCOL
                  RMLT(J,I,M) = RMLT(J,I,M)/ RMLT(J,I,MM)
  400           CONTINUE
             END IF
C
C6E6----Get the next operator.
             GO TO 45
C
C6E7-----Done defining the array.  Get the print code and print the array.
1000          IPRN=0
              L=20-ISTOP+ISTART
              IF(L.GT.1)  THEN
                 RW=' '
                 RW(L:20)=LINE(ISTART:ISTOP)
                 READ(RW,'(I20)',ERR=1200) IPRN
              END IF
 1200         IF(IPRN.GE.0) THEN
                 ANAME=' MULT. ARRAY: '//MLTNAM(M)
                 CALL ULAPRWC(RMLT(1,1,M),NCOL,NROW,0,IOUT,IPRN,
     1                 ANAME)
              END IF
          END IF
 2000   CONTINUE
      ENDIF
C
C7------Read the zone array names and arrays
      IF(NZONAR.GT.0) THEN
         DO 3000 NZ=1,NZONAR
         READ(INZONE,'(A)') ZONNAM(NZ)
         CALL U2DINT(IZON(1,1,NZ),'  ZONE ARRAY: '//ZONNAM(NZ),
     1            NROW,NCOL,0,INZONE,IOUT)
 3000    CONTINUE
      END IF
C
C8------Return.
      RETURN
      END
C
C -----------------------------------------------------------------------
      SUBROUTINE SGWF2BAS7U1ARPVAL(IUPVAL)
C     ******************************************************************
C     READ PARAMETER INPUT FILE
C     ******************************************************************
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,    ONLY: IOUT,IUNIT
      USE PARAMMODULE, ONLY:MXPAR,IPSUM,PARNAM,B,NPVAL
C
      CHARACTER*10 PNI, PNJ
      CHARACTER*200 LINE
C     ------------------------------------------------------------------
C
C1------CHECK TO SEE IF THE PARAMETER FILE WAS DECLARED IN THE NAME FILE.
      IU=IUNIT(IUPVAL)
      IF(IU.LE.0) THEN
         NPVAL=0
         RETURN
      END IF
C
C2------INITIALIZE VARIABLES
      IERR = 0
      NPE = 0
C
C3------IDENTIFY PARAMETER VALUE OPTION.
      WRITE (IOUT,12) IU
   12 FORMAT (1X,/,1X,
     1  'PARAMETER VALUE INPUT FILE,  INPUT READ FROM UNIT ',I4)
C
C4------READ & PRINT NUMBER OF PARAMETER VALUES.
      CALL URDCOM(IU,IOUT,LINE)
      LLOC = 1
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,NPVAL,DUM,IOUT,IU)
      WRITE (IOUT,14) NPVAL
   14 FORMAT (1X,/,1X,'NUMBER OF PARAMETER VALUES TO BE READ FROM',
     1               ' PARAMETER VALUE FILE:',I5)
      IF (NPVAL.LE.0) THEN
        WRITE (IOUT,16)
   16   FORMAT(1X,'NPVAL IN PARAMETER INPUT FILE MUST BE',
     1         ' > 0 -- STOP EXECUTION')
        CALL USTOP(' ')
      ENDIF
      IPSUM=NPVAL
C
C5-----DEACTIVATE OPTION IF THERE ARE NO PARAMETERS IN FILE.
      IF(NPVAL.LE.0) THEN
         WRITE(IOUT,*) ' NPVAL in parameter file is 0,',
     1            ' so ignoring the parameter file'
        CLOSE(UNIT=IU)
        IU=0
        RETURN
      END IF
C
C6------STOP IF THERE ARE MORE THAN THE MAXIMUM NUMBER OF PARAMETERS.
      IF(NPVAL.GT.MXPAR) THEN
         WRITE(IOUT,*) ' PARAMETER FILE CONTAINS',NPVAL,
     1     ' VALUES, BUT THE MAXIMUM NUMBER OF PARAMETERS IS',MXPAR
         CALL USTOP(' ')
      END IF
C
C7------WRITE A HEADING FOR THE LIST OF PARAMETERS.
      WRITE (IOUT,520)
  520 FORMAT (/,' INFORMATION ON PARAMETERS LISTED IN PARAMETER FILE',/,
     &             13X,'  VALUE IN',/,
     &   '    NAME     PARAMETER FILE',/,
     &   ' ----------  --------------')
C
C8-----READ AND WRITE PARAMETER NAMES AND VALUES.
      DO 70 I=1,NPVAL
        READ(IU,*,ERR=80) PARNAM(I),B(I)
        WRITE(IOUT,570) PARNAM(I),B(I)
  570   FORMAT(1X,A10,2X,G12.5)
C
C8A-----CHECK FOR DUPLICATE PARAMETER NAME FOR ALL BUT THE FIRST PARAMETER.
        IF (I.GT.1) THEN
          PNI=PARNAM(I)
          CALL UPCASE(PNI)
          IM1 = I-1
          DO 60 J=1,IM1
            PNJ=PARNAM(J)
            CALL UPCASE(PNJ)
            IF (PNI.EQ.PNJ) THEN
              WRITE(IOUT,500) PARNAM(I)
  500         FORMAT (' PARAMETER "',A10,
     &        '" IS LISTED MORE THAN ONCE IN PARAMETER FILE',/,
     &        ' -- STOP EXECUTION')
                IERR = 1
            ENDIF
   60     CONTINUE
        ENDIF
   70 CONTINUE
C
C9------WRITE A MESSAGE EXPLAINING THAT THE PARAMETER VALUES REPLACE THE
C9------VALUES FROM PACKAGE INPUT FILES..
      WRITE (IOUT,620)
  620 FORMAT(1X,77('-'))
      WRITE (IOUT,630)
  630 FORMAT(' FOR THE PARAMETERS LISTED IN THE TABLE ABOVE,',
     &       ' PARAMETER VALUES IN INDIVIDUAL',/,
     &       ' PACKAGE INPUT FILES ARE REPLACED BY THE VALUES FROM',
     &       ' THE PARAMETER INPUT FILE.')
C
C10-----STOP IF THERE WERE DUPLICATE NAMES.
      IF (IERR.GT.0) THEN
        WRITE(IOUT,680)
  680 FORMAT(/,
     &' ERROR FOUND IN PARAMETER INPUT FILE.  SEARCH ABOVE',/,
     &' FOR "STOP EXECUTION"')
         CALL USTOP(' ')
      ENDIF
C
C11-----CLOSE FILE AND RETURN.
      CLOSE(UNIT=IU)
      RETURN
C
C
   80 WRITE(IOUT,590)
  590 FORMAT(1X,/,1X,
     1  'ERROR ENCOUNTERED IN READING PARAMETER INPUT FILE',/,
     2       ' -- STOP EXECUTION')
      CALL USTOP(' ')
C
      END
C
C--------------------------------------------------------------
      SUBROUTINE GWF2BAS7U1FM
C     ******************************************************************
C     SET HCOF=RHS=0.
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,ONLY:RHS,AMAT,TURBGRAD,NJAS
C     ------------------------------------------------------------------
C
C1------FOR EACH CELL INITIALIZE HCOF AND RHS ACCUMULATORS.
      ZERO=0.0D0
      AMAT=ZERO
      RHS=ZERO
C
C1A------ALLOCATE SPACE FOR TURBGRAD (AT SOLUTION LEVEL FOR NOW) AND INITIALIZE
      ALLOCATE(TURBGRAD(NJAS))
      DO I=1,NJAS
        TURBGRAD(I) = 1.0
      ENDDO
C
C2------RETURN
      RETURN
      END
C -----------------------------------------------------------------------
      SUBROUTINE GWF2BAS8ST(KPER)
C     ******************************************************************
C     SETUP TIME VARIABLES FOR NEW TIME PERIOD
C     INITIALIZE HNEW AND HOLD TO ABOVE BOTTOM FOR KPER=1 AND ICONCV=0
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,     ONLY:IOUT,PERLEN,NSTP,TSMULT,HNEW,HOLD,ICONCV,BOT,
     *                     IBOUND,NODES,NLAY,NODLAY
      USE GWFBCFMODULE, ONLY: LAYCON
      USE GWFBASMODULE,ONLY:DELT,PERTIM,IATS,DELTAT
C     ------------------------------------------------------------------
C
C1------IF NOT ADAPTIVE TIME STEPPING
      IF(IATS.EQ.0)THEN
C
C2------WRITE STRESS PERIOD INFORMATION
      WRITE (IOUT,1) KPER,PERLEN(KPER),NSTP(KPER),TSMULT(KPER)
    1 FORMAT('1',/28X,'STRESS PERIOD NO. ',I4,', LENGTH =',G15.7,/
     1            28X,47('-'),//
     2            30X,'NUMBER OF TIME STEPS =',I10,//
     3            31X,'MULTIPLIER FOR DELT =',F10.3)
C
C3------CALCULATE THE LENGTH OF THE FIRST TIME STEP
C3A-----ASSUME TIME STEP MULTIPLIER IS EQUAL TO ONE.
        DELT=PERLEN(KPER)/FLOAT(NSTP(KPER))
C
C3B-----IF TIME STEP MULTIPLIER IS NOT ONE THEN CALCULATE FIRST
C3B-----TERM OF GEOMETRIC PROGRESSION.
        ONE=1.
        IF(TSMULT(KPER).NE.ONE)
     1    DELT=PERLEN(KPER)*(ONE-TSMULT(KPER))/
     2        (ONE-TSMULT(KPER)**NSTP(KPER))
      ELSE
C4------FOR ADAPTIVE TIME STEPPING
C
C5------WRITE STRESS PERIOD INFORMATION
      WRITE (IOUT,2) KPER,PERLEN(KPER)
2     FORMAT('1',/28X,'STRESS PERIOD NO. ',I4,', LENGTH =',G15.7,/
     1            28X,47('-'))
C6------SET DELT
        IF(DELTAT.GT.PERLEN(KPER))THEN
          DELTAT = PERLEN(KPER)
        ENDIF
        DELT = DELTAT
      ENDIF
C
C7------PRINT THE LENGTH OF THE FIRST TIME STEP.
      WRITE (IOUT,9) DELT
    9 FORMAT(1X,/28X,'INITIAL TIME STEP SIZE =',G15.7)
C
C8------INITIALIZE PERTIM (ELAPSED TIME WITHIN STRESS PERIOD).
      PERTIM=0.
C
C9------CHECK THAT ALL PARAMETERS IN PARAMETER VALUE FILE HAVE BEEN DEFINED.
      IF(KPER.GT.1) CALL SGWF2BAS7STPVAL()
C
C10-----SET HEADS ABOVE BOTTOM FOR ICONCV=0 AT FIRST ENTRY
      IF(KPER.EQ.1.AND.ICONCV.EQ.0)THEN
        DO K=1,NLAY
          IF(LAYCON(K).NE.0.OR.LAYCON(K).NE.2)THEN
          NNDLAY = NODLAY(K)
          NSTRT = NODLAY(K-1)+1
          DO N=NSTRT,NNDLAY
          IF(IBOUND(N).NE.0)THEN
          IF(HNEW(N).LT.BOT(N))THEN
            HNEW(N) = BOT(N)
            HOLD(N) = BOT(N)
          ENDIF
          ENDIF
          ENDDO
          ENDIF
        ENDDO
      ENDIF
C
C11------RETURN
      RETURN
      END
C -----------------------------------------------------------------------
      SUBROUTINE GWF2BAS7AD(KPER,KSTP)
C     ******************************************************************
C     ADVANCE TO NEXT TIME STEP; COPY NEW INTO OLD VARIABLES
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,      ONLY:NODES,TSMULT,HNEW,HOLD,So,Sn,NEQS,
     *                      iunit,area,iout
      USE GWFBASMODULE,ONLY:DELT,TOTIM,PERTIM,IATS,DELTAT
C     ------------------------------------------------------------------
C
C1------IF NOT FIRST TIME STEP THEN CALCULATE TIME STEP LENGTH FOR STANDARD TIME STEPPING.
      IF(IATS.EQ.0)THEN
        IF(KSTP.NE.1) DELT=TSMULT(KPER)*DELT
      ELSE
        DELT= DELTAT
      ENDIF
C
C2------ACCUMULATE ELAPSED TIME IN SIMULATION(TOTIM) AND IN THIS
C2------STRESS PERIOD(PERTIM).
      TOTIM=TOTIM+DELT
      PERTIM=PERTIM+DELT
C
C3------COPY HNEW TO HOLD.
      DO 10 N=1,NEQS
      So(N) = Sn(N)
   10 HOLD(N)=HNEW(N)
C
C4------RETURN
      RETURN
      END
C -----------------------------------------------------------------------
      SUBROUTINE GWF2FASTFORWARD(KPER,KSTP)
C     ******************************************************************
C     READ OLD FILE TO FAST FORWARD FROM
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL, ONLY:NODES,TSMULT,HNEW,HOLD,So,Sn,NEQS,IUNSTR,TOP,BOT,
     *    IBOUND,iunit,area,iout,NODLAY,NROW,NCOL,NLAY,NODES,IXSEC,INCLN
      USE GWFBASMODULE,ONLY:DELT,TOTIM,PERTIM,IATS,DELTAT,
     * IFAST,ISPFAST,ITSFAST,IUGFAST,IUCFAST
      USE GWFBCFMODULE,ONLY:LAYCON
      USE CLN1MODULE, ONLY: ACLNNDS,NCLNNDS,IFLINCLN
      REAL, SAVE,  DIMENSION(:,:,:),ALLOCATABLE  ::HTMP
      REAL,  SAVE, DIMENSION(:),ALLOCATABLE  ::HTMP1,HTMPCLN
      DOUBLE PRECISION HD,THCK,TOTTHICK,BBOT,TTOP,TOTIMREAD,PERTIMREAD
     1  ,AHD
       SAVE KPERREAD,KSTPREAD
      CHARACTER*16 TEXT
C     ------------------------------------------------------------------
C
C1------IDENTIFY PACKAGE AND READ HEADS FROM BOOTSTRAP FILE FOR THIS TIME
      INU = IUGFAST
      WRITE(IOUT,1) INU,KPER,KSTP
    1 FORMAT(1X,/1X,'FST -- FASTFORWARDING SUBROUTINE, VERSION 1',
     1', 01/23/2017',/,9X,'GROUNDWATER HEAD FILE UNIT IS',I3,
     2'. ENTER SUBROUTINE FOR STRESS PERIOD',
     3   I10,' AND TIME STEP',I10)
C
C1----INITIALIZE FOR FIRST TIME IN
      IF (KSTP.EQ.1.AND.KPER.EQ.1) THEN
        KPERREAD = 1
        KSTPREAD = 1
        IF(IUNSTR.EQ.0) THEN
          ALLOCATE(HTMP(NCOL,NROW,NLAY))
        ELSE
          ALLOCATE(HTMP1(Nodes))
        ENDIF
        IF(INCLN.GT.0) ALLOCATE(HTMPCLN(NCLNNDS))
      ENDIF
      IF(KSTPREAD.GE.KSTP) THEN
C ------NEED TO READ THE FAST FORWARD FILE
        IF(IUNSTR.EQ.0) THEN
C2-------FOR STRUCTURED GRID READ BINARY FILE INTO HTMP
          DO 350 K=1,NLAY
            KK=K
            CALL ULASAVRD(HTMP(1,1,K),TEXT,KSTPREAD,KPERREAD,PERTIMREAD,
     1              TOTIMREAD,NCOL,NROW,KK,INU)
  350     CONTINUE
          WRITE(IOUT,351)KPERREAD,KSTPREAD
351       FORMAT(10X,'*** FASTFORWARD FILE READ FOR STRESS PERIOD = ',
     1      I10,', AND TIME-STEP = ',I10,' ***')
        ELSE
C4--------FOR UNSTRUCTURED GRID READ BINARY FILE INTO HTMP1
          DO K=1,NLAY
            NNDLAY = NODLAY(K)
            NSTRT = NODLAY(K-1)+1
            CALL ULASAVURD(HTMP1,TEXT,KSTPREAD,KPERREAD,PERTIMREAD,
     1               TOTIMREAD,NSTRT,NNDLAY,ILAY,INU,NODES)
          ENDDO
          WRITE(IOUT,351)KPERREAD,KSTPREAD
        ENDIF
C-------FOR CLN NODES
          IF(INCLN.GT.0)THEN
C2A------ READ BINARY FILE INTO HTMP
          INU = IUCFAST
          IDUM = 1
          CALL ULASAVRD(HTMPCLN,TEXT,KSTPREAD,KPERREAD,PERTIMREAD,
     1                TOTIMREAD,NCLNNDS,IDUM,IDUM,INU)
        ENDIF
C-----------NEED TO UPDATE FOR DUAL DOMAIN FLOW

C--------------------------------------------------------------
        IF(KSTPREAD.GT.KSTP)THEN
C --------RESTART FILE GOT TO NEXT STRESS PERIOD SO ADJUST KSTPREAD AND KPERREAD
          KSTPREAD = KSTP
          KPERREAD = KPER
        ENDIF
        KSTPREAD = KSTPREAD + 1
        ENDIF
        IF (KPERREAD.GT.KPER) THEN
          IFAST = 2
        ELSEIF (KPERREAD.EQ.KPER) THEN
          IFAST = 1
        ENDIF
C--------------------------------------------------------------------------------------
C ------STOP FAST-FORWARDING ONCE SP AND TS ARE REACHED, AND UPDATE ALL ARRAYS
      IF(KPER.EQ.ISPFAST.AND.KSTP.EQ.ITSFAST)THEN
        IFAST = 3
        IF(IUNSTR.EQ.0) THEN
C2B-------FOR STRUCTURED GRID COPY HTMP INTO HNEW
          N=0
          DO 360 K=1,NLAY
          DO 360 I=1,NROW
          DO 360 J=1,NCOL
            N=N+1
            HNEW(N) = HTMP(J,I,K)
360       CONTINUE
          DEALLOCATE (HTMP)
        ELSE
C2B-------FOR UNSTRUCTURED GRID COPY HTEMP1 INTO HNEW
          DO N=1,NODES
            HNEW(N) =  HTMP1(N)
          ENDDO
          DEALLOCATE (HTMP1)
        ENDIF
C
        IF(INCLN.GT.0)THEN
C2B-------FOR CLN NODES COPY HTEMP INTO HNEW
          DO N=1,NCLNNDS
            NG = NODES + N
            HNEW(NG) =  HTMPCLN(N)
          ENDDO
          DEALLOCATE (HTMPCLN)
        ENDIF
C---------------------------------------------------------------------
C6--------GET SNEW FOR THIS HNEW
        DO K=1,NLAY
          IF(LAYCON(K).GE.4) THEN
C-----------LOOP THROUGH EACH CELL IN LAYER
            NNDLAY = NODLAY(K)
            NSTRT = NODLAY(K-1)+1
            DO N=NSTRT,NNDLAY
              IF(IBOUND(N).NE.0) THEN
C---------------CALCULATE SATURATED THICKNESS.
                HD=HNEW(N)
                BBOT=BOT(N)
                TTOP=TOP(N)
                TOTTHICK = TTOP - BBOT
                CALL SAT_THIK(N,HD,TOTTHICK,BBOT,THCK,K)
                Sn(N)=THCK
              ENDIF
            ENDDO
          ENDIF
        ENDDO
C4-----SET SNEW FOR CLN-NODES FOR THIS HNEW
        DO  IFN=1,NCLNNDS
          N = ACLNNDS(IFN,1)
          IFLIN = IFLINCLN(IFN)
          IF(IBOUND(N).NE.0.AND.IFLIN.LE.0) THEN
C-----------CALCULATE INITIAL SATURATED THICKNESS FOR UNCONFINED CASES.
            HD=HNEW(N)
            BBOT = ACLNNDS(IFN,5)
            CALL CLN_THIK(IFN,HD,BBOT,THCK)
            Sn(N)=THCK
          ENDIF
        ENDDO
C-----------NEED TO UPDATE FOR DUAL DOMAIN FLOW

C -----------------------------------------------------------------------
C1------IF NOT FIRST TIME STEP THEN CALCULATE TIME STEP LENGTH FOR STANDARD TIME STEPPING.
        IF(IATS.EQ.0)THEN
          IF(KSTP.NE.1) DELT=TSMULT(KPER)*DELT
        ELSE
          DELT= DELTAT
        ENDIF
C
C2------ACCUMULATE ELAPSED TIME IN SIMULATION(TOTIM) AND IN THIS
C2------STRESS PERIOD(PERTIM).
        TOTIM=TOTIMREAD
        PERTIM=PERTIMREAD
      ENDIF
C
C4------RETURN
      RETURN
      END
C -----------------------------------------------------------------------
      SUBROUTINE SGWF2BAS7STPVAL()
C     ******************************************************************
C     CHECK THAT PARAMETER DEFINITIONS ARE COMPLETE.
C     ******************************************************************
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,      ONLY: IOUT
      USE PARAMMODULE, ONLY:NPVAL,PARTYP,PARNAM
C     ------------------------------------------------------------------
      IF(NPVAL.LE.0) RETURN
      IERR=0
C
C1------CHECK THAT ALL PARAMETERS IN PARAMETER INPUT FILE HAVE BEEN DEFINED.
      DO 90 IP=1,NPVAL
        IF (PARTYP(IP).EQ.' ') THEN
          IERR = 1
          WRITE(IOUT,110) PARNAM(IP)
  110     FORMAT(1X,/,1X,'PARAMETER "',A10,
     1      '" IN PARAMETER INPUT FILE HAS NOT BEEN DEFINED',/,
     2           ' -- STOP EXECUTION')
        ENDIF
   90 CONTINUE
C
      IF(IERR.NE.0) CALL USTOP(' ')
C
C2------RETURN.
      RETURN
      END
C -----------------------------------------------------------------------
      SUBROUTINE ATS1AD(KITER,KSTP,KPER,ICNVG,INOC,ISTOP)
C     ******************************************************************
C     SET PRINT FLAGS AND ADVANCE TO MASS BALANCE COMPUTATIONS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL, ONLY:IOUT,NLAY,NSTP,IXSEC,IFREFM,ITRNSP,PERLEN,ISSFLG,
     1    AREA
      USE SMSMODULE, ONLY: MXITER
      USE GWFBASMODULE,ONLY:IHDDFL,ISPCFL,IBUDFL,ICBCFL,IPEROC,ITSOC,
     1    IBDOPT,IOFLG,DELT,DELTAT,PERTIM,TOTIM,
     2    NPSTPS,NPTIMES,TIMOT,ITIMOT,TMAXAT,TMINAT,TADJAT,TCUTAT,
     3    IBUDFLAT,ICBCFLAT,IHDDFLAT,ISPCFLAT
C
C     ------------------------------------------------------------------
C
C1------DETERMINE IF PRINTING IS NEEDED AT THIS TIME
      IATSPR = 0
C1A-----PRINT FOR STEADY-STATE STRESS PERIODS
      IF (ISSFLG(KPER).EQ.1) IATSPR = 1
C1B-----PRINT EVERY NPSTPS TIMES
      IF (MOD(KSTP,NPSTPS).EQ.0) IATSPR = 1
C1C-----PRINT AT END OF STRESS PERIOD
      IF(ABS(PERTIM-PERLEN(KPER)).LT.TMINAT) IATSPR = 1
C1D-----PRINT WHEN OUTPUT TIME IS REACHED
      IF(NPTIMES.GT.0)THEN
        IF(TOTIM.GE.(TIMOT(ITIMOT) - TMINAT))THEN
          IATSPR = 1
          ITIMOT = ITIMOT + 1
        ENDIF
      ENDIF
C2------SET FLAGS IF PRINTING
      IBUDFL = IBUDFLAT
      ICBCFL = 0
      IHDDFL = 0
      IF(ITRNSP.NE.0) ISPCFL = 0
      IF(IATSPR.EQ.1) THEN
        ICBCFL = ICBCFLAT
        IHDDFL = IHDDFLAT
        IF(ITRNSP.NE.0)THEN
          ISPCFL = ISPCFLAT
        ENDIF
      ENDIF
C
C3-------RETURN.
      RETURN
      END
C -----------------------------------------------------------------------
      SUBROUTINE ATS1AJ(KITER,KSTP,KPER,ICNVG,INOC,ISTRFIN,ISTOP,
     1  INEVT,INRCH,INFHB)
C     ******************************************************************
C     READ RTS/ETS AND ADJUST RECH/EVTR AS NEEDED
C     AND SET NEW DELTAT FOR ADAPTIVE TIME STEPPING
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL, ONLY:IOUT,NLAY,NSTP,IXSEC,IFREFM,ITRNSP,PERLEN,ISSFLG,
     1    AREA
      USE SMSMODULE, ONLY: MXITER
      USE GWFBASMODULE,ONLY:IHDDFL,ISPCFL,IBUDFL,ICBCFL,IPEROC,ITSOC,
     1    IBDOPT,IOFLG,DELT,DELTAT,PERTIM,TOTIM,IFRCNVG,
     2    NPSTPS,NPTIMES,TIMOT,ITIMOT,TMAXAT,TMINAT,TADJAT,TCUTAT,
     3    IBUDFLAT,ICBCFLAT,IHDDFLAT
      USE GWFRCHMODULE, ONLY: INRTS,tstartrch,tendrch,factrrch,rtsrch,
     1   IZNRCH,RECH,TIMRCH,irch,IRTSRD,inirch,MXZNRCH,IRTSOPT,RECHSV
      USE GWFEVTMODULE, ONLY: INETS,tstartevt,tendevt,factrevt,etsevt,
     1   IZNEVT,EVTR,TIMEVT,ievt,IETSRD,inievt,MXZNEVT,IETSOPT
      USE GWFFHBMODULE,ONLY: TIMFHB,ISFHBOPT
C
C     ------------------------------------------------------------------
C
C------------------------------------------------------------------------
C4------READ NEXT LINE OF RTS IF FLAG IS ON AND SET RECHARGE
C------------------------------------------------------------------------
      IF(INRCH.GT.0)THEN
      IF(IRTSRD.EQ.1)THEN
C4B-----------READ NEXT LINE OF RTS FILE
        read(inrts,*)tstartrch,tendrch,factrrch,(rtsrch(i),i=1,mxznrch)
        write(iout,2)tstartrch,tendrch,factrrch,(rtsrch(i),i=1,mxznrch)
2       format(/2x,'*** RTS read - Tstart, Tend, Factor, Rts(mxznrch)'/
     1     5x,200g15.7)
        IF(tstartrch. GT. TOTIM)THEN
C4C----------ACCOMMODATE ZERO-RECHARGE GAP IN DATA FROM PREVIOUS TENDRCH
          TIMRCH = tstartrch
          DO I=1,MXZNRCH
            RTSRCH(I) = 0.0
          ENDDO
          DO NN=1,INIRCH
            RECH(NN) = RECHSV(NN)
          ENDDO
          BACKSPACE(INRTS)
          WRITE(IOUT,3)TSTARTRCH,TOTIM
3         FORMAT(2X,'*** ZERO RECHARGE APPLIED FROM RTS SINCE ',1X,
     1    'TSTARTRCH',G15.6,', IS LARGER THAN CURRENT TOTIM',G15.6,
     2    '. ***')
        ELSE
C4D----------SET TIMRCH FOR NEXT RECORD IN RTS FILE AND FILL RECH ARRAY WITH RTS DATA
          TIMRCH = TENDRCH
          DO 52 NN=1,INIRCH
            N = IRCH(NN)
            izr = iznrch(n)
            if(izr.ge.1.and.izr.le.mxznrch)
     *      RECH(NN)=RECHSV(NN) + rtsrch(izr)*AREA(N)*factrrch
   52     CONTINUE
          WRITE(IOUT,4)
4         FORMAT(2X,'*** RECH ARRAY UPDATED FROM RTS FILE FOR USE ',
     1           'IN THE FOLLOWING TIME STEP***')
        ENDIF
        IRTSRD = 0
      ENDIF
      ENDIF
C------------------------------------------------------------------------
C5------READ NEXT LINE OF ETS IF FLAG IS ON AND SET ET
C------------------------------------------------------------------------
      IF(INEVT.GT.0)THEN
      IF(IETSRD.EQ.1)THEN
C5A-----------READ NEXT LINE OF ETS FILE
        read(inrts,*)tstartevt,tendevt,factrevt,(etsevt(i),i=1,mxznevt)
        write(iout,5)tstartevt,tendevt,factrevt,(etsevt(i),i=1,mxznevt)
5       format(2x,'*** ETS read - Tstart, Tend, Factor, Ets(mxznevt)'/
     1     5x,200g15.7)
        IF(tstartevt. GT. TOTIM)THEN
C5C----------ACCOMMODATE ZERO-ET GAP IN DATA FROM PREVIOUS TENDEVT
          TIMEVT = tstartevt
          DO I=1,MXZNEVT
            ETSEVT(I) = 0.0
          ENDDO
          DO NN=1,INIEVT
            EVTR(NN) = 0.0
          ENDDO
          BACKSPACE(INETS)
          WRITE(IOUT,6)TSTARTEVT,TOTIM
6         FORMAT(2X,'*** ZERO ET APPLIED FROM ETS SINCE ',1X,
     1      'TSTARTEVT',G15.6,', IS LARGER THAN TOTIM',G15.6,'. ***')
        ELSE
C5D----------SET TIMEVT FOR NEXT RECORD IN ETS FILE AND FILL EVTR ARRAY WITH ETS DATA
          TIMEVT = TENDEVT
          DO 53 NN=1,INIEVT
            N = IEVT(NN)
            ize = iznevt(n)
            if(ize.ge.1.and.ize.le.mxznevt)
     *      EVTR(NN) = etsevt(izr)*AREA(N)*factrevt
   53     CONTINUE
          WRITE(IOUT,7)
7         FORMAT(2X,'*** EVTR ARRAY UPDATED FROM ETS FILE ***')
        ENDIF
        IETSRD = 0
      ENDIF
      ENDIF
C------------------------------------------------------------------------
C6------SET DELTAT FOR NEXT TIME STEP
C------------------------------------------------------------------------
C6A-----ADJUST DELTAT FOR CONVERGENCE - BUT NOT WHEN FORCING CONVERGENCE
      IF(IFRCNVG.EQ.1.AND.KITER.EQ.MXITER)THEN
        DELTAT = DELT*TADJAT
      ELSE
        IF(KITER.LE.INT(MXITER/3)) THEN
          DELTAT=DELT*TADJAT
        ELSEIF(KITER.GT.INT(2*MXITER/3)) THEN
          DELTAT=DELT/TADJAT
        ELSE
          DELTAT=DELT
        ENDIF
      ENDIF
C6B-----ADJUST DELTAT IF IT IS LARGER THAN TMAXAT
      IF(DELTAT.GT.TMAXAT)THEN
        DELTAT = TMAXAT
      ENDIF
C6C-----ADJUST DELTAT IF NEW TIME IS WITHIN TMINAL OF PRINT TIME AND KSTP > 1
      IF(NPTIMES.GT.0)THEN
        IF(KSTP.GT.1.AND.(TOTIM+DELTAT).GT.TIMOT(ITIMOT)-TMINAT)THEN
          DELTAT = TIMOT(ITIMOT) - TOTIM
        ENDIF
      ENDIF
C6D-----ADJUST DELTAT IF NEW TIME IS WITHIN TMINAL OF TIMRCH IF RTS IS ON
      IF(INRCH.GT.0)THEN
        IF(IRTSOPT.GT.0)THEN
          IF( (TOTIM+DELTAT) .GT. (TIMRCH-TMINAT) )THEN
            DELTAT = TIMRCH - TOTIM
            IRTSRD = 1 ! SET FLAG TO READ RTS ARRAY AFTER NEXT STEP
          ENDIF
        ENDIF
      ENDIF
C6E-----ADJUST DELTAT IF NEW TIME IS WITHIN TMINAL OF TIMEVT IF ETS IS ON
      IF(INEVT.GT.0)THEN
        IF(IETSOPT.GT.0)THEN
          IF( (TOTIM+DELTAT) .GT. (TIMEVT-TMINAT) )THEN
            DELTAT = TIMEVT - TOTIM
            IETSRD = 1 ! SET FLAG TO READ ETS ARRAY AFTER NEXT STEP
          ENDIF
        ENDIF
      ENDIF
C6F-----ADJUST DELTAT IF NEW TIME IS WITHIN TMINAL OF TIMFHB IF STAIRCASE OPTION IS ON
      IF(INFHB.GT.0)THEN
        IF(ISFHBOPT.GT.0)THEN
          IF( (TOTIM+DELTAT) .GT. (TIMFHB-TMINAT) )THEN
            DELTAT = TIMFHB - TOTIM
          ENDIF
        ENDIF
      ENDIF
C-----------------------------------------------------------------------------
C7------AT END OF STRESS PERIOD SET FLAG ISTRFIN AND RETURN
      IF(ABS(PERTIM-PERLEN(KPER)).LT.TMINAT) THEN
        ISTRFIN = 1
        RETURN
      ENDIF
C-----------------------------------------------------------------------------
C8------FINALLY ADJUST DELTAT AND SET FLAGS IF NEW TIME IS WITHIN TMINAL OF PERLEN
      IF((PERTIM+DELTAT).GT.PERLEN(KPER)-TMINAT)THEN
        DELTAT = PERLEN(KPER) - PERTIM
      ENDIF
C------------------------------------------------------------------------
C9------CHECK IF DELTAT IS LESS THAN TMINAT AND SET STOP FLAG
      IF(DELTAT.LT.TMINAT) ISTOP = 1
C
C10------RETURN.
      RETURN
      END
C -----------------------------------------------------------------------
      SUBROUTINE ATS1CT(KITER,KSTP,KPER,ICNVG,INOC,ISTOP,INEVT,INRCH)
C     ******************************************************************
C     CUT TIME STEP SIZE FOR NONCONVERGED SOLUTION AND RESET PARAMETER VECTORS
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL, ONLY:IOUT,NLAY,NSTP,IXSEC,IFREFM,ITRNSP,PERLEN,
     1    HNEW,HOLD,SN,SO,NEQS,ISSFLG
      USE GWFBASMODULE,ONLY:IHDDFL,ISPCFL,IBUDFL,ICBCFL,IPEROC,ITSOC,
     1                      IBDOPT,IOFLG,DELT,DELTAT,PERTIM,TOTIM,
     2                      NPSTPS,NPTIMES,TIMOT,ITIMOT,TMINAT,TCUTAT
      USE GWFRCHMODULE, ONLY: IRTSRD
      USE GWFEVTMODULE, ONLY: IETSRD
C
C     ------------------------------------------------------------------
C
C1-----PRINT TIME SUMMARY FOR NONCONVERGED SOLUTION
      WRITE(IOUT,10) DELT,KSTP,KPER
10    FORMAT(/10X,'**** NONLINEAR ITERATIONS DID NOT CONVERGE FOR DELT',
     1  ' =',G12.4,  ' IN TIME STEP ',I5,' OF STRESS PERIOD',I7,' ****')
C------------------------------------------------------------------------
C2------RESET DELTAT AND TIME VALUES TO REATTEMPT THIS TIME STEP
      DELTAT=DELT/TCUTAT
      TOTIM = TOTIM - DELT
      PERTIM = PERTIM - DELT
      TOTIMWR = TOTIM + DELTAT
      PERTIMWR = PERTIM + DELTAT
      WRITE(IOUT,11) DELTAT,TOTIMWR,PERTIMWR
11    FORMAT(/10X,'**** REDUCING TIME STEP SIZE TO DELT = ',G12.4,
     1  ', NEW TOTIM IS =',G12.4,  ', NEW PERTIM IS = ',G12.4,' ****')
C------------------------------------------------------------------------
C3------RESET HEAD AND SATURATION VECTORS FROM OLD VALUES
      DO N=1,NEQS
        HNEW(N) = HOLD(N)
        SN(N) = SO(N)
      ENDDO
C------------------------------------------------------------------------
C4------SET STOP FLAG IF STEADY STATE RUN DID NOT CONVERGE
C4------OR IF DELTAT IS LESS THAN TMINAT
      ISS = ISSFLG(KPER)
      IF(DELTAT.LT.TMINAT. OR. ISS.EQ.1) THEN
        ISTOP = 1
C5-----PRINT BUDGET AND HEADS FOR NONCONVERGED SOLUTION
        IBUDFL = 1
        ICBCFL = 0
        IHDDFL = 1
      ENDIF
C6-------SHUT OFF FLAG TO READ RTS AND ETS FILES, IF ON
      IF(INRCH.GT.0)THEN
        IRTSRD=0
      ENDIF
      IF(INEVT.GT.0)THEN
        IETSRD=0
      ENDIF
C
C7------RETURN.
      RETURN
      END
C -----------------------------------------------------------------------
      SUBROUTINE GWF2BAS7OC(KSTP,KPER,ICNVG,INOC)
C     ******************************************************************
C     OUTPUT CONTROLLER FOR HEAD, DRAWDOWN, AND BUDGET
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,      ONLY:IOUT,NLAY,NSTP,IXSEC,IFREFM,ITRNSP
      USE GWFBASMODULE,ONLY:IHDDFL,ISPCFL,IBUDFL,ICBCFL,IPEROC,ITSOC,
     1                      IBDOPT,IOFLG,IATS
C
C     ------------------------------------------------------------------
C
C1------TEST UNIT NUMBER (INOC (INOC=IUNIT(12))) TO SEE IF
C1------OUTPUT CONTROL IS ACTIVE.  IF NOT, SET DEFAULTS AND RETURN.
      IF(INOC.LE.0) THEN
         IHDDFL=0
         IF(ICNVG.EQ.0 .OR. KSTP.EQ.NSTP(KPER))IHDDFL=1
         IBUDFL=0
         IF(ICNVG.EQ.0 .OR. KSTP.EQ.NSTP(KPER))IBUDFL=1
         ICBCFL=0
         IF(ITRNSP.NE.0)THEN
            ISPCFL=0
            IF(KSTP.EQ.NSTP(KPER))ISPCFL=1
         ENDIF
         GO TO 1000
      END IF
C
C2------OUTPUT CONTROL IS ACTIVE. IF IPEROC >= 0,
C2------READ ADAPTIVE TIME STEPPING PARAMETERS AND OUTPUT FLAGS USING ALPHABETIC INPUT STRUCTURE.
      IF(IPEROC.GE.0) THEN
         CALL SGWF2BAS7N(KPER,KSTP,INOC,IOUT,NLAY)
         GO TO 600
      END IF
C
C3------IF IATS>0, READ ADAPTIVE TIME STEPPING PARAMETERS
      IF(IATS.GT.0)CALL ATS1RP(KPER,INOC,IOUT)
C
C4------READ AND PRINT OUTPUT FLAGS AND CODE FOR DEFINING IOFLG USING
C4------THE ORIGINAL NUMERIC INPUT STRUCTURE.
      IF(ITRNSP.EQ.0)THEN
        IF(IFREFM.EQ.0) THEN
         READ(INOC,'(4I10)') INCODE,IHDDFL,IBUDFL,ICBCFL
        ELSE
         READ(INOC,*) INCODE,IHDDFL,IBUDFL,ICBCFL
        END IF
        WRITE(IOUT,3) IHDDFL,IBUDFL,ICBCFL
    3   FORMAT(1X,/1X,'HEAD/DRAWDOWN PRINTOUT FLAG =',I2,
     1    5X,'TOTAL BUDGET PRINTOUT FLAG =',I2,
     2   /1X,'CELL-BY-CELL FLOW TERM FLAG =',I2)
      ELSE
        IF(IFREFM.EQ.0) THEN
         READ(INOC,'(5I10)') INCODE,IHDDFL,IBUDFL,ICBCFL,ISPCFL
        ELSE
         READ(INOC,*) INCODE,IHDDFL,IBUDFL,ICBCFL,ISPCFL
        END IF
       WRITE(IOUT,4) IHDDFL,IBUDFL,ICBCFL,ISPCFL
    4   FORMAT(1X,/1X,'HEAD/DRAWDOWN PRINTOUT FLAG =',I2,
     1    5X,'TOTAL BUDGET PRINTOUT FLAG =',I2,
     2   /1X,'CELL-BY-CELL FLOW TERM FLAG =',I2,
     3   /1X,'CONCENTRATION PRINTOUT FLAG =',I2)
      ENDIF
      IF(ICBCFL.NE.0) ICBCFL=IBDOPT
C
C4------DECODE INCODE TO DETERMINE HOW TO SET FLAGS IN IOFLG.
      IF(INCODE.LT.0) THEN
C
C5------INCODE <0, USE IOFLG FROM LAST TIME STEP.
        WRITE(IOUT,101)
  101   FORMAT(1X,'REUSING PREVIOUS VALUES OF IOFLG')
      ELSE IF(INCODE.EQ.0) THEN
C
C6------INCODE=0, READ IOFLG FOR LAYER 1 AND ASSIGN SAME TO ALL LAYERS
        IF(ITRNSP.EQ.0)THEN
          IF(IFREFM.EQ.0) THEN
           READ(INOC,'(4I10)') (IOFLG(1,M),M=1,4)
          ELSE
           READ(INOC,*) (IOFLG(1,M),M=1,4)
          END IF
          IOFLG(1,7)=0
          DO 210 K=1,NLAY
            IOFLG(K,1)=IOFLG(1,1)
            IOFLG(K,2)=IOFLG(1,2)
            IOFLG(K,3)=IOFLG(1,3)
            IOFLG(K,4)=IOFLG(1,4)
            IOFLG(K,7)=IOFLG(1,7)
  210     CONTINUE
          WRITE(IOUT,211) (IOFLG(1,M),M=1,4)
  211     FORMAT(1X,/1X,'OUTPUT FLAGS FOR ALL LAYERS ARE THE SAME:'/
     1     1X,'  HEAD    DRAWDOWN  HEAD  DRAWDOWN'/
     2     1X,'PRINTOUT  PRINTOUT  SAVE    SAVE'/
     3     1X,34('-')/1X,I5,I10,I8,I8)
       ELSE
         IF(IFREFM.EQ.0) THEN
           READ(INOC,'(6I10)') (IOFLG(1,M),M=1,6)
          ELSE
           READ(INOC,*) (IOFLG(1,M),M=1,6)
          END IF
          IOFLG(1,7)=0
          DO 212 K=1,NLAY
          IOFLG(K,1)=IOFLG(1,1)
          IOFLG(K,2)=IOFLG(1,2)
          IOFLG(K,3)=IOFLG(1,3)
          IOFLG(K,4)=IOFLG(1,4)
          IOFLG(K,5)=IOFLG(1,5)
          IOFLG(K,6)=IOFLG(1,6)
          IOFLG(K,7)=IOFLG(1,7)
  212     CONTINUE
          WRITE(IOUT,213) (IOFLG(1,M),M=1,6)
  213     FORMAT(1X,/1X,'OUTPUT FLAGS FOR ALL LAYERS ARE THE SAME:'/
     1     1X,'  HEAD    DRAWDOWN  HEAD  DRAWDOWN    CONC    CONC'/
     2     1X,'PRINTOUT  PRINTOUT  SAVE    SAVE    PRINTOUT  SAVE'/
     3     1X,51('-')/1X,I5,I10,I8,I8,I8,I8)
       ENDIF
      ELSE
C
C7------INCODE>0, READ IOFLG IN ENTIRETY -- IF CROSS SECTION, READ ONLY
C7------ONE VALUE.
        MM = 4
        IF(ITRNSP.NE.0) MM = 6
        IF(IXSEC.EQ.0) THEN
           DO 301 K=1,NLAY
           IF(IFREFM.EQ.0) THEN
              READ(INOC,'(5I10)') (IOFLG(K,M),M=1,MM)
           ELSE
              READ(INOC,*) (IOFLG(K,M),M=1,MM)
           END IF
           IF(MM.EQ.4) IOFLG(K,7)=0
  301      CONTINUE
           IF(MM.EQ.4)THEN
             WRITE(IOUT,302) 'OUTPUT FLAGS FOR EACH LAYER:','LAYER'
  302        FORMAT(1X,/1X,A,/
     1       1X,'         HEAD    DRAWDOWN  HEAD  DRAWDOWN'/
     2       1X,A,'  PRINTOUT  PRINTOUT  SAVE    SAVE'/
     3       1X,41('-'))
             WRITE(IOUT,303) (K,(IOFLG(K,M),M=1,MM),K=1,NLAY)
  303        FORMAT(1X,I4,I8,I10,I8,I8)
           ELSE
             WRITE(IOUT,305) 'OUTPUT FLAGS FOR EACH LAYER:','LAYER'
  305        FORMAT(1X,/1X,A,/
     1       1X,'       HEAD    DRAWDOWN  HEAD  DRAWDOWN   CONC   CONC'/
     2       1X,A,' PRINTOUT  PRINTOUT  SAVE    SAVE PRINTOUT    SAVE'/
     3       1X,41('-'))
             WRITE(IOUT,306) (K,(IOFLG(K,M),M=1,MM),K=1,NLAY)
  306        FORMAT(1X,I4,I8,I10,I8,I8,I7,I7)
           ENDIF
        ELSE
           IF(IFREFM.EQ.0) THEN
              READ(INOC,'(6I10)') (IOFLG(1,M),M=1,MM)
           ELSE
              READ(INOC,*) (IOFLG(1,M),M=1,MM)
           END IF
           WRITE(IOUT,302) 'OUTPUT FLAGS FOR CROSS SECTION:','     '
           WRITE(IOUT,304) (IOFLG(1,M),M=1,MM)
  304      FORMAT(1X,I12,I10,I8,I8,I8,I8)
        END IF
      END IF
C
C8------THE LAST STEP IN A STRESS PERIOD AND STEPS WHERE ITERATIVE
C8------PROCEDURE FAILED TO CONVERGE GET A VOLUMETRIC BUDGET.
  600 IF(ICNVG.EQ.0 .OR. KSTP.EQ.NSTP(KPER)) IBUDFL=1
C
C9------RETURN
 1000 RETURN
C
      END
      SUBROUTINE GWF2TIB1RP(IN)
C     ******************************************************************
C     READ TRANSIENT IBOUND PACKAGE DATA FOR STRESS PERIOD
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,      ONLY:IOUT,IFREFM,IUNSTR,IBOUND,HNEW,IA,JA
      USE GWFBASMODULE, ONLY: HNOFLO
      INTEGER, DIMENSION(:),ALLOCATABLE  ::ITEMP
C
      CHARACTER*24 ANAME
      CHARACTER(LEN=200) line
C
      DATA ANAME /'     ZEROED IBOUND CELLS'/
C     ------------------------------------------------------------------
C
C1------IDENTIFY PACKAGE.
      WRITE(IOUT,1)IN
    1 FORMAT(1X,/1X,'TIB -- TRANSIENT IBOUND PACKAGE, VERSION 1, ',
     1' 12/24/2012, INPUT READ FROM UNIT ',I4)
C2------READ FIRST LINE
      CALL URDCOM(In, Iout, line)
      LLOC = 1
C3------READ FLAGS
      IF(IFREFM.EQ.0)THEN
        READ(LINE,'(3I10)') NIB0,NIB1,NIBM1
      ELSE
        CALL URWORD(line, lloc, istart, istop, 2, NIB0, r, Iout, In)
        CALL URWORD(line, lloc, istart, istop, 2, NIB1, r, Iout, In)
        CALL URWORD(line, lloc, istart, istop, 2, NIBM1, r, Iout, In)
      END IF
C------------------------------------------------------------------------
C4------CHECK IF IBOUND IS TO BE ZEROED OUT.
      IF(NIB0.LE.0) THEN
C
C4A-----NIB0=<0, SO NO CELLS INACTIVATED.
        WRITE(IOUT,3)
    3   FORMAT(1X,/1X,'NO CELLS INACTIVATED FROM LAST STRESS PERIOD')
      ELSE
C
C4B-----NIB0>0, SO READ LIST OF INACTIVATED CELLS AND SET IBOUND TO ZERO
        ALLOCATE (ITEMP(NIB0))
        CALL U1DINT(ITEMP,ANAME,NIB0,0,IN,IOUT)
        DO I=1,NIB0
          ICELL = ITEMP(I)
          IBOUND(ICELL) = 0
          HNEW(ICELL) = HNOFLO
        ENDDO
        DEALLOCATE(ITEMP)
      ENDIF
C------------------------------------------------------------------------
C5------CHECK IF IBOUND IS TO BE ACTIVATED.
      IF(NIB1.LE.0) THEN
C
C5A-----NIB1=<0, SO NO CELLS ACTIVATED.
        WRITE(IOUT,4)
4       FORMAT(1X,/1X,'NO CELLS ACTIVATED FROM LAST STRESS PERIOD')
      ELSE
C
C5B-----NIB1>0, SO READ LIST OF ACTIVATED CELLS AND SET IBOUND TO 1
        DO IB=1,NIB1
C5C-------READ CELL NUMBER
          CALL URDCOM(In, Iout, line)
          LLOC = 1
          IF(IFREFM.EQ.0)THEN
            READ(LINE,'(I10)') ICELL
            LLOC = 11
          ELSE
            CALL URWORD(line, lloc, istart, istop, 2, ICELL, r,Iout, In)
          END IF
C5D--------GET OPTIONS
          IAVHEAD=0
          IHEAD = 0
          CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,I,R,IOUT,IN)
          IF(LINE(ISTART:ISTOP).EQ.'HEAD') THEN
C5D1---------READ KEYWORD OPTION FOR HEAD TO BE READ.
            IHEAD = 1
            CALL URWORD(LINE,LLOC,ISTART,ISTOP,3,I,HEAD,IOUT,IN)
          ELSEIF(LINE(ISTART:ISTOP).EQ.'AVHEAD') THEN
C5D2----------READ KEYWORD OPTION FOR AVERAGE HEAD TO BE READ.
             IAVHEAD=1
          ENDIF
C5E-----------SET IBOUND AND HEADS
          IBOUNDKP = IBOUND(ICELL)
          IBOUND(ICELL) = 1
          IF(IHEAD.EQ.1)THEN
C5E1--------HEAD IS SET TO GIVEN VALUE
            HNEW(ICELL) = HEAD
          ELSEIF(IAVHEAD.EQ.1)THEN
C5E2--------HEAD IS SET TO AVERAGE OF CONNECTING ACTIVE CELLS
            HEAD = 0.0
            ISUM = 0
            DO I=IA(ICELL)+1,IA(ICELL+1)-1
              JJ = JA(I)
              IF(IBOUND(JJ).NE.0) THEN
                HEAD = HEAD + HNEW(JJ)
                ISUM = ISUM + 1
              ENDIF
            ENDDO
            HEAD = HEAD / ISUM
            HNEW(ICELL) = HEAD
          ELSE
C5E3--------CHECK TO SEE IF NODE WAS PREVIOUSLY INACTIVE
            IF(IBOUNDKP.EQ.0)THEN
              WRITE(IOUT,11)ICELL
11            FORMAT(1X,'*** NEED TO SET HEAD IF INACTIVE CELL IS MADE'
     1        1X,'ACTIVE FOR CELL ',I9,', STOPPING ***')
              STOP
            ENDIF
          ENDIF
        ENDDO
      ENDIF
C------------------------------------------------------------------------
C6------CHECK IF IBOUND IS TO BE MADE MINUS ONE (PRESCRIBED HEAD).
      IF(NIBM1.LE.0) THEN
C
C5A-----NIBM1=<0, SO NO CELLS MADE PRESCRIBED HEAD.
        WRITE(IOUT,5)
5       FORMAT(/1X,'NO CELLS PRESCRIBED HEAD FROM LAST STRESS PERIOD')
      ELSE
C
C5B-----NIBM1>0, SO READ LIST OF PRESCRIBED HEAD CELLS AND SET IBOUND TO -1
        DO IB=1,NIBM1
C5C-------READ CELL NUMBER
          CALL URDCOM(In, Iout, line)
          LLOC = 1
          IF(IFREFM.EQ.0)THEN
            READ(LINE,'(I10)') ICELL
            LLOC = 11
          ELSE
            CALL URWORD(line, lloc, istart, istop, 2, ICELL, r,Iout, In)
          END IF
C5D--------GET OPTIONS
          IAVHEAD=0
          IHEAD = 0
          CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,I,R,IOUT,IN)
          IF(LINE(ISTART:ISTOP).EQ.'HEAD') THEN
C5D1---------READ KEYWORD OPTION FOR HEAD TO BE READ.
            IHEAD = 1
            CALL URWORD(LINE,LLOC,ISTART,ISTOP,3,I,HEAD,IOUT,IN)
          ELSEIF(LINE(ISTART:ISTOP).EQ.'AVHEAD') THEN
C5D2----------READ KEYWORD OPTION FOR AVERAGE HEAD TO BE READ.
             IAVHEAD=1
          ENDIF
C5E-----------SET IBOUND AND HEADS
          IBOUNDKP = IBOUND(ICELL)
          IBOUND(ICELL) = -1
          IF(IHEAD.EQ.1)THEN
C5E1--------HEAD IS SET TO GIVEN VALUE
            HNEW(ICELL) = HEAD
          ELSEIF(IAVHEAD.EQ.1)THEN
C5E2--------HEAD IS SET TO AVERAGE OF CONNECTING ACTIVE CELLS
            HEAD = 0.0
            ISUM = 0
            DO I=IA(ICELL)+1,IA(ICELL+1)-1
              JJ=JA(I)
              IF(IBOUND(JJ).NE.0) THEN
                HEAD = HEAD + HNEW(JJ)
                ISUM = ISUM + 1
              ENDIF
            ENDDO
            HEAD = HEAD / ISUM
            HNEW(ICELL) = HEAD
          ELSE
C5E3--------CHECK TO SEE IF NODE WAS PREVIOUSLY INACTIVE
            IF(IBOUNDKP.EQ.0)THEN
              WRITE(IOUT,12)ICELL
12            FORMAT(1X,'*** NEED TO SET HEAD IF INACTIVE CELL IS MADE'
     1        1X,'PRESCRIBED HEAD FOR CELL ',I9,', STOPPING ***')
              STOP
            ENDIF
          ENDIF
        ENDDO
      ENDIF
C
C9------RETURN
      RETURN
C
      END
      SUBROUTINE ATS1RP(KPER,INOC,IOUT)
C     ******************************************************************
C     READ PARAMETERS FOR ADAPTIVE TIME STEPPING.
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL, ONLY: NSTP,IFREFM,PERLEN,ISSFLG
      USE GWFBASMODULE, ONLY: TIMOT,DELTAT,TMINAT,TMAXAT,TADJAT,
     1    TCUTAT,NPTIMES,NPSTPS,IPEROC
C
      REAL*8 TDEL
      REAL DELTS,TMINS,TMAXS,TADJS,TCUTS
      CHARACTER*200 LINE
C     ------------------------------------------------------------------
C
C1------REFLECT ATS INPUT
      WRITE(IOUT,91)
   91 FORMAT(1X,/1X,'READING ADAPTIVE TIME STEPPING PARAMETERS')
C
C2------READ ADAPTIVE TIME-STEPPING PARAMETERS USING ORIGINAL NUMERIC STRUCTURE
      CALL URDCOM(INOC,IOUT,LINE)
      IF(IFREFM.EQ.0) THEN
            READ(LINE,'(5F10.3,2I10)')DELTAT,TMINAT,TMAXAT,TADJAT,
     1          TCUTAT,NPTIMES,NPSTPS
      ELSE
        LLOC = 1
        CALL URWORD(LINE,LLOC,ISTART,ISTOP,3,I,DELTS,IOUT,INOC)
        DELTAT = DELTS
        CALL URWORD(LINE,LLOC,ISTART,ISTOP,3,I,TMINS,IOUT,INOC)
        TMINAT = TMINS
        CALL URWORD(LINE,LLOC,ISTART,ISTOP,3,I,TMAXS,IOUT,INOC)
        TMAXAT = TMAXS
        CALL URWORD(LINE,LLOC,ISTART,ISTOP,3,I,TADJS,IOUT,INOC)
        TADJAT = TADJS
        CALL URWORD(LINE,LLOC,ISTART,ISTOP,3,I,TCUTS,IOUT,INOC)
        TCUTAT = TCUTS
      ENDIF
100   CONTINUE
C
C3------PERFORM CHECKS ON INPUT
      IF(DELTAT.LT.1.0E-20) DELTAT = 1.0
      IF(TMINAT.LT.1.0E-20) TMINAT = 1.0E-10
      IF(TMAXAT.LT.1.0E-20) TMINAT = 1.0E10
      IF(TADJAT.LT.1.0) TADJAT = 2.0
      IF(TCUTAT.LT.1.0) TCUTAT = 5.0
      IF(NPTIMES.GT.0)THEN
        IF(KPER.EQ.1)THEN
          IF(DELTAT.GT.TIMOT(1)) DELTAT = TIMOT(1)
        ELSE
          TDEL = TIMOT(KPER) - TIMOT(KPER-1)
          IF(DELTAT.GT.TDEL) DELTAT = TDEL
        ENDIF
      ENDIF
C      IF(NPSTPS.LE.0) NPSTPS=NSTP
      IF(ISSFLG(KPER).EQ.1) DELTAT = PERLEN(KPER)
C
C4------WRITE ADAPTIVE TIME STEPPING PARAMETERS TO LST FILE
      WRITE(IOUT,10) DELTAT,TMINAT,TMAXAT,TADJAT,TCUTAT
   10 FORMAT( / 5X,'INITIAL TIME STEP SIZE............(DELTAT) =',G16.8,
     1        / 5X,'MINIMUM TIME STEP SIZE............(TMINAT) =',G16.8,
     1        / 5X,'MAXIMUM TIME STEP SIZE............(TMAXAT) =',G16.8,
     1        / 5X,'MULTIPLIER FOR DELT...............(TADJAT) =',G16.8,
     1        / 5X,'DIVIDER FOR DELT..................(TCUTAT) =',G16.8)
C
C5------RETURN.
 1000 RETURN
      END
C--------------------------------------------------------------------------
      SUBROUTINE GWF2BAS7OT(KSTP,KPER,ICNVG,ISA)
C     ******************************************************************
C     OUTPUT TIME, VOLUMETRIC BUDGET, HEAD, AND DRAWDOWN
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GLOBAL,    ONLY:ITMUNI,IOUT,IUNSTR,INCLN,DDREF,STRT,NEQS,HNEW,
     1   IFMBC,MBEGWUNF,MBEGWUNT,MBECLNUNF,MBECLNUNT
      USE GWFBASMODULE,ONLY:DELT,PERTIM,TOTIM,IHDDFL,IBUDFL,
     1                      MSUM,VBVL,VBNM,IDDREF
C     ------------------------------------------------------------------
C
C
C1------CLEAR PRINTOUT FLAG (IPFLG)
      IPFLG=0
C
C
      IF(ISA.EQ.0) THEN
         WRITE(IOUT,9) KSTP,KPER
    9    FORMAT(1X,/11X,'NO FLOW EQUATION TO SOLVE IN TIME STEP',I3,
     1      ' OF STRESS PERIOD',I3,/1X,'ALL HEADS ARE 0.0')
         IPFLG=1
      END IF
C
C2------IF ITERATIVE PROCEDURE FAILED TO CONVERGE PRINT MESSAGE
      IF(ICNVG.EQ.0) THEN
         WRITE(IOUT,17) KSTP,KPER
   17    FORMAT(1X,/11X,'****FAILED TO CONVERGE IN TIME STEP',I3,
     1      ' OF STRESS PERIOD ',I4,'****')
         IPFLG=1
      END IF
C
C3------IF HEAD AND DRAWDOWN FLAG (IHDDFL) IS SET WRITE HEAD,
C3------DRAWDOWN, AND IBOUND IN ACCORDANCE WITH FLAGS IN IOFLG.
      IF(IHDDFL.EQ.0) GO TO 100
C3A-----FOR POROUS MATRIX NODES
      IF(IUNSTR.EQ.0)THEN ! WRITE M2K5 STYLE FOR STRUCTURED GRID
        CALL SGWF2BAS7H(KSTP,KPER,IPFLG,ISA)
        CALL SGWF2BAS7D(KSTP,KPER,IPFLG,ISA)
        IF(IFMBC.NE.0) CALL SGWF2BAS7F(KSTP,KPER,IPFLG,ISA)
        CALL SGWF2BAS7IB(KSTP,KPER)
      ELSE
        CALL SGWF2BAS7HU(KSTP,KPER,IPFLG,ISA)
        CALL SGWF2BAS7DU(KSTP,KPER,IPFLG,ISA)
        IF(IFMBC.NE.0) CALL SGWF2BAS7FU(KSTP,KPER,IPFLG,ISA)
        CALL SGWF2BAS7IBU(KSTP,KPER)
      ENDIF
C-------------------------------------------------------------
C3B-----FOR CONDUIT NODES
C-------------------------------------------------------------
      IF(INCLN.GT.0)THEN
        CALL SCLN1H(KSTP,KPER,IPFLG,ISA)
        CALL SCLN1D(KSTP,KPER,IPFLG,ISA)
        IF(IFMBC.NE.0) CALL SCLN1F(KSTP,KPER,IPFLG,ISA)
        CALL SCLN1IB(KSTP,KPER)
      ENDIF
C-------------------------------------------------------------
C
  100 CONTINUE

C4------PRINT TOTAL BUDGET IF REQUESTED
      IF(IBUDFL.EQ.0) GO TO 120
      CALL SGWF2BAS7V(MSUM,VBNM,VBVL,KSTP,KPER,IOUT)
      IPFLG=1
C
  120 CONTINUE
C5------RESET DRADWOWN REFERENCE ARRAY OF FLAG IS ON
      IF(IDDREF.NE.0) THEN
         IF(ASSOCIATED(DDREF,STRT)) THEN
            ALLOCATE(DDREF(NEQS))
         END IF
         DDREF=HNEW
         WRITE(IOUT,99)
   99    FORMAT(1X,'Drawdown Reference has been reset to the',
     1               ' end of this time step')
         IDDREF=0
      END IF
C
C6------END PRINTOUT WITH TIME SUMMARY AND FORM FEED IF ANY PRINTOUT
C6------WILL BE PRODUCED.
         IF(IPFLG.EQ.0) RETURN
      CALL SGWF2BAS7T(KSTP,KPER,DELT,PERTIM,TOTIM,ITMUNI,IOUT)
      WRITE(IOUT,101)
  101 FORMAT('1')
C
C7------RETURN
      RETURN
      END
C
      SUBROUTINE SGWF2BAS7T(KSTP,KPER,DELT,PERTIM,TOTIM,ITMUNI,IOUT)
C     ******************************************************************
C     PRINT SIMULATION TIME
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      DOUBLE PRECISION DELT,PERTIM,TOTIM
C     ------------------------------------------------------------------
      WRITE(IOUT,199) KSTP,KPER
  199 FORMAT(1X,///10X,'TIME SUMMARY AT END OF TIME STEP ',I9,
     1     ' IN STRESS PERIOD ',I9)
C
C1------USE TIME UNIT INDICATOR TO GET FACTOR TO CONVERT TO SECONDS.
      ZERO=0.
      CNV=ZERO
      IF(ITMUNI.EQ.1) CNV=1.
      IF(ITMUNI.EQ.2) CNV=60.
      IF(ITMUNI.EQ.3) CNV=3600.
      IF(ITMUNI.EQ.4) CNV=86400.
      IF(ITMUNI.EQ.5) CNV=31557600.
C
C2------IF FACTOR=0 THEN TIME UNITS ARE NON-STANDARD.
      IF(CNV.NE.ZERO) GO TO 100
C
C2A-----PRINT TIMES IN NON-STANDARD TIME UNITS.
      WRITE(IOUT,301) DELT,PERTIM,TOTIM
  301 FORMAT(21X,'     TIME STEP LENGTH =',G15.6/
     1       21X,'   STRESS PERIOD TIME =',G15.6/
     2       21X,'TOTAL SIMULATION TIME =',G15.6)
C
C2B-----RETURN
      RETURN
C
C3------CALCULATE LENGTH OF TIME STEP & ELAPSED TIMES IN SECONDS.
  100 DELSEC=CNV*DELT
      TOTSEC=CNV*TOTIM
      PERSEC=CNV*PERTIM
C
C4------CALCULATE TIMES IN MINUTES,HOURS,DAYS AND YEARS.
      SIXTY=60.
      HRDAY=24.
      DAYYR=365.25
      DELMN=DELSEC/SIXTY
      DELHR=DELMN/SIXTY
      DELDY=DELHR/HRDAY
      DELYR=DELDY/DAYYR
      TOTMN=TOTSEC/SIXTY
      TOTHR=TOTMN/SIXTY
      TOTDY=TOTHR/HRDAY
      TOTYR=TOTDY/DAYYR
      PERMN=PERSEC/SIXTY
      PERHR=PERMN/SIXTY
      PERDY=PERHR/HRDAY
      PERYR=PERDY/DAYYR
C
C5------PRINT TIME STEP LENGTH AND ELAPSED TIMES IN ALL TIME UNITS.
      WRITE(IOUT,200)
  200 FORMAT(19X,' SECONDS     MINUTES      HOURS',7X,
     1    'DAYS        YEARS'/20X,59('-'))
      WRITE (IOUT,201) DELSEC,DELMN,DELHR,DELDY,DELYR
  201 FORMAT(1X,'  TIME STEP LENGTH',1P,5G12.5)
      WRITE(IOUT,202) PERSEC,PERMN,PERHR,PERDY,PERYR
  202 FORMAT(1X,'STRESS PERIOD TIME',1P,5G12.5)
      WRITE(IOUT,203) TOTSEC,TOTMN,TOTHR,TOTDY,TOTYR
  203 FORMAT(1X,'        TOTAL TIME',1P,5G12.5)
C
C6------RETURN
      RETURN
      END
      SUBROUTINE SGWF2BAS7V(MSUM,VBNM,VBVL,KSTP,KPER,IOUT)
C     ******************************************************************
C     PRINT VOLUMETRIC BUDGET
C     ******************************************************************
C
C     SPECIFICATIONS:
C     ------------------------------------------------------------------
      CHARACTER*16 VBNM(MSUM)
      DOUBLE PRECISION VBVL(4,MSUM)
      CHARACTER*17 VAL1,VAL2
      DOUBLE PRECISION ZERO,TWO,HUND,BIGVL1,BIGVL2,SMALL,
     *  TOTRIN,TOTROT,TOTVIN,TOTVOT
C     ------------------------------------------------------------------
C
C1------DETERMINE NUMBER OF INDIVIDUAL BUDGET ENTRIES.
      MSUM1=MSUM-1
      IF(MSUM1.LE.0) RETURN
C
C2------CLEAR RATE AND VOLUME ACCUMULATORS.
      ZERO=0.
      TWO=2.
      HUND=100.
      BIGVL1=9.99999E11
      BIGVL2=9.99999E10
      SMALL=0.1
      TOTRIN=ZERO
      TOTROT=ZERO
      TOTVIN=ZERO
      TOTVOT=ZERO
C
C3------ADD RATES AND VOLUMES (IN AND OUT) TO ACCUMULATORS.
      DO 100 L=1,MSUM1
      TOTRIN=TOTRIN+VBVL(3,L)
      TOTROT=TOTROT+VBVL(4,L)
      TOTVIN=TOTVIN+VBVL(1,L)
      TOTVOT=TOTVOT+VBVL(2,L)
  100 CONTINUE
C
C4------PRINT TIME STEP NUMBER AND STRESS PERIOD NUMBER.
      WRITE(IOUT,260) KSTP,KPER
      WRITE(IOUT,265)
C
C5------PRINT INDIVIDUAL INFLOW RATES AND VOLUMES AND THEIR TOTALS.
      DO 200 L=1,MSUM1
      IF(VBVL(1,L).NE.ZERO .AND.
     1       (VBVL(1,L).GE.BIGVL1 .OR. VBVL(1,L).LT.SMALL)) THEN
         WRITE(VAL1,'(1PE17.4)') VBVL(1,L)
      ELSE
         WRITE(VAL1,'(F17.4)') VBVL(1,L)
      END IF
      IF(VBVL(3,L).NE.ZERO .AND.
     1       (VBVL(3,L).GE.BIGVL1 .OR. VBVL(3,L).LT.SMALL)) THEN
         WRITE(VAL2,'(1PE17.4)') VBVL(3,L)
      ELSE
         WRITE(VAL2,'(F17.4)') VBVL(3,L)
      END IF
      WRITE(IOUT,275) VBNM(L),VAL1,VBNM(L),VAL2
  200 CONTINUE
      IF(TOTVIN.NE.ZERO .AND.
     1      (TOTVIN.GE.BIGVL1 .OR. TOTVIN.LT.SMALL)) THEN
         WRITE(VAL1,'(1PE17.4)') TOTVIN
      ELSE
         WRITE(VAL1,'(F17.4)') TOTVIN
      END IF
      IF(TOTRIN.NE.ZERO .AND.
     1      (TOTRIN.GE.BIGVL1 .OR. TOTRIN.LT.SMALL)) THEN
         WRITE(VAL2,'(1PE17.4)') TOTRIN
      ELSE
         WRITE(VAL2,'(F17.4)') TOTRIN
      END IF
      WRITE(IOUT,286) VAL1,VAL2
C
C6------PRINT INDIVIDUAL OUTFLOW RATES AND VOLUMES AND THEIR TOTALS.
      WRITE(IOUT,287)
      DO 250 L=1,MSUM1
      IF(VBVL(2,L).NE.ZERO .AND.
     1       (VBVL(2,L).GE.BIGVL1 .OR. VBVL(2,L).LT.SMALL)) THEN
         WRITE(VAL1,'(1PE17.4)') VBVL(2,L)
      ELSE
         WRITE(VAL1,'(F17.4)') VBVL(2,L)
      END IF
      IF(VBVL(4,L).NE.ZERO .AND.
     1       (VBVL(4,L).GE.BIGVL1 .OR. VBVL(4,L).LT.SMALL)) THEN
         WRITE(VAL2,'(1PE17.4)') VBVL(4,L)
      ELSE
         WRITE(VAL2,'(F17.4)') VBVL(4,L)
      END IF
      WRITE(IOUT,275) VBNM(L),VAL1,VBNM(L),VAL2
  250 CONTINUE
      IF(TOTVOT.NE.ZERO .AND.
     1      (TOTVOT.GE.BIGVL1 .OR. TOTVOT.LT.SMALL)) THEN
         WRITE(VAL1,'(1PE17.4)') TOTVOT
      ELSE
         WRITE(VAL1,'(F17.4)') TOTVOT
      END IF
      IF(TOTROT.NE.ZERO .AND.
     1      (TOTROT.GE.BIGVL1 .OR. TOTROT.LT.SMALL)) THEN
         WRITE(VAL2,'(1PE17.4)') TOTROT
      ELSE
         WRITE(VAL2,'(F17.4)') TOTROT
      END IF
      WRITE(IOUT,298) VAL1,VAL2
C
C7------CALCULATE THE DIFFERENCE BETWEEN INFLOW AND OUTFLOW.
C
C7A-----CALCULATE DIFFERENCE BETWEEN RATE IN AND RATE OUT.
      DIFFR=TOTRIN-TOTROT
      ADIFFR=ABS(DIFFR)
C
C7B-----CALCULATE PERCENT DIFFERENCE BETWEEN RATE IN AND RATE OUT.
      PDIFFR=ZERO
      AVGRAT=(TOTRIN+TOTROT)/TWO
      IF(AVGRAT.NE.ZERO) PDIFFR=HUND*DIFFR/AVGRAT
C
C7C-----CALCULATE DIFFERENCE BETWEEN VOLUME IN AND VOLUME OUT.
      DIFFV=TOTVIN-TOTVOT
      ADIFFV=ABS(DIFFV)
C
C7D-----GET PERCENT DIFFERENCE BETWEEN VOLUME IN AND VOLUME OUT.
      PDIFFV=ZERO
      AVGVOL=(TOTVIN+TOTVOT)/TWO
      IF(AVGVOL.NE.ZERO) PDIFFV=HUND*DIFFV/AVGVOL
C
C8------PRINT DIFFERENCES AND PERCENT DIFFERENCES BETWEEN INPUT
C8------AND OUTPUT RATES AND VOLUMES.
      IF(ADIFFV.NE.ZERO .AND.
     1      (ADIFFV.GE.BIGVL2 .OR. ADIFFV.LT.SMALL)) THEN
         WRITE(VAL1,'(1PE17.4)') DIFFV
      ELSE
         WRITE(VAL1,'(F17.4)') DIFFV
      END IF
      IF(ADIFFR.NE.ZERO .AND.
     1      (ADIFFR.GE.BIGVL2 .OR. ADIFFR.LT.SMALL)) THEN
         WRITE(VAL2,'(1PE17.4)') DIFFR
      ELSE
         WRITE(VAL2,'(F17.4)') DIFFR
      END IF
      WRITE(IOUT,299) VAL1,VAL2
      WRITE(IOUT,300) PDIFFV,PDIFFR
C
C9------RETURN.
      RETURN
C
C    ---FORMATS
C
  260 FORMAT('1',/2X,'VOLUMETRIC BUDGET FOR ENTIRE MODEL AT END OF'
     1,' TIME STEP',I8,' IN STRESS PERIOD',I8/2X,87('-'))
  265 FORMAT(1X,/5X,'CUMULATIVE VOLUMES',6X,'L**3',7X
     1,'RATES FOR THIS TIME STEP',6X,'L**3/T'/5X,18('-'),17X,24('-')
     2//11X,'IN:',38X,'IN:'/11X,'---',38X,'---')
  275 FORMAT(1X,3X,A16,' =',A17,6X,A16,' =',A17)
  286 FORMAT(1X,/12X,'TOTAL IN =',A,14X,'TOTAL IN =',A)
  287 FORMAT(1X,/10X,'OUT:',37X,'OUT:'/10X,4('-'),37X,4('-'))
  298 FORMAT(1X,/11X,'TOTAL OUT =',A,13X,'TOTAL OUT =',A)
  299 FORMAT(1X,/12X,'IN - OUT =',A,14X,'IN - OUT =',A)
  300 FORMAT(1X,/1X,'PERCENT DISCREPANCY =',F15.2
     1,5X,'PERCENT DISCREPANCY =',F15.2,///)
C
      END
      SUBROUTINE SGWF2BAS7N(KPER,KSTP,INOC,IOUT,NLAY)
C     ******************************************************************
C     SET OUTPUT FLAGS USING ALPHABETIC OUTPUT CONTROL INPUT STRUCTURE
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      USE GWFBASMODULE, ONLY: IOFLG,IHDDFL,ISPCFL,IBUDFL,ICBCFL,IPEROC,
     1    ITSOC,IBDOPT,IATS,DELTAT,TMINAT,TMAXAT,TADJAT,TCUTAT,
     2    IDDREF,IDDREFNEW
      USE SMSMODULE, ONLY: HCLOSE,BTOL,MXITER
C
      CHARACTER*200 LINE
C     ------------------------------------------------------------------
C
C1------ERROR IF OUTPUT CONTROL TIME STEP PRECEDES CURRENT SIMULATION
C1------TIME STEP.
      IF((IPEROC.LT.KPER).OR.(IPEROC.EQ.KPER .AND. ITSOC.LT.KSTP)) THEN
         WRITE(IOUT,5) IPEROC,ITSOC,KPER,KSTP
    5    FORMAT(1X,/1X,'OUTPUT CONTROL WAS SPECIFIED FOR A NONEXISTENT',
     1   ' TIME STEP',/
     2   1X,'OR OUTPUT CONTROL DATA ARE NOT ENTERED IN ASCENDING ORDER',
     3   /1X,'OUTPUT CONTROL STRESS PERIOD ',I8,'   TIME STEP ',I8,/
     4   1X,'MODEL STRESS PERIOD ',I8,'   TIME STEP ',I8,/
     5   1X,'APPLYING THE SPECIFIED OUTPUT CONTROL TO THE CURRENT TIME',
     6   ' STEP')
         IPEROC=KPER
         ITSOC=KSTP
      END IF
C
C2------CLEAR I/O FLAGS.
      IHDDFL=0
      ISPCFL=0
      IBUDFL=0
      ICBCFL=0
      DO 10 I=1,7
      DO 10 K=1,NLAY
      IOFLG(K,I)=0
10    CONTINUE
C
C3------IF OUTPUT CONTROL TIME STEP DOES NOT MATCH SIMULATION TIME STEP,
C3------WRITE MESSAGE THAT THERE IS NO OUTPUT CONTROL THIS TIME STEP,
C3------AND RETURN.
      IF(IATS.EQ.0)THEN
        IF(IPEROC.NE.KPER .OR. ITSOC.NE.KSTP) THEN
          WRITE(IOUT,11) KPER,KSTP
11        FORMAT(1X,/1X,'NO OUTPUT CONTROL FOR STRESS PERIOD ',I8,
     1              '   TIME STEP ',I8)
          RETURN
        END IF
      ELSE
        IF(IPEROC.NE.KPER) THEN
          WRITE(IOUT,12) KPER
12        FORMAT(1X,/1X,'NO OUTPUT CONTROL FOR STRESS PERIOD ',I8)
          RETURN
        END IF
      ENDIF
C
C4------OUTPUT CONTROL TIME STEP MATCHES SIMULATION TIME STEP.
      IF(IATS.EQ.0)THEN
        WRITE(IOUT,13) IPEROC,ITSOC
13      FORMAT(1X,/1X,'OUTPUT CONTROL FOR STRESS PERIOD ',I8,
     1              '   TIME STEP ',I8)
      ELSE
        WRITE(IOUT,14) IPEROC
14      FORMAT(1X,/1X,'OUTPUT CONTROL FOR STRESS PERIOD ',I8)
      ENDIF
C4B-----SET IDDREF FLAG FROM NEW SETTING
      IDDREF=IDDREFNEW
      IF(IDDREFNEW.NE.0) WRITE(IOUT,52)
   52      FORMAT(1X,'Drawdown Reference will be reset at the',
     1               ' end of this time step')
C
C
C4A-----OUTPUT CONTROL MATCHES SIMULATION TIME.  READ NEXT OUTPUT
C4A-----RECORD; SKIP ANY BLANK LINES.
50    READ(INOC,'(A)',END=1000) LINE
      IF(LINE.EQ.' ') GO TO 50
C
C4A1----LOOK FOR "PERIOD", WHICH TERMINATES OUTPUT CONTROL FOR CURRENT
C4A1----TIME STEP.  IF FOUND, DECODE TIME STEP FOR NEXT OUTPUT.
      LLOC=1
      CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
      IF(LINE(ISTART:ISTOP).EQ.'PERIOD') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,IPEROC,R,IOUT,INOC)
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
         IF(IATS.EQ.1) GO TO 521 ! DO NOT CHECK FOR STEP FOR ADAPTIVE TIME STEPPING
c         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
         IF(LINE(ISTART:ISTOP).NE.'STEP') GO TO 2000
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,ITSOC,R,IOUT,INOC)
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
521      CONTINUE
C4A1a------SET DDREF FLAG IF KEYWORD IS SET
         IF(LINE(ISTART:ISTOP).EQ.'DDREFERENCE') THEN
           IDDREFNEW=1
         ELSE
           IDDREFNEW=0
         END IF
         RETURN
C
C4A2----LOOK FOR "PRINT", WHICH MAY REFER TO "BUDGET", "HEAD", OR
C4A2----"DRAWDOWN" OR CONCENTRATION.
      ELSE IF(LINE(ISTART:ISTOP).EQ.'PRINT') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
         IF(LINE(ISTART:ISTOP).EQ.'BUDGET') THEN
            WRITE(IOUT,53)
53          FORMAT(4X,'PRINT BUDGET')
            IBUDFL=1
         ELSE IF(LINE(ISTART:ISTOP).EQ.'HEAD') THEN
            CALL SGWF2BAS7L(1,LINE,LLOC,IOFLG,NLAY,IOUT,'PRINT HEAD',
     1              INOC)
            IHDDFL=1
         ELSE IF(LINE(ISTART:ISTOP).EQ.'DRAWDOWN') THEN
            CALL SGWF2BAS7L(2,LINE,LLOC,IOFLG,NLAY,IOUT,
     1              'PRINT DRAWDOWN',INOC)
            IHDDFL=1
         ELSE IF(LINE(ISTART:ISTOP).EQ.'CONC') THEN
            CALL SGWF2BAS7L(5,LINE,LLOC,IOFLG,NLAY,IOUT,'PRINT CONC',
     1              INOC)
            ISPCFL=1
         ELSE IF(LINE(ISTART:ISTOP).EQ.'CONCENTRATION') THEN
            CALL SGWF2BAS7L(5,LINE,LLOC,IOFLG,NLAY,IOUT,'PRINT CONC',
     1              INOC)
            ISPCFL=1
         ELSE
            GO TO 2000
         END IF
C-----------------------------------------------------------------------------
C4A3----LOOK FOR "SAVE", WHICH MAY REFER TO "BUDGET", "HEAD",
C4A3----"DRAWDOWN", OR "IBOUND" OR CONCENTRATION.
      ELSE IF(LINE(ISTART:ISTOP).EQ.'SAVE') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,1,N,R,IOUT,INOC)
         IF(LINE(ISTART:ISTOP).EQ.'BUDGET') THEN
            WRITE(IOUT,57)
57          FORMAT(4X,'SAVE BUDGET')
            ICBCFL=IBDOPT
         ELSE IF(LINE(ISTART:ISTOP).EQ.'HEAD') THEN
            CALL SGWF2BAS7L(3,LINE,LLOC,IOFLG,NLAY,IOUT,'SAVE HEAD',
     &                      INOC)
            IHDDFL=1
         ELSE IF(LINE(ISTART:ISTOP).EQ.'DRAWDOWN') THEN
            CALL SGWF2BAS7L(4,LINE,LLOC,IOFLG,NLAY,IOUT,'SAVE DRAWDOWN',
     1          INOC)
            IHDDFL=1
c          ELSE IF(LINE(ISTART:ISTOP).EQ.'IBOUND') THEN
c            CALL SGWF2BAS7L(5,LINE,LLOC,IOFLG,NLAY,IOUT,'SAVE IBOUND',
c     1                     INOC)
c            IHDDFL=1
         ELSE IF(LINE(ISTART:ISTOP).EQ.'CONC') THEN
            CALL SGWF2BAS7L(6,LINE,LLOC,IOFLG,NLAY,IOUT,'SAVE CONC',
     &                      INOC)
            ISPCFL=1
         ELSE IF(LINE(ISTART:ISTOP).EQ.'CONCENTRATION') THEN
            CALL SGWF2BAS7L(6,LINE,LLOC,IOFLG,NLAY,IOUT,'SAVE CONC',
     &                      INOC)
            ISPCFL=1
         ELSE
            GO TO 2000
         END IF
C--------------------------------------------------------------------------
C4A4-----LOOK FOR ATS PARAMETERS
       ELSEIF(LINE(ISTART:ISTOP).EQ.'DELTAT') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,3,I,DELTS,IOUT,INOC)
         DELTAT = DELTS
         WRITE(IOUT,61)DELTAT
61          FORMAT(4X,'DELTAT',G15.6)
      ELSEIF(LINE(ISTART:ISTOP).EQ.'TMINAT') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,3,I,TMINS,IOUT,INOC)
         TMINAT = TMINS
         WRITE(IOUT,62)TMINAT
62          FORMAT(4X,'TMINAT',G15.6)
      ELSEIF(LINE(ISTART:ISTOP).EQ.'TMAXAT') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,3,I,TMAXS,IOUT,INOC)
         TMAXAT = TMAXS
         WRITE(IOUT,63)TMAXAT
63          FORMAT(4X,'TMAXAT',G15.6)
      ELSEIF(LINE(ISTART:ISTOP).EQ.'TADJAT') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,3,I,TADJS,IOUT,INOC)
         TADJAT = TADJS
         WRITE(IOUT,64)TADJAT
64          FORMAT(4X,'TADJAT',G15.6)
      ELSEIF(LINE(ISTART:ISTOP).EQ.'TCUTAT') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,3,I,TCUTS,IOUT,INOC)
         TCUTAT = TCUTS
         WRITE(IOUT,65)TCUTAT
65          FORMAT(4X,'TCUTAT',G15.6)
C4A5-----LOOK FOR SOLVER PARAMETERS
      ELSEIF(LINE(ISTART:ISTOP).EQ.'HCLOSE') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,3,I,HCLOSES,IOUT,INOC)
         HCLOSE = HCLOSES
         WRITE(IOUT,66)HCLOSE
66          FORMAT(4X,'HCLOSE',G15.6)
      ELSEIF(LINE(ISTART:ISTOP).EQ.'BTOL') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,3,I,BTOLS,IOUT,INOC)
         BTOL = BTOLS
         WRITE(IOUT,67)BTOL
67          FORMAT(4X,'BTOL',G15.6)
      ELSEIF(LINE(ISTART:ISTOP).EQ.'MXITER') THEN
         CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,MXITER,R,IOUT,INOC)
         WRITE(IOUT,68)MXITER
68          FORMAT(4X,'MXITER',G15.6)
C
C4A6----WHEN NO KNOWN ALPHABETIC WORDS ARE FOUND, THERE IS AN ERROR.
      ELSE
         GO TO 2000
C
C4B-----AFTER SUCCESSFULLY DECODING ONE RECORD, READ ANOTHER.
      END IF
      GO TO 50
C
C5------END OF FILE WHILE READING AN OUTPUT CONTROL RECORD, SO THERE
C5------WILL BE NO FURTHER OUTPUT.  SET IPEROC AND ITSOC HIGH ENOUGH
C5------THAT THE MODEL TIME WILL NEVER MATCH THEM.
1000  IPEROC=9999
      ITSOC=9999
      RETURN
C
C6------ERROR DECODING ALPHABETIC INPUT STRUCTURE.
2000  WRITE(IOUT,2001) LINE
2001  FORMAT(1X,/1X,'ERROR READING OUTPUT CONTROL INPUT DATA:'/1X,A80)
      CALL USTOP(' ')
      END
      SUBROUTINE SGWF2BAS7L(IPOS,LINE,LLOC,IOFLG,NLAY,IOUT,LABEL,INOC)
C     ******************************************************************
C     WHEN USING ALPHABETIC OUTPUT CONTROL, DECODE LAYER
C     NUMBERS FOR PRINTING OR SAVING HEAD OR DRAWDOWN
C     ******************************************************************
C
C        SPECIFICATIONS:
C     ------------------------------------------------------------------
      DIMENSION IOFLG(NLAY,7)
      CHARACTER*200 LINE
      CHARACTER*(*) LABEL
      DIMENSION LAYER(999)
C     ------------------------------------------------------------------
C
C1------INITIALIZE COUNTER FOR NUMBER OF LAYERS FOR WHICH OUTPUT IS
C1------SPECIFIED.
      NSET=0
C
C2------CHECK FOR A VALID LAYER NUMBER.  WHEN FOUND, SET FLAG AND
C2------REPEAT.
10    CALL URWORD(LINE,LLOC,ISTART,ISTOP,2,L,R,-1,INOC)
      IF(L.GT.0 .AND. L.LE.NLAY) THEN
         NSET=NSET+1
         LAYER(NSET)=L
         IOFLG(L,IPOS)=1
         GO TO 10
      END IF
C
C3------DONE CHECKING FOR LAYER NUMBERS.  IF NO LAYER NUMBERS WERE
C3------FOUND, SET FLAGS FOR ALL LAYERS.
      IF(NSET.EQ.0) THEN
         DO 110 K=1,NLAY
         IOFLG(K,IPOS)=1
110      CONTINUE
         WRITE(IOUT,111) LABEL
111      FORMAT(4X,A,' FOR ALL LAYERS')
C
C4------IF ONE OR MORE LAYER NUMBERS WERE FOUND, PRINT THE NUMBERS.
      ELSE
         WRITE(IOUT,112) LABEL,(LAYER(M),M=1,NSET)
112      FORMAT(4X,A,' FOR LAYERS:',(1X,15I3))
      END IF
C
C5------RETURN.
      RETURN
      END
C
C -----------------------------------------------------------------------
      SUBROUTINE GWF2BAS7U1DA
C  DEALLOCATE GLOBAL DATA
      USE GLOBAL
      USE PARAMMODULE
      USE GWFBASMODULE
C
        DEALLOCATE(NCOL)
        DEALLOCATE(NROW)
        DEALLOCATE(NLAY)
        DEALLOCATE(NPER)
        DEALLOCATE(NBOTM)
        DEALLOCATE(NCNFBD)
        DEALLOCATE(ITMUNI)
        DEALLOCATE(LENUNI)
        DEALLOCATE(IXSEC)
        DEALLOCATE(ITRSS)
        DEALLOCATE(INBAS)
        DEALLOCATE(IFREFM)
        DEALLOCATE(NODES)
        DEALLOCATE(NEQS)
        DEALLOCATE(IOUT)
C
        DEALLOCATE(IUNIT)
        DEALLOCATE(LAYCBD)
        DEALLOCATE(LAYHDT)
        DEALLOCATE(LAYHDS)
        DEALLOCATE(ICONCV,NOCVCO,NOVFC)
        DEALLOCATE(NSTP)
        DEALLOCATE(TSMULT)
        DEALLOCATE(ISSFLG)
        DEALLOCATE(HNEW)
        DEALLOCATE(HOLD)
        DEALLOCATE(SN,SO)
        DEALLOCATE(IBOUND)
        IF(IUNSTR.EQ.0)THEN
          DEALLOCATE(DELR)
          DEALLOCATE(DELC)
        ENDIF
C
        DEALLOCATE(BOT)
        DEALLOCATE(TOP)
        DEALLOCATE(AREA)
        DEALLOCATE(PGF)
        DEALLOCATE(FAHL)
        DEALLOCATE(IVC)
        DEALLOCATE(NODLAY)
        DEALLOCATE(RHS)
        DEALLOCATE(AMAT)
        DEALLOCATE(IA)
        DEALLOCATE(JA)
        DEALLOCATE(NJAS, JAS)
        IF(INCLN.NE.0.OR.INGNC.NE.0.OR.INGNC2.NE.0.OR.INGNCn.NE.0) THEN
          DEALLOCATE(JAFL)
        ENDIF
        DEALLOCATE(INGNC,INGNC2,INGNCn,ISYMFLG)
C-------------------------------------------------------
C---------DEALLOCATE CLN DOMAIN ARRAYS
C-------------------------------------------------------
        IF(INCLN.GT.0) CALL CLN1DA
        DEALLOCATE(INCLN)
C-------------------------------------------------------
        DEALLOCATE(ISYM)
        DEALLOCATE(BUFF)
        IF(.NOT.ASSOCIATED(DDREF,STRT))
     1           DEALLOCATE(DDREF)
        DEALLOCATE(STRT)
        DEALLOCATE(IDDREF,IDDREFNEW)
C
        DEALLOCATE(ICLSUM,IPSUM,INAMLOC,NMLTAR,NZONAR,NPVAL)
        DEALLOCATE (B)
        DEALLOCATE (IACTIVE)
        DEALLOCATE (IPLOC)
        DEALLOCATE (IPCLST)
        DEALLOCATE (PARNAM)
        DEALLOCATE (PARTYP)
        DEALLOCATE (ZONNAM)
        DEALLOCATE (MLTNAM)
        DEALLOCATE (INAME)
        DEALLOCATE (RMLT)
        DEALLOCATE (IZON)
C
        DEALLOCATE(MSUM)
        DEALLOCATE(IHEDFM)
        DEALLOCATE(IHEDUN)
        DEALLOCATE(IDDNFM)
        DEALLOCATE(IDDNUN)
        DEALLOCATE(IBOUUN)
        DEALLOCATE(LBHDSV)
        DEALLOCATE(LBDDSV)
        DEALLOCATE(LBBOSV)
        DEALLOCATE(IBUDFL)
        DEALLOCATE(ICBCFL)
        DEALLOCATE(IHDDFL)
        DEALLOCATE(ISPCFL)
        DEALLOCATE(IAUXSV)
        DEALLOCATE(IBDOPT)
        DEALLOCATE(IPRTIM)
        DEALLOCATE(IFRCNVG)
        DEALLOCATE(IPEROC)
        DEALLOCATE(ITSOC)
        DEALLOCATE(ICHFLG)
        DEALLOCATE(DELT)
        DEALLOCATE(PERTIM)
        DEALLOCATE(PERLEN)
        DEALLOCATE(TOTIM)
        DEALLOCATE(HNOFLO)
        DEALLOCATE(CHEDFM)
        DEALLOCATE(CDDNFM)
        DEALLOCATE(CBOUFM)
        IF(NPTIMES.GT.0) DEALLOCATE(TIMOT)
        DEALLOCATE(IATS,NPTIMES,NPSTPS,IBUDFLAT,ICBCFLAT,IHDDFLAT)
        DEALLOCATE(DELTAT,TMINAT,TMAXAT,TADJAT,TCUTAT)
C
        DEALLOCATE(IOFLG)
        DEALLOCATE(VBVL)
        DEALLOCATE(VBNM)
        DEALLOCATE(IUNSTR)
C
        DEALLOCATE(IDEALLOC_LPF)
        DEALLOCATE(IDEALLOC_HY)
        DEALLOCATE(ITRNSP)
        DEALLOCATE(NOCVCO)
        DEALLOCATE(ICONCV)
C
        NULLIFY(IATMP,NJA)
        DEALLOCATE(CL1,CL2)
C
      RETURN
      END


