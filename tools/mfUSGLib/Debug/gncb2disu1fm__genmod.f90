        !COMPILER-GENERATED INTERFACE MODULE: Mon Jan 06 10:29:20 2020
        MODULE GNCB2DISU1FM__genmod
          INTERFACE 
            SUBROUTINE GNCB2DISU1FM(NGNCB,GNCB,IRGNCB,ISYMGNCB,MXADJB,  &
     &MXGNCB,BOTB,ICONSTRAINTB)
              INTEGER(KIND=4) :: MXGNCB
              INTEGER(KIND=4) :: MXADJB
              INTEGER(KIND=4) :: NGNCB
              REAL(KIND=4) :: GNCB(4+2*MXADJB,MXGNCB)
              INTEGER(KIND=4) :: IRGNCB(MXADJB,MXGNCB)
              INTEGER(KIND=4) :: ISYMGNCB
              REAL(KIND=4) :: BOTB(MXGNCB)
              INTEGER(KIND=4) :: ICONSTRAINTB
            END SUBROUTINE GNCB2DISU1FM
          END INTERFACE 
        END MODULE GNCB2DISU1FM__genmod
