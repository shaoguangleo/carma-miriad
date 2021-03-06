c**********************************************************************
c* Powell -- Minimization of a function, without derivative information.
c& bpw
c: optimization,mathematics
c+
      subroutine powell(x,e,n,f,escale,icon,mxiter,calcfx,w,maxfun,
     *                  ifail)
c
      implicit none
      integer n,icon,mxiter,maxfun,ifail
      real f,escale
      real x(n),e(n),w(n*(n+3))
      external calcfx
c
c  1) Purpose.
c  This subroutine finds the minimum of a function of several
c  variables. It requires no derivatives. the user must provide a
c  routine to evaluate the function for any values of the variables.
c  i.e. the program will find a minimum of a function , f ,of n
c  variables where
c            f = f(x(1),x(2),x(5),...x(n))
c
c  Briefly the method used is:
c  Starting from a point x(1),x(2),...,x(n) the program constructs
c  n+1 lines through the point and searches for a minimum of f along
c  each line calling calcfx for appropriate values of f as it goes.
c  x(1),x(2),x(5),x(6),....,x(n) are then re-set.   each set of n+1
c  searches is called an iteration. Iterations continue until the
c  minimum is found.
c
c  2) Arguments:
c
c    n          must be set to the number of variables.
c
c    x and e    These are one dimensional arrays.  On entry to the
c               routine x(i) must be set to an approximation to the ith
c               variable and e(i) to the accuracy to which its optimum
c               value is required.  On exit x(i) will be set to the
c               calculated optimum value of the ith variable.  It is
c               assumed that the magnitudes of the parameters e(i) are
c               approximately proportional to the magnitudes of the
c               corresponding variables x(i).
c
c    f          Thus will be set to the minimum value of the function.
c
c    escale     This limits the maximum change in the variables at a
c               single step.  x(i) will not be changed by more than
c               escale*e(i).
c
c    icon       This must be set to 1 or 2. It controls the ultimate
c               convergence criterion (see section 5).
c
c    maxit      The routine will be left regarless after maxit
c    maxfun     iterations have been completed, or maxfun function
c               evaluations.
c
c    w          Scratch array.
c
c    ifail      Error return.
c               Ifail = 0:   Success
c                       1    Maximum change does not alter function
c                       2    Accuracy limited by errors in calcfx.
c                       3    Max iterations performed within Powell
c                       4    Max function values evaluated in Powell
c
c  3) Method.
c  This will be published by m.j.d. powell in the july or october
c  1964. computer journal. The minimum will practically never be
c  found in less than n iteration. The function is calculated at
c  least 2n times per iteration. The method is such that each
c  iteration causes the function to decrease, except when the
c  ultimate convergence criterion is being applied with icon=2.
c
c  4) Subroutine calcfx.
c     subroutine calcfx (n,x,f)
c  must be provided by the user. n is the number of variables. x(i)
c  x(2),.....x(n) are the current values of the variables. It must
c  set f to the corresponding value of the function to be minimized.
c  Remember that as calcfx is the name of a subroutine and is one
c  of the arguments of powell  calcfx must appear in an external
c  statement in any subprogram calling powell.
c  e.g.
c     external calcfx
c
c  5) The ultimate convergence criterion.
c  This will normally be satisfactory if icon is set to one.
c  However if low accuracy is required or if it is suspected that the
c  required accuracy is not being achieved. icon should be set to two
c  and a more thorough check on the ultimate convergence will be
c  made at the expense of increasing the execution time by maybe
c  as much as 30 per cent. With icon=1 convergence will be assumed
c  when an iteration changes each variable by less than 10 per cent
c  of the required accuracy. With icon=2 such a point is found and it
c  is then displaced by ten times the required accuracy in each
c  variable. Minimization is continued from the new point until a
c  change of less than 10per cent is again made by an iteration. The
c  two estimate of the minimum are then compared.
c
c  6) Recommendations.
c  a) Do not set escale so small that powell must creep slowly to the
c  minimum, it is only there to prevent the unlikely circumstance of
c  a jump from one local minimum to another. this usually wont
c  happen even if  escale is large(10**9).
c  b) Set the required accuracy so that sscale is at least 100,
c  c) If the answers appear to be unreasonable, try different
c  initial values of the variables x(i).
c
c  7) Reference.
c     Powell M.J.D. (1964)  An efficient method for finding the
c     minimum of a function of several variables without calculating
c     derivatives. The Computer Journal, vol. 7, p. 303.
c--
c  History:
c    rjs Dark-ages Stolen from somewhere.
c    rjs  25jan90  Minor documentation improvement.
c
c $Id$
c----------------------------------------------------------------------
      integer nfcc,i,j,jj,jjj,k,ind,inn,iterc,isgrad,itone,ixp,idirn
      integer iline,is,jil
      real scer,ddmag,fkeep,fp,sum,dmax,ddmax,dmag,dacc,dl,d,da,dd,fa
      real fprev,fb,db,fc,dc,fi,di,a,b,fhold,aaa

      ifail = 0
      ddmag = 0.1*escale
      scer  = 0.05/escale
      jj  = n*n + n
      jjj = jj + n
      k = n + 1
      nfcc = 1
      ind = 1
      inn = 1
      do 2 i = 1, n
        do 1 j = 1, n
          w(k) = 0.0
          if (i.eq.j) then
            w(k) = abs(e(i))
            w(i) = escale
          end if
          k = k + 1
1       continue
2     continue

      iterc=1
      isgrad=2
      call calcfx(n,x,f)
      fkeep=abs(f)+abs(f)

5     itone = 1
      fp=f
      sum=0.
      ixp=jj
      do 6 i=1,n
        ixp=ixp+1
        w(ixp)=x(i)
6     continue

      idirn=n+1
      iline=1
7     dmax=w(iline)
      dacc=dmax*scer
      dmag=amin1 (ddmag,0.1*dmax)
      dmag=amax1(dmag,20.*dacc)
      ddmax=10.*dmag
      if (itone.eq.3) go to 71
      dl=0.
      d=dmag
      fprev=f
      is=5
      fa=f
      da=dl
8     dd=d-dl
      dl=d
58    k=idirn
      do 9 i=1,n
        x(i)=x(i)+dd*w(k)
        k=k+1
9     continue
      call calcfx(n,x,f)
      nfcc=nfcc+1
      if (nfcc.gt.maxfun) go to 999
      go to (10,11,12,13,14,96),is


14    if (f.lt.fa) then
        fb = f
        db = d
      else if (f.eq.fa) then
        if (abs(d).gt.dmax) then
          ifail = 1
          return
        end if
        d = d + d
        go to 8
      else
c       Maximum change does not alter function.
        fb = fa
        db = da
        fa = f
        da = d
      end if

      go to (83,23),isgrad
23    d=db+db-da
      is=1
      go to 8
83    d=0.5*(da+db-(fa-fb)/(da-db))
      is=4
      if ((da-d)*(d-db).ge.0.0) go to 8
25    is=1
      if (abs(d-db).le.ddmax) go to 8
26    d=db+sign (ddmax,db-da)
      is=1
      ddmax=ddmax+ddmax
      ddmag=ddmag+ddmag
      if (ddmax.le.dmax) go to 8
      ddmax=dmax
      go to 8
13    if (f.ge.fa) go to 23
28    fc=fb
      dc=db
29    fb=f
      db=d
      go to 30
12    if (f.le.fb) go to 28
      fa=f
      da=d
      go to 30
11    if (f.ge.fb) go to 10
      fa=fb
      da=db
      go to 29
71    dl=1.
      ddmax=5.
      fa=fp
      da=-1.
      fb=fhold
      db=0.
      d=1.
10    fc=f
      dc=d
30    a=(db-dc)*(fa-fc)
      b=(dc-da)*(fb-fc)
      if ((a+b)*(da-dc).le.0.0) then
        fa=fb
        da=db
        fb=fc
        db=dc
        go to 26
      end if

      d=0.5*(a*(db+dc)+b*(da+dc))/(a+b)
      di=db
      fi=fb
      if (fb.gt.fc) then
        di=dc
        fi=fc
      end if

      if (itone.eq.3) then
        itone = 2
      else
        if (abs(d-di).le.dacc) go to 41
        if (abs(d-di).le.0.03*abs(d)) go to 41
      end if

      if ((da-dc)*(dc-d).ge.0.0) then
        fa=fb
        da=db
        fb=fc
        db=dc
        go to 25
      end if
      is=2
      if ((db-d)*(d-dc).lt.0.0) is = 3
      go to 8

41    f=fi
      d=di-dl
      dd=((dc-db)*(dc-da)*(da-db)/(a+b))
      dd=sqrt(abs(dd))
      do 49 i=1,n
        x(i)=x(i)+d*w(idirn)
        w(idirn)=dd*w(idirn)
        idirn=idirn+1
49    continue
      w(iline)=w(iline)/dd
      iline=iline+1
      if (itone.eq.2) go to 38
      if (fprev.ge.f+sum) then
        sum=fprev-f
        jil=iline
      end if
      if (idirn.le.jj) go to 7
      if (ind.eq.2) go to 53
92    fhold=f
      is=6
      ixp=jj
      do 59 i=1,n
        ixp=ixp+1
        w(ixp)=x(i)-w(ixp)
59    continue
      dd=1.
      go to 58
96    if (ind.ne.2) then
        if (fp.le.f) go to 37
        d=2.*(fp+f-2.*fhold)/(fp-f)**2
        if (d*(fp-fhold-sum)**2.ge.sum) go to 37
      end if
      j=jil*n+1
      if (j.le.jj) then
        do 62 i=j,jj
          k=i-n
          w(k)=w(i)
62      continue
        do 97 i=jil,n
          w(i-1)=w(i)
97      continue
      end if
      idirn=idirn-n
      itone = 3
      k=idirn
      ixp=jj
      aaa=0.
      do 65 i=1,n
        ixp=ixp+1
        w(k)=w(ixp)
        if (aaa.lt.abs(w(k)/e(i))) aaa = abs(w(k)/e(i))
        k=k+1
65    continue
      ddmag=1.
      w(n)=escale/aaa
      iline=n
      go to 7

37    ixp=jj
      aaa=0.
      f=fhold
      do 99 i=1,n
        ixp=ixp+1
        x(i)=x(i)-w(ixp)
        if (aaa*abs(e(i)).lt.abs(w(ixp))) aaa = abs(w(ixp)/e(i))
99    continue
      go to 53
38    aaa=aaa*(1.+di)
      if (ind.eq.2) go to 106
53    if (ind.eq.2) go to 88
      if (aaa.le.0.1) then
        if (icon.eq.1)return
        ind = 2
        if (inn.eq.2) go to 101
        inn = 2
        k = jjj
        do 102 i = 1, n
          k = k + 1
          w(k) = x(i)
          x(i) = x(i) + 10.0*e(i)
102     continue
        fkeep = f
        call calcfx (n,x,f)
        nfcc = nfcc + 1
        if (nfcc.gt.maxfun) go to 999
        ddmag = 0.0
        go to 108
      end if

      if (f.lt.fp) go to 35
c
c  Accuracy limited by errors in calcfx
c
      ifail = 2
      return
88    ind=1
35    ddmag=0.4*sqrt(abs(fp-f))
      isgrad=1
108   iterc=iterc+1
      if (iterc.le.mxiter) goto 5
c
c  Max iterations performed
c
      ifail = 3
      if (f.le.fkeep) return
      f=fkeep
      do 111 i=1,n
        jjj=jjj+1
        x(i)=w(jjj)
111   continue
      return

101   jil = 1
      fp=fkeep
      if (f.eq.fkeep) then
        ifail = 2
        return
      else if (f.gt.fkeep) then
        jil = 2
        fp = f
        f  = fkeep
      end if

      ixp=jj
      do 113 i=1,n
        ixp=ixp+1
        k=ixp+n
        if (jil.eq.1) then
          w(ixp)=w(k)
        else
          w(ixp)=x(i)
          x(i)=w(k)
        end if
113   continue
      jil=2
      go to 92
106   if (aaa.le.0.1) return
      inn=1
      go to 35
c
c  Max function values evaluated in powell.
c
 999  ifail = 4
      return
      end
