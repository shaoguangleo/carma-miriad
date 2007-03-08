c************************************************************************
	program atlod
	implicit none
c
c= atlod - Convert an RPFITS file into Miriad uv format.
c& rjs
c: data transfer
c+
c	ATLOD is a MIRIAD task, which converts a uv data-set from the RPFITS
c	format to Miriad format.
c@ in
c	Name of the input RPFITS files. Several names can be given -- wildcard
c	expansion is supported. If a single name is given, this can be a raw
c	tape device name (e.g. /dev/nrst0 in UNIX) containing several files.
c	In this case, see the NFILES keyword below. There is no default. 
c@ out
c	Name of the output Miriad uv data-set. No default.
c@ ifsel
c	IF number to select.  Default is all IFs.  For example,
c	if you observed with 5 GHz (frequency 1) and 8 GHz (frequency 2) 
c	simultaneously, IF 1 would be the 5 GHz data and IF 2 would 
c	be the 8 GHz data.
c@ restfreq
c	The rest frequency, in GHz, for line observations.  By default,
c	the value in the RPFITS file is used.  Giving a value for the
c	"restfreq" parameter overrides the RPFITS file value. If you
c	do set this parameter, you MUST give the same number of values as the
c	number of IFs written out. A value of 0 is used for a continuum
c	observation. For example, if you have two IFs, the first of
c	which is HI, and the second is continuum, use
c	    restfreq=1.420405752,0
c@ options
c	This gives extra processing options. Several can be given,
c	separated by comas.
c	  'birdie'  ATCA self-interference can corrupt channels at integral
c	            multiples of 128 MHz. The birdie option flags these
c	            channels. Additionally, in continuum (33 channels/128MHz)
c	            mode, the birdie option dicards every second channel, plus
c	            some edge channels. The channels discarded
c	            are those most likely affected by the self-interference.
c	            Discarding these channels does not have a
c	            sensitivity penalty, because the effective channel
c	            bandwidth is twice the channel separation.
c	  'reweight' Re-weight the lag spectrum to eliminate the "Gibbs" phenomena.
c	  'compress' Write output data in compressed format.
c	  'noauto'  Discard autocorrelation data. The default is to
c	            copy the autocorrelation data.
c	  'nocross' Discard cross-correlation data. The default is to
c	            copy the cross correlation data.
c	  'relax'   Do not flag visibilities based on SYSCAL information.
c	            The default is to flag visibilities if they have
c	            not been preceded by a valid SYSCAL record, or if the
c	            the values in the SYSCAL record look bad. SYSCAL
c	            values are checked for sampler statistics being within
c	            3% of 17.3%, or 0.5% of 50.0%, that the XY phase
c	            is within 10 degrees of its running median, and that
c	            the XY amplitudes are within 1 Jy or 10% of its running
c	            median. The tests for xy phase and amplitude are
c	            skipped for 3mm data (as there is no noise calibration
c	            signal).
c         'mmrelax' This option is ignored, and is present for historical
c	            reasons.
c	  'unflag'  Save any data that is flagged. By default ATLOD
c	            discards most data that is flagged.
c	  'opcorr'  Correct for atmospheric opacity. This option is possible
c	            for data measured after October 2003. It should not be
c	            used for 3mm data. Generally it is only relevant for
c	            12mm observations.
c	  'samcorr' Correct the pre-Dec93 data for incorrect sampler
c	            statistics. Since December 1993, sampler corrections
c	            are performed online -- Miriad ignores the samcorr
c	            option for this data.
c	  'xycorr'  Apply the on-line measurement of the XY phase.
c	  'hanning' Hanning smooth spectra and drop every other channel
c	            This option is ignored for 128-MHz, 33-channel data.
c	  'bary'    Use the barycentre as the velocity rest frame. The
c	            default is to use the LSR frame.
c	  'noif'    Do not map the simultaneous IFs to the IF axis.
c	            By default ATLOD attempts to map the simultaneous
c	            frequencies to the IF axis. This will not be possible
c	            if there are a different number of polarisations in
c	            the different IFs.
c	  'nopflag' If at least one polarisation of a set of 2 or 4 polarimetric
c	            spectra are bad, ATLOD normally flags all of the
c	            polarisations. Option nopflag changes this so that only
c	            the nominally bad spectrum is flagged.
c	  'hires'   Treat bin data as measurements in the high time resolution
c	            mode. The output dataset contains no bins, but instead
c	            appears as data measured with small cycle times.
c	  'pmps'    Undo `poor man's phase switching'. This is an obscure option
c	            that you should not generally use.
c	  'single'  Assume input is a single dish RPFITS file (from Mopra or
c	            Parkes). This is usually used together with option 'relax'.
c	  'caldata' Save visibilities associated with certain system
c	            calibrations. Currently this consists of reference pointing
c	            calibration and "paddle" measurements.
c	  'nocacal' Flag data that atlod suspects is taken during a CACAL scann.
c		    There is potential for error in atlod determining which data
c		    are and are not part of a cacal scan. Use this with caution.
c         'nopol'   Discard data that is not "parallel hand" Stokes type.
c@ nfiles
c	This gives one or two numbers, being the number of files to skip,
c	followed by the number of files to process. This is only
c	useful when the input is a tape device containing multiple files.
c	The default is 0,1 (i.e. skip none, process 1 file).
c
c	NOTE: Using this feature to skip many files on a tape is VERY
c	inefficient. It is far faster to skip using operating system commands.
c	When doing this, however, you should be aware is that every RPFITS files
c	consists of 3 tape files. Thus you will want to skip three times as
c	many tape files as RPFITS files. For example, in UNIX, to skip 10
c	RPFITS files, use
c	            mt -f /dev/nrst0 fsf 30
c@ nscans
c	This gives one or two numbers, being the number of scans to skip,
c	followed by the number of scans to process. NOTE: This applies to
c	all files read. The default is to skip none and process all scans.
c--
c
c  History:
c    rjs  12feb91 Original version.
c    rjs  20feb91 Eliminated my confusion between "files" and "scans". Precessed
c		  J2000 RA,DEC to get obsra,obsdec.
c    nebk 06mar91 Add XYPHASE array
c    nebk 12may91 Broke it, to give rjs the shits.
c    rjs  16may91 Fixed it, to spite nebk.
c    rjs  17may91 Fixed the headache of the sign of the XY phase and the
c		  if_invert switch.
c    rjs  19may91 noapply option. Calculates and prints out average XY phase.
c    rjs  12jun91 Make the default restfreq the value of if_freq.
c    rjs  13jun91 Subtracted (rather than adding) 45 deg to chi.
c    rjs  17jun91 Fiddled with XYPHASE and CHI some more.
c    rjs  21jul91 Write out xsampler, ysampler, xyamp variables.
c    rjs  13dec91 Deleted obstype processing (now done in uvio).
c    rjs  22jul92 Implemented nfiles processing.
c    rjs  28aug92 Doc changges only.
c    nebk 07sep92 Incredibly stupid mistake.  Only Mr. S could do it.
c                 VIS and WEIGHT were not dimensioned big enough.
c		  Also include MIRCONST.H in ATLOD.H for pi
c    rjs  11sep92 Add number of scans to skip.
c    rjs  14sep92 Better messages. Write antenna coordinates and LST,
c		  as well as jiggery pokery with antenna numbers and XY phase.
c    rjs  18sep92 Write out X and Y Tsys separately.
c    rjs  21sep92 Get XYPHASE right (I think!).
c    rjs  28oct92 Sign of XY phase was wrong for 2nd IF in 2 IF system
c		  when the 2 IFs had different sideband indicators.
c    nebk 02feb93 Deal with all RPFITSIN error conditions explicitly
c                 and look for next scan if I/O error occurs
c    rjs  16mar93 Better (?) AsciiCpy.
c    rjs  29mar93 Change value of jyperk.
c    rjs  27oct93 Change treatment of xy phases. Add sampler correction.
c    nebk 28oct93 Add keywords ifsel,restfreq and options=hanning
c    rjs  17nov93 Rewritten.
c    rjs  25nov93 Eliminate spurious messages after the start of a scan.
c    rjs  13dec93 Sign convention of V change.
c    rjs  27jan94 Fix bug which mislabelled polarisations when
c		  options=noif. Minor formating improvements. Robustness to
c		  i/o errors.
c    rjs  14mar94 INTBASE change.
c    rjs   8apr94 Readd disabling of sampler correction after 11Dec93. Where did
c		  this mod disappear to?
c    rjs  29aug94 w axis changes.
c    rjs   2sep94 Read multiple files.
c    rjs  21sep94 Change sign convention for XY and YX. Discard dettached
c		  antennas.
c    rjs   3nov94 Eliminate spurious error message.
c    rjs  28nov94 Be more strict about what sampler stats are OK.
c    rjs  13jan95 Friday 13th! Add pulsar bin no as uv variable.
c    rjs  25jan95 Write the fudged source name (rather than just
c		  discarding it!!).
c    nebk 18feb95 Write out a correct fudged source name rather than
c		  a totally scrambled one.  Mr. S must be on drugs again.
c    nebk 03mar95 Add options=birdie and record file names in history.
c    rjs  14mar95 Discard channels for options=birdie.
c    rjs  27mar95 Options=reweight.
c    rjs  26apr95 Make options=unflag always behave as advertised.
c    rjs  20sep95 Option=birdie flags the birdie channel in spectral
c		  line mode.
c    rjs  27sep95 Flagging stats. Will Mr K still whinge? Probably!
c    rjs   6nov95 xycorr option.
c    rjs  29may96 Write out nbin variable.
c    rjs  02jul96 Changes to honour the proper motion parameters.
c    rjs  16jul96 Flagged all polarisation if any bad, and added nopflag
c		  option.
c    rjs  17jul96 Flag if there are glitches in the XY amplitude.
c    rjs  22nov96 Reset median-based flaggers after a scan change.
c    rjs  05dec96 Write pointing centre RA and DEC if needed.
c    rjs  03feb97 Better error messages, and make it more robust to multibeam
c		  datasets. NOTE: To change it so that multibeam datasets
c		  can be read:
c		  * Set ATANT to 15 in atlod.h
c		  * Comment out checks for invalid antennas in antchk
c		  * Get rid of skip when jstat.eq.5 in RPDISP.
c    rjs  22sep97 Replace call to fdatejul with dayjul.
c    rjs  07jan98 Better printing of source names.
c    rjs  06apr98 Increase the max size of an integration.
c    rjs  07may98 Change in handling of jstat.eq.5 return value.
c    rjs  14may98 Handle higher time resolution.
c    rjs  04oct98 Extra check for validity of a record.
c    rjs  12nov98 options=hires now supports high time resolution bin mode.
c    rjs  31aug99 Check for bad RPFITS value for sdf.
c    rjs  11jun00 Include pmps switch. More robust to bad number of channels
c		  etc in RPFITS file. Increase buffer space.
c    dpr  10apr01 Add cluge for correlator UT day rollover bug.
c    dpr  11apr01 ATANT=8 in atlog.h
c    rjs  22may02 Added options=mmrelax
c    rjs  25may02 Generate "tcorr" variable to keep track of whether
c		  Tsys scaling has been performed or not.
c    rjs  16jul03 Do not flip sign of XY and YX correlations for 12mm
c                 package.
c    rjs  19jul03 Removed option=mmrelax, and made this automatic!
c    rjs  06dec03 Write out met data, axisrms, axismax data. options=opcorr
c    rjs  30dec03 Doc change only.
c    rjs  15feb04 Save input RPFITS name and calcode.
c    rjs  10jun04 Handle change in xy correlation at 12mm.
c    rjs  11sep04 Add rain guage and seeing monitor data to output.
c    rjs  23oct04 Fix pntra and pntdec bug - always write them out.
c    rjs  16jun05 Detect CACAL data. Better flagging stats messages.
c    rjs  17sep05 Correct date for sampler correction code.
c    rjs  15oct05 Check for buffer overflows. Increase buffer size. Better
c	          flagging statistics.
c    rjs  02jan06 Save reference pointing information. 8MHz debirdie algorithm.
c		  Added nopol option.
c    rjs  14jan06 Be relaxed about missing met data scans when applying
c		  opacity correction.
c
c  Program Structure:
c    Miriad atlod can be divided into three rough levels. The high level
c    gets input parameters, opens the output, and tells the appropriate
c    subroutines what to do.
c
c    The RP layer is the layer which interacts with RPFITSIN and the RPFITS
c    common. It "dispatch" routine (RPDISP) waits for an integration to
c    start, and then calls the Poke routines in the order:
c	Poke1st (start an integration)
c	PokeMisc,PokeAnt,PokeIF,PokeSrc (if these have changed)
c	PokeSC (syscal info), PokeData (corr data).
c	PokeFlsh (finish the integration)
c    Prioir to calling the Poke routines, RPDISP discards unneeded
c    data and maps the selected frequencies notional IFs.
c    The RP layer is in charge of data selection.
c
c    The Poke layer buffers up information about the current integration,
c    and flushes it to the output file when all is ready. The Poke
c    layer is in charge of any massaging that needs to be done to the
c    data (e.g. hanning smoothing, sampler correction).
c------------------------------------------------------------------------
	integer MAXFILES,MAXTIMES
	parameter(MAXFILES=128,MAXTIMES=32)
	character version*(*)
	parameter(version='AtLod: version 1.0 02-Jan-06')
c
	character in(MAXFILES)*128,out*64,line*64,t1*18,t2*18
	integer tno,ntimes
	integer ifile,ifsel,nfreq,iostat,nfiles,i
	double precision rfreq(2),times(2,MAXTIMES)
	logical doauto,docross,docomp,dosam,relax,unflag,dohann
	logical dobary,doif,birdie,dowt,dopmps,doxyp,doop
	logical polflag,hires,sing,docaldat,nocacal,nopol
	integer fileskip,fileproc,scanskip,scanproc
c
c  Externals.
c
	character rperr*32,itoaf*8
c
c  Get the input parameters.
c
	call output(version)
	call keyini
	call mkeyf('in',in,MAXFILES,nfiles)
	if(nfiles.eq.0)
     *	  call bug('f','Input name must be given')
	call keya('out',out,' ')
	if(out.eq.' ')
     *	  call bug('f','Output name must be given')
        call keyi('ifsel',ifsel,0)
        call mkeyd('restfreq',rfreq,2,nfreq)
	call getopt(doauto,docross,docaldat,docomp,dosam,doxyp,doop,
     *	  relax,
     *	  sing,unflag,dohann,birdie,dobary,doif,dowt,dopmps,
     *	  nopol,polflag,
     *	  hires,nocacal)
	call keyi('nfiles',fileskip,0)
	call keyi('nfiles',fileproc,nfiles-fileskip)
	if(nfiles.gt.1.and.fileproc+fileskip.gt.nfiles)
     *	  fileproc = nfiles - fileskip
	if(fileskip.lt.0.or.fileproc.lt.1)
     *	  call bug('f','Invalid NFILES parameter')
	call keyi('nscans',scanskip,0)
	call keyi('nscans',scanproc,0)
	if(scanskip.lt.0.or.scanproc.lt.0)
     *	  call bug('f','Invalid NSCANS parameter')
	call keyfin
c
	call cacalIni
c
c  Open the output and initialise it.
c
	call uvopen(tno,out,'new')
	if(.not.docomp)call uvset(tno,'corr','r',0,0.,0.,0.)
	call uvset(tno,'preamble','uvw/time/baseline',0,0.,0.,0.)
	call Fixed(tno,dobary)
c
c  Do some history processing.
c
	call hisopen(tno,'write')
	call hiswrite(tno,'ATLOD: Miriad '//version)
	call hisinput(tno,'ATLOD')
c
c  Process a number of files.
c
	ifile = 0
	iostat = 0
	dowhile(ifile.lt.fileskip+fileproc.and.iostat.eq.0)
	  ifile = ifile + 1
	  if(ifile.le.fileskip)then
	    if(nfiles.eq.1)then
	      call output('Skipping file '//itoaf(ifile))
	      call RPSkip(in(1),iostat)
	    else
	      call output('Ignoring file '//in(ifile))
	      iostat = 0
	    endif
	    if(iostat.ne.0)call bug('f','Error skipping RPFITS file')
	  else
	    call PokeIni(tno,dosam,doxyp,doop,dohann,birdie,dowt,
     *		dopmps,dobary,doif,hires)
	    if(nfiles.eq.1)then
	      i = 1
	    else
	      i = ifile
	    endif
	    if(i.ne.ifile)then
	      call liner('Processing file '//itoaf(ifile))
	    else
	      call liner('Processing file '//in(ifile))
	    endif
	    call RPDisp(in(i),scanskip,scanproc,doauto,docross,
     *		docaldat,relax,sing,unflag,nopol,polflag,ifsel,
     *		rfreq,nfreq,iostat)
	  endif
	enddo
c
c  Close up shop.
c
	if(iostat.ne.0)then
	  line = 'RPFITS i/o error: '//rperr(iostat)
	  call bug('w',line)
	  call bug('w','Prematurely finishing because of errors')
	  call hiswrite(tno,'ATLOD: '//line)
	  call hiswrite(tno,
     *		 'ATLOD: Prematurely finishing because of errors')
	endif
	call uvflush(tno)
c
c  Report on what appear to be runs on cacal.
c
	call cacalFin(times,MAXTIMES,ntimes)
	call liner(' ')
	if(ntimes.eq.0)call liner('No CACAL data was detected')
	do i=1,ntimes
	  call julday(times(1,i),'H',t1)
	  call julday(times(2,i),'H',t2)
	  line = 'Probable CACAL data from '//t1//' to '//t2
	  call liner(line)
	enddo
c
c  All said and done.
c
	call hisclose(tno)
	call uvclose(tno)
c
	if(nocacal.and.ntimes.gt.0)then
	  call output('Flagging probable CACAL data ...')
	  call uvopen(tno,out,'old')
	  call caflag(tno,times,ntimes)
	  call uvclose(tno)
	endif
c
	end
c************************************************************************
	subroutine caflag(tno,times,ntimes)
c
	implicit none
	integer tno,ntimes
	double precision times(2,ntimes)
c------------------------------------------------------------------------
	include 'maxdim.h'
	complex data(MAXCHAN)
	logical flags(MAXCHAN),doflag
	double precision preamble(4),time
	integer nchan,i
c
	call uvrewind(tno)
	call uvread(tno,preamble,data,flags,MAXCHAN,nchan)
	dowhile(nchan.gt.0)
	  doflag = .false.
	  time = preamble(3)
	  do i=1,ntimes
	    doflag = doflag.or.
     *		     (times(1,i).le.time.and.time.lt.times(2,i))
	  enddo
	  if(doflag)then
	    do i=1,nchan
	      flags(i) = .false.
	    enddo
	    call uvflgwr(tno,flags)
	  endif
	  call uvread(tno,preamble,data,flags,MAXCHAN,nchan)
	enddo
c
	end
c************************************************************************
	subroutine GetOpt(doauto,docross,docaldat,docomp,dosam,doxyp,
     *	  doop,relax,sing,
     *	  unflag,dohann,birdie,dobary,doif,dowt,dopmps,
     *	  nopol,polflag,hires,nocacal)
c
	implicit none
	logical doauto,docross,dosam,relax,unflag,dohann,dobary,doop
	logical docomp,doif,birdie,dowt,dopmps,doxyp,polflag,hires,sing
	logical docaldat,nocacal,nopol
c
c  Get the user options.
c
c  Output:
c    doauto	Set if the user want autocorrelation data.
c    docross	Set if the user wants cross-correlation data.
c    docaldat	Do not flag calibration data.
c    docomp	Write compressed data.
c    dosam	Correct for sampler statistics.
c    doxyp	Correct the data with the measured xy phase.
c    doop	Correct for opacity.
c    dohann     Hanning smooth spectra
c    birdie	Discard bad channels in continuum mode.
c    doif	Map the simultaneous frequencies to the IF axis.
c    relax
c    unflag
c    dobary	Compute barycentric radial velocities.
c    birdie
c    dowt	Reweight the lag spectrum.
c    dopmps	Undo "poor man's phase switching"
c    nopol	Select only parallel-hand polarisations.
c    polflag	Flag all polarisations if any are bad.
c    hires      Convert bin-mode to high time resolution data.
c    sing	Single dish mode.
c------------------------------------------------------------------------
	integer nopt
	parameter(nopt=21)
	character opts(nopt)*8
	logical present(nopt)
	data opts/'noauto  ','nocross ','compress','relax   ',
     *		  'unflag  ','samcorr ','hanning ','bary    ',
     *		  'noif    ','birdie  ','reweight','xycorr  ',
     *		  'opcorr  ',
     *		  'nopflag ','hires   ','pmps    ','mmrelax ',
     *		  'single  ','caldata ','nocacal ','nopol   '/
	call options('options',opts,present,nopt)
	doauto = .not.present(1)
	docross = .not.present(2)
	docomp  = present(3)
	relax   = present(4)
	unflag  = present(5)
	dosam   = present(6)
        dohann  = present(7)
	dobary  = present(8)
	doif    = .not.present(9)
	birdie  = present(10)
	dowt    = present(11)
	doxyp   = present(12)
	doop    = present(13)
	polflag = .not.present(14)
	hires   = present(15)
	dopmps  = present(16)
c
c  Option mmrelax is now ignored (set automatically!).
c	mmrelax = present(16)
	sing    = present(18)
	docaldat= present(19)
	nocacal = present(20)
	nopol   = present(21)
c
	if((dosam.or.doxyp.or.doop).and.relax)call bug('f',
     *	  'You cannot use options samcorr, xycorr or opcorr with relax')
	end
c************************************************************************
	subroutine Fixed(tno,dobary)
c
	implicit none
	integer tno
	logical dobary
c
c  This updates variables that never change.
c
c  Input:
c    tno	Handle of the output uv data-set.
c    dobary	Velocity restframe is the barycentre.
c------------------------------------------------------------------------
	double precision latitude,longitud,dtemp
	real chioff
	integer mount
	logical ok
c
	call uvputvrr(tno,'epoch',2000.,1)
	call uvputvrr(tno,'vsource',0.,1)
	call obspar('ATCA','latitude',latitude,ok)
	if(ok)call obspar('ATCA','longitude',longitud,ok)
	if(ok)call obspar('ATCA','evector',dtemp,ok)
	if(ok)chioff = dtemp
	if(ok)call obspar('ATCA','mount',dtemp,ok)
	if(ok)mount = dtemp
	if(.not.ok)then
	  call bug('w','Unable to determine telescope lat/long')
	else
	  call uvputvrd(tno,'latitud',latitude,1)
	  call uvputvrd(tno,'longitu',longitud,1)
	  call uvputvrr(tno,'evector',chioff,1)
	  call uvputvri(tno,'mount',mount,1)
	endif
c
	if(dobary)then
	  call uvputvra(tno,'veltype','VELO-HEL')
	else
	  call uvputvra(tno,'veltype','VELO-LSR')
	endif
	end
c************************************************************************
c************************************************************************
	subroutine PokeIni(tno1,dosam1,doxyp1,doop1,
     *		dohann1,birdie1,dowt1,dopmps1,dobary1,doif1,hires1)
c
	implicit none
	integer tno1
	logical dosam1,doxyp1,dohann1,doif1,dobary1,birdie1,dowt1
	logical dopmps1,hires1,doop1
c
c  Initialise the Poke routines.
c------------------------------------------------------------------------
	include 'atlod.h'
	integer bl,p,if,bin
	logical ok
c
	sname  = ' '
	tno    = tno1
	dosam  = dosam1
	doxyp  = doxyp1
	opcorr = doop1
	dohann = dohann1
	doif   = doif1
	dobary = dobary1
	birdie = birdie1
	dowt   = dowt1
	dopmps = dopmps1
	hires  = hires1
c
	if(dowt)call LagWt(wts,2*ATCONT-2,0.04)
c
	newsc = .false.
	newfreq = .false.
	nants = 0
	nifs = 0
	nused = 0
	do if=1,ATIF
	  nstoke(if) = 0
	  nfreq(if) = 0
	enddo
c
c  Reset the counters, etc.
c
	do if=1,ATIF
	  nbin(if) = 0
	enddo
	inttim = 0
	do bin=1,ATBIN
	  do bl=1,ATBASE
	    do p=1,ATPOL
	      do if=1,ATIF
	        pnt(if,p,bl,bin) = 0
	      enddo
	    enddo
	  enddo
	enddo
c
c  Nominal met data values.
c
	stemp = 300
	spress = 1013*97.5
	shumid = 0.3
c
c  Determine some constants for later use.
c
	call obspar('ATCA','latitude', lat, ok)
	if(.not.ok)call bug('f','Could not get ATCA latitude')
	call obspar('ATCA','longitude',long,ok)
	if(.not.ok)call bug('f','Could not get ATCA longitude')
c
	end
c************************************************************************
	subroutine PokeInfo(scanno,time)
c
	implicit none
	double precision time
	integer scanno
c
c  Give some information about the current scan that has just
c  started.
c------------------------------------------------------------------------
	character date*32,line*64
	integer length
c
	character itoaf*4
	integer len1
c
	call julday(time,'H',date)
	line = 'Scan '//itoaf(scanno)
	length = len1(line)
	line(length+1:) = ' started at '//date
	call output(line)
	end
c************************************************************************
	subroutine PokeStat(nrec,fgbad,fgoffsrc,fginvant,fgsysc,fgsam,
     *								fgcal)
c
	implicit none
	integer nrec,fgbad,fgoffsrc,fginvant,fgsysc,fgsam,fgcal
c
c  Report statistics on this file.
c------------------------------------------------------------------------
c
c  Externals.
c
	character itoaf*8,pcent*6
c
	call output('---------------------------------------')
	call liner(
     *		'Total number of spectra selected: '//itoaf(nrec+fgbad))
	if(fgbad.gt.0)call liner(
     *		'Number of invalid data records: '//itoaf(fgbad))
	call output(' ')
	if(fgoffsrc+fginvant+fgsysc+fgsam+fgcal.gt.0)then
	  call liner('Summary of spectra flagged')
	  call liner('Flagging Reason            Fraction')
	  call liner('---------------            --------')
	  if(fgoffsrc.gt.0)call liner(
     *		'Antenna off-source/off-line '//pcent(fgoffsrc,nrec))
	  if(fginvant.gt.0)call liner(
     *		'Antenna disabled            '//pcent(fginvant,nrec))
	  if(fgsysc.gt.0)call liner(
     *		'Missing SYSCAL record       '//pcent(fgsysc,nrec))
	  if(fgsam.gt.0)call liner(
     *		'Bad SYSCAL values           '//pcent(fgsam,nrec))
	  if(fgcal.gt.0)call liner(
     *		'Discarded cal data          '//pcent(fgcal,nrec))
	else
	  call liner('There was no flagged data')
	endif
	call liner('---------------------------------------')
c
	end
c************************************************************************
	subroutine liner(string)
c
	implicit none
	character string*(*)
c
c------------------------------------------------------------------------
	character line*72
	include 'atlod.h'
c
	call output(string)
	line = 'ATLOD:    '//string
	call hiswrite(tno,line)
	end
c************************************************************************
	subroutine liners(string)
c
	implicit none
	character string*(*)
c
c------------------------------------------------------------------------
	character line*72
	include 'atlod.h'
c
	line = 'ATLOD:     '//string
	call hiswrite(tno,line)
	end
c************************************************************************
	subroutine sortcds(ncard,card,sctype,refpnt,nants,okref)
c
	implicit none
	integer ncard,nants
	logical okref
	real refpnt(2,nants)
	character card(ncard)*(*),sctype*(*)
c
c  Write out selected cards to the history file.
c
c------------------------------------------------------------------------
	integer i,cacalval
	logical ok
c
	okref = .false.
	do i=1,nants
	  refpnt(1,i) = 0
	  refpnt(2,i) = 0
	enddo
c
	do i=1,ncard
c	  if(card(i)(1:8).eq.'OBSLOG' .or.card(i)(1:8).eq.'ATTEN'   .or.
c     *	    card(i)(1:8).eq.'SUBREFL' .or.card(i)(1:8).eq.'CORR_CFG'.or.
c     *	    card(i)(1:8).eq.'SCANTYPE'.or.card(i)(1:8).eq.'CACALCNT'.or.
c     *	    card(i)(1:8).eq.'POINTCOR'.or.card(i)(1:8).eq.'POINTINF'
c     *								)then
	  if(card(i)(1:8).eq.'OBSLOG')then
	    call liners(card(i)(20:))
	  else if(card(i)(1:8).eq.'POINTCOR')then
	    call crackpnt(card(i),refpnt,nants,ok)
	    if(.not.ok)then
	      call bug('w','Error decoding reference pointing card')
	    else
	      okref = .true.
	    endif
	  else if(card(i)(1:8).eq.'CACALCNT')then
	    call cardvali(card(i),cacalval)
	    call cacalCnt(cacalval)
	  else if(card(i)(1:8).eq.'SCANTYPE')then
	    sctype = card(i)(11:)
	    call lcase(sctype)
	  endif
	enddo
c
	end
c************************************************************************
	subroutine crackpnt(line,refpnt,nants,ok)
c
	implicit none
	character line*(*)
	integer nants
	real refpnt(2,nants)
	logical ok
c
c------------------------------------------------------------------------
	integer k1,k2,iant,length
	character token*8
c
c  Externals.
c
	integer len1
c
	ok = .false.
	k1 =10
	k2 = len1(line)
c
	call getfield(line,k1,k2,token,length)
	if(token(1:3).ne.'CA0')return
	iant = ichar(token(4:4)) - ichar('0')
	if(iant.le.0.or.iant.gt.nants)return
	call getfield(line,k1,k2,token,length)
	if(token.ne.'Az=')return
	call getfield(line,k1,k2,token,length)
	if(length.eq.0)return
	call atorf(token,refpnt(1,iant),ok)
	if(.not.ok)return
	call getfield(line,k1,k2,token,length)
	if(token.ne.'El=')return
	call getfield(line,k1,k2,token,length)
	if(length.eq.0)return
	call atorf(token,refpnt(2,iant),ok)
	if(.not.ok)return
	ok = .true.
	end
c************************************************************************
	subroutine cardvali(card,ival)
c
	implicit none
	integer ival
	character card*(*)
c------------------------------------------------------------------------
	integer i,j
	double precision out
	logical ok
c
        i = index(card,'=') + 1
        dowhile(card(i:i).eq.' '.and.i.le.len(card))
          i = i + 1
        enddo
        j = i - 1
        do while(card(j+1:j+1).ne.' '.and.card(j+1:j+1).ne.'/')
          j = j + 1
        enddo   
        ok = .false.   
        if(j.ge.i)call atodf(card(i:j),out,ok)
        if(.not.ok)
     *      call bug('f','Conversion error in decoding FITS card')
	ival = nint(out)
c
	end
c************************************************************************
	subroutine PokeName(in)
c
	character in*(*)
c
c------------------------------------------------------------------------
	include 'atlod.h'
	character c*1
	integer i1,i2,i
c
	integer len1
c
	i1 = 1
	i2 = len1(in)	
	do i=1,i2
	  c = in(i:i)
	  if(index('/[]:',c).ne.0)i1 = i + 1
	enddo
	if(i1.gt.i2)i1 = 1
	call uvputvra(tno,'name',in(i1:i2))
	end
c************************************************************************
	subroutine Poke1st(time1,nifs1,nants1)
c
	implicit none
	double precision time1
	integer nifs1,nants1
c
c  Set some fundamental parameters just before we start dumping other
c  things.
c
c------------------------------------------------------------------------
	include 'atlod.h'
	time = time1
	nifs = nifs1
	nants = nants1
	if(nifs.le.0.or.nifs.gt.ATIF.or.nants.le.0.or.nants.gt.ATANT)
     *	  call bug('f','Invalid nants or nifs in Poke1st')
	call uvputvri(tno,'nants',nants,1)
c
	end
c************************************************************************
	subroutine PokeIF(if,nfreq1,bw,freq,ref,rfreq,nstok,cstok)
c
	implicit none
	integer if,nfreq1,nstok
	character cstok(nstok)*(*)
	double precision freq,bw,ref,rfreq
c
c  Save the frequency/IF information.
c
c------------------------------------------------------------------------
	include 'atlod.h'
	integer p,t
c
c  Externals.
c
	integer PolsP2C	
c
	if(if.gt.nifs)call bug('f','Invalid IF in PokeIF')
	if(nstok.gt.ATPOL)call bug('f',
     *		'Invalid number of polarisation parameters in PokeIF')
c
	nfreq(if) = nfreq1
	if(nfreq(if).gt.1)then
	  sdf(if) = 1e-9*bw / (nfreq(if) - 1)
	else
	  sdf(if) = 1e-9*abs(bw)
	endif
	if(abs(sdf(if)).eq.0)
     *	  call bug('w','Channel width in RPFITS file is 0')
	sfreq(if) = 1e-9*freq - (ref-1)*sdf(if)
	edge(if) = 0
	bchan(if) = 0
c
c  If we are working in "birdie" mode, compute the channel with the
c  128MHz LO signal in it.
c
	if(birdie.and.nfreq(if).eq.33)then
	  call birdchan(sfreq(if),sdf(if),nfreq(if),t)
c
	  edge(if) = 3 + mod(t,2)
	  sfreq(if) = sfreq(if) + edge(if)*sdf(if)
	  sdf(if) = 2*sdf(if)
	  nfreq(if) = (nfreq(if)-2*edge(if)+1)/2
	endif
c
	if(dohann.and.nfreq(if).gt.33)then
	  edge(if) = 1
	  sfreq(if) = sfreq(if) + edge(if)*sdf(if)
	  sdf(if) = 2*sdf(if)
	  nfreq(if) = (nfreq(if)-2*edge(if)+1)/2
	endif
c
c  If birdie mode, flag out the birdie channel.
c
	if(birdie)then
	  call birdchan(sfreq(if),sdf(if),nfreq(if),bchan(if))
	else
	  bchan(if) = 0
	endif
c
	nstoke(if) = nstok
	restfreq(if) = 1e-9 * rfreq
c
	do p=1,nstoke(if)
	  polcode(if,p) = PolsP2C(cstok(p))
	enddo
c
	newfreq = .true.
c
	end
c************************************************************************
	subroutine birdchan(sfreq,sdf,nfreq,chan)
c
	implicit none
	integer nfreq,chan
	double precision sfreq,sdf
c------------------------------------------------------------------------
	double precision flo
c
	if(abs(sdf).eq.0)call bug('f',
     *	  'Cannot use options=birdie when channel width is unknown')
	flo = sfreq + 0.5*(nfreq-1)*sdf
	flo = 0.128d0 * nint(flo/0.128d0)
	chan = nint((flo - sfreq)/sdf) + 1
	if(chan.le.0) chan = chan + nint(0.128d0/abs(sdf))
	end
c************************************************************************
	subroutine pokemet(mdata1,mcount1)
c
	implicit none
	integer mcount1
	real mdata1(mcount1)
	
c
c------------------------------------------------------------------------
	include 'atlod.h'
	integer i
c
	do i=1,mcount1
	  mdata(i) = mdata1(i)
	enddo
	mcount = mcount1
c
	end
c************************************************************************
	subroutine pokeref(refpnt1,nant1)
c
	implicit none
	integer nant1
	real refpnt1(2,nant1)
c------------------------------------------------------------------------
	include 'atlod.h'
	integer i
c
	do i=1,nant1
	  refpnt(1,i) = refpnt1(1,i)
	  refpnt(2,i) = refpnt1(2,i)
	enddo
	refnant = nant1
	end
c************************************************************************
	subroutine PokeSC(ant,if,chi1,tcorr1,
     *		xtsys1,ytsys1,xyphase1,xyamp1,xsamp,ysamp,pntrms,pntmax)
c
	implicit none
	integer ant,if,tcorr1
	real chi1,xtsys1,ytsys1,xyphase1,xyamp1
	real xsamp(3),ysamp(3),pntrms,pntmax
c
c  Save the SYSCAL group info.
c------------------------------------------------------------------------
	include 'atlod.h'
	if(ant.gt.nants.or.if.gt.nifs)call bug('f',
     *				'Invalid Ant or IF in PokeSC')
c
	tcorr = tcorr1
	chi = chi1
	axisrms(ant)=pntrms
	axismax(ant)=pntmax
	xtsys(if,ant) = xtsys1
	ytsys(if,ant) = ytsys1
	xyphase(if,ant) = xyphase1
	xyamp(if,ant) = xyamp1
c
	xsampler(1,if,ant) = xsamp(1)
	xsampler(2,if,ant) = xsamp(2)
	xsampler(3,if,ant) = xsamp(3)
c
	ysampler(1,if,ant) = ysamp(1)
	ysampler(2,if,ant) = ysamp(2)
	ysampler(3,if,ant) = ysamp(3)
c
	newsc = .true.
c
	end
c************************************************************************
	subroutine PokeSrc(srcnam,ra1,dec1,obsra1,obsdec1,
     *					pntra1,pntdec1,calcode1)
c
	implicit none
	character srcnam*(*)
	double precision ra1,dec1,obsra1,obsdec1,pntra1,pntdec1
	character calcode1*(*)
c
c  Flush out source information.
c------------------------------------------------------------------------
	include 'atlod.h'
	double precision r1,d1,pntra,pntdec
	character line*80,sdash*80,calcode*16
	integer length,l
c
c  Externals.
c
	integer len1
	double precision Epo2Jul
c
c  Save ra and dec.
c
	ra = ra1
	dec = dec1
	pntra = pntra1
	pntdec = pntdec1
c
c  Some (all?) RPFITS files fail to give the apparent RA and DEC of
c  the source. Compute this if necessarry.
c
	if((obsra1.eq.0.and.abs(ra).gt.0.01).or.
     *	   (obsdec1.eq.0.and.abs(dec).gt.0.01))then
	  call precess(Epo2Jul(2000.d0,'J'),ra,dec,time,obsra,obsdec)
	  call Nutate(time,obsra,obsdec,r1,d1)
	  call Aberrate(time,r1,d1,obsra,obsdec)
	else
	  obsra = obsra1
	  obsdec = obsdec1
	endif
c
c  Fiddle the source name to be all lower case, and eliminate
c  any special characters or spaces.
c
	sdash = srcnam
	length = min(len1(srcnam),len(sdash))
	if(length.gt.0)call lcase(sdash(1:length))
	do l=1,length
	  if((sdash(l:l).ge.'a'.and.sdash(l:l).le.'z').or.
     *	     (sdash(l:l).ge.'0'.and.sdash(l:l).le.'9').or.
     *	      sdash(l:l).eq.'+'.or. sdash(l:l).eq.'-'.or.
     *	      sdash(l:l).eq.'.')then
	    continue
	  else
	    sdash(l:l) = '_'
	  endif
	enddo
c
c  Give a message about a new source.
c
	if(srcnam.ne.sname.and.length.gt.0)then
	  line = 'Source: '//sdash(1:length)
	  call output(line)
	  sname = srcnam
	endif
c
	if(length.gt.0)call uvputvra(tno,'source',sdash(1:length))
	call uvputvrd(tno,'ra',ra,1)
	call uvputvrd(tno,'dec',dec,1)
	call uvputvrd(tno,'pntra',pntra,1)
	call uvputvrd(tno,'pntdec',pntdec,1)
	call uvputvrd(tno,'obsra',obsra,1)
	call uvputvrd(tno,'obsdec',obsdec,1)
c
	calcode = calcode1
	length = len1(calcode)
	if(length.eq.0)then
	  calcode = 'none'
	  length = len1(calcode)
	endif
	call uvputvra(tno,'calcode',calcode(1:length))
c
	newpnt = .true.
	end
c************************************************************************
	subroutine PokeAnt(n,x,y,z,sing)
c
	implicit none
	integer n
	double precision x(n),y(n),z(n)
	logical sing
c
c  Set antenna coordinates.
c
c------------------------------------------------------------------------
	include 'atlod.h'
	include 'mirconst.h'
	double precision r,z0,cost,sint,temp,antpos(3*ATANT)
	integer i
	logical more
c
c  Check the number of antennas.
c
	if(n.ne.nants)call bug('f',
     *			'Inconsistent no. antennas, in PokeAnt')
c
c  Convert them to the Miriad system: y is local East, z is parallel to pole
c  Units are nanosecs.
c
	i = 1
	more = .true.
	dowhile(more)
	  r = sqrt(x(i)*x(i) + y(i)*y(i))
	  more = r.eq.0
	  if(more)i = i + 1
	  more = more.and.i.le.nants
	enddo
	if(i.gt.nants)then
	  if(.not.sing)
     *	    call bug('w','Antenna table is identically 0!!')
	  cost = 1
	  sint = 0
	  z0 = 0
	else
	  cost = x(i) / r
	  sint = y(i) / r
	  z0 = z(i)
	endif
c
	do i=1,nants
	  temp = x(i)*cost + y(i)*sint - r
	  antpos(i)         = (1d9/DCMKS) * temp
	  temp = -x(i)*sint + y(i)*cost
	  antpos(i+nants)   = (1d9/DCMKS) * temp
	  antpos(i+2*nants) = (1d9/DCMKS) * (z(i)-z0)
	enddo
	call uvputvrd(tno,'antpos',antpos,3*nants)
c
	end
c************************************************************************
	subroutine PokeData(u1,v1,w1,baseln,if,bin,vis,nfreq1,nstoke1,
     *		flag1,inttime1,docon,doxyflip,doxy)
c
	implicit none
	integer nfreq1,nstoke1,if,baseln,bin
	real u1,v1,w1,inttime1
	logical flag1(nstoke1),docon,doxyflip,doxy
	complex vis(nfreq1*nstoke1)
c
c  Buffer up the data. Perform sampler correction and hanning smoothing
c  if needed.
c------------------------------------------------------------------------
	integer PolXX,PolYY,PolXY,PolYX
	parameter(PolXX=-5,PolYY=-6,PolXY=-7,PolYX=-8)
c
	include 'atlod.h'
	include 'mirconst.h'
	integer ipnt,i1,i2,bl,p,pol
	logical doconj,doneg
	real rscr(2*ATCONT-2)
	complex cscr(ATCONT)
c
	if(if.gt.nifs)call bug('f',
     *		'Incorrect IF number')
	if(nstoke1.ne.nstoke(if))call bug('f',
     *		'Inconsistent number of polarisastions')
	i2 = baseln / 256
	i1 = mod(baseln,256)
	doconj = docon
	if(i1.gt.i2)then
	  doconj = .not.doconj
	  bl = ((i1-1)*i1)/2 + i2
	  u(bl) = -u1 / (1e-9*CMKS)
	  v(bl) = -v1 / (1e-9*CMKS)
	  w(bl) = -w1 / (1e-9*CMKS)
	  dosw(bl) = .false.
	else
	  bl = ((i2-1)*i2)/2 + i1
	  u(bl) = u1 / (1e-9*CMKS)
	  v(bl) = v1 / (1e-9*CMKS)
	  w(bl) = w1 / (1e-9*CMKS)
	  dosw(bl) = .true.
	endif
c
c  Save the integration time.
c
	if(inttime1.gt.0)then
	  inttime(bl) = inttime1
	else
	  inttime(bl) = 10
	endif
	inttim = max(inttim,inttime(bl))
c       
c  Remove the phase switching.
c
	if(dopmps)
     *	  call deswitch(vis,nstoke(if),nfreq1,time,inttime(bl),i1,i2)
c
c  Reweight the data, if needed.
c
	if(dowt.and.nfreq1.eq.ATCONT)
     *	  call Reweight(vis,cscr,rscr,nstoke(if),nfreq1,wts)
c
c  Do the 8 MHz de-birdie'ing operation.
c
	if(birdie.and.
     *	   abs(abs(nfreq(if)*sdf(if))-0.008).lt.0.0001)then
	  call do8(vis,nstoke(if),nfreq(if),sfreq(if),sdf(if))
	endif
	
c
c  Allocate buffer slots for each polarisation. Save the flags, Copy the
c  data to the output. Do sampler corrections.
c
	if(bin.gt.ATBIN)call bug('f','Invalid pulsar bin number')
	do p=1,nstoke(if)
	  ipnt = nused + 1
	  pnt(if,p,bl,bin) = ipnt
	  flag(if,p,bl,bin) = flag1(p)
	  nbin(if) = max(nbin(if),bin)
	  nused = nused + nfreq(if)
	  if(nused.gt.ATDATA)call bug('f','Buffer overflow in PokeData')
	  doneg = (polcode(if,p).eq.PolXY.or.
     *		   polcode(if,p).eq.PolYX).and.doxyflip
	  call DatCpy(nstoke(if),nfreq(if),nfreq1,
     *		dohann.and.nfreq1.gt.33,birdie.and.nfreq1.eq.33,
     *		edge(if),doconj,doneg,vis(p),data(ipnt))
	  if(dosam)call SamCorr(nfreq(if),data(ipnt),polcode(if,p),
     *		i2,i1,if,time,xsampler,ysampler,ATIF,ATANT)
c
c  Do XY phase correction if needed.
c
	  if(doxyp.and.doxy)then
	    if(dosw(bl))then
	      pol = polcode(if,p)
	      if(pol.eq.PolXY)then
		pol = PolYX
	      else if(pol.eq.PolYX)then
		pol = PolXY
	      endif
	      call XypCorr(nfreq(if),data(ipnt),pol,
     *		i1,i2,if,xyphase,ATIF,ATANT)
	    else
	      call XYpCorr(nfreq(if),data(ipnt),polcode(if,p),
     *		i2,i1,if,xyphase,ATIF,ATANT)
	    endif
	  endif
	enddo
c
	end
c************************************************************************
	subroutine do8(vis,npol,nfreq,sfreq,sdf)
c
	implicit none
	integer nfreq,npol
	complex vis(npol,nfreq)
	double precision sfreq,sdf
c------------------------------------------------------------------------
	include 'maxdim.h'
	double precision flo
	integer chan,i,j,n
	complex cbuff(MAXDIM+1),ctmp
	real    rbuff(2*MAXDIM)
c
	if(abs(sdf).eq.0)call bug('f',
     *	  'Cannot use options=birdie when channel width is unknown')
	flo = sfreq + 0.5*(nfreq-1)*sdf
	flo = 0.128d0 * nint(flo/0.128d0)
	chan = nint((flo - sfreq)/sdf) + 1
	if(chan.le.0) chan = chan + nint(0.128d0/abs(sdf))
	if(chan.le.nfreq)then
	  if(nfreq.gt.MAXDIM+1)
     *	    call bug('f','Buffer overflow when debirding 8MHz')
	  n = 2*nfreq-2
	  do j=1,npol
	    do i=1,nfreq
	      cbuff(i) = vis(j,i)
	    enddo
	    ctmp = cbuff(chan)
	    cbuff(chan) = 0
	    call fftcr(cbuff,rbuff,-1,n)
	    rbuff(nfreq) = 0
	    call fftrc(rbuff,cbuff,1,n)
	    cbuff(chan) = n*ctmp
	    do i=1,nfreq
	      vis(j,i) = cbuff(i)/n
	    enddo
	  enddo
	endif
c
	end
c************************************************************************
	subroutine deswitch(vis,npol,nchan,time,inttime,i1,i2)
c
	implicit none
	integer npol,nchan,i1,i2
	complex vis(nchan,npol)
	double precision time
	real inttime
c
c  Correct for on-line phase switching.
c
c------------------------------------------------------------------------
	integer i,j,istate
	real s
	double precision rinttime
c
        integer states(8,6)
        data states/
     *  +1,-1,+1,-1,+1,-1,+1,-1,
     *  +1,+1,-1,-1,+1,+1,-1,-1,
     *  +1,-1,-1,+1,+1,-1,-1,+1,
     *  +1,+1,+1,+1,-1,-1,-1,-1,
     *  +1,+1,-1,-1,-1,-1,+1,+1,
     *  +1,+1,+1,+1,+1,+1,+1,+1/
c
	rinttime = 5.d0 * nint(inttime/5.0) / 86400.d0
        istate = mod(nint(mod(time,1.0d0)/rinttime),8) + 1
c
	s = 1
	if(states(istate,i1).ne.states(istate,i2)) s = -1
c
	do j=1,npol
	  do i=1,nchan
	    vis(i,j) = s * vis(i,j)
	  enddo
	enddo
c
	end
c************************************************************************
	subroutine XypCorr(nfreq,vis,pol,i1,i2,if,xyphase,ATIF,ATANT)
c
	implicit none
	integer nfreq,pol,i1,i2,if,ATIF,ATANT
	complex vis(nfreq)
	real xyphase(ATIF,ATANT)
c
c  Correct the data with the measured XY phase.
c------------------------------------------------------------------------
	integer PolXX,PolYY,PolXY,PolYX
	parameter(PolXX=-5,PolYY=-6,PolXY=-7,PolYX=-8)
	integer i
	complex fac
	real theta
c
	if(pol.eq.PolYY)then
	  theta = xyphase(if,i1) - xyphase(if,i2)
	else if(pol.eq.PolXY)then
	  theta =                - xyphase(if,i2)
	else if(pol.eq.PolYX)then
	  theta = xyphase(if,i1)
	else
	  theta = 0
	endif
c
	if(theta.ne.0)then
	  fac = cmplx(cos(theta),-sin(theta))
	  do i=1,nfreq
	    vis(i) = fac*vis(i)
	  enddo
	endif
c
	end
c************************************************************************
	subroutine Reweight(vis,cscr,rscr,npol,nchan,wts)
c
	implicit none
	integer npol,nchan
	complex vis(npol,nchan),cscr(nchan)
	real wts(2*nchan-2),rscr(2*nchan-2)
c
c  Reweight the lag spectrum.
c------------------------------------------------------------------------
	integer i,p
c
	do p=1,npol
	  do i=1,nchan
	    cscr(i) = vis(p,i)
	  enddo
	  call fftcr(cscr,rscr,-1,2*nchan-2)
	  do i=1,2*nchan-2
	    rscr(i) = rscr(i)*wts(i)/real(2*nchan-2)
	  enddo
	  call fftrc(rscr,cscr, 1,2*nchan-2)
	  do i=1,nchan
	    vis(p,i) = cscr(i)
	  enddo
	enddo
c
	end
c************************************************************************
	subroutine PokeMisc(telescop,observer,version,sctype)
c
	implicit none
	character telescop*(*),observer*(*),version*(*),sctype*(*)
c
c  Set various miscellaneous parameters.
c------------------------------------------------------------------------
	include 'atlod.h'
	character atemp*32
	integer length
c
	call AsciiCpy(telescop,atemp,length)
	if(length.gt.0)then
	  call uvputvra(tno,'telescop',atemp(1:length))
	  call uvputvra(tno,'instrume',atemp(1:length))
	endif
c
	call AsciiCpy(observer,atemp,length)
	if(length.gt.0)call uvputvra(tno,'observer',atemp(1:length))
c
	call AsciiCpy(version,atemp,length)
	if(length.gt.0)call uvputvra(tno,'version',atemp(1:length))
c
	call AsciiCpy(sctype,atemp,length)
	if(length.gt.0)call uvputvra(tno,'sctype',atemp(1:length))
c
	end
c************************************************************************
	subroutine PokeFlsh
c
	implicit none
c
c  Flush out a saved integration.
c------------------------------------------------------------------------
	include 'atlod.h'
	include 'mirconst.h'
	integer NDATA
	parameter(NDATA=MAXCHAN*MAXWIN)
	integer i1,i2,if,p,bl,nchan,npol,ipnt,ischan(ATIF)
	integer tbinhi,tbin,binhi,binlo,bin
	complex vis(NDATA)
	logical flags(NDATA)
	double precision preamble(5),vel,lst,tdash,az,el
	real buf(3*ATANT*ATIF),fac(ATIF),freq0(ATIF),Tb(ATIF),tfac
	real jyperk
c
c  Externals.
c
	double precision eqeq
	real getjpk
c
	if(nused.eq.0)return
c
c  Check that we can do what is asked.
c
	if(newfreq)then
	  if(doif)then
	    do if=2,nifs
	      if(nbin(if).ne.nbin(1))    call bug('f',
     *		'Number of bins differ between IFs. '//
     *		'Use options=noif.')
	      if(nstoke(if).ne.nstoke(1))call bug('f',
     *		'Number of polarisations differ between IFs. '//
     *		'Use options=noif.')
	      do p=1,nstoke(if)
	        if(polcode(if,p).ne.polcode(1,p))call bug('f',
     *		'Polarisation types differ between IFs. '//
     *		'Use options=noif.')
	      enddo
	    enddo
	  else if(hires)then
	    do if=2,nifs
	      if(nbin(if).ne.nbin(1))    call bug('f',
     *		'Number of bins in different IFs must '//
     *				   'agree for options=hires')
	    enddo
	  endif
	endif
c
c  Compute apparent LST.
c
	if(hires)then
	  tdash  = time - 0.5*inttim*(nbin(1)-1)/86400.0d0
	  tbinhi = nbin(1)
	else
	  tdash  = time
	  tbinhi = 1
	endif
c
c  Write out the reference pointing data.
c
	if(refnant.gt.0)then
	  call uvputvrr(tno,'refpnt',refpnt,2*refnant)
	endif
c
c  Write out the met data.
c
	if(mcount.ge.5)then
	  call uvputvrr(tno,'airtemp',mdata(1),1)
	  call uvputvrr(tno,'pressmb',0.975*mdata(2),1)
	  call uvputvrr(tno,'relhumid',mdata(3),1)
	  call uvputvrr(tno,'wind',mdata(4),1)
	  call uvputvrr(tno,'winddir',mdata(5),1)
	endif
	if(mcount.ge.7)then
c	  call uvputvrr(tno,'metflag',mdata(6),1)
	  call uvputvrr(tno,'rain',mdata(7),1)
	endif
	if(mcount.ge.9)then
c	  call uvputvrr(tno,'smonphas',mdata(8),1)
	  call uvputvrr(tno,'smonrms', mdata(9),1)
	endif
c
	do tbin=1,tbinhi
	  call jullst(tdash,long,lst)
	  lst = lst + eqeq(tdash)
	  call uvputvrd(tno,'lst',lst,1)
c
c  Compute the az and el of the telescopes.c
c
	  call azel(obsra,obsdec,lst,lat,az,el)
	  call uvputvrd(tno,'antaz',az*180.d0/DPI,1)
	  call uvputvrd(tno,'antel',el*180.d0/DPI,1)
c
c  Get ready to apply opacity correction.
c
	  jyperk = getjpk(real(sfreq(1)))

	  if(opcorr)then
	    do if=1,nifs
	      freq0(if) = (sfreq(if) + 0.5*(nfreq(if)-1)*sdf(if))*1e9
	    enddo
	    if(mcount.lt.3)then
	      call bug('w','No met data to compute opacity correction')
	    else
	      stemp = mdata(1) + 273.15
	      spress = 97.5*mdata(2)
	      shumid = 0.01*data(3)
	    endif
	    call opacGet(nifs,freq0,real(el),stemp,spress,shumid,
     *					     		   fac,Tb)
	    tfac = 1
	    do if=1,nifs
	      fac(if) = 1/fac(if)
	      tfac = tfac * fac(if)
	    enddo
	    jyperk = jyperk * tfac**(1.0/real(nifs))
	  else
	    do if=1,nifs
	      fac(if) = 1
	    enddo
	  endif
c
c  Compute radial velocity of the observatory.
c
	  call VelRad(.not.dobary,tdash,obsra,obsdec,ra,dec,lst,lat,vel)
	  call uvputvrr(tno,'veldop',real(vel),1)
	  call uvputvrr(tno,'jyperk',jyperk,1)
c
c  Handle the case that we are writing the multiple IFs out as multiple
c  records.
c
	if(.not.doif.and.nifs.gt.1)then
	  do if=1,nifs
	    call uvputvri(tno,'nspect',1,1)
	    call uvputvri(tno,'npol',  nstoke(if),1)
	    call uvputvri(tno,'nschan',nfreq(if),1)
	    call uvputvri(tno,'ischan',1,1)
	    call uvputvrd(tno,'sfreq', sfreq(if),1)
	    call uvputvrd(tno,'sdf',   sdf(if),  1)
	    call uvputvrd(tno,'restfreq',restfreq(if),1)
	    if(newsc)call ScOut(tno,chi,tcorr,
     *		xtsys,ytsys,xyphase,xyamp,
     *		xsampler,ysampler,axisrms,axismax,
     *		ATIF,ATANT,nants,if,if,buf)
	    if(hires)then
	      binlo = tbin
	      binhi = tbin
	    else
	      binlo = 1
	      binhi = nbin(if)
	    endif
	    do bin=binlo,binhi
	      if(.not.hires)call uvputvri(tno,'nbin',nbin(if),1)
	      bl = 0
	      do i2=1,nants
	        do i1=1,i2
	          bl = bl + 1
	          preamble(1) = u(bl)
	          preamble(2) = v(bl)
		  preamble(3) = w(bl)
	          preamble(4) = tdash
	          preamble(5) = 256*i1 + i2
	          do p=1,nstoke(if)
		    ipnt = pnt(if,p,bl,bin)
		    if(ipnt.gt.0)then
		      call PolPut(tno,polcode(if,p),dosw(bl))
		      call GetFlag(flag(if,p,bl,bin),nfreq(if),
     *						  bchan(if),flags)
		      if(.not.hires)call uvputvri(tno,'bin',bin,1)
		      call uvputvrr(tno,'inttime',inttime(bl),1)
		      if(opcorr)
     *			call opapply(data(ipnt),nfreq(if),fac(if))
		      call uvwrite(tno,preamble,data(ipnt),flags,
     *							nfreq(if))

		    endif
		  enddo
	        enddo
	      enddo
	    enddo
	  enddo
c
c  Handle the case were we are writing the multiple IFs out as a single record.
c
	else
	  if(newfreq.and.tbin.eq.1)then
	    ischan(1) = 1
	    do if=2,nifs
	      ischan(if) = ischan(if-1) + nfreq(if)
	    enddo
	    call uvputvri(tno,'nspect',nifs,1)
	    call uvputvri(tno,'ischan',ischan,nifs)
	    call uvputvri(tno,'nschan',nfreq,nifs)
	    call uvputvrd(tno,'sfreq', sfreq,nifs)
	    call uvputvrd(tno,'sdf',   sdf,nifs)
	    call uvputvrd(tno,'restfreq',restfreq,nifs)
	    if(.not.hires)call uvputvri(tno,'nbin',nbin(1),1)
	  endif
	  if(newsc.and.tbin.eq.1)call ScOut(tno,chi,tcorr,
     *		xtsys,ytsys,xyphase,xyamp,
     *		xsampler,ysampler,axisrms,axismax,
     *		ATIF,ATANT,nants,1,nifs,buf)
	  if(hires)then
	    binlo = tbin
	    binhi = tbin
	  else
	    binlo = 1
	    binhi = nbin(1)
	  endif
	  do bin=binlo,binhi
	    bl = 0
	    do i2=1,nants
	      do i1=1,i2
	        bl = bl + 1
	        preamble(1) = u(bl)
	        preamble(2) = v(bl)
	        preamble(3) = w(bl)
	        preamble(4) = tdash
	        preamble(5) = 256*i1 + i2
	        call CntStok(npol,pnt(1,1,bl,bin),nifs,nstoke(1),ATIF)
	        if(npol.gt.0)then
		  call uvputvri(tno,'npol',npol,1)
	          do p=1,nstoke(1)
		    call GetDat(data,nused,pnt(1,p,bl,bin),
     *			flag(1,p,bl,bin),nfreq,fac,bchan,nifs,
     *			vis,flags,NDATA,nchan)
		    if(nchan.gt.0)then
		      if(.not.hires)call uvputvri(tno,'bin',bin,1)
		      call uvputvri(tno,'pol',polcode(1,p),1)
		      call uvputvrr(tno,'inttime',inttime(bl),1)
		      call uvwrite(tno,preamble,vis,flags,nchan)
		    endif
	          enddo
	        endif
	      enddo
	    enddo
	  enddo
	endif
c
	tdash = tdash + inttim/86400.0d0
	enddo
c
c  Reset the counters, etc.
c
	inttim = 0
	do bl=1,ATBASE
	  do p=1,ATPOL
	    do if=1,nifs
	      do bin=1,nbin(if)
		pnt(if,p,bl,bin) = 0
	      enddo
	    enddo
	  enddo
	enddo
c
	do if=1,nifs
	  nbin(if) = 0
	enddo	  
c
	mcount = 0
	refnant = 0
	nused = 0
	newsc   = .false.
	newfreq = .false.
	newpnt  = .false.
	end
c************************************************************************
	subroutine opapply(data,nchan,fac)
c
	implicit none
	integer nchan
	real fac
	complex data(nchan)
c------------------------------------------------------------------------
	integer i
c
	do i=1,nchan
	  data(i) = fac*data(i)
	enddo
c
	end
c************************************************************************
	subroutine PolPut(tno,pol,dosw)
c
	implicit none
	integer tno,pol
	logical dosw
c
c  Write out the polarisation flag. If "dosw" is true, switch
c  PolXY to PolYX and visa versa.
c
c------------------------------------------------------------------------
	integer PolXX,PolYY,PolXY,PolYX
	parameter(PolXX=-5,PolYY=-6,PolXY=-7,PolYX=-8)
c
	if(dosw)then
	  if(pol.eq.PolXY)then
	    call uvputvri(tno,'pol',PolYX,1)
	  else if(pol.eq.PolYX)then
	    call uvputvri(tno,'pol',PolXY,1)
	  else
	    call uvputvri(tno,'pol',pol,1)
	  endif
	else
	  call uvputvri(tno,'pol',pol,1)
	endif
c
	end
c************************************************************************
c************************************************************************
	subroutine VelRad(dolsr,time,raapp,decapp,raepo,decepo,
     *	  lst,lat,vel)
c
	implicit none
	logical dolsr
	double precision time,raapp,decapp,raepo,decepo
	double precision lst,lat,vel
c
c  Compute the radial velocity of the observatory, in the direction of
c  a source, with respect to either LSR or the barycentre.
c
c  Input:
c    dolsr	If true, compute LSR velocity. Otherwise barycentric.
c    time	Time of interest (Julian date).
c    raapp,decapp Apparent RA and DEC (radians).
c    raepo,decepo RA and DEC at the J2000 epoch (radians).
c    lat	Observatory geodetic latitude (radians).
c    lst	Local sideral time (radians).
c  Output:
c    vel	Radial velocity.
c------------------------------------------------------------------------
	double precision lmn2000(3),lmnapp(3)
	double precision velsite(3),posearth(3),velearth(3),velsun(3)
	integer i
c
c  Compute barycentric velocity.
c
	call sph2lmn(raapp,decapp,lmnapp)
	call vsite(lat,lst,velsite)
	call vearth(time,posearth,velearth)
	vel = 0
	do i=1,3
	  vel = vel - (velsite(i) + velearth(i))*lmnapp(i)
	enddo
c
c  To compute LSR velocity, we need the source position in J2000 coordinates.
c  Vsun returns the Suns LSR velocity in the J2000 frame. Add this
c  contribution to the velocity we already have.
c
	if(dolsr)then
	  call sph2lmn(raepo,decepo,lmn2000)
	  call vsun(velsun)
	  do i=1,3
	    vel = vel + lmn2000(i)*velsun(i)
	  enddo
	endif
c
	end
c************************************************************************
	subroutine DatCpy(nstoke,nfreq,nfreq1,dohann,skip,edge,
     *					doconj,doneg,in,out)
c
	integer nstoke,nfreq,nfreq1,edge
	logical dohann,doconj,doneg,skip
	complex in(nstoke,nfreq1),out(nfreq)
c
c  Copy the data to an output buffer, conjugating and going
c  Hanning smoothing (if necessary) as we go.
c------------------------------------------------------------------------
	integer i,id
c
	if(dohann)then
	  if(nfreq.ne.(nfreq1-2*edge+1)/2)
     *		call bug('f','Incorrect dim info, in DatCpy')
	  id = edge + 1
	  do i=1,nfreq
	    out(i) = 0.25*(in(1,id-1)+in(1,id+1)) + 0.5*in(1,id)
	    id = id + 2
	  enddo
c
	else if(skip)then
	  if(nfreq.ne.(nfreq1-2*edge+1)/2)
     *		call bug('f','Incorrect dim info, in DatCpy')
	  id = edge + 1
	  do i=1,nfreq
	    out(i) = in(1,id)
	    id = id + 2
	  enddo
c
	else
	  if(nfreq.ne.nfreq1-2*edge)
     *		call bug('f','Incorrect dim info, in DatCpy')
	  id = edge + 1
	  do i=1,nfreq
	    out(i) = in(1,id)
	    id = id + 1
	  enddo
	endif
c
c  Do we need to negate?
c
	if(doneg)then
	  do i=1,nfreq
	    out(i) = -out(i)
	  enddo
	endif
c
c  Do we need to conjugate?
c
	if(doconj)then
	  do i=1,nfreq
	    out(i) = conjg(out(i))
	  enddo
	endif
c
	end
c************************************************************************
	subroutine GetFlag(flag,n,bchan,flags)
c
	implicit none
	integer n,bchan
	logical flag,flags(n)
c
c  Set the flags.
c------------------------------------------------------------------------
	integer i
c
	do i=1,n
	  flags(i) = flag
	enddo
	if(bchan.ge.1.and.bchan.le.n)flags(bchan) = .false.
c
	end
c************************************************************************
	subroutine ScOut(tno,chi,tcorr,xtsys,ytsys,xyphase,xyamp,
     *		xsampler,ysampler,axisrms,axismax,
     *		ATIF,ATANT,nants,if1,if2,buf)
c
	implicit none
	integer tno,ATIF,ATANT,nants,if1,if2,tcorr
	real chi,xtsys(ATIF,ATANT),ytsys(ATIF,ATANT)
	real xyphase(ATIF,ATANT),xyamp(ATIF,ATANT)
	real xsampler(3,ATIF,ATANT),ysampler(3,ATIF,ATANT)
	real buf(3*ATIF*ATANT),axisrms(ATANT),axismax(ATANT)
c
c  Write out a syscal record into the appropriate Miriad variables.
c
c  Input:
c    n		IF number to write out. If this is zero, all IFs are
c		written out.
c  Scratch:
c    buf	Used to buffer the data before writing.
c------------------------------------------------------------------------
	call uvputvrr(tno,'chi',chi,1)
	call uvputvri(tno,'tcorr',tcorr,1)
	call Sca(tno,'axisrms', axisrms, nants,buf)
	call Sca(tno,'axismax', axismax, nants,buf)
	call Sco(tno,'xtsys',   xtsys,   1,ATIF,ATANT,if1,if2,nants,buf)
	call Sco(tno,'ytsys',   ytsys,   1,ATIF,ATANT,if1,if2,nants,buf)
	call Sct(tno,'systemp',xtsys,ytsys,ATIF,ATANT,if1,if2,nants,buf)
	call Sco(tno,'xyphase', xyphase, 1,ATIF,ATANT,if1,if2,nants,buf)
	call Sco(tno,'xyamp',   xyamp,   1,ATIF,ATANT,if1,if2,nants,buf)
	call Sco(tno,'xsampler',xsampler,3,ATIF,ATANT,if1,if2,nants,buf)
	call Sco(tno,'ysampler',ysampler,3,ATIF,ATANT,if1,if2,nants,buf)
	end
c************************************************************************
	subroutine Sca(tno,var,axis,nants,buf)
c
	implicit none
	integer tno,nants
	character var*(*)
	real axis(nants),buf(2*nants)
c
c------------------------------------------------------------------------
	integer i,j
c
	j = 1
	do i=1,nants
	  buf(j) = axis(i)
	  buf(j+1) = axis(i)
	  j = j + 2
	enddo
c
	call uvputvrr(tno,var,buf,2*nants)
c
	end
c************************************************************************
	subroutine Sct(tno,var,xtsys,ytsys,ATIF,ATANT,if1,if2,nants,buf)
c
	implicit none
	integer tno,ATIF,ATANT,if1,if2,nants
	character var*(*)
	real buf(ATIF*ATANT),xtsys(ATIF,ATANT),ytsys(ATIF,ATANT)
c
c  Write out the SYSTEMP variable, which we fudge to be the geometric
c  mean of the xtsys and ytsys variables.
c------------------------------------------------------------------------
	integer ant,if,cnt
c
	cnt = 0
	do if=if1,if2
	  do ant=1,nants
	    cnt = cnt + 1
	    buf(cnt) = sqrt(xtsys(if,ant)*ytsys(if,ant))
	  enddo
	enddo
c
	call uvputvrr(tno,var,buf,cnt)
c
	end
c************************************************************************
	subroutine Sco(tno,var,dat,ndim,ATIF,ATANT,if1,if2,nants,buf)
c
	implicit none
	integer ATIF,ATANT,if1,if2,nants,tno,ndim
	character var*(*)
	real dat(ndim,ATIF,ATANT),buf(ndim*ATIF*ATANT)
c
c  Write out a syscal variable.
c------------------------------------------------------------------------
	integer ant,if,cnt,n
c
	cnt = 0
	do if=if1,if2
	  do ant=1,nants
	    do n=1,ndim
	      cnt = cnt + 1
	      buf(cnt) = dat(n,if,ant)
	    enddo
	  enddo
	enddo
c
	call uvputvrr(tno,var,buf,cnt)
c
	end
c************************************************************************
	subroutine CntStok(npol,pnt,nifs,nstoke,ATIF)
c
	implicit none
	integer npol,nifs,nstoke,ATIF,pnt(ATIF,nstoke)
c
c  Determine the number of valid Stokes records in this record.
c------------------------------------------------------------------------
	logical valid
	integer p,if
c
	npol = 0
	do p=1,nstoke
	  valid = .false.
	  do if=1,nifs
	    valid = valid.or.pnt(if,p).gt.0
	  enddo
	  if(valid)npol = npol + 1
	enddo
c
	end
c************************************************************************
	subroutine GetDat(data,nvis,pnt,flag,nfreq,fac,bchan,nifs,
     *					vis,flags,ndata,nchan)
c
	implicit none
	integer nvis,nifs,pnt(nifs),nfreq(nifs),bchan(nifs),nchan
	integer ndata
	logical flag(nifs),flags(ndata)
	complex vis(ndata),data(nvis)
	real fac(nifs)
c
c  Construct a visibility record constructed from multiple IFs.
c------------------------------------------------------------------------
	integer n,ipnt,i,nchand
c
	nchan = 0
	nchand = 0
	do n=1,nifs
	  if(nchand+nfreq(n).gt.ndata)
     *			call bug('f','Buffer overflow in GetDat')
	  ipnt = pnt(n)
	  if(ipnt.gt.0)then
	    if(nchan.lt.nchand)then
	      do i=nchan+1,nchand
		flags(i) = .false.
		vis(i) = 0
	      enddo
	      nchan = nchand
	    endif
c
	    do i=nchan+1,nchan+nfreq(n)
	      vis(i) = fac(n)*data(ipnt)
	      flags(i) = flag(n)
	      ipnt = ipnt + 1
	    enddo
	    if(bchan(n).ge.1.and.bchan(n).le.nfreq(n))
     *			flags(nchan+bchan(n)) = .false.
	    nchan = nchan + nfreq(n)
	  endif
	  nchand = nchand + nfreq(n)
	enddo
c
	if(nchan.lt.nchand.and.nchan.gt.0)then
	  do i=nchan+1,nchand
	    vis(i) = 0
	    flags(i) = .false.
	  enddo
	  nchan = nchand
	endif
c
	end
c************************************************************************
	subroutine AsciiCpy(in,out,length)
c
	implicit none
	character in*(*),out*(*)
	integer length
c
c------------------------------------------------------------------------
	integer i
c
c  Externals.
c
	integer len1
c
	length = 0
	out = ' '
	do i=1,len(in)
	  if(length.lt.len(out).and.in(i:i).ge.' ')then
	    length = length + 1
	    out(length:length) = in(i:i)
	  endif
	enddo
c
	length = len1(out)
c
	end
c************************************************************************
	subroutine SamCorr(nfreq,vis,pol,i1,i2,if,time,
     *		xsampler,ysampler,ATIF,ATANT)
c
	implicit none
	integer i1,i2,if,nfreq,pol,ATIF,ATANT
	real xsampler(3,ATIF,ATANT),ysampler(3,ATIF,ATANT)
	double precision time
	complex vis(nfreq)
c
c  Correct the data for the incorrect sampler statistics.
c
c------------------------------------------------------------------------
	double precision J20Jun91,J21Aug93,J11Dec93
	parameter(J20Jun91=2448427.5d0,J21Aug93=2449220.5d0)
	parameter(J11Dec93=2449332.5d0)
	integer PolXX,PolYY,PolXY,PolYX
	parameter(PolXX=-5,PolYY=-6,PolXY=-7,PolYX=-8)
	real fac, ssexp
	integer i
c
c  Externals.
c
	real twobit_gain_adjust
c
	if(time.gt.J11Dec93)return
	ssexp = 17.3
	if(time.gt.J20Jun91.and.time.le.J21Aug93)ssexp=17.1
c
	if(pol.eq.PolXX)then
	  fac = twobit_gain_adjust(ssexp,xsampler(1,if,i1),
     *					 xsampler(2,if,i1),
     *					 xsampler(3,if,i1),
     *					 xsampler(1,if,i2),
     *					 xsampler(2,if,i2),
     *					 xsampler(3,if,i2))
	else if(pol.eq.PolYY)then
	  fac = twobit_gain_adjust(ssexp,ysampler(1,if,i1),
     *					 ysampler(2,if,i1),
     *					 ysampler(3,if,i1),
     *					 ysampler(1,if,i2),
     *					 ysampler(2,if,i2),
     *					 ysampler(3,if,i2))
	else if(pol.eq.PolXY)then
	  fac = twobit_gain_adjust(ssexp,xsampler(1,if,i1),
     *					 xsampler(2,if,i1),
     *					 xsampler(3,if,i1),
     *					 ysampler(1,if,i2),
     *					 ysampler(2,if,i2),
     *					 ysampler(3,if,i2))
	else if(pol.eq.PolYX)then
	  fac = twobit_gain_adjust(ssexp,ysampler(1,if,i1),
     *					 ysampler(2,if,i1),
     *					 ysampler(3,if,i1),
     *					 xsampler(1,if,i2),
     *					 xsampler(2,if,i2),
     *					 xsampler(3,if,i2))
	else
	  fac = 1
	endif
c
	do i=1,nfreq
	  vis(i) = fac * vis(i)
	enddo
c
	end
c************************************************************************
c************************************************************************
	subroutine RPSkip(in,iostat)
c
	implicit none
	character in*(*)
	integer iostat
c
c  Skip an RPFITS file.
c------------------------------------------------------------------------
	call RPOpen(in,iostat)
	if(iostat.eq.0)call RPEOF(iostat)
	if(iostat.eq.0)call RPClose(iostat)
	end
c************************************************************************
	subroutine RPDisp(in,scanskip,scanproc,doauto,docross,docaldat,
     *	  relax,sing,unflag,nopol,polflag,ifsel,userfreq,nuser,iostat)
c
	implicit none
	character in*(*)
	integer scanskip,scanproc,ifsel,nuser,iostat
	double precision userfreq(*)
	logical doauto,docross,relax,unflag,polflag,sing,docaldat,nopol
c
c  Process an RPFITS file. Dispatch information to the
c  relevant Poke routine. Then eventually flush it out with PokeFlsh.
c
c  Inputs:
c    scanskip	Scans to skip.
c    scanproc	Number of scans to process. If 0, process all scans.
c    doauto	Save autocorrelation data.
c    docross	Save crosscorrelation data.
c    docaldat	Do not flag calibration data.
c    relax	Save data even if the SYSCAL record is bad.
c    sing
c    nopol	Select only the parallel-hand polarisations.
c    polflag	Flag all polarisations if any are bad.
c    unflag	Save data even though it may appear flagged.
c    ifsel	IF to select. 0 means select all IFs.
c    userfreq	User-given rest frequency to override the value in
c		the RPFITS file.
c    nuser	Number of user-specificed rest frequencies.
c------------------------------------------------------------------------
	include 'maxdim.h'
	include 'mirconst.h'
	integer MAXPOL,MAXSIM,MAXXYP,NDATA
	parameter(MAXPOL=4,MAXSIM=4,MAXXYP=5,NDATA=MAXCHAN*MAXPOL)
	double precision J01Jul04
	parameter(J01Jul04=2453187.5d0)
	include 'rpfits.inc'
	integer scanno,i1,i2,baseln,i,id,j
	logical NewScan,NewSrc,NewFreq,NewTime,Accum,ok,badbit
	logical flags(MAXPOL),corrfud,kband,wband,flipper
	integer jstat,flag,bin,ifno,srcno,simno,Ssrcno,Ssimno
	integer If2Sim(MAX_IF),nifs(MAX_IF),Sim2If(MAXSIM,MAX_IF)
	integer Sif(MAX_IF)
	real ut,utprev,utprevsc,u,v,w,weight(MAXCHAN*MAXPOL)
	complex vis(NDATA)
	double precision reftime,ra0,dec0,pntra,pntdec
	character calcode*16,sctype*16
c
c  The following has to agree with the first dimension of if_cstok in 
c  rpfits.inc.
c
	integer MPOL
	parameter(MPOL=4)
	integer nstoke(MAX_IF)
	character cstoke(MPOL,MAX_IF)*4
	logical pselect(MPOL,MAX_IF)
c
c  Information on flagging.
c
	integer nrec,nspec,fgbad,fgoffsrc,fginvant,fgsysc,fgsam,fgcal
c
c  Variables to track the sysc records.
c
	logical scinit(MAX_IF,ANT_MAX),scbuf(MAX_IF,ANT_MAX)
	logical xflag(MAX_IF,ANT_MAX),yflag(MAX_IF,ANT_MAX)
	integer ptag(MAXXYP,MAX_IF,ANT_MAX)
	integer atag(MAXXYP,MAX_IF,ANT_MAX)
	integer nxyp(MAX_IF,ANT_MAX),tcorr
	real xyp(MAXXYP,MAX_IF,ANT_MAX),xya(MAXXYP,MAX_IF,ANT_MAX)
	real xyphase(MAX_IF,ANT_MAX),xyamp(MAX_IF,ANT_MAX)
	real pntrms(ANT_MAX),pntmax(ANT_MAX)
	real xsamp(3,MAX_IF,ANT_MAX),ysamp(3,MAX_IF,ANT_MAX)
	real xtsys(MAX_IF,ANT_MAX),ytsys(MAX_IF,ANT_MAX)
	real chi,tint,mdata(9)
c
c  Variables for reference pointing.
c
	logical okref
	real refpnt(2,ANT_MAX)
c
	logical antvalid(ANT_MAX)
	integer mcount
	double precision jday0,time,tprev
c
c  Open the RPFITS file.
c
	call RPOpen(in,iostat)
	if(iostat.ne.0)return
c
c  Initialise.
c
	call PokeName(in)
	call AtFlush(mcount,scinit,tcorr,scbuf,xflag,yflag,
     *						MAX_IF,ANT_MAX)
c
c  Read the header.
c
	ncard = -1
	jstat = -1
	call rpfitsin(jstat,vis,weight,baseln,ut,u,v,w,flag,
     *						bin,ifno,srcno)
	if(jstat.ne.0)call bug('w','Error reading 1st RPFITS header')
	if(jstat.ne.0)return
c	if(card(1)(25:30).ne.'RPFITS')
c     *		      call bug('f','Input file is not in RPFITS format')
	sctype = 'unknown'
	okref = .false.
	if(ncard.gt.0)call sortcds(ncard,card,sctype,
     *					refpnt,ANT_MAX,okref)
c
c  Initialise.
c
	do j=1,ANT_MAX
	  do i=1,MAX_IF
	    nxyp(i,j) = 0
	  enddo
	enddo
c
	kband = .false.
	wband = .false.
c
c  Initialise flagging information.
c
	nrec  = 0
	fgbad = 0
	fgoffsrc = 0
	fginvant = 0
	fgsysc   = 0
	fgsam    = 0
	fgcal    = 0
c
	utprev   = -1
	utprevsc = -1
	Accum = .false.
	NewScan = .true.
	corrfud=.false.
	Ssrcno = 0
	Ssimno = 0
	scanno = 1
	tprev = 0
c
c  Loop the loop getting data.
c
	jstat = 0
	badbit = .false.
	dowhile(jstat.eq.0)
	  call rpfitsin(jstat,vis,weight,baseln,ut,u,v,w,flag,
     *						bin,ifno,srcno)
	  if(jstat.ne.5)badbit = .false.
c
c  Handle header encountered.  Note that the next header
c  read will be the same one we just encountered, not the
c  next one
c
	  if(jstat.eq.1)then
	    ncard = -1
	    jstat = -1
	    call rpfitsin(jstat,vis,weight,baseln,ut,u,v,w,flag,
     *						bin,ifno,srcno)
	    if(ncard.gt.0)
     *		call sortcds(ncard,card,sctype,refpnt,ANT_MAX,okref)
	    NewScan = .true.
	    scanno = scanno + 1
c
c  Flush the number of buffered samples.
c
	    do j=1,ANT_MAX
	      do i=1,MAX_IF
	        nxyp(i,j) = 0
	      enddo
	    enddo
c
c  Handle end-of-scan 
c
	  else if(jstat.eq.2)then
	    jstat = 0
c
c  Handle FG table encountered (ignore it)
c
          else if(jstat.eq.4)then
            jstat = 0
c
c  Handle some i/o error. First time tolerate it, but if it happens
c  immediately again, skip to the next header.
c
	  else if(jstat.eq.5)then
	    if(badbit)then
	      call bug('w', 
     *          'I/O error occurred with jstat=5. Look for next header')
	      jstat = -1
	      call rpfitsin(jstat,vis,weight,baseln,ut,u,v,w,flag,
     *						bin,ifno,srcno)
	      NewScan = .true.
	      scanno = scanno + 1
	    else
	      badbit = .true.
	      jstat = 0
	    endif
c
c  Other errors, including EOF.
c
          else if(jstat.ne.0)then
	    continue
c
c  Check if we have run out of records of interest. If so, skip to the
c  end of the file and pretend we have hit EOF.
c
	  else if(scanproc.gt.0.and.scanno.gt.scanskip+scanproc)then
	    call RPEOF(jstat)
	    if(jstat.eq.0)jstat = 3
c
c  Handle a SYSCAL record. If it appears to belong to this integration,
c  send it through to the Poke routines right away. Otherwise, end the
c  integration and buffer up the SYSCAL record for later delivery.
c
	  else if(baseln.eq.-1)then
	    NewTime = abs(sc_ut-utprevsc).gt.0.04
	    if(NewScan.or.an_found.or.NewTime)then
	      call AtFlush(mcount,scinit,tcorr,
     *			scbuf,xflag,yflag,MAX_IF,ANT_MAX)
	      Accum = .false.
	      utprevsc = sc_ut
	    endif
	    call SetSC(scinit,scbuf,MAX_IF,ANT_MAX,sc_q,sc_if,sc_ant,
     *		sc_cal,if_invert,polflag,
     *		xyphase,xyamp,xtsys,ytsys,xsamp,ysamp,
     *		chi,tcorr,pntrms,pntmax,
     *		nxyp,xyp,ptag,xya,atag,MAXXYP,xflag,yflag,wband,
     *		mdata,mcount)
c
c  Data record. Check whether we want to accept it.
c  If OK, and we have a new scan, calculate the new scan info.
c
	  else if(ifno.lt.1.or.ifno.gt.n_if.or.srcno.lt.1)then
	    fgbad = fgbad + 1
	  else
	    ok = scanno.gt.scanskip
	    if(ok.and.NewScan)then
	      call dayjul(datobs,jday0)
	      time = ut / (3600.d0*24.d0) + jday0
c
c  Now we cludge a correlator fix:
c  It can happen that the datobs is written just before the 
c  change of a ut day, but the ut is written after the change of
c  ut day. What the correlator should do is write the ut as ut+8640,
c  but as of 10-04-01 it didn't. 
c  So, in this case, jday0 should be incremented here.
c  We assume no-one is going to average more than 30 sec...
c
	      if ((ut .lt. 30) .and. (86400*(time-tprev).lt.-1)) then
		jday0=jday0+1
		time = ut / (3600.d0*24.d0) + jday0
		corrfud=.true.
		call bug('w',
     *          'Assuming first scan of integration')
		call bug('w',
     *          'started before UT day rollover')
	      endif
	      call SimMap(if_num,n_if,if_simul,if_chain,ifsel,
     *		  If2Sim,nifs,Sim2If,Sif,MAXSIM)
	      call ChkAnt(x,y,z,antvalid,nant,sing)
	      call PolMap(nopol,MPOL,n_if,if_nstok,if_cstok,
     *		nstoke,cstoke,pselect)
	    endif
c
c  Determine whether to flush the buffers.
c
	    simno = If2Sim(ifno)
	    NewFreq = simno.ne.Ssimno
	    NewTime = abs(ut-utprev).gt.0.04
	    NewSrc = srcno.ne.Ssrcno
	    if(Accum.and.(NewScan.or.an_found.or.NewSrc.or.NewFreq.or.
     *							NewTime))then
	      call AtFlush(mcount,scinit,tcorr,
     *		scbuf,xflag,yflag,MAX_IF,ANT_MAX)
	      Accum = .false.
	    endif
c
	    i1 = baseln/256
	    i2 = mod(baseln,256)
	    if(ok) ok = (i1.eq.i2.and.doauto).or.(i1.ne.i2.and.docross)
            if(ok)then
	      ok = ifno.ge.1.and.ifno.le.n_if.and.
     *	    	   min(i1,i2).ge.1.and.max(i1,i2).le.nant.and.
     *		   bin.ge.0
	      if(.not.ok)fgbad = fgbad + 1
	    endif
            if(ok)ok = If2Sim(ifno).gt.0
	    if(ok) then
	      nspec = nstoke(ifno)
	      nrec = nrec + nspec
	      if((sctype.eq.'point'.or.sctype.eq.'paddle').and.
     *			.not.docaldat)then
	        flag = 1
	        fgcal = fgcal + nspec
	      else if(flag.ne.0)then
		fgoffsrc = fgoffsrc + nspec
	      else if(.not.(antvalid(i1).and.antvalid(i2)))then
		flag = 1
		fginvant = fginvant + nspec
	      else if(.not.((scinit(ifno,i1).and.scinit(ifno,i2)).or.
     *		relax))then
		flag = 1
		fgsysc = fgsysc + nspec
	      endif
	      if(ok) ok = flag.eq.0.or.unflag
	    endif
c
c  If we are going to accept it, see if we need to flush the buffers.
c
	    if(ok)then
c
c  Initialise the Poke routines with new info as required.
c
	      if(.not.Accum)then
	        time = ut / (3600.d0*24.d0) + jday0
		call Poke1st(time,nifs(simno),nant)
		if(NewScan)call PokeMisc(instrument,rp_observer,
     *						version,sctype)
	        if(an_found)call PokeAnt(nant,x,y,z,sing)
	        if(NewScan.or.NewFreq)then
		  kband = .false.
		  wband = .false.
		  do i=1,nifs(simno)
		    id = Sim2If(i,simno)
		    if(nuser.ge.i)rfreq = 1e9*userfreq(i)
		    kband = kband.or.
     *			   (if_freq(id).gt.13e9.and.if_freq(id).lt.28e9)
		    wband = wband.or.if_freq(id).gt.75e9
		    call PokeIF(i,if_nfreq(id),if_invert(id)*if_bw(id),
     *			if_freq(id),if_ref(id),rfreq,
     *			nstoke(id),cstoke(1,id))
		  enddo
		endif
		calcode = su_cal(srcno)
		if(su_name(srcno).eq.'1934-638')calcode = 'c'
		if(NewScan)then
		  call cacalTyp(calcode,time)
		  call PokeInfo(scanno,time)
		endif
	 	pntra = su_pra(srcno)
		pntdec = su_pdec(srcno)
		if(pntra.eq.0.or.pntdec.eq.0)then
		  pntra = su_ra(srcno)
		  pntdec = su_dec(srcno)
		endif
		if(abs(pm_ra)+abs(pm_dec).gt.0)then
		  reftime = pm_epoch + 2 400 000.5d0
		  ra0  = 2*DPI/(24d0*3600d0*365.25d0) * pm_ra
		  ra0  = su_ra(srcno)  + ra0* (time-reftime)
		  dec0 = 2*DPI/(360.d0*3600d0*365.25d0) * pm_dec
		  dec0 = su_dec(srcno) + dec0*(time-reftime)
		  call PokeSrc(su_name(srcno),ra0,dec0,0.d0,0.d0,
     *			pntra,pntdec,calcode)
		else if(NewScan.or.NewSrc)then
c		if(NewScan.or.NewSrc)then
		  call PokeSrc(su_name(srcno),
     *		  su_ra(srcno),su_dec(srcno),
     *		  su_rad(srcno),su_decd(srcno),pntra,pntdec,calcode)
		endif
	      endif
c
c  Flush out the met data and reference pointing if needed.
c
	      if(okref)then
		call PokeRef(refpnt,nant)
		okref = .false.
	      endif
	      if(mcount.gt.0)then
		call PokeMet(mdata,mcount)
		mcount = 0
	      endif
c
c  Flush out any buffered SYSCAL records.
c
	      if(scbuf(ifno,i1))call PokeSC(i1,Sif(ifno),chi,tcorr,
     *		xtsys(ifno,i1),ytsys(ifno,i1),
     *		xyphase(ifno,i1),xyamp(ifno,i1),
     *		xsamp(1,ifno,i1),ysamp(1,ifno,i1),
     *		pntrms(i1),pntmax(i1))
	      if(scbuf(ifno,i2))call PokeSC(i2,Sif(ifno),chi,tcorr,
     *		xtsys(ifno,i2),ytsys(ifno,i2),
     *		xyphase(ifno,i2),xyamp(ifno,i2),
     *		xsamp(1,ifno,i2),ysamp(1,ifno,i2),
     *		pntrms(i2),pntmax(i2))
c
	      scbuf(ifno,i1) = .false.
	      scbuf(ifno,i2) = .false.
c
c  Determine the flags for each polarisation based on the sampler
c  statistics if the samplers have been initialised.
c
	      call GetFg(nstoke(ifno),cstoke(1,ifno),flag,
     *		xflag(ifno,i1).or.relax,yflag(ifno,i1).or.relax,
     *		xflag(ifno,i2).or.relax,yflag(ifno,i2).or.relax,
     *		flags,fgsam)
c
c  Send the data record to the Poke routines.
c
	      if(bin.eq.0) bin = 1
c	      tint = 0
	      tint = intbase
	      if(tint.eq.0)tint = intime
	      if(tint.eq.0)tint = 15.0
	      flipper = .not.kband.or.time.gt.J01Jul04
c
c  It is pretty late to be checking for a buffer overflow, but RPFITSIN's
c  interface does not guard against it at all! So at least we are checking!
c
	      if(if_nfreq(ifno)*if_nstok(ifno).gt.NDATA)
     *		call bug('f','Buffer overflow within rpfitsin')
c
	      if(nstoke(ifno).ne.if_nstok(ifno))
     *		call vissy(vis,if_nfreq(ifno),if_nstok(ifno),
     *		  pselect(1,ifno))
c
	      call PokeData(u,v,w,baseln,Sif(ifno),bin,
     *		vis,if_nfreq(ifno),nstoke(ifno),flags,
     *		tint,if_invert(ifno).lt.0,flipper,.not.wband)
c
c  Reinitialise things.
c
	      if (86400*(time-tprev).lt.-1) then
		if (.not. corrfud) then
                  call bug('w',
     *		   'Data are out of time order')
		else
		  corrfud = .false.
		endif
	      endif
	      tprev = time
	      utprev = ut
	      Accum = .true.
	      Ssrcno = srcno
	      Ssimno = simno
	      NewScan = .false.
	      an_found = .false.
	    endif
	  endif
	enddo
c
c  Flush out anything remaining.
c
	if(Accum.and.jstat.eq.3)call PokeFlsh
c
c  Give summary about flagging.
c
	if(version.le.' ')version='unknown'
	call liner('RPFITS file version is '//version)
	call PokeStat(nrec,fgbad,fgoffsrc,fginvant,fgsysc,fgsam,fgcal)
c
c  We are done. Close up, and return the error code.
c
	call RPClose(iostat)
	if(iostat.eq.0.and.jstat.ne.3)iostat = jstat
c
	end
c************************************************************************
	subroutine RPEOF(jstat)
c
	implicit none
	integer jstat
c
c  Skip to the EOF.
c
c------------------------------------------------------------------------
	integer flag,baseln,bin,ifno,srcno
	real ut,u,v,w,weight
	complex vis
c
	character rperr*32
c
	jstat = 2
	call rpfitsin(jstat,vis,weight,baseln,ut,u,v,w,flag,
     *						bin,ifno,srcno)
	if(jstat.eq.3)jstat = 0
	if(jstat.ne.0)call bug('w',
     *		'Error while skipping: '//rperr(jstat))
	end
c************************************************************************
	character*(*) function RPErr(jstat)
c
	implicit none
	integer jstat
c
c  Translate an RPFITSIN jstat value into something a bit more
c  meaningful.
c------------------------------------------------------------------------
	character itoaf*8
c
	integer NMESS
	parameter(NMESS=7)
	character mess(NMESS)*32
	data mess/'Operation unsuccessful          ',
     *		  'Operation successful            ',
     *            'Encountered header while reading',
     *		  'Probably OK ... End of scan     ',
     *		  'Encountered end-of-file	   ',
     *		  'Encountered FG table            ',
     *		  'Illegal parameter encountered   '/
c
	if(jstat.ge.-1.and.jstat.le.5)then
	  rperr = mess(jstat+2)
	else
	  rperr = 'RPFITS error: jstat='//itoaf(jstat)
	endif
c
	end
c************************************************************************
	subroutine RPClose(jstat)
c
	implicit none
	integer jstat
c------------------------------------------------------------------------
	integer flag,baseln,bin,ifno,srcno
	real ut,u,v,w,weight
	complex vis
c
	character rperr*32
c
	jstat = 1
	call rpfitsin(jstat,vis,weight,baseln,ut,u,v,w,flag,
     *						bin,ifno,srcno)
	if(jstat.ne.0)call bug('w',
     *		'Error closing file: '//rperr(jstat))
	end
c************************************************************************
	subroutine RPOpen(in,jstat)
c
	implicit none
	character in*(*)
	integer jstat
c
c  Open the RPFITS file.
c------------------------------------------------------------------------
	include 'rpfits.inc'
c
	integer flag,baseln,bin,ifno,srcno
	real ut,u,v,w,weight
	complex vis
c
c  External.
c
	character rperr*32
c
	file = in
c
	jstat = -3
	an_found = .false.
	call rpfitsin(jstat,vis,weight,baseln,ut,u,v,w,flag,
     *						bin,ifno,srcno)
	if(jstat.ne.0) call bug('w',
     *	    'Error opening RPFITS file: '//rperr(jstat))
	if(jstat.ne.0)return
	end
c************************************************************************
	subroutine PolMap(nopol,mpol,nif,nstin,cstin,nstout,cstout,
     *								pselect)
c
	implicit none
	integer nif,mpol
	integer nstin(nif),nstout(nif)
	logical pselect(mpol,nif),nopol
	character cstin(mpol,nif)*(*),cstout(mpol,nif)*(*)
c
c  Weed out non-parallel-hand polarisations from the list of Stokes
c  parameters.
c
c  Input:
c    nif
c    nstin
c    cstin
c  Output:
c    nstout
c    cstout
c    pselect
c------------------------------------------------------------------------
	integer i,j
	character token*4
c
	if(nopol)then
	  do j=1,nif
	    nstout(j) = 0
	    do i=1,nstin(j)
	      token = cstin(i,j)
	      call ucase(token)
	      if(token.eq.'XX'.or.token.eq.'YY'.or.
     *	         token.eq.'RR'.or.token.eq.'LL'.or.token.eq.'I')then
	        nstout(j) = nstout(j) + 1
	        cstout(nstout(j),j) = cstin(i,j)
	        pselect(i,j) = .true.
	      else
	        pselect(i,j) = .false.
	      endif
	    enddo
	  enddo
	else
	  do j=1,nif
	    nstout(j) = nstin(j)
	    do i=1,nstin(j)
	      cstout(i,j) = cstin(i,j)
	      pselect(i,j) = .true.
	    enddo
	  enddo
	endif
c
	end
c************************************************************************
	subroutine vissy(vis,nchan,nstin,pselect)
c
	implicit none
	integer nchan,nstin
	complex vis(nstin*nchan)
	logical pselect(nstin)
c------------------------------------------------------------------------
	integer ki,ko,i,j
c
	ki = 0
	ko = 0
	do j=1,nchan
	  do i=1,nstin
	    ki = ki + 1
	    if(pselect(i))then
	      ko = ko + 1
	      vis(ko) = vis(ki)
	    endif
	  enddo
	enddo
c
	end
c************************************************************************
	character*(*) function pcent(frac,total)
c
	implicit none
	integer frac,total
c------------------------------------------------------------------------
	character val*5
	real x
	x = real(100*frac)/real(total)
	if(x.gt.9.99)then
	  write(val,'(f5.1)')x
	else
	  write(val,'(f5.2,a)')x
	endif
	pcent = val//'%'
	end
c************************************************************************
	subroutine ChkAnt(x,y,z,antvalid,nant,sing)
c
	implicit none
	integer nant
	double precision x(nant),y(nant),z(nant)
	logical antvalid(nant),sing
c
c  Check for a valid antenna position.
c------------------------------------------------------------------------
	integer i
c
	do i=1,nant
	  antvalid(i) = (abs(x(i)) + abs(y(i)) + abs(z(i)).gt.0).or.
     *			sing
	enddo
c
	end
c************************************************************************
	subroutine GetFg(nstok,cstok,flag,xflag1,yflag1,xflag2,yflag2,
     *		flags,fgsam)
c
	implicit none
	integer nstok,flag,fgsam
	character cstok(nstok)*(*)
	logical flags(nstok),xflag1,yflag1,xflag2,yflag2
c
c  Flag a polarisation either if "flag" indicates that the entire record
c  is bad, or if the syscal-based flags are bad.
c------------------------------------------------------------------------
	integer p

c
	if(flag.ne.0)then
	  do p=1,nstok
	    flags(p) = .false.
	  enddo
	else
	  do p=1,nstok
	    if(cstok(p).eq.'XX')then
	      flags(p) = xflag1.and.xflag2
	    else if(cstok(p).eq.'YY')then
	      flags(p) = yflag1.and.yflag2
	    else if(cstok(p).eq.'XY')then
	      flags(p) = xflag1.and.yflag2
	    else if(cstok(p).eq.'YX')then
	      flags(p) = yflag1.and.xflag2
	    else
	      call bug('f','Unrecognised polarisation type, in GetFg')
	    endif
	    if(.not.flags(p))fgsam = fgsam + 1
	  enddo
	endif
c
	end
c************************************************************************
	subroutine syscflag(polflag,xsamp,ysamp,xyphase,xyamp,
     *		nxyp,maxxyp,xyp,ptag,xya,atag,xflag,yflag,mmrelax)
c
	implicit none
	real xsamp(3),ysamp(3),xyphase,xyamp
	integer nxyp,maxxyp,ptag(maxxyp),atag(maxxyp)
	real xyp(maxxyp),xya(maxxyp)
	logical polflag,xflag,yflag,mmrelax
c
c  Determine data flags based on the values of syscal statistics.
c
c  The data will be flagged bad if:
c    * The sampler stats deviate by 3% from 17.3%, or 0.5% from 50.0%
c    * There is a 10 degree change in the xyphase relative to the median
c      of the "nxyp" values.
c    * There is a 1 Jy or 10% change in the xyamp relative to the median
c      of the "nxyp" values.
c
c  Input:
c    xsamp	The x sampler statistics (percent).
c    ysamp	The y sampler statistics (percent).
c    xyphase	The online xyphase measurement (radians).
c    xyamp	XY amplitude, in (pseudo)Jy.
c    maxxyp	The max number of xy phase 
c  Input/Output:
c    nxyp	Number of buffered xyphase measurements.
c    tag	Tags for xyphase measurements. The oldest xyphase measurement
c		has the smallest tag value.
c    xyp	Buffered xyphase measurements. These are always
c		sorted into ascending order. In radians.
c    xya	Buffered xyamp measurements. These are always
c		sorted into ascending order. In (pseudo)Jy.
c
c  Output:
c    xflag	Flag for the X channel.
c    yflag	Flag for the y channel.
c------------------------------------------------------------------------
	include 'mirconst.h'
	real mxyp,mxya
	integer ntemp
c
	ntemp = nxyp
	call MedMerge(nxyp,maxxyp,xyphase,xyp,ptag,mxyp)
	call MedMerge(ntemp,maxxyp,xyamp,xya,atag,mxya)
c
c  Flag both x and y as bad if there is a glitch in the xy phase.
c  Otherwise flag according to the goodness of the sampler stats.
c
	if((abs(xyamp-mxya).gt.max(1.0,0.1*mxya).or.
     *	   abs(xyphase-mxyp).gt.10.*pi/180.).and..not.mmrelax)then
	  xflag = .false.
	  yflag = .false.
	else
	  xflag = abs(xsamp(2)-50.0).lt.0.5 .and.
     *		  abs(xsamp(1)-17.3).lt.3.0 .and.
     *		  abs(xsamp(3)-17.3).lt.3.0
	  yflag = abs(ysamp(2)-50.0).lt.0.5 .and.
     *		  abs(ysamp(1)-17.3).lt.3.0 .and.
     *		  abs(ysamp(3)-17.3).lt.3.0
	  if(polflag)then
	    xflag = xflag.and.yflag
	    yflag = xflag
	  endif
	endif
c
	end
c************************************************************************
	subroutine MedMerge(nxyp,maxxyp,xyphase,xyp,tag,mxyp)
c
	implicit none
	integer nxyp,maxxyp,tag(maxxyp)
	real xyphase,xyp(maxxyp),mxyp
c------------------------------------------------------------------------
	integer tmin,tmax,i,nxyp2
	logical more
c
c  Find the xyphase with the biggest and smallest tags.
c
	if(nxyp.gt.0)then
	  tmax = 1
	  tmin = 1
	  do i=2,nxyp
	    if(tag(i).gt.tag(tmax))tmax = i
	    if(tag(i).lt.tag(tmin))tmin = i
	  enddo
	  tmax = tag(tmax) + 1
	else
	  tmax = 1
	endif
c
c  If the buffer is full, discard the xyphase with the minimum tag,
c  by squeezing it out.
c
	if(nxyp.eq.maxxyp)then
	  do i=tmin+1,nxyp
	    xyp(i-1) = xyp(i)
	    tag(i-1) = tag(i)
	  enddo
	else
	  nxyp = nxyp + 1
	endif
c
c  Merge in the new xyphase.
c
	i = nxyp
	more = i.gt.1
	dowhile(more)
	  more = xyp(i-1).gt.xyphase
	  if(more)then
	    xyp(i) = xyp(i-1)
	    tag(i) = tag(i-1)
	    i = i - 1
	    more = i.gt.1
	  endif
	enddo
	xyp(i) = xyphase
	tag(i) = tmax
c
c  Determine the median xyphase
c
	nxyp2 = nxyp/2
	if(2*nxyp2.ne.nxyp)then
	  mxyp = xyp(nxyp2+1)
	else
	  mxyp = 0.5*(xyp(nxyp2)+xyp(nxyp2+1))
	endif
c
	end
c************************************************************************
	real function getjpk(freq)
c
	implicit none
	real freq
c------------------------------------------------------------------------
	if(freq.lt.15)then
	  getjpk = 13
	else if(freq.lt.30)then
	  getjpk = 13
	else
	  getjpk = 13
	endif
c
	end
c************************************************************************
	subroutine SetSC(scinit,scbuf,MAXIF,MAXANT,nq,nif,nant,
     *		syscal,invert,polflag,
     *		xyphase,xyamp,xtsys,ytsys,xsamp,ysamp,
     *		chi,tcorr,pntrms,pntmax,nxyp,xyp,ptag,xya,atag,MAXXYP,
     *		xflag,yflag,mmrelax,mdata,mcount)
c
	implicit none
	integer MAXIF,MAXANT,MAXXYP,nq,nif,nant,invert(MAXIF)
	integer tcorr,mcount
	real syscal(nq,nif,nant),mdata(9)
	logical polflag
	logical scinit(MAXIF,MAXANT),scbuf(MAXIF,MAXANT)
	real xyphase(MAXIF,MAXANT),xyamp(MAXIF,MAXANT)
	real xtsys(MAXIF,MAXANT),ytsys(MAXIF,MAXANT)
	real xsamp(3,MAXIF,MAXANT),ysamp(3,MAXIF,MAXANT)
	real pntrms(MAXANT),pntmax(MAXANT)
	real chi
	real xyp(MAXXYP,MAXIF,MAXANT),xya(MAXXYP,MAXIF,MAXANT)
	integer ptag(MAXXYP,MAXIF,MAXANT)
	integer atag(MAXXYP,MAXIF,MAXANT)
	integer nxyp(MAXIF,MAXANT)
	logical xflag(MAXIF,MAXANT),yflag(MAXIF,MAXANT),mmrelax
c
c  Copy across SYSCAL records. Do any necessary fiddles on the way.
c------------------------------------------------------------------------
	include 'mirconst.h'
	integer j,k,ij,ik
	logical done,ok
c
	done = .false.
	do k=1,nant
	  do j=1,nif
	    ik = nint(syscal(1,j,k))
	    ij = nint(syscal(2,j,k))
	    ok = ij.gt.0.and.ik.gt.0.and.ij.le.maxif.and.ik.le.maxant
	    if(ok.and.nq.ge.13) ok = syscal(13,j,k).eq.0
	    if(ok)then
	      scinit(ij,ik) = .true.
	      scbuf(ij,ik)  = .true.
	      xyphase(ij,ik) = invert(ij)*syscal(3,j,k)
	      xyamp(ij,ik) = 0
	      if(nq.ge.14)xyamp(ij,ik) = syscal(14,j,k)
	      pntrms(ik) = 0
	      if(nq.ge.16)pntrms(ik) = syscal(16,j,k)
	      pntmax(ik) = 0
	      if(nq.ge.15)pntmax(ik) = syscal(15,j,k)
	      if(syscal(4,j,k).gt.0)tcorr = tcorr + 1
	      if(syscal(5,j,k).gt.0)tcorr = tcorr + 1
	      xtsys(ij,ik) = 0.1* syscal(4,j,k) * syscal(4,j,k)
	      ytsys(ij,ik) = 0.1* syscal(5,j,k) * syscal(5,j,k)
	      xsamp(1,ij,ik) = syscal(6,j,k)
	      xsamp(2,ij,ik) = syscal(7,j,k)
	      xsamp(3,ij,ik) = syscal(8,j,k)
	      ysamp(1,ij,ik) = syscal(9,j,k)
	      ysamp(2,ij,ik) = syscal(10,j,k)
	      ysamp(3,ij,ik) = syscal(11,j,k)
	      call syscflag(polflag,xsamp(1,ij,ik),ysamp(1,ij,ik),
     *		xyphase(ij,ik),xyamp(ij,ik),nxyp(ij,ik),maxxyp,
     *		xyp(1,ij,ik),ptag(1,ij,ik),xya(1,ij,ik),atag(1,ij,ik),
     *		xflag(ij,ik),yflag(ij,ik),mmrelax)
	      if(.not.done.and.syscal(12,j,k).ne.0)then
		chi = pi/180 * syscal(12,j,k) + pi/4
		done = .true.
	      endif
c
c  Save met data. The array consists of
c    1 Temperature
c    2 Pressure
c    3 Humidity
c    4 Wind speed
c    5 Wind direction
	    else if(ik.eq.0)then
	      mcount = 6
	      mdata(1) = syscal(2,j,k)
	      mdata(2) = syscal(3,j,k)
	      mdata(3) = syscal(4,j,k)
	      mdata(4) = syscal(5,j,k)
	      mdata(5) = syscal(6,j,k)
	      mdata(6) = syscal(7,j,k)
	      mdata(7) = syscal(8,j,k)
	      mdata(8) = syscal(9,j,k)
	      mdata(9) = syscal(10,j,k)
	      if(syscal(11,j,k).eq.0)mcount=9
	    endif
	  enddo
	enddo
c
	end
c************************************************************************
	subroutine AtFlush(mcount,scinit,tcorr,scbuf,xflag,yflag,
     *							MAXIF,MAXANT)
c
	implicit none
	integer MAXIF,MAXANT
	integer tcorr,mcount
	logical scinit(MAXIF,MAXANT),scbuf(MAXIF,MAXANT)
	logical xflag(MAXIF,MAXANT),yflag(MAXIF,MAXANT)
c
c------------------------------------------------------------------------
	integer i,j
c
	mcount = 0
	do j=1,MAXANT
	  do i=1,MAXIF
	    scinit(i,j) = .false.
	    scbuf(i,j)  = .false.
	    xflag(i,j)  = .false.
	    yflag(i,j)  = .false.
	  enddo
	enddo
	tcorr = 0
c
	call PokeFlsh
c
	end
c************************************************************************
	subroutine SimMap(ifnum,nif,ifsimul,ifchain,ifsel,
     *		  If2Sim,nifs,Sim2If,Sif,MAXSIM)
c
	implicit none
	integer nif,ifnum(nif),ifsimul(nif),ifchain(nif),ifsel,MAXSIM
	integer If2Sim(nif),nifs(nif),Sim2IF(MAXSIM,nif),Sif(nif)
c
c  Using the RPFITS IF table, determine a map between RPFITS "ifno",
c  to a simultaneous group number. Then determine a map between the
c  simultaneous group number and the RPFITS "ifno" number.
c
c  What the &%^$&^%&^ is the RPFITS entry "IF_NUM" used for? Is it
c  an extra level of indirection in the the IF table or what? Avoid
c  attempting to understand this (no one else does). Just make sure
c  that IF_NUM(i).eq.i, which means that IF_NUM must be redundant and
c  irrelevant.
c
c  Input:
c    nif	Total number of entries in the RPFITS IF table.
c    ifnum	RPFITS IF_NUM column. Just check that IF_NUM(i)==i.
c    ifsimul,ifchain RPFITS columns.
c    ifsel	IF axis to select (user specified).
c    MAXSIM	Maximum number of simultaneous frequencies.
c  Output:
c    If2Sim	Map from ifno to "simultaneous group number".
c    Sim2If	Map from "simultaneous group number" to "ifno". There can
c		be up to MAXSIM entries per "sim. group no.".
c    nifs	Number of simultaneous IFs in each sim. group.
c    Sif	Maps from RPFITS ifno to the position on the Miriad IF axis.
c------------------------------------------------------------------------
	integer i,j,nsimgrp,s
	logical more
c
	do i=1,nif
	  if(ifnum(i).ne.i)call bug('f',
     *		'IF_NUM(i).ne.i ... I do not understand')
	enddo
c
c  Assign a simultaneous IF to each of them.
c
	nsimgrp = 0
	do i=1,nif
	  If2Sim(i) = 0
	  if(ifsel.eq.0.or.ifsel.eq.ifchain(i))then
	    do j=1,i-1
	      if(ifsimul(i).eq.ifsimul(j).and.If2Sim(j).gt.0)
     *		If2Sim(i) = If2Sim(j)
	    enddo
	    if(If2Sim(i).eq.0)then
	      nsimgrp = nsimgrp + 1
	      If2Sim(i) = nsimgrp
	      nifs(nsimgrp) = 0
	    endif
	  endif
	enddo
c
c  Map from simultaneous group number to ifno.
c
	do i=1,nif
	  s = If2Sim(i)
	  if(s.gt.0)then
	    nifs(s) = nifs(s) + 1
	    Sim2If(nifs(s),s) = i
	  endif
	enddo
c
c  Sort the Sim2If index so that the ifno with smaller IF_CHAIN come
c  first.
c
	do i=1,nsimgrp
	  more = .true.
	  dowhile(more)
	    more = .false.
	    do j=2,nifs(i)
	      if(ifchain(Sim2If(j,i)).lt.ifchain(Sim2If(j-1,i)))then
		s = Sim2If(j,i)
		Sim2If(j,i) = Sim2If(j-1,i)
		Sim2If(j-1,i) = s
		more = .true.
	      endif
	    enddo
	  enddo
	enddo
c
c  Determine the map from the RPFITS ifno variable to the position on the
c  Miriad IF axis.
c
	do i=1,nif
	  Sif(i) = 0
	enddo
c
	do i=1,nsimgrp
	  do j=1,nifs(i)
	    Sif(Sim2If(j,i)) = j
	  enddo
	enddo
c
	end
c************************************************************************
	subroutine cacalIni
c
	implicit none
c------------------------------------------------------------------------
	integer MAXTIMES
	parameter(MAXTIMES=32)
	integer bcal,scal,ntimes
	double precision stime,times(2,MAXTIMES)
	common/cacalcom/times,stime,ntimes,scal,bcal
c
	scal = -1
	bcal = -1
	stime = 0
	ntimes = 0
	end
c************************************************************************
	subroutine cacalCnt(count)
c
	implicit none
	integer count
c------------------------------------------------------------------------
	integer MAXTIMES
	parameter(MAXTIMES=32)
	integer bcal,scal,ntimes
	double precision stime,times(2,MAXTIMES)
	common/cacalcom/times,stime,ntimes,scal,bcal
c
	bcal = count
 	end
c************************************************************************
	subroutine cacalTyp(calcode,time)
c
	implicit none
	character calcode*(*)
	double precision time
c------------------------------------------------------------------------
	integer MAXTIMES
	parameter(MAXTIMES=32)
	integer bcal,scal,ntimes
	double precision stime,times(2,MAXTIMES)
	common/cacalcom/times,stime,ntimes,scal,bcal
c
	if(bcal.ge.0)then
	  if(scal.ge.0..and.bcal.gt.scal.and.
     *	     time-stime.gt.0.and.time-stime.le.0.5/24.0)then
	    ntimes = ntimes + 1
	    if(ntimes.gt.MAXTIMES)
     *		call bug('f','Buffer overflow in cacalTyp')
	    times(1,ntimes) = stime
	    times(2,ntimes) = time
	  endif
	  if(index(calcode,'c').ne.0.or.index(calcode,'C').ne.0)then
	    scal = bcal
	    stime = time
	  else
	    scal = -1
	  endif
	  bcal = -1
	endif
c
	end
c************************************************************************
	subroutine cacalFin(time1,MAXTIME1,ntime1)
c
	implicit none
	integer MAXTIME1,ntime1
	double precision time1(2,MAXTIME1)
c------------------------------------------------------------------------
	integer MAXTIMES
	parameter(MAXTIMES=32)
	integer bcal,scal,ntimes
	double precision stime,times(2,MAXTIMES)
	common/cacalcom/times,stime,ntimes,scal,bcal
c
	integer i
c
	if(ntimes.gt.MAXTIME1)
     *	  call bug('f','Buffer overflow in cacalFin')
	do i=1,ntimes
	  time1(1,i) = times(1,i)
	  time1(2,i) = times(2,i)
	enddo
	ntime1 = ntimes
c	  
	end
c************************************************************************
c************************************************************************
c
c  The following code was contributed by WEW via NEBK.
c
c------------------------------------------------------------------------
      REAL FUNCTION TWOBIT_GAIN_ADJUST(SSEXP, N1, Z1, P1, N2, Z2, P2)
C----------------------------------------------------------------------
C
C      Finds gain correction factor to be applied to data whose
C      gain has been calculated on the assumption that the
C      sampler statistics were either set on :
C
C      17.1, 50.0, 17.1 percent, for SSEXP = 17.1
C                  --OR--   
C      17.3, 50.0, 17.3 percent, for SSEXP = 17.3
C
C      whereas they were actually n1, z1, p1 and n2, z2, p2 percent
C      on inputs 1,2.  ( n=neg, z=zero, p=pos )
C
C      The data should be multiplied by twobit_gain_adjust
C      to obtain the corrected data.
C
C----------------------------------------------------------------------

C PARAMETERS
      REAL      N1, Z1, P1, N2, Z2, P2, SSEXP

C EXTERNAL FUNCTIONS
      REAL      GAIN_PARAM, TWOBIT_GAIN_R0

C LOCAL VARIABLES
      REAL      QN1, QZ1, QP1, QN2, QZ2, QP2
      REAL      A

C BEGIN

      QN1 = GAIN_PARAM( N1 )
      QZ1 = GAIN_PARAM( Z1 )
      QP1 = GAIN_PARAM( P1 )

      QN2 = GAIN_PARAM( N2 )
      QZ2 = GAIN_PARAM( Z2 )
      QP2 = GAIN_PARAM( P2 )

C In the following, a is the gain that was applied on line. 
C It is calculated from
C  a = average correlator count / digital correlator gain at
C      zero correlation

      IF (SSEXP.GT.17.2) THEN
C          5.444705 = 6.19 / 1.1368844
         A = 5.444705
      ELSE IF (SSEXP.GT.17.0) THEN
C          5.392175663 = 6.13 / 1.1368324
         A = 5.392175663 
      END IF
         
C
      TWOBIT_GAIN_ADJUST = A /
     *     TWOBIT_GAIN_R0( QN1, QZ1, QP1, QN2, QZ2, QP2 )
      END
c************************************************************************
      REAL FUNCTION GAIN_PARAM( LEVEL_PERCENT )
C----------------------------------------------------------------------
C
C      Gets "gain parameter" - i.e. parameter useful for calculating
C      gain of 2-bit digital correlator for uncorrelated inputs
C      where one of the sampler statistics is level_percent.
C
C----------------------------------------------------------------------

C PARAMETERS
      REAL      LEVEL_PERCENT

C EXTERNAL FUNCTIONS
      REAL      GAUSS_LEVEL

C LOCAL VARIABLES
      REAL      X

C BEGIN

C Find level ( RMS = 1.0 ) appropriate to this statistic
      X = GAUSS_LEVEL( LEVEL_PERCENT / 100.0 )

      GAIN_PARAM = EXP( -X * X / 2.0 )

      END
c************************************************************************
      REAL FUNCTION GAUSS_LEVEL( FRACTION_ABOVE_LEVEL )
C----------------------------------------------------------------------
C
C      Assuming Gaussian statistics, estimates the level given
C       the probability of being above this level, i.e.
C       the fraction of samples above this level.
C
C      Ref.      Approximation formulae - max. error 4.5E-04
C
C----------------------------------------------------------------------

C PARAMETERS
      REAL            FRACTION_ABOVE_LEVEL

C CONSTANTS
      REAL            C0, C1, C2, D1, D2, D3

      PARAMETER      ( C0 = 2.515517 )
      PARAMETER      ( C1 = 0.802853 )
      PARAMETER      ( C2 = 0.010328 )
      PARAMETER      ( D1 = 1.432788 )
      PARAMETER      ( D2 = 0.189269 )
      PARAMETER      ( D3 = 0.001308 )

C LOCAL VARIABLES
      REAL            P, T, TT, TTT, A, B
      LOGICAL            INVERT

C BEGIN

C Algorithm works for ( 0.0 < p <= 0.5 )  hence
      IF (FRACTION_ABOVE_LEVEL .GT. 0.5 ) THEN
         P = 1.0 - FRACTION_ABOVE_LEVEL
         INVERT = .TRUE.
      ELSE
         P = FRACTION_ABOVE_LEVEL
         INVERT = .FALSE.
      END IF

      IF( P .LT. 1.0E-10 ) P = 1.0E-10

      T = SQRT( LOG( 1.0 / ( P * P ) ) )
      TT = T * T
      TTT = T * TT

      A = C0 + ( C1 * T ) + ( C2 * TT )
      B = 1.0 + ( D1 * T ) + ( D2 * TT ) + ( D3 * TTT )
      GAUSS_LEVEL = T - ( A / B )

      IF( INVERT ) GAUSS_LEVEL = -GAUSS_LEVEL

      RETURN

      END



c************************************************************************
      REAL FUNCTION TWOBIT_GAIN_R0( QN1, QZ1, QP1, QN2, QZ2, QP2 )
C----------------------------------------------------------------------
C
C      Finds gain of digital correlator for uncorrelated inputs 1,2
C      where the "gain paramaters" are ( qn1, qz1, qp1 ) and
C      ( qn2, qz2, qp2 ).  n=neg, z=zero, p=pos
C
C----------------------------------------------------------------------

C PARAMETERS
      REAL      QN1, QZ1, QP1, QN2, QZ2, QP2

C EXTERNAL FUNCTIONS
      REAL      G_QUAD

C BEGIN

      TWOBIT_GAIN_R0 = 0.159154943 * 
     *            ( G_QUAD( QZ1, QP1, QZ2, QP2 ) +
     *                G_QUAD( QZ1, QN1, QZ2, QP2 ) +
     *                  G_QUAD( QZ1, QP1, QZ2, QN2 ) +
     *                    G_QUAD( QZ1, QN1, QZ2, QN2 ) )
      END
c************************************************************************
      REAL FUNCTION G_QUAD( QZ1, QP1, QZ2, QP2 )
      REAL QZ1, QP1, QZ2, QP2
      G_QUAD = 9 * QP1 * QP2 +
     *         3 * ( QZ1 * QP2 + QP1 * QZ2 ) + QZ1 * QZ2
      END
