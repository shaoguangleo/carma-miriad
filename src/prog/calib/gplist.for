c************************************************************************
	program gplist
	implicit none
c
c= GpList -- List gains table and optionally overwrite calibration
c& smw
c: calibration
c+
c     GpList is a Miriad task to list the amplitude gains in a gains table
c     and (optionally) replace the amplitude information in a gains
c     table with constants of the users choosing, and/or simultaneously 
c	setting the phase corrections to zero.
c
c     WARNING: if you modify the gains, the resulting amplitude gains will be 
c              constant with time! The original gains table is overwritten.
c
c     The motivation for this routine arose from BIMA datasets in which the
c     calibrator is weak so that conventional amplitude calibration was not
c     very successful. This was compounded by old BIMA ant3 being blown about 
c     by the wind. The source, on the other hand, was strong but time
c     variable, hence not susceptible to self-cal. From observations of
c     strong planets before and after it was observed that the amplitude
c     scale was reasonably stable, and certainly more stable than implied
c     by the phase-calibrator data, so that only phase calibration really needs
c     to be applied to the source. This program allows the amplitude scale
c     to be forced to the desired values (in this case, obtained from the
c     planet observations) without changing the phase calibration.
c
c     This routine is specific to CARMA, hardcoded for 15 antennae.
c       
c@ vis
c     The input visibility file, containing the gain file to list/massage
c@ options
c     amp      List the amplitude gains: default option
c              The mean, median and rms (about the mean) are reported.
c     phase    List the phase corrections.
c     complex  List complex gains for 10 antennas only (2 lines per soln)
c     all      List all complex gains (one line per antenna per solution
c              for all antennas; lots of output, better than
c              options=complex if you want to grep one one antenna.)
c     replace  Replace the amplitude gains with the list supplied 
c              Unless OPTIONS=FORCE is also set, only antennas with 
c              non-zero values in the list are affected
c              so if jyperk is not set, nothing happens. Phases are
c              preserved unless options=zerophas is also specified
c     force    If set, then all values in jyperk are enforced when
c              doing a replace, even if they (or the initial gains)
c              are zero
c     limit    Impose an upper limit on the amplitude gains using the
c              list specified in jyperk
c     multiply Multiply existing sqrt(Jy/K) values in a gains table by
c              the list supplied in the jyperk variable. Only antennas
c              corresponding to nonzero jyperk elements are changed.
c              No effect on phases.
c     zerophas Zero all phase corrections (no antenna selection method)
c     addphase Correct gains by antenna based phases supplied in the
c              jyperk array, units degrees. Note that these phases
c              are added to the existing phase gains, except when 
c              OPTIONS=ZEROPHAS is also used.
c     clip     Set to zero all gains outside range jyperk(1),jyperk(2)
c              Useful for pseudo-flagging of bad data, e.g.,
c              gplist vis=dummy options=clip jyperk=0.5,2.0
c              effectively flags data with gains outside 0.5-2 (default 
c              range). However, data are not really flagged. The next
c              option is an alternative "flagging" option.
c     sigclip  Set to zero all gains more than jyperk(1)*rms away from 
c              median on each antenna
c     
c     Use options=replace,zerophas with suitable jyperk list to 
c     both set amp scale and zero phases (the two steps are 
c     carried out sequentially with the amplitudes being set first)
c
c     Use options=addphase to add phases to the existing ones.
c 
c     Use options=addphase,force to replace phases.
c
c@ ants
c     If given, this is the list of ants you want to see displayed.
c     Useful if you want a less wide screen display.
c     By default all are displayed, within limits.
c
c@ jyperk 
c     Array of 15 numbers (1 per antenna) giving the Jy-per-K values.
c     Array elements default to zero so you don't have to give 15 numbers.
c     Action will only be taken for antennas corresponding to nonzero 
c     elements of jyperk.
c     Used for options=replace or options=multiply. For options=replace,
c     if any of the numbers are zero then the amp gains in the pre-existing
c     table will not be changed, so you can change the gains on a single
c     antennna without changing the others by setting all the other
c     values to zero. However, be aware that your one bad antenna will
c     have affected the solutions for the other antennas as well.
c     For options=multiply, jyperk supplies a list of multiplication
c     factors (one per antenna) which will be used to multiply the 
c     sqrt(Jy/K) amplitude gains in the existing table. 
c  
c--
c  History:
c    smw     23feb95 Original version: cloned from Bob's gpaver, 
c                    complete with occasional vulgarity
c    smw     25feb95 Added 'complex' and 'zerophas' options
c    smw     25may95 Added 'multiply' option
c    smw     07sep95 Converted to 12 antennas
c    smw     01jan96 Added phase option, deleted redundant solarfix option
c    smw     17feb96 Compiled at Hat Creek and prettied up some things
c    rjs     15may96 Trivial FORTRAN standardisation.
c    smw     17dec96 Added 'limit' option 
c    smw     04nov97 Upgraded hardcoded output (necessary to fit
c                    everything into 80 character lines) to 10 antennas 
c                    with real antenna 2
c    smw     27may99 Added median output at Kartik's suggestion
c    smw     15jul99 Added rms output at Kartik's request
c    smw     06aug99 Changed output format at Kartik's request
c    smw     16aug99 Added "clip" option 
c    smw     19aug99 Added "sigclip" option 
c    smw     30aug99 Added "force" option 
c    pjt     27jul00 Fixed bug in options=phase for 10th ant
c    pjt      4aug00 smw generously allowed me to fix the write-history
c   		     'bug' when nothing was modified
c    smw     21nov03 Modified "force" option to enforce any value
c    pjt     22nov05 Increased 12 to 15 for CARMA array, use MAXGANT
c                    removed 'dbcor'
c    pjt/smw  2may06 Fixed a cut&paste error in displaying median & rms
c    jhz     20nov06 Reformated the print-out of the gain list by dynamically
c                    assigning the number of antenna gains.
c                    Keep the default for the Carma array.
c    pjt/smw 28nov06 Added new options=addphase
c    smw/pjt  8dec06 Format fiddling
c    dnf     14feb08 More format fiddling to assure spaces between columns
c    pjt     24nov08 Fix dyn mode for > 15 ants, remove options=dyn (now default)
c    pjt      5dec09 Add ants= keyword to limit the width of output
c    pjt     30jun09 Add antenna numbers (to get SZA data to work: 16..230
c                    
c  Bugs and Shortcomings:
c    fix options=complex for > 8 ants
c    missing antennas are listed as 0's, not easily distinguishable from a refant
c    phases are wrapped within -180..180, and integer, there is no options
c    unwrap here (yet), cf. options=wrap in gpplt.
c-----------------------------------------------------------------------
	include 'gplist.h'
	character version*(*)
	parameter(version='GpList: version 30-jun-09')
	logical dovec,docomp,dophas,doall,dozero,domult,hexists,doamp
	logical dolimit,doclip,dosigclip,doforce,dohist,doaddph
	real jyperk(MAXGANT) 
	character vis*80,msg*256
	integer ngains,nfeeds,ntau,nants,iostat,njyperk,i
	integer tVis,nantsd,antsd(MAXGANT)
	data jyperk /MAXGANT * 0.0/
c
c  Get the input parameters.
c
	call output(version)
	call keyini
	call keya('vis',vis,' ')
	call mkeyr('jyperk',jyperk,MAXGANT,njyperk)
	call mkeyi('ants',antsd,MAXGANT,nantsd)
	call GetOpt(doamp,dovec,docomp,dophas,doall,dozero,domult,
     *            dolimit,doclip,dosigclip,doforce,doaddph)
	call keyfin
	if(vis.eq.' ')call bug('f','An input file must be given')
c
c  Open the visibility file. Use the hio routines, as all we want to get
c  at is items for which the uvio routines have no access anyway.
c
	call hopen(tVis,vis,'old',iostat)
	if(iostat.ne.0)call AverBug(iostat,'Error opening '//vis)

      IF (.not.hexists(tVis,'gains')) then
       CALL output(' ')
       msg='There are no gains present in this dataset!!!'
       CALL output(msg)
       msg='To create a dummy gains table, run gperror!!!'
       CALL output(msg)
       CALL output(' ')
       call bug('f','Aborting now.')
      ENDIF

      IF (dovec.and.domult) then
       CALL output(' ')
       msg='options=replace,multiply should not be done together !!!'
       CALL output(msg)
       msg='You must make separate runs for each (both use jyperk)!!!'
       CALL output(msg)
       CALL output(' ')
       call bug('f','Aborting now.')
      ENDIF

c
c
c  Determine the number of feeds in the gain table.
c
      call rdhdi(tVis,'ngains',ngains,0)
      call rdhdi(tVis,'nfeeds',nfeeds,1)
      call rdhdi(tVis,'ntau',  ntau,  0)
      if(nfeeds.le.0.or.nfeeds.gt.2.or.mod(ngains,nfeeds+ntau).ne.0
     *	  .or.ntau.gt.1.or.ntau.lt.0)
     *	  call bug('f','Bad number of gains or feeds in '//vis)
	nants = ngains / (nfeeds + ntau)
      write(6,*) "Found gain entries for ",nants," antennas."
      if (nantsd.EQ.0) then
	nantsd = nants
	do i=1,nants
	  antsd(i) = i
	enddo
      endif
c
c  List/Replace the gains now.
c
      call ReplGain(tVis,dohist,
     *        doamp,dovec,docomp,dophas,doall,dozero,domult,dolimit,
     *        doclip,dosigclip,doforce,
     *        nfeeds,ntau,nants,jyperk,nantsd,antsd,
     *        doaddph)
c
c  Write out some history now.
c
      if(dohist) then
	call hisopen(tVis,'append')
	call hiswrite(tVis,'GPLIST: Miriad '//version)
	call hisinput(tVis,'GPLIST')
	call hisclose(tVis)
      endif
c
c  Close up everything.
c
	call hclose(tVis)	
	end
c***********************************************************************
       subroutine GetOpt(doamp,dovec,docomp,dophas,doall,dozero,
     &          domult,dolimit,doclip,dosigclip,doforce,doaddph)
c
	implicit none
	logical doamp,dovec,docomp,dophas,doall,dozero,domult,
     &        dolimit,doclip,dosigclip,doforce,doaddph
c
c  Get "Task Enrichment Parameters".
c
c  Output:
c    dovec	Replace amplitude gains
c    docomp List complex gains for 6 current ants
c    dozero Zero phase corrections
c    doall  full list of complex gains
c    dophas List phase gains
c    domult Multiply amplitude gains
c    dolimit Impose upper limit on gains
c    doclip Set amp gain to zero if outside absolute "normal" range
c    dosigclip Set amp gain to zero if outside relative "normal" range
c    doforce Force use of zeroes in jyperk array.
c    doaddph if true, add/replace phases instead of amps
c-----------------------------------------------------------------------
	integer nopts
	parameter(nopts=12)
	logical present(nopts)
	character opts(nopts)*8
      data opts
     &/'amp     ','complex ','replace ','zerophas','all     ',
     & 'phase   ','multiply','limit   ','clip    ','sigclip ',
     & 'force   ','addphase'/
c
	call options('options',opts,present,nopts)
      docomp = present(2)
      dovec = present(3)
      dozero = present(4)
      doall = present(5)
      dophas = present(6)
      domult = present(7)
      dolimit = present(8)
      doclip = present(9)
      dosigclip = present(10)
      doforce = present(11)
      doamp = present(1).or.present(10).or.(.not.
     &(docomp.or.dovec.or.dophas.or.doall.or.dozero.or.domult.
     &        or.dolimit.or.doclip))
      doaddph = present(12)
c
	end
c************************************************************************
	subroutine AverBug(iostat,message)
c
	implicit none
	integer iostat
	character message*(*)
c
c  Give an error message, and bugger off.
c------------------------------------------------------------------------
	call bug('w',message)
	call bugno('f',iostat)
	end
c***********************************************************************
      subroutine ReplGain(tVis,dohist,doamp,dovec,docomp,dophas,doall,
     *              dozero,domult,dolimit,doclip,dosigclip,doforce,
     *              nfeeds,ntau,nants,jyperk,nantsd,antsd,doaddph)
c
      implicit none
      include 'gplist.h'
      integer MAXSOLS,MAXGAINS
      parameter(MAXSOLS=10000,MAXGAINS=3*MAXSOLS*MAXGANT)
      logical doamp,dovec,docomp,dophas,doall,dozero,domult,dolimit,
     *        doclip,dosigclip,doforce,dohist,doaddph
      integer nfeeds,ntau,nants,tVis,j,jant(MAXGANT),k,jind(3600)
      integer nantsd,antsd(MAXGANT)
      real jyperk(MAXGANT),MeanGain(MAXGANT),radtodeg,
     *     GainArr(MAXGANT,3600),
     *     MednGain(MAXGANT), MedArr(3600), GainRms(MAXGANT), 
     *     mingain, maxgain
      logical doMed
c
c  Read and write the gains, and list gains and replace amplitudes
c
c  Gains are stored as Gains(ant,time)
c
c------------------------------------------------------------------------
        complex Gains(MAXGAINS), g
	double precision time(MAXSOLS)
	integer nsols,offset,pnt,i,m,tGains,iostat,ngains
	character line*256,ctime*10,msg*256,word*32
	character*32 fmt99,fmt198, fmt199, fmt299
        integer igains
c
c  Externals.
c
	integer hsize, len1

c
c  Data 
c
	data doMed /.false./

c
c  Open the gains table and read them all in.
c
	dohist = .FALSE.
	call haccess(tVis,tGains,'gains','read',iostat)
	if(iostat.ne.0)call AverBug(iostat,'Error opening the gains')
	nsols = (hsize(tGains)-8)/(8*nants*(nfeeds+ntau)+8)
	if(nsols.gt.MAXSOLS.or.nsols*nants*(nfeeds+ntau).gt.MAXGAINS)
     *	  call bug('f','Gain table too big for me to handle')
c
	ngains = nants*(nfeeds+ntau)
	offset = 8
	pnt = 1
	do i=1,nsols
	  call hreadd(tGains,time(i),offset,8,iostat)
	  offset = offset + 8
	  if(iostat.eq.0)call hreadr(tGains,Gains(pnt),offset,8*ngains,
     *						 iostat)
	  pnt = pnt + ngains
	  offset = offset + 8*ngains
	  if(iostat.ne.0)call Averbug(iostat,'Error reading gain table')
	enddo         
	radtodeg=180.0/3.14159

c
c  Close up.
c
	call hdaccess(tGains,iostat)
	if(iostat.ne.0)call AverBug(iostat,'Error closing gain table')

c
c  Set the dynamic format statements
c
	write(fmt99, '(a,i2,a)') '(a8,2x,',nantsd,'(f5.2,1x))'
	write(fmt299,'(a,i2,a)') '(a10,2x,',nantsd,'(f5.1,1x))'
	write(fmt198,'(a,i2,a)') '(a10,',nantsd,'i5)'
	write(fmt199,'(a,i2,a)') '(a10,',nantsd,'(1x,f6.2))'
c  
c  Now list the values read
c
      if (docomp) then
         call output('The complex gains listed in the table are:')
	 msg = '  Time     AntN 1/9     Ants 2/10     ' //
     *	       'Ants 3/11    Ants 4/12    Ants 5/13  '  //
     *	       'Ants 6/14    Ants 7/15    Ant  8/16'
         call output(msg)
c         *** TODO:  this needs some major work for dynamic ngains values
c          
	 if (ngains.gt.8) call bug('w','Better use options=all')
         do i=1,nsols
            call JulDay(time(i),'H',line(1:18))
            ctime = line(9:18)
	    write(msg,95) ctime,
     *                    (Gains((i-1)*nants+igains), igains=1,ngains)
	    call output(msg)
         enddo
      else if (doall) then
         call output('The complex gains listed in the table are:')
         do i=1,nsols
            call JulDay(time(i),'H',line(1:18))
            ctime = line(9:18)
         write(msg,96) ctime,'Ant  ',1,'   gain = ',Gains((i-1)*nants+1)
            call output(msg)
            do j=2,nants
               write(msg,97) 'Ant  ',j,'   gain = ',Gains((i-1)*nants+j)
               call output(msg)
            enddo
         enddo
      else if (dophas) then
         call output('The phase gain values listed in the table are:')
	 msg =  'Time  AntN '
	 do i=1,ngains
	    write(word,'(3x,i2)') i
	    msg = msg(1:len1(msg)) // word
	 enddo
	 call output(msg)
         do i=1,nsols
            call JulDay(time(i),'H',line(1:18))
            ctime = line(9:18)
            k=(i-1)*nants
	    write(msg,fmt198) ctime,
     *                (nint(radtodeg*
     *                atan2(AImag(Gains(k+antsd(m))),
     *                Real(Gains(k+antsd(m))))),m=1,nantsd)
            call output(msg)
         enddo
      else if (doamp) then
         do j=1,nants
            MeanGain(j)=0.0
            GainRms(j)=0.0
            jant(j)=0
         enddo
	 call output('The amplitude gain values listed '//
     *               'in the table are:')
	 msg =  'Time  AntN '
	 do i=1,ngains
	    write(word,'(5x,i2)') i
	    msg = msg(1:len1(msg)) // word
	 enddo
	 call output(msg)

	 do i=1,nsols
	    call JulDay(time(i),'H',line(1:18))
	    ctime = line(9:18)
	    write(msg,fmt199) ctime,
     *             (abs(Gains((i-1)*nants+antsd(m))), m=1,nantsd)
	    call output(msg)
	    do j=1,nants
	       if (abs(Gains((i-1)*nants+j)).gt.0.0) then
		  MeanGain(j)=MeanGain(j)+abs(Gains((i-1)*nants+j))
		  GainRms(j)=GainRms(j)+abs(Gains((i-1)*nants+j))**2
		  jant(j)=jant(j)+1
		  GainArr(j,jant(j))=abs(Gains((i-1)*nants+j))
	       endif
	    enddo
	 enddo
	 do j=1,nants
	    if (jant(j).gt.0) MeanGain(j)=MeanGain(j)/jant(j)
	    if (jant(j).gt.2) then
	       doMed = .true.
	       do k=1,jant(j)
		  MedArr(k)=GainArr(j,k)
	       enddo
	       call sortidxr( jant(j), MedArr, jind)
	       MednGain(j)=MedArr(jind(int(jant(j)/2)))
	       GainRms(j)=sqrt((GainRms(j)-
     *                    jant(j)*MeanGain(j)*MeanGain(j))/(jant(j)-1))
	    else
	       GainRms(j)=0.0
	    endif
	 enddo
	 write(msg,197) '------------------------------------',
     &               '------------------------------------'
	 call output(msg)
         write(msg,fmt199) 'Means:    ',
     *                        (MeanGain(antsd(m)),m=1,nantsd)
	 call output(msg)
	 if (doMed) then
	    write(msg,fmt199) 'Medians:  ',(MednGain(antsd(m)),
     *                                      m=1,nantsd)
	    call output(msg)
            write(msg,fmt199) 'Rms:      ', (GainRms(antsd(m)),
     *                                      m=1,nantsd)
	    call output(msg)
	 endif
	 write(msg,197) '------------------------------------',
     *                  '------------------------------------'
	 call output(msg)
      endif
c
c  Do the replacement of current amp corrections with specified list
c
      if (dovec) then
         dohist = .TRUE.
         if (doforce) then
         msg='Replacing amplitude gains with (all values enforced):'
         call output(msg)
         else
         msg='Replacing amplitude gains with (0.0 means no change):'
         call output(msg)
         end if
         write(msg,99) '          ',jyperk(1),jyperk(2),jyperk(3),
     *     jyperk(4),jyperk(5),jyperk(6),jyperk(7),jyperk(8),
     *     jyperk(9),jyperk(10),jyperk(11),jyperk(12),jyperk(13),
     *     jyperk(14),jyperk(15)
         call output(msg)
         do i=1,nsols
            do j=1,nants
        if (Gains((i-1)*nants+j).ne.cmplx(0.0,0.0)) then
               Gains((i-1)*nants+j)=
     *       jyperk(j)*Gains((i-1)*nants+j)/abs(Gains((i-1)*nants+j))
          else if (doforce) then
               Gains((i-1)*nants+j)=cmplx(jyperk(j),0.0)
          end if
            enddo
         enddo
      endif
c
c  Zero all phases
c
      if (dozero) then
         dohist = .TRUE.
         msg='Zeroing all phases: use options=complex to check.'
         call output(msg)
         do i=1,nsols
            do j=1,nants
               if (Gains((i-1)*nants+j).ne.cmplx(0.0,0.0))
     *        Gains((i-1)*nants+j)=cmplx(abs(Gains((i-1)*nants+j)),0.0)
            enddo
         enddo
      endif

c
c  Add or Set phases
c
      if(doaddph) then
         dohist = .TRUE.
         if (doforce) then
	    msg='Replacing phase gains (all values enforced):'
         else
	    msg='Replacing phase gains (0.0 means no change):'
         end if
	 call output(msg)
         write(msg,299) '          ',jyperk(1),jyperk(2),jyperk(3),
     *     jyperk(4),jyperk(5),jyperk(6),jyperk(7),jyperk(8),
     *     jyperk(9),jyperk(10),jyperk(11),jyperk(12),jyperk(13),
     *     jyperk(14),jyperk(15)
         call output(msg)
         do i=1,nsols
            do j=1,nants
	       g = cmplx(cos(jyperk(j)/radtodeg),
     *                   sin(jyperk(j)/radtodeg))

	       if (doforce) then
		  Gains((i-1)*nants+j)= g * abs(Gains((i-1)*nants+j))
	       else
		  Gains((i-1)*nants+j) = g * Gains((i-1)*nants+j) 
	       end if
            enddo
         enddo
      endif

c
c  Multiply amplitudes by arbitrary numbers supplied in jyperk
c
      if (domult) then
         dohist = .TRUE.
         msg='Multiplying sqrt(Jy/K) by (1 per antenna):'
         call output(msg)
         write(msg,99) 'sqrt(Jy/K) x ',jyperk(1),jyperk(2),jyperk(3),
     *     jyperk(4),jyperk(5),jyperk(6),jyperk(7),jyperk(8),
     *     jyperk(9),jyperk(10),jyperk(11),jyperk(12),jyperk(13),
     *     jyperk(14),jyperk(15)
         call output(msg)
         do i=1,nsols
            do j=1,nants
        if (Gains((i-1)*nants+j).ne.cmplx(0.0,0.0).and.jyperk(j).ne.0.0) 
     *   Gains((i-1)*nants+j)=jyperk(j)*Gains((i-1)*nants+j)
            enddo
         enddo
      endif
c
c  Impose upper limit on amp gains using numbers supplied in jyperk
c
      if (dolimit) then
         dohist = .TRUE.
         msg='Imposing upper limits on gains of:'
         call output(msg)
         write(msg,99) ' ',jyperk(1),jyperk(2),jyperk(3),
     *     jyperk(4),jyperk(5),jyperk(6),jyperk(7),jyperk(8),
     *     jyperk(9),jyperk(10),jyperk(11),jyperk(12),jyperk(13),
     *     jyperk(14),jyperk(15)
         call output(msg)
         do i=1,nsols
            do j=1,nants
        if (Gains((i-1)*nants+j).ne.cmplx(0.0,0.0).and.jyperk(j).ne.0.0.
     *       and.abs(Gains((i-1)*nants+j)).gt.jyperk(j)) 
     *   Gains((i-1)*nants+j)=
     *      jyperk(j)*Gains((i-1)*nants+j)/abs(Gains((i-1)*nants+j))
            enddo
         enddo
      endif
c
c  "Clip": set gains to zero if outside "normal" range
c
      if (doclip) then
         dohist = .TRUE.
         k = 0
         if (jyperk(1).eq.0.0) jyperk(1)=0.5
         if (jyperk(2).eq.0.0) jyperk(2)=2.0
         write(msg,93) 'Clipping gains outside range:',jyperk(1),
     *                 jyperk(2)
         call output(msg)
         do i=1,nsols
            do j=1,nants
        if (Gains((i-1)*nants+j).ne.cmplx(0.0,0.0).and.
     *       ((abs(Gains((i-1)*nants+j)).lt.jyperk(1)).or.
     *         abs(Gains((i-1)*nants+j)).gt.jyperk(2))) then
                  Gains((i-1)*nants+j)=cmplx(0.0,0.0)
                  k = k + 1
               end if
            enddo
         enddo
         write(msg,92) 'Clipped ',k,' antenna-interval pairs.'
         call output(msg)
      endif
c
c  "SigClip": set gains to zero if outside relative "normal" range
c             doamp must have already run to get Median and Rms
c
      if (dosigclip) then
         dohist = .TRUE.
         k = 0
         if (jyperk(1).eq.0.0) jyperk(1)=3.0
         write(msg,91) 'Clipping gains outside range:',jyperk(1),
     *                  ' sigma'
         call output(msg)
         do j=1,nants
            mingain = MednGain(j)-jyperk(1)*GainRms(j)
            maxgain = MednGain(j)+jyperk(1)*GainRms(j)
            do i=1,nsols
        if (Gains((i-1)*nants+j).ne.cmplx(0.0,0.0).and.
     *     (GainRms(j).ne.0.0).and.
     *       ((abs(Gains((i-1)*nants+j)).lt.mingain).or.
     *         abs(Gains((i-1)*nants+j)).gt.maxgain)) then
                  Gains((i-1)*nants+j)=cmplx(0.0,0.0)
                  k = k + 1
               end if
            enddo
         enddo
         write(msg,92) 'Clipped ',k,' antenna-interval pairs.'
         call output(msg)
      endif


      if (.NOT.dohist) return
c
c  Now write out the new gain solutions.
c
	call wrhdi(tVis,'nsols',nsols)
	call haccess(tVis,tGains,'gains','write',iostat)
	if(iostat.ne.0)call AverBug(iostat,'Error reopening gain table')
c
	call hwritei(tGains,0,0,4,iostat)
	if(iostat.ne.0)
     *	  call AverBug(iostat,'Error writing gain table preamble')
c
	offset = 8
	pnt = 1
	do i=1,nsols
	  call hwrited(tGains,time(i),offset,8,iostat)
	  offset = offset + 8
	  if(iostat.eq.0)call hwriter(tGains,Gains(pnt),offset,8*ngains,
     *								 iostat)
	  pnt = pnt + ngains
	  offset = offset + 8*ngains
	  if(iostat.ne.0)call Averbug(iostat,'Error writing gain table')
	enddo
c
	call hdaccess(tGains,iostat)
	if(iostat.ne.0)call AverBug(iostat,'Error reclosing gain table')
c
199   format(a8,15(1x,f6.2))
198   format(a8,15i5)
197   format(a36,a36)
299   format(a10,2x,15(f5.1,1x))
99    format(a8,2x,15(f5.2,1x))
97    format(10x,a,i2,a,f9.3,f9.3)
96    format(a8,2x,a,i2,a,f9.3,f9.3)
95    format(a10,1x,8(f5.2,1x,f5.2,2x))
93    format(a30,1x,f5.2,1x,f5.2)
92    format(a9,1x,i4,a25)
91    format(a30,1x,f5.2,1x,a6)
	end
c************************************************************************
