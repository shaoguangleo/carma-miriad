************************************************************************
	program uvlist
	implicit none
c
c= AT_UVLIST - Print data, variables and other information from uv dataset
c& rjs
c: uv analysis
c+
c	UVLIST produces various listing of a MIRIAD UV data file.
c@ vis
c	The input UV dataset name. No default.
c@ options
c	This controls what is listed, and the verbosity. Several can be
c	given, separated by commas. Minimum match is used. Possible values
c	are:
c	  brief     Short listing (default).
c	  full      The opposite of "brief".
c	  data      List correlation data. For brief listings, a maximum
c	            of 6 channels is printed.
c	  variables List uv variables.
c	  sigma     List the value and rms of the first data channel.
c	  spectral  List spectral and velocity information.
c	  array     List antenna and array information.
c	  source    List information about the source.
c	If no listing options are given, uvlist uses options=brief,data.
c	The following options determine the application of calibration
c	corrections to the data, for the data list options. The default
c	is to apply calibration corrections when they are available.
c	  nocal     Do not apply antenna gain corrections.
c	  nopol     Do not correct for polarisation leakage.
c	  nopass    Do not apply bandpass corrections.
c@ select
c	This selects the data to be processed, using the standard uvselect
c	format. Default is all data.
c@ stokes
c	Normal stokes keyword. The default is to list the unconverted
c	polarisations. NOTE: When you set this parameter, the "Visibility
c	Number" printed in some listing may no longer be entirely accurate,
c	as there is not a correspondence a visibility listed and a visibility
c	in the data-set.
c@ line
c	For options=data, this gives the normal uv linetype, with the normal
c	defaults. See the help on "line" for more information.
c@ recnum   
c	The number of output records. This is used to cut off long outputs.
c	The default is either 1 or 20, depending on the options.
c@ log
c	The list output file name. The default is the terminal.
c--
c
c  History:
c    wh    oct89 - Original version.
c    RJS 20Mar89 - Broke one line longer than 72 characters into two lines.
c    wh  4apr89  - print ut/lst in hr:min:sec  and fix bugs
C    wh  7apr89  - change format to print julian date
c    RJS 24apr89 - Changed the baseline parameter to double precision.
c		   Added a "save" statement to writeit.
c		   Declared otherwise undeclared variables everywhere.
c		   Several cosmetic changes.
c    wh  25apr89 - ut/lst need not be present anymore
c    wh  28apr89 - nwide can be 0
c    wh  12may89 - bigger field for time/log
c    rjs 12may89 - Improved code to deal with a missing nwide value.
c    rjs 26may89 - Checks for long variables in PRINTHD.
c    rjs 29may89 - Deleted some unused variables.
c    mchw31oct89 - fixed bugs, converted units and used amphase routine.
c    rjs  1nov89 - Improved error checking, fixed more bugs, converted
c		   it to use the "log" routines.
c    mchw 6nov89 - Added "spec" option to list spectral windows.
c    rjs  7nov89 - Significant rework. Changed it to use the selection
c		   and linetype routines. Included the functionality of the
c		   UVPRT task. Added 'brief' mode.
c    8nov89 mchw - add ra to header list; corrected sign of velocity incr.
c    8nov89 rjs  - More minor mods.
c   12feb90 rjs  - Again minor mods.
c    9mar90 rjs  - Change in calling sequence to JulDay.
c   27mar90 rjs  - Changed date format for brief data listings.
c   28mar90 rjs  - Changed 'option' to 'options'. Minor other correction.
c   31mar90 rjs  - Fixed default linetype for wide only file.
c    2may90 pjt  - line*128 ; maxdim.h now gets maxchan
c    4may90 mchw - replaced line*80 so it works again.
c    7may90 mchw - fixed listspec so it works for nspect.gt.6
c   15may90 mchw - changed writeit to have same fix as in ImList.
c   16jul90 mchw - Message for nspect=0 in case user requests spectra.
c    9jan91 rjs  - Fixed format in long listing to deal with more than
c		   999 channels.
c   18mar91 mchw - Fixed format in printhd so cray can handle long lines.
c   22may91 mchw - Changed keya to keyf.
c   17jun91 jm   - Fixed default value of UT.
c   19jun91 mchw - Added options=list.
c   25jun92 rjs  - Doc changes, and list the polarisation type. Misc
c		   changes.
c   12feb93 rjs  - Improved some indentation. Cosmetic change.
c   29mar93 mchw - List statistics and highest channels.
c   01apr93 rjs  - Correct continuation, and initialise some variables.
c   07may93 mchw - fixed bug with needhd in options=list?
c   01jul93 mchw - time average option. Does not yet handle polariation.
c   06jul93 rjs  - print lat and long in dd:mm:ss.s format. Eliminate
c		   use of angles (replace with rangle and hangle).
c   12jul93 mchw - Don't list if all channels flagged in options=stat.
c   20jul93 rjs	 - Gave up on mchw version. Develop ATNF version.
c		   Sigma options.
c   11aug93 rjs  - Use hdprsnt to determine if calibration is being applied.
c   16sep93 rjs	 - Rename bsrch to binsrch.
c   23dec93 rjs  - Include optical velocities in options=spec.
c   21jan93 rjs  - Formatting error for options=spec
c   23aug94 rjs  - More decimal points in options=spec
c    1aug95 rjs  - Fix minor bug which only shows up on sgi machine.
c   28sep95 rjs  - Added options=array
c   29nov95 rjs  - Cope with value being unset.
c   18may96 rjs  - Correct formating bug in ListSepc
c   28aug96 rjs  - List source information.
c   18mar97 rjs  - Consistently write to log file.
c   11may97 rjs  - Better listing format for options=array
c   19aug98 rjs  - Correct printing of longitude in options=array
c   22may01 dpr  - XY-EW support
c   01jan07 rjs  - Handle more than 100 antennas in a simple way.
c   18jun09 rjs  - Number antennas in "array" printout.
c   23apr10 rjs  - Recognised blanked antenna numbers in "array" printout.
c------------------------------------------------------------------------
	include 'maxdim.h'
	character version*(*)
	parameter(version='Uvlist: version 1.0 23-Apr-10')
c
	character out*50,last*1,date*18,uvflags*8
	complex data(MAXCHAN)
	logical flags(MAXCHAN)
	logical dovar,dodata,dospect,dobrief,docal,dopol,dopass,dosigma
	logical doarray,dosrc,more
	double precision lst,pmbl(4)
	real rms2
	integer lIn,vars
	integer numrec,nchan,num,time0,p,visno
c
c  Externals.
c
	logical uvVarUpd,uvDatOpn
c
c  Read the inputs.
c
	call output(version)
 	call keyini
	call GetOpt(dovar,dodata,dospect,dosigma,doarray,dosrc,
     *			dobrief,docal,dopol,dopass)
	if(dospect.or.doarray.or.dosrc.or.dovar.or..not.dobrief)then
	  call keyi('recnum',numrec,1)
	else
	  call keyi('recnum',numrec,20)
	endif
c
c  Determine the uvDat flags. If no data are being handled, then turn off
c  all calibration.
c
	uvflags = 'sdlwb'
	if(.not.dodata.and..not.dosigma)then
	  docal = .false.
	  dopol = .false.
	  dopass = .false.
	endif
	if(docal) uvflags(6:6) = 'c'
	if(dopol) uvflags(7:7) = 'e'
	if(dopass)uvflags(8:8) = 'f'
	call uvDatInp('vis',uvflags)
 	call keya('log',out,' ')
	call keyfin
c
c  Open the output text file.
c
 	call LogOpen(out,'q')
c
c  Open the data file, apply selection, do linetype initialisation and
c  determine the variables of interest.
c
	if(.not.uvDatOpn(lIn))call bug('f','Failed to open a vis file')
	if(dovar)call VarLoad(lIn,dobrief,vars)
c
c  Read through the file, listing what we have to.
c
	num=0
	call uvDatRd(pmbl,data,flags,MAXCHAN,nchan)
	time0 = pmbl(3) + 100
	call writein(lIn,dovar,dodata,dospect,dosigma,doarray,dobrief,
     *					docal,dopol,dopass)
	last = ' '
	dowhile ( nchan.gt.0 .and. num.lt.numrec)
	  num = num + 1
c
c  List the header, if required.
c
	  if(dovar)then
	    if(uvvarupd(vars))then
	      call printhd(lIn,pmbl(3))
	      last = 'v'
	    endif
	  endif
c
	  if(dodata.or.dosigma)then
	    call uvDatGti('visno',VisNo)
            call uvrdvrd(lIn,'lst',lst,0.d0)
	    call uvDatGti('pol',p)
	    if(dobrief.or.dosigma)then
	      if(int(pmbl(3)-0.5).ne.time0)then
	        last = '?'
		time0 = int(pmbl(3)-0.5)
		call JulDay(dble(time0+0.5),'H',date)
		call LogWrite('Data values for '//date(1:7),more)
	      endif
	    endif
	  endif
c
c  Data listing.
c
	  if(dodata)then
	    if(dobrief)then
	      call BriefDat(last.ne.'d',pmbl(1),pmbl(2),pmbl(3),pmbl(4),
     *					VisNo,data,flags,nchan,p)
	    else
	      call LongDat(last.ne.'d',pmbl(1),pmbl(2),pmbl(3),pmbl(4),
     *		lst,VisNo,data,flags,nchan,p)
	    endif
	    last = 'd'
	  endif
c
c  Variance of data.
c
	  if(dosigma)then
	    call uvDatGtr('variance',rms2)
	    call ListSig(last.ne.'r',pmbl(3),pmbl(4),VisNo,data,flags,
     *		rms2,p)
	    last = 'r'
	  endif
c
c  List the array info, if required.
c
	  if(doarray)then
	    call listarr(lIn)
	    last = 'a'
	  endif
c
c  List information about the source, if required.
c
	  if(dosrc)then
	    call listsrc(lIn)
	    last = 'o'
	  endif
c
c  List the spectra info, if required.
c
	  if(dospect)then
	    call listspec(lIn)
	    last = 's'
	  endif
c
c  Loop the loop.
c
	  call uvDatRd(pmbl,data,flags,MAXCHAN,nchan)
	enddo
c
c  Close up shop.
c
	call LogClose
	call uvDatCls
	end
c************************************************************************
	subroutine BriefDat(needhd,uin,vin,timein,basein,VisNo,
     *					    data,flags,nchan,p)
c
	implicit none
	integer nchan,VisNo,p
	logical needhd,flags(nchan)
	complex data(nchan)
	double precision uin,vin,timein,basein
c
c  Do a brief listing of the data.
c
c  Input:
c    needhd	If true, give a heading line.
c    VisNo	Visibility number.
c    uin,vin	U,V coordinates, in wavelengths.
c    timein	Time, as a Julian day.
c    basein	Baseline number.
c    data	The correlation data.
c    flags	The data flags.
c    nchan	The number of channels.
c    p		Polarisation code. A value of zero indicates it is
c		not know.
c------------------------------------------------------------------------
	integer mchan
	parameter(mchan=5)
	integer nchand,j,length,b1,b2
	logical more
	character line*128,ctime*10,pol*2
	real amp(mchan),arg(mchan)
	character cflag(mchan)*1
c
c  Externals.
c
	character PolsC2P*2
c
	nchand = min(mchan,nchan)
	if(needhd)then
	  call LogWrite(' ',more)
	  length = 0
	  call cat(line,length,
     *	   ' Vis #    Time      Ant Pol U(kLam)  V(kLam)')
	  do j=1,nchand
	    call cat(line,length,'   Amp  Phase')
	  enddo
	  call LogWrite(line(1:length),more)
	endif
c
	call basant(basein,b1,b2)
c
	pol = ' '
	if(p.ne.0) pol = PolsC2P(p)
c
	do j=1,nchand
	  call amphase (data(j), amp(j), arg(j))
	  if(flags(j))then
 	    cflag(j) = ' '
	  else
	    cflag(j) = '*'
	  endif
	enddo
	call JulDay(timein,'H',line(1:18))
	ctime = line(9:18)
c
	if(b2.lt.100)then
	  length = 6 + 1 + 10 + 3 + 1 + 2 + 1 + 2 + 18 + nchand*(8+4+1)
	  write(line,100)mod(VisNo,1000000),ctime,
     *   	       b1,b2,pol,0.001*uin,0.001*vin,
     *		       (amp(j),nint(arg(j)),cflag(j),j=1,nchand)
 100	  format(i6,1x,a,i3,'-',i2,1x,a,2f9.2,10(f8.3,i4,a))
	else
	  length = 6 + 1 + 10 + 3 + 1 + 3 + 1 + 3 + 18 + nchand*(8+4+1)
	  write(line,110)mod(VisNo,1000000),ctime,
     *   	       b1,b2,pol,0.001*uin,0.001*vin,
     *		       (amp(j),nint(arg(j)),cflag(j),j=1,nchand)
 110	  format(i6,1x,a,i4,'-',i3,1x,a,2f9.2,10(f8.3,i4,a))
	endif
	call LogWrite(line(1:length),more)
	end
c************************************************************************
	subroutine ListSig(needhd,timein,basein,VisNo,data,flags,rms2,p)
c
	implicit none
	integer VisNo,p
	logical needhd,flags
	complex data
	double precision timein,basein
	real rms2
c
c  Do a brief listing of the data.
c
c  Input:
c    needhd	If true, give a heading line.
c    VisNo	Visibility number.
c    timein	Time, as a Julian day.
c    basein	Baseline number.
c    data	The correlation data.
c    flags	The data flags.
c    p		Polarisation code. A value of zero indicates it is
c		not know.
c    rms2	Sigma**2.
c------------------------------------------------------------------------
	character line*80,ctime*10,pol*2,cflag*1
	real amp,arg
	integer b1,b2
	logical more
c
c  Externals.
c
	character PolsC2P*2
c
	if(needhd)then
	  call LogWrite(' ',more)
	  call LogWrite(
     *	    ' Vis #    Time      Ant Pol   Amp  Phase  Sigma',more)
	endif
c
	call basant(basein,b1,b2)
c
	pol = ' '
	if(p.ne.0) pol = PolsC2P(p)
c
	call amphase(data,amp,arg)
	if(flags)then
 	  cflag = ' '
	else
	  cflag = '*'
	endif
	call JulDay(timein,'H',line(1:18))
	ctime = line(9:18)
c
	if(b2.lt.100)then
	  write(line,100)mod(VisNo,1000000),ctime,
     *   	       b1,b2,pol,amp,nint(arg),cflag,sqrt(rms2)
 100	  format(i6,1x,a,i3,'-',i2,1x,a,f8.3,i4,a,f8.4)
	else
	  write(line,110)mod(VisNo,1000000),ctime,
     *   	       b1,b2,pol,amp,nint(arg),cflag,sqrt(rms2)
 110	  format(i6,1x,a,i4,'-',i3,1x,a,f8.3,i4,a,f8.4)
	endif
	call LogWrite(line,more)
	end
c************************************************************************
	subroutine LongDat(needhd,uin,vin,timein,basein,lst,VisNo,
     *						data,flags,nchan,p)
	implicit none
	integer nchan,VisNo,p
	logical needhd,flags(nchan)
	complex data(nchan)
	double precision uin,vin,timein,basein,lst
c
c  Do a full listing of the data.
c
c  Input:
c    needhd	If true, give a heading line.
c    VisNo	Visibility number.
c    uin,vin	U,V coordinates, in wavelengths.
c    timein	Time, as a Julian day.
c    basein	Baseline number.
c    lst	LST, in radians.
c    data	The correlation data.
c    flags	The data flags.
c    nchan	The number of channels.
c    p		Polarisation type.
c------------------------------------------------------------------------
	include 'mirconst.h'
	integer mchan
	parameter(mchan=5)
	character line*80,date*18,cflag(mchan)*1,pol*2
	real amp(mchan),phas(mchan)
	logical more
	integer i,j,i1,i2,nchand
c
c  Externals.
c
	character PolsC2P*2
c
	if(needhd)then
	  call LogWrite(' ',more)
	  line = ' Vis #   Ant     Date         Pol  U(klam)  V(klam) '
     *		 //'  LST(hrs)'
	  call LogWrite(line,more)
	endif
c
c  Give the preamble.
c
	call basant(basein,i1,i2)
	pol = ' '
	if(p.ne.0) pol = PolsC2P(p)
	call JulDay(timein,'H',date)
c
	if(i2.lt.100)then
	  write(line,'(''|'',i6,i3,''-'',i2,x,a,1x,a,2f9.2,f10.4)')
     *	    mod(Visno,1000000),i1,i2,date(1:16),pol,0.001*uin,0.001*vin,
     *	    lst*12.0/pi
	else
	  write(line,'(''|'',i6,i4,''-'',i3,x,a,1x,a,2f9.2,f10.4)')
     *	    mod(Visno,1000000),i1,i2,date(1:16),pol,0.001*uin,0.001*vin,
     *	    lst*12.0/pi
	endif
	call LogWrite(line,more)
c
c  List the channel data.
c
	do i=1,nchan,mchan
	  nchand = min(nchan-i+1,mchan)
	  do j=1,nchand
	    if(flags(i+j-1))then
	      cflag(j) = ' '
	    else
	      cflag(j) = '*'
	    endif
	    call amphase(data(i+j-1),amp(j),phas(j))
	  enddo
	  write(line,'(5(i4,f7.2,i4,a))') 
     *		      (i+j-1,amp(j),nint(phas(j)),cflag(j),j=1,nchand)
	  call LogWrite(line,more)
	enddo
c
	call LogWrite(' ',more)
	end
c************************************************************************
	subroutine GetOpt(dovar,dodata,dospect,dosigma,doarray,dosrc,
     *					dobrief,docal,dopol,dopass)
c
	implicit none
	logical dovar,dodata,dospect,dobrief,docal,dopol,dopass,dosigma
	logical doarray,dosrc
c
c  Determine which of the options is to be done. Default is
c  "brief" "data".
c
c  Outputs:
c    dovar,dodata,dospect,dosigma,doarray,dosrc Things to list.
c    dobrief		   Do it in brief or verbose mode.
c    docal,dopol,dopass	   Calibration switches.
c------------------------------------------------------------------------
	integer nopts
	parameter(nopts=11)
	character opts(nopts)*9
	logical present(nopts)
c
	data opts/'brief    ','full     ','data     ','variables',
     *		  'spectral ','sigma    ','nocal    ','nopol    ',
     *		  'nopass   ','array    ','source   '/
c
	call options('options',opts,present,nopts)
c
	if(present(1).and.present(2))
     *	  call bug('f','Cannot combine options BRIEF and FULL')
	dobrief = .not.present(2)
	dodata = present(3)
	dovar = present(4)
	dospect = present(5)
	dosigma = present(6)
	docal = .not.present(7)
	dopol = .not.present(8)
	dopass= .not.present(9)
	doarray = present(10)
	dosrc   = present(11)
	if(.not.(dovar.or.dospect.or.dosigma.or.doarray.or.dosrc))
     *							dodata = .true.
c
	end
C************************************************************************
	subroutine writein(lIn,dovar,dodata,dospect,dosigma,doarray,
     *	  dobrief,docal,dopol,dopass)
c
	implicit none
	integer lIn
	logical dovar,dodata,dospect,dosigma,dobrief,docal,dopol,dopass
	logical doarray
c
c  Write out the input parameters to the output log file / terminal.
c
c  Input:
c    lIn			  Handle of the input.
c    vis			  Name of the input file.
c    dovar,dodata,dospect,dobrief,doarray
c    docal,dopol,dopass		  Calibration switches.
c------------------------------------------------------------------------
	integer CHANNEL,WIDE,VELOCITY
	parameter(CHANNEL=1,WIDE=2,VELOCITY=3)
	character line*80,linetype*12,vis*64
	double precision datline(6)
	real start,width,step
	integer nchan,type,length
	logical more
c
c  Externals.
c
	integer len1
	logical hdprsnt
c
c  Determine the linetype.
c
	call uvDatGta('name',vis)
	call uvinfo(lIn,'line',datline)
	type = nint(datline(1))
	if(type.eq.CHANNEL)  linetype = 'channel'
	if(type.eq.WIDE)     linetype = 'wide'
	if(type.eq.VELOCITY) linetype = 'velocity'
	nchan = nint(datline(2))
	start = datline(3)
	width = datline(4)
	step  = datline(5)
c
c  Give the file name.
c
	line = 'UV Listing for data-set '//vis
	call LogWrite(line,more)
	call LogWrite(' ',more)
c
	length = 0
	if(dobrief)then
	  call cat(line,length,'Options: brief')
	else
	  call cat(line,length,'Options: full')
	endif
	if(dovar)   call cat(line,length,',variables')
	if(dodata)  call cat(line,length,',data')
	if(dospect) call cat(line,length,',spectral')
	if(dosigma) call cat(line,length,',sigma')
	if(doarray) call cat(line,length,',array')
	call LogWrite(line(1:length),more)
c
	if(dodata)then
	  length = len1(linetype)
	  write(line,'(a,i4,a,a)')
     *	  'No. channels:',nchan,', Linetype: ',linetype(1:length)
	  call LogWrite(line,more)
	  write(line,'(a,f9.3,a,f9.3,a,f9.3)')
     *	  'Line Start:',start,', Width:',width,', Step:',step
	  call LogWrite(line,more)
	  length = 0
	  if(docal.and.hdprsnt(lIn,'gains'))
     *	    call cat(line,length,'Antenna gains, ')
	  if(dopol.and.hdprsnt(lIn,'leakage'))
     *	    call cat(line,length,'Polarization Leakages, ')
	  if(dopass.and.hdprsnt(lIn,'bandpass'))
     *	    call cat(line,length,'Bandpass corrections, ')
	  if(length.gt.2)then
	    length = length - 2
	    call cat(line,length,' applied.')
	    call LogWrite(line(1:length),more)
	  endif
	endif
	call LogWrite(' ',more)
	call LogWrite('------------------------------'//
     *		      '------------------------------',more)
	end
c************************************************************************
	subroutine cat(line,length,string)
c
	implicit none
	character line*(*),string*(*)
	integer length
c
c  Append a string to the end of another string.
c
c  Input:
c    string
c  Input/Output:
c    line
c    length
c------------------------------------------------------------------------
	line(length+1:length+len(string)) = string
	length = length + len(string)
	end
c************************************************************************
	subroutine VarLoad(lIn,brief,vars)
c
	implicit none
	integer lIn,vars
	logical brief
c
c  Load the names of all the variables in the uv data set.
c
c  Inputs:
c    lIn	Handle of the input data set.
c    brief	If true, then only the important variables are considered.
c  Output:
c    vars	Variable handle.
c------------------------------------------------------------------------
	include 'at_uvlist.h'
	integer item,is,i,j,k
	logical select,overflow
	character varin*12,vsave*8
c
c  Externals.
c
	integer binsrcha
c
c  The following table is a list of "important" and "unimportant" variables.
c  In brief mode, only the important variables are listed. In full mode,
c  all, except the unimportant variables, are listed. NOTE: the tables MUST
c  be in alphabetic order!
c
	integer ngood,nbad
	parameter(ngood=12,nbad=8)
	character vargood(ngood)*8,varbad(nbad)*8
	data (varbad(j),j=1,nbad)/
     *	'baseline','coord   ','corr    ','lst     ','time    ',
     *	'tscale  ','ut      ','wcorr   '/
	data (vargood(j),j=1,ngood)/
     *	'antpos  ','corbw   ','corfin  ','cormode ','dec     ',
     *	'freq    ','freqif  ','nants   ','nchan   ','ra      ',
     *	'source  ','vsource '/
c
 	call haccess(lIn,item,'vartable','read',is)
	if(is.ne.0) call bugno('f',is)
	vnum=0
	is = 0
	overflow = .false.
 	dowhile (is.eq.0)
 	  call hreada(item,varin,is)
	  if(is.eq.0.and.varin.ne.' ')then
	    if(brief)then
	      select = binsrcha(varin(3:10),vargood,ngood).gt.0
	    else
	      select = binsrcha(varin(3:10),varbad,nbad).eq.0
	    endif
	    if(select)then
	      if(vnum.eq.itlen)then
		overflow = .true.
		is = -1
	      else
		vnum=vnum+1
		varname(vnum)=varin(3:10)
	      endif
	    endif
	  end if
 	enddo
	if(is.ne.-1) call bugno('f',is)
 	call hdaccess(item,is)
	if(is.ne.0) call bugno('f',is)
	if(overflow)call bug('w','Variable table overflow -- some lost')
c
c  Sort the names
c
	do i=1,vnum-1
 	  k=i
 	  do j=i+1,vnum   
	    if(varname(j).lt.varname(k)) k=j
 	  enddo 	 
	  vsave=varname(i)
 	  varname(i)=varname(k)
 	  varname(k)=vsave
	enddo
c
c  Mark all the variables we are interested in.
c
	call uvvarini(lIn,vars)
	do i=1,vnum
	  call uvvarset(vars,varname(i))
	enddo
	end
C************************************************************************
	subroutine printhd(lIn,timein)
c
	implicit none
	integer lIn
	double precision timein
c
c  This print out the header variables in a standard format, using
c  the table in uvlist.h.
c
c  Inputs:
c    lIn	Pointer to dataset.
c    timein	Julian date.
c------------------------------------------------------------------------
	integer maxdata
	parameter(maxdata=50)
	include 'at_uvlist.h'
c
	character vflag*1,date*18
	integer k,i,j,nsubs,vsubs,ant1,ant2,length
	logical more,vupd
c
	character line*670
	character sdata*32
	real data(maxdata)
	integer idata(maxdata)
	double precision ddata(maxdata)
c
c  Externals.
c
	character hangle*13,rangle*13,stcat*80,itoaf*12
	integer len1
c
	call LogWrite(' ',more)
	call JulDay(timein,'H',date)
	length = 20 + len(date(1:16))
	line(1:length) = 'Header variables at '//date(1:16)
	call LogWrite(line(1:length),more)
c
	do k=1,vnum
	    call uvprobvr(lIn,varname(k),vflag,vsubs,vupd)
c
c  A unset or large variable.
c
	    if(vsubs.eq.0)then
	      line = varname(k)//': (no value set)'
	      call writeit(line,24)
	    else if(vsubs.gt.maxdata) then
	      write(line,'(a,'': ('',i5,'' elements)'')')varname(k),
     *							   vsubs
	      call writeit(line,26)
c
c  A real variable.
c
	    else if(vflag.eq.'r') then
	      call uvgetvrr(lIn,varname(k),data,vsubs)
	      if(varname(k)(1:2).eq.'ra' .or. 
     *			varname(k)(1:2).eq.'ha') then
	        call writeit(
     *			varname(k)//': '//hangle(dble(data(1))),23)
	      else if (varname(k).eq.'dec'.or.
     *		       varname(k).eq.'obsdec'.or.
     *		       varname(k).eq.'latitud'.or.
     *		       varname(k).eq.'longitu') then
	        call writeit(
     *			varname(k)//': '//rangle(dble(data(1))),23)
	      else if (varname(k).eq.'baseline') then
		call basant(dble(data(1)),ant1,ant2)
	        line = stcat(varname(k)//':'//itoaf(ant1),
     *					'-'//itoaf(ant2))
	        call writeit(line,len1(line))
	      else
	        do j=1,vsubs,5
		  nsubs=min(vsubs-j+1,5)
	          write(line,'(a8,'':'',5(1pg13.6))') 
     *			varname(k),(data(j+i),i=0,nsubs-1)
		  call writeit(line,9+nsubs*13)
	        enddo
	      end if
c
c  A character variable.
c
	    else if (vflag.eq.'a') then
	      call uvgetvra(lIn,varname(k),sdata)
	      vsubs=len1(sdata)
	      write(line,'(a8,'':'',a)') varname(k),sdata
	      call writeit(line,9+vsubs)
c
c  An integer variable.
c
	    else if (vflag.eq.'i') then
	      call uvgetvri(lIn,varname(k),idata,vsubs)
	      do j=1,vsubs,8
	        nsubs=min(vsubs-j+1,8)
	        write(line,'(a8,'':'',8(i8))') 
     *			varname(k),(idata(j+i),i=0,nsubs-1)
	        call writeit(line,9+nsubs*8)
	      enddo
c
c  A double precision variable.
c
	    else if (vflag.eq.'d') then
	      call uvgetvrd(lIn,varname(k),ddata,vsubs)
	      if(varname(k).eq.'ra' .or. 
     *		 varname(k).eq.'obsra' .or.
     *		 varname(k).eq.'ut' .or.
     *		 varname(k).eq.'lst') then
	        call writeit(
     *			varname(k)//': '//hangle(ddata(1)),23)
	      else if (varname(k).eq.'dec'.or.
     *		       varname(k).eq.'obsdec'.or.
     *		       varname(k).eq.'latitud'.or.
     *		       varname(k).eq.'longitu') then
	        call writeit(
     *			varname(k)//': '//rangle(ddata(1)),23)
	      else
	        do j=1,vsubs,5
		  nsubs=min(vsubs-j+1,5)
		  write(line,'(a8,'':'',5(1pg13.5))') 
     *			varname(k),(ddata(j+i),i=0,nsubs-1)
		  call writeit(line,9+nsubs*13)
	        enddo
	      endif
c
c  Something else ??
c
	    else
	      write(line,'(a,'': ('',i5,'' elements)'')')varname(k),
     *							   vsubs
	      call writeit(line,26)
	    endif
	enddo
c
c  Flush buffer if needed.
c
	line=' '
	call writeit(line,80)
	end
C************************************************************************
	subroutine writeit(partial,plen)
	implicit none
	integer plen
	character partial*(*)
c
c  Stuff pieces of line into buffer and print them.
c
c  Input:
c    partial	A piece of a line.
c    plen	Length of partial.
c------------------------------------------------------------------------
	character line*80
	integer i,j,jend
	logical first,more
	save line,i,j,first
	data first/.true./
c
	if(first) then
	  first=.false.
	  i=1
	  j=1
	  line=' '
	end if
c
	if(plen+i.gt.len(line)) then
	  call LogWrite(line,more)
	  line=' '
	  j=1
	  dowhile (plen-j .gt.len(line))
	    jend=j+79
	    dowhile (partial(jend:jend).ne.' ')
	      jend=jend-1
	    enddo
	    call LogWrite(partial(j:jend),more)
	    j=jend+1
	  enddo
	  i=1
	end if
	line(i:i+plen-j) = partial(j:plen)
	i = i+plen - 1
	i = (i-1)/25*25 + 26
	end
c************************************************************************
	subroutine listspec(lIn)
	implicit none
	integer lIn
c
c  List spectral windows
c
c  Inputs:
c    lIn	Handle of uvdata file
c
c   6nov89  mchw
c   7nov89  rjs  Some tidying and error checking.
c   8nov89  mchw changed sign of velocity increment
c   7may90  mchw changed to handle nspect.gt.6
c------------------------------------------------------------------------
        include 'maxdim.h'
	include 'mirconst.h'
c
	character line*80,veltype*16,frame*24
	logical more
	integer nspect,nschan(MAXWIN),ischan(MAXWIN),i,j,k
	real veldop,vsource
	double precision restfreq(MAXWIN),sfreq(MAXWIN)
	double precision sdf(MAXWIN),vinc(MAXWIN)
	double precision vstart(MAXWIN),vend(MAXWIN)
	double precision oinc(MAXWIN)
	double precision ostart(MAXWIN),oend(MAXWIN)
c
	call LogWrite(' ',more)
	call uvrdvri(lIn,'nspect',nspect,0)
	if(nspect.gt.MAXWIN)call bug('f','Too many windows')
	if(nspect.gt.0) then
	  call uvgetvrd(lIn,'restfreq',restfreq,nspect)
	  call uvgetvri(lIn,'nschan',nschan,nspect)
	  call uvgetvri(lIn,'ischan',ischan,nspect)
	  call uvgetvrd(lIn,'sfreq',sfreq,nspect)
	  call uvgetvrd(lIn,'sdf',sdf,nspect)
	  call uvrdvrr(lIn,'veldop',veldop,0.)
	  call uvrdvrr(lIn,'vsource',vsource,0.)
	  call uvrdvra(lIn,'veltype',veltype,'VELO-LSR')
	  veldop = veldop - vsource
c
c  Determine velocity rest frame.
c
	  if(veltype(6:8).eq.'LSR')then
	    frame = 'Local Standard of Rest'
	  else if(veltype(6:8).eq.'HEL')then
	    frame = 'Barycentric'
	  else if(veltype(6:8).eq.'OBS')then
	    frame = 'Topocentric'
	  else
	    frame = 'Unknown'
	  endif
c
c  Determine the velocity info.
c
	  do j=1,nspect
	    if(restfreq(j).gt.0)then
	      vinc(j)   =  -0.001*cmks*sdf(j)/restfreq(j)
	      vstart(j) = 0.001*cmks*(1-sfreq(j)/restfreq(j)) - veldop
	      vend(j)   = vstart(j) + vinc(j)*(nschan(j)-1)
	      oinc(j)   =  -0.001*cmks*sdf(j)*restfreq(j)/(sfreq(j)**2)
	      ostart(j) = 0.001*cmks*(restfreq(j)/sfreq(j)-1) - veldop
	      oend(j) = 0.001*cmks*(
     *		restfreq(j)/(sfreq(j)+sdf(j)*(nschan(j)-1))-1) - veldop
	    else
	      vinc(j) = 0
	      vstart(j) = 0
	      vend(j) = 0
	      oinc(j) = 0
	      ostart(j) = 0
	      oend(j) = 0
	    endif
	  enddo
c
c  List the stuff.
c
	  do j=1,nspect,4
	    k=min(j+3,nspect)
c
	    write(line,'(''Velocity rest frame       : '',a)')
     *		frame
	    call LogWrite(line,more)
	    write(line,'(''Obs radial velocity (km/s):'',f10.3)')
     *		veldop
	    call LogWrite(line,more)
	    write(line,'(''Rest frequency      (GHz) :'',8f12.7)')
     *		(restfreq(i),i=j,k)
	    call LogWrite(line,more)
	    write(line,'(''Start channel             :'',8i12)')
     *		(ischan(i),i=j,k)
	    call LogWrite(line,more)
	    write(line,'(''Number of channels        :'',8i12)')
     *		(nschan(i),i=j,k)
	    call LogWrite(line,more)
	    write(line,'(''Start frequency     (GHz) :'',8f12.7)')
     *		(sfreq(i),i=j,k)
	    call LogWrite(line,more)
	    write(line,'(''Frequency increment (GHz) :'',8f12.7)')
     *		(sdf(i),i=j,k)
	    call LogWrite(line,more)
c
	    call LogWrite('Radio Velocities:',more)
	    write(line,'(''  Start velocity    (km/s):'',8f12.3)')
     *		(vstart(i),i=j,k)
	    call LogWrite(line,more)
	    write(line,'(''  End velocity      (km/s):'',8f12.3)')
     *		(vend(i),i=j,k)
	    call LogWrite(line,more)
	    write(line,'(''  Velocity increment(km/s):'',8f12.3)')
     *		(vinc(i),i=j,k)
	    call LogWrite(line,more)
c
	    call LogWrite('Optical Velocities:',more)
	    write(line,'(''  Start velocity    (km/s):'',8f12.3)')
     *		(ostart(i),i=j,k)
	    call LogWrite(line,more)
	    write(line,'(''  End velocity      (km/s):'',8f12.3)')
     *		(oend(i),i=j,k)
	    call LogWrite(line,more)
	    write(line,'(''  Velocity increment(km/s):'',8f12.3)')
     *		(oinc(i),i=j,k)
	    call LogWrite(line,more)
c
	    call LogWrite(' ',more)
	  enddo
	else
	  call LogWrite('These uvdata have no spectra',more)
	endif
	end
c************************************************************************
	subroutine listsrc(lIn)
c
	implicit none
	integer lIn
c
c
c------------------------------------------------------------------------
	include 'mirconst.h'
	character source*32,line*48
	double precision ra,dec
	logical more
	real pltb,plangle,plmaj,plmin,dra,ddec
c
c  Externals.
c
	character hangle*20,rangle*20
c
c
	call uvrdvra(lIn,'source',source,' ')
	if(source.ne.' ')call logwrite('Source: '//source,more)
c
	call uvrdvrd(lIn,'ra',ra,0.d0)
	line = 'RA:  '//hangle(ra)
	call logwrite(line,more)
c
	call uvrdvrd(lIn,'dec',dec,0.d0)
	line = 'DEC: '//rangle(dec)
	call logwrite(line,more)
c
	call uvrdvrr(lIn,'dra',dra,0.)
	call uvrdvrr(lIn,'ddec',ddec,0.)
	if(abs(dra)+abs(ddec).gt.0)then
	  write(line,'(a,f7.1,a,f7.1,a)') 
     *	  	   'Offset RA:',180/PI*3600*dra,
     *		', Offset DEC:',180/PI*3600*ddec,' arcsec'
	  call logwrite(line,more)
	endif
c
	call uvrdvrr(lIn,'pltb',pltb,0.)
	if(pltb.gt.0)then
	  write(line,'(a,f6.1,a)')'Planet temperature:',pltb,' K'
	  call logwrite(line,more)
	endif
c
	call uvrdvrr(lIn,'plmaj',plmaj,0.)
	call uvrdvrr(lIn,'plmin',plmin,0.)
	call uvrdvrr(lIn,'plangle',plangle,0.)
	if(abs(plmaj*plmin).gt.0)then
	  write(line,'(a,f7.1,a,f7.1,a)')
     *		'Planet axes:',plmaj,' by',plmin,' arcsec'
	  call logwrite(line,more)
	  write(line,'(a,f7.1,a)')
     *		'Planet position angle:',plangle,' degrees'
	  call logwrite(line,more)
	endif
c
	end
c************************************************************************
	subroutine listarr(lIn)
	implicit none
	integer lIn
c
c  List array information.
c
c  Inputs:
c    lIn	Handle of uvdata file
c
c------------------------------------------------------------------------
        include 'maxdim.h'
	include 'mirconst.h'
	double precision FAC
	parameter(FAC=DCMKS*1D-9)
c
	integer nants,i,n,mount
	character type*1,line*64,telescop*16
	logical update,ok,more
	double precision xyz(3*MAXANT),lat,long,dtemp
c
c  Externals.
c
	character rangle*16,itoaf*8
c
	call uvrdvra(lIn,'telescop',telescop,' ')
	if(telescop.ne.' ')
     *	  call logwrite('Telescope: '//telescop,more)
c
	call uvprobvr(lIn,'latitud',type,n,update)
	ok = type.eq.'d'.and.n.eq.1
	if(.not.ok.and.telescop.ne.' ')then
	  call obspar(telescop,'latitude',lat,ok)
	else if(ok)then
	  call uvrdvrd(lIn,'latitud',lat,0.d0)
	endif
	if(ok)call logwrite('Latitude:   '//rangle(lat),more)
c
	call uvprobvr(lIn,'longitu',type,n,update)
	ok = type.eq.'d'.and.n.eq.1
	if(.not.ok.and.telescop.ne.' ')then
	  call obspar(telescop,'longitude',long,ok)
	else if(ok)then
	  call uvrdvrd(lIn,'longitu',long,0.d0)
	endif
	if(ok)call logwrite('Longitude: '//rangle(long),more)
c
	call uvrdvri(lIn,'mount',mount,-1)
	ok = mount.ge.0
	if(.not.ok.and.telescop.ne.' ')then
	  dtemp = -1
	  call obspar(telescop,'mount',dtemp,ok)
	  mount = nint(dtemp)
	endif	  
	if(ok)then
	  if(mount.eq.0)then
	    call logwrite('Mounts: Alt-az',more)
	  else if(mount.eq.1)then
	    call logwrite('Mounts: Equatorial',more)
	  else if(mount.eq.3)then
	    call logwrite('Mounts: XY-EW',more)
	  else if(mount.eq.4)then
	    call logwrite('Mounts: Nasmyth',more)
	  else
	    call logwrite('Mounts: Unrecognized mount code '//
     *						itoaf(mount),more)
	  endif
	endif
	call logwrite(' ',more)
c
	call uvprobvr(lIn,'antpos',type,nants,update)
	if(type.ne.'d')nants = 0
	if(nants.le.0)call bug('w','Array information not available')
	if(nants.le.0)return
	if(mod(nants,3).ne.0)call bug('f','Invalid antenna table size')
	nants = nants/3
	if(nants.gt.MAXANT)call bug('f','Too many antennas for me')
	call uvgetvrd(lIn,'antpos',xyz,3*nants)
c
	call logwrite(
     *	  'Antenna positions in local equatorial coordinates',more)
	call logwrite(' ',more)
	call logwrite(
     *	  '        X (meters)     Y (meters)     Z (meters)',more)
	call logwrite(
     *	  '        ----------     ----------     ----------',more)
	do i=1,nants
	  if(nint(xyz(i)).eq.999999.and.
     *	    nint(xyz(i+nants)).eq.999999.and.
     *	    nint(xyz(i+2*nants)).eq.999999)then
	    write(line,'(i3,11x,a,14x,a,14x,a)')i,'?','?','?'
	  else
	    write(line,'(i3,3f15.4)')i,
     *		FAC*xyz(i),FAC*xyz(i+nants),FAC*xyz(i+2*nants)
	  endif
	  call logwrite(line,more)
	enddo
	end

