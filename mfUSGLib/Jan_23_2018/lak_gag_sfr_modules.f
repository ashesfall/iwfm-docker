C
      MODULE GWFLAKMODULE
C------VERSION 7;   CREATED FOR MODFLOW-2005
        CHARACTER(LEN=64),PARAMETER ::Version_lak =
     +'$Id: gwf2lak7_dev.f 2370 2011-01-27 17:35:48Z rniswon $'
        INTEGER,SAVE,POINTER   ::NLAKES,NLAKESAR,ILKCB,NSSITR,LAKUNIT
        INTEGER,SAVE,POINTER   ::MXLKND,LKNODE,ICMX,NCLS,LWRT,NDV,NTRB,
     +                           IRDTAB
        REAL,   SAVE,POINTER   ::THETA,SSCNCR,SURFDEPTH
Cdep    Added SURFDEPTH  3/3/2009
Crgn    Added budget variables for GSFLOW CSV file
        REAL,   SAVE,POINTER   ::TOTGWIN_LAK,TOTGWOT_LAK,TOTDELSTOR_LAK
        REAL,   SAVE,POINTER   ::TOTSTOR_LAK,TOTEVAP_LAK,TOTPPT_LAK
        REAL,   SAVE,POINTER   ::TOTRUNF_LAK,TOTWTHDRW_LAK,TOTSURFIN_LAK
        REAL,   SAVE,POINTER   ::TOTSURFOT_LAK
        INTEGER,SAVE, DIMENSION(:),  POINTER ::ICS, NCNCVR, LIMERR, 
     +                                         LAKTAB
        INTEGER,SAVE, DIMENSION(:,:),POINTER ::ILAKE,ITRB,IDIV,ISUB,IRK
        INTEGER,SAVE, DIMENSION(:),ALLOCATABLE ::LKARR1
        REAL,   SAVE, DIMENSION(:),  POINTER ::STAGES
        DOUBLE PRECISION,SAVE,DIMENSION(:), POINTER ::STGNEW,STGOLD,
     +                                        STGITER,VOLOLDD,STGOLD2
        REAL,   SAVE, DIMENSION(:),  POINTER ::VOL,FLOB,DSRFOT
        DOUBLE PRECISION,   SAVE, DIMENSION(:),  POINTER ::PRCPLK,EVAPLK
        REAL,   SAVE, DIMENSION(:),  POINTER ::BEDLAK
        REAL,   SAVE, DIMENSION(:),  POINTER ::WTHDRW,RNF,CUMRNF
        REAL,   SAVE, DIMENSION(:),  POINTER ::CUMPPT,CUMEVP,CUMGWI
        REAL,   SAVE, DIMENSION(:),  POINTER ::CUMUZF
        REAL,   SAVE, DIMENSION(:),  POINTER ::CUMGWO,CUMSWI,CUMSWO
        REAL,   SAVE, DIMENSION(:),  POINTER ::CUMWDR,CUMFLX,CNDFCT
        REAL,   SAVE, DIMENSION(:),  POINTER ::VOLINIT
        REAL,   SAVE, DIMENSION(:),  POINTER ::BOTTMS,BGAREA,SSMN,SSMX
Cdep    Added cumulative and time step error budget arrays
        REAL,   SAVE, DIMENSION(:),  POINTER ::CUMVOL,CMLAKERR,CUMLKOUT
        REAL,   SAVE, DIMENSION(:),  POINTER ::CUMLKIN,TSLAKERR,DELVOL
crgn        REAL,   SAVE, DIMENSION(:),  POINTER ::EVAP,PRECIP,SEEP,SEEP3
        DOUBLE PRECISION,   SAVE, DIMENSION(:),  POINTER ::EVAP,PRECIP
        DOUBLE PRECISION,   SAVE, DIMENSION(:),  POINTER ::EVAP3,PRECIP3
        DOUBLE PRECISION,   SAVE, DIMENSION(:),  POINTER ::FLWITER
        DOUBLE PRECISION,   SAVE, DIMENSION(:),  POINTER ::FLWITER3
        DOUBLE PRECISION,   SAVE, DIMENSION(:),  POINTER ::SEEP,SEEP3
        DOUBLE PRECISION,   SAVE, DIMENSION(:),  POINTER ::SEEPUZ
        DOUBLE PRECISION,   SAVE, DIMENSION(:),  POINTER ::WITHDRW
        DOUBLE PRECISION,   SAVE, DIMENSION(:),  POINTER ::SURFA
        REAL,   SAVE, DIMENSION(:),  POINTER ::SURFOT,SURFIN
        REAL,   SAVE, DIMENSION(:),  POINTER ::SUMCNN,SUMCHN
        REAL,   SAVE, DIMENSION(:,:),POINTER ::CLAKE,CRNF,SILLVT
        REAL,   SAVE, DIMENSION(:,:),POINTER ::CAUG,CPPT,CLAKINIT
        REAL,   SAVE, DIMENSION(:),POINTER ::BDLKN1
Cdep  Added arrays for tracking lake budgets for dry lakes
        REAL,   SAVE, DIMENSION(:),  POINTER ::EVAPO,FLWIN
        REAL,   SAVE, DIMENSION(:),  POINTER ::GWRATELIM
Cdep    Allocate arrays to add runoff from UZF Package
        REAL,   SAVE, DIMENSION(:),  POINTER ::OVRLNDRNF,CUMLNDRNF
Cdep    Allocate arrays for lake depth, area,and volume relations
        DOUBLE PRECISION,   SAVE, DIMENSION(:,:),  POINTER ::DEPTHTABLE
        DOUBLE PRECISION,   SAVE, DIMENSION(:,:),  POINTER ::AREATABLE
        DOUBLE PRECISION,   SAVE, DIMENSION(:,:),  POINTER ::VOLUMETABLE
Cdep    Allocate space for three dummy arrays used in GAGE Package
C         when Solute Transport is active
        REAL,   SAVE, DIMENSION(:,:),POINTER ::XLAKES,XLAKINIT,XLKOLD
Crsr    Allocate arrays in BD subroutine
        INTEGER,SAVE, DIMENSION(:),  POINTER ::LDRY,NCNT,NCNST,KSUB
        INTEGER,SAVE, DIMENSION(:),  POINTER ::MSUB1
        INTEGER,SAVE, DIMENSION(:,:),POINTER ::MSUB
        REAL,   SAVE, DIMENSION(:),  POINTER ::FLXINL,VOLOLD,GWIN,GWOUT
        REAL,   SAVE, DIMENSION(:),  POINTER ::DELH,TDELH,SVT,STGADJ
      END MODULE GWFLAKMODULE
C-------------------------------------------------------------------------------------
      MODULE GWFGAGMODULE
        INTEGER,SAVE,POINTER  ::NUMGAGE
        INTEGER,SAVE,  DIMENSION(:,:),  POINTER :: IGGLST
      END MODULE GWFGAGMODULE
C-------------------------------------------------------------------------------------
      MODULE GWFSFRMODULE
        CHARACTER(LEN=64),PARAMETER:: Version_sfr =
     +'$Id: gwf2sfr7.f 3394 2007-06-06 01:31:28Z deprudic $'   
        DOUBLE PRECISION,PARAMETER :: NEARZEROSFR=1.0D-30    
        DOUBLE PRECISION,SAVE,POINTER:: THETAB, FLUXB, FLUXHLD2, HEPS
        REAL,PARAMETER :: CLOSEZEROSFR=1.0E-15
        INTEGER, SAVE :: Nfoldflbt, NUMTAB, MAXVAL, NSEGDIM
        INTEGER,SAVE,  DIMENSION(:),  POINTER:: DVRCH   
        INTEGER,SAVE,  DIMENSION(:,:,:),POINTER:: DVRCELL 
        REAL,   SAVE,  DIMENSION(:,:),POINTER:: RECHSAVE  
        REAL,   SAVE,  DIMENSION(:,:),POINTER:: DVRPERC 
        REAL,   SAVE,  DIMENSION(:),POINTER:: DVEFF
        INTEGER,SAVE,POINTER:: NSS, NSTRM, NSFRPAR, ISTCB1, ISTCB2
        INTEGER,SAVE,POINTER:: IUZT, MAXPTS, IRTFLG, NUMTIM
        INTEGER,SAVE,POINTER:: ISFROPT, NSTRAIL, ISUZN, NSFRSETS
        INTEGER,SAVE,POINTER:: NUZST, NSTOTRL, NUMAVE
        INTEGER,SAVE,POINTER:: ITMP, IRDFLG, IPTFLG, NP
        REAL,   SAVE,POINTER:: CONST, DLEAK, WEIGHT, SFRRATIN, SFRRATOUT
        REAL   ,SAVE,POINTER:: FLWTOL, STRMDELSTOR_CUM, STRMDELSTOR_RATE
        DOUBLE PRECISION,SAVE,POINTER:: TOTSPFLOW
        INTEGER,SAVE,  DIMENSION(:),  ALLOCATABLE:: IOTSG, NSEGCK
        INTEGER,SAVE,  DIMENSION(:),  ALLOCATABLE:: ITRLSTH
        INTEGER,SAVE,  DIMENSION(:,:),ALLOCATABLE:: ISEG, IDIVAR, ISTRM
        INTEGER,SAVE,  DIMENSION(:,:),ALLOCATABLE:: LTRLIT, LTRLST
        INTEGER,SAVE,DIMENSION(:,:),ALLOCATABLE:: ITRLIT, ITRLST, NWAVST
        REAL,   SAVE, DIMENSION(:),  ALLOCATABLE:: STRIN, STROUT, FXLKOT
        REAL,   SAVE, DIMENSION(:),  ALLOCATABLE:: UHC, SGOTFLW, DVRSFLW
        REAL,   SAVE,  DIMENSION(:),  ALLOCATABLE:: SFRUZBD
        REAL,   SAVE,  DIMENSION(:,:),ALLOCATABLE:: SEG, STRM, SFRQ
        REAL,   SAVE,  DIMENSION(:,:),ALLOCATABLE:: HWDTH, HWTPRM
        REAL,   SAVE,  DIMENSION(:,:),ALLOCATABLE:: QSTAGE, XSEC
        REAL,   SAVE,  DIMENSION(:,:),ALLOCATABLE:: AVDPT, AVWAT, WAT1
        REAL,  SAVE,DIMENSION(:,:),ALLOCATABLE:: CONCQ, CONCRUN, CONCPPT
        REAL,   SAVE,  DIMENSION(:,:),POINTER:: TABFLOW, TABTIME
        INTEGER,SAVE,  DIMENSION(:,:),POINTER:: ISFRLIST          
        DOUBLE PRECISION,SAVE,DIMENSION(:),  ALLOCATABLE:: THTS,THTR,EPS
        DOUBLE PRECISION,SAVE,DIMENSION(:), ALLOCATABLE:: FOLDFLBT, THTI
        DOUBLE PRECISION,SAVE,DIMENSION(:), ALLOCATABLE:: SUMLEAK,SUMRCH
        DOUBLE PRECISION,SAVE,DIMENSION(:),  ALLOCATABLE:: HLDSFR
        DOUBLE PRECISION,SAVE,DIMENSION(:,:),ALLOCATABLE:: UZFLWT,UZSTOR
        DOUBLE PRECISION,SAVE,DIMENSION(:,:),ALLOCATABLE:: UZWDTH,UZSEEP
        DOUBLE PRECISION,SAVE,DIMENSION(:,:),ALLOCATABLE::DELSTOR,WETPER
        DOUBLE PRECISION,SAVE,DIMENSION(:,:),ALLOCATABLE:: UZDPIT,UZDPST
        DOUBLE PRECISION,SAVE,DIMENSION(:,:),ALLOCATABLE:: UZTHIT,UZTHST
        DOUBLE PRECISION,SAVE,DIMENSION(:,:),ALLOCATABLE:: UZSPIT,UZSPST
        DOUBLE PRECISION,SAVE,DIMENSION(:,:),ALLOCATABLE:: UZFLIT,UZFLST
        DOUBLE PRECISION,SAVE,DIMENSION(:,:),ALLOCATABLE::UZOLSFLX,HSTRM
        DOUBLE PRECISION,SAVE,DIMENSION(:,:),ALLOCATABLE::QSTRM,SLKOTFLW
        DOUBLE PRECISION,SAVE,DIMENSION(:,:),ALLOCATABLE:: DLKOTFLW,
     +    DLKSTAGE
        INTEGER,SAVE:: IHAVEDIV
      END MODULE GWFSFRMODULE

      MODULE GWFSFRBLK
        DOUBLE PRECISION,PARAMETER :: NEARZERO=1.0D-30
!        DOUBLE PRECISION,SAVE :: THETAB, FLUXB, FLUXHLD2
        REAL,PARAMETER :: CLOSEZERO=1.0E-15
      END MODULE GWFSFRBLK
C
C
C     ******************************************************************
C     CHECK FOR STEAMBED BELOW CELL BOTTOM. RECORD REACHES FOR PRINTING
C     ******************************************************************
      MODULE ICHKSTRBOT_MODULE
      USE GWFSFRMODULE,ONLY:ISTRM,STRM,NSTRM
      USE GLOBAL,ONLY:BOT,IBOUND
      implicit none
      type check_bot
        integer ltype,IRCHNUM,iflag,iunit
      end type check_bot      
      public check_bot
      CONTAINS
      FUNCTION ICHKSTRBOT(self)
      type (check_bot), intent(in) :: self
      INTEGER NRCH,JSEG,ISEG,ICHKSTRBOT
      ICHKSTRBOT = 0
      JSEG = ISTRM(4,self%IRCHNUM)
      ISEG = ISTRM(5,self%IRCHNUM)
      NRCH = ISTRM(6, self%IRCHNUM)
      IF ( self%LTYPE.GT.0  .AND. IBOUND(NRCH).GT.0 ) THEN 
        IF ( STRM(4, self%IRCHNUM)-BOT(NRCH).LT.-1.0E-12 ) THEN
          IF ( self%IFLAG.EQ.0 ) THEN
          WRITE(self%IUNIT,*)
          WRITE(self%IUNIT,*)' REACHES WITH ALTITUDE ERRORS:'
          WRITE(self%IUNIT,*)'   NRCH    SEG  REACH      ',
     +                'STR.ELEV.      CELL-BOT.'
          END IF
          WRITE(self%IUNIT,100)NRCH,JSEG,ISEG,
     +                STRM(4, self%IRCHNUM),BOT(NRCH)
          ICHKSTRBOT = 1
        END IF
      END IF
      IF ( self%IFLAG.GT.0 .AND. self%IRCHNUM.EQ.NSTRM ) THEN
        WRITE(self%IUNIT,*)' MODEL STOPPING DUE TO REACH ALTITUDE ERROR'
        CALL USTOP(' ')
      END IF
  100 FORMAT(3I7,2F15.7)
      END FUNCTION ICHKSTRBOT
      END MODULE ICHKSTRBOT_MODULE
