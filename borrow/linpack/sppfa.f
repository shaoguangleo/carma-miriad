C***********************************************************************
c*SPPFA -- Factor a real symmetric positive definite matrix in packed form.
c:LINPACK
c+
      SUBROUTINE SPPFA(AP,N,INFO)
      INTEGER N,INFO
      REAL AP(1)
C
C     SPPFA FACTORS A REAL SYMMETRIC POSITIVE DEFINITE MATRIX
C     STORED IN PACKED FORM.
C
C     SPPFA IS USUALLY CALLED BY SPPCO, BUT IT CAN BE CALLED
C     DIRECTLY WITH A SAVING IN TIME IF	 RCOND	IS NOT NEEDED.
C     (TIME FOR SPPCO) = (1 + 18/N)*(TIME FOR SPPFA) .
C
C     ON ENTRY
C
C	 AP	 REAL (N*(N+1)/2)
C		 THE PACKED FORM OF A SYMMETRIC MATRIX	A .  THE
C		 COLUMNS OF THE UPPER TRIANGLE ARE STORED SEQUENTIALLY
C		 IN A ONE-DIMENSIONAL ARRAY OF LENGTH  N*(N+1)/2 .
C		 SEE COMMENTS BELOW FOR DETAILS.
C
C	 N	 INTEGER
C		 THE ORDER OF THE MATRIX  A .
C
C     ON RETURN
C
C	 AP	 AN UPPER TRIANGULAR MATRIX  R , STORED IN PACKED
C		 FORM, SO THAT	A = TRANS(R)*R .
C
C	 INFO	 INTEGER
C		 = 0  FOR NORMAL RETURN.
C		 = K  IF THE LEADING MINOR OF ORDER  K	IS NOT
C		      POSITIVE DEFINITE.
C
C
C     PACKED STORAGE
C
C	   THE FOLLOWING PROGRAM SEGMENT WILL PACK THE UPPER
C	   TRIANGLE OF A SYMMETRIC MATRIX.
C
C		 K = 0
C		 DO 20 J = 1, N
C		    DO 10 I = 1, J
C		       K = K + 1
C		       AP(K) = A(I,J)
C	      10    CONTINUE
C	      20 CONTINUE
C
C--
C     LINPACK.	THIS VERSION DATED 08/14/78 .
C     CLEVE MOLER, UNIVERSITY OF NEW MEXICO, ARGONNE NATIONAL LAB.
C
C     SUBROUTINES AND FUNCTIONS
C
C     BLAS SDOT
C     FORTRAN SQRT
C
C     INTERNAL VARIABLES
C
      REAL SDOT,T
      REAL S
      INTEGER J,JJ,JM1,K,KJ,KK
C     BEGIN BLOCK WITH ...EXITS TO 40
C
C
	 JJ = 0
	 DO 30 J = 1, N
	    INFO = J
	    S = 0.0E0
	    JM1 = J - 1
	    KJ = JJ
	    KK = 0
	    IF (JM1 .LT. 1) GO TO 20
	    DO 10 K = 1, JM1
	       KJ = KJ + 1
	       T = AP(KJ) - SDOT(K-1,AP(KK+1),1,AP(JJ+1),1)
	       KK = KK + K
	       T = T/AP(KK)
	       AP(KJ) = T
	       S = S + T*T
   10	    CONTINUE
   20	    CONTINUE
	    JJ = JJ + J
	    S = AP(JJ) - S
C     ......EXIT
	    IF (S .LE. 0.0E0) GO TO 40
	    AP(JJ) = SQRT(S)
   30	 CONTINUE
	 INFO = 0
   40 CONTINUE
      RETURN
      END
