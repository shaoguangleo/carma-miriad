#!/bin/csh -f

echo "Plot uv coverage and beam. Tabulate FWHM, sidelobe levels and uvrange"

# mchw 27jun02
# mchw 07nov02 - focus on Tb for 1 MHz channels

# 23sep02 increase image size and decrease Nyquist sample interval for config > 20


# Nyquist sample time = 12 x 3600 s x (dish_diam/2)/(pi*baseline)
# calc '12*3600*6/(pi*4000)' = 20s = 5.73E-3 hours for 4 km config
# 1 min = 0.01666 hours is Nyquist sample interval at 1.375 km
# PBFWHM = 24"
# field = 24/pixel
# config   uvmin  uvmax(m)  fwhm   pixel(")  field(pixel) Nyquist
#   1       14.4    159     1.6    0.425        57        8.65 min
#  10       14.4    415     1.0    0.174       138        3.3
#  20       14.7   1046     0.36   0.067       358        1.3
#  30       36.6   2832     0.14   0.025       960        0.48 = 29s = 8.1E-3
#  35       36.6   4153     0.09   0.017      1412        0.33 = 20s = 5.73E-3 hrs

goto start
start:

# check inputs
  if($#argv<3) then
    echo " Usage: mfs.csh   config   declination" 
    echo "   config"
    echo "          Antenna configuration. "
    echo "            e.g. config1.ant. Omit the .ant. No default."
    echo "   declination"
    echo "          Source declination [degrees]. No default."
    echo "   harange"                                                                 
    echo "          HA range: start,stop,interval [hours]. e.g. -1,1,.1  No default."
    echo " "
    exit 1
  endif

set config  = $1
set dec     = $2
set nchan   = 1
set harange = $3
set select  = '-shadow(12)'
set freq    = 230
set imsize  = 0
set systemp = 40,290,0.1


echo "   ---  ALMA Single Field MFS Imaging    ---   " > timing
echo " config  = $config"             >> timing
echo " dec     =  $dec"               >> timing
echo " harange =  $harange  hours"    >> timing
echo " select  =  $select"            >> timing
echo " freq    =  $freq"              >> timing
echo " nchan   =  $nchan"             >> timing
echo " imsize  =  $imsize"            >> timing
echo " systemp =  $systemp"           >> timing
echo " " >> timing
echo "   ---  TIMING   ---   "        >> timing
echo START: `date` >> timing

goto continue
continue:

echo generate uv-data
rm -r $config.$dec.uv
uvgen ant=$config.ant baseunit=-3.33564 radec=23:23:25.803,$dec lat=-23.02 harange=$harange source=$MIRCAT/point.source telescop=alma systemp=$systemp jyperk=40 freq=$freq corr=$nchan,1,1,1 out=$config.$dec.uv
echo UVGEN: `date` >> timing

#uvplt device=/xs vis=$config.$dec.uv axis=uc,vc options=nobase,equal

echo make image
rm -r $config.$dec.bm $config.$dec.mp
set nvis = `invert options=mfs vis=$config.$dec.uv map=$config.$dec.mp beam=$config.$dec.bm imsize=$imsize sup=0 select=$select | grep Visibilities | awk '{print $3}'`
#set nvis = `invert vis=$config.$dec.uv map=$config.$dec.mp beam=$config.$dec.bm imsize=$imsize sup=0 select=$select | grep Visibilities | awk '{print $3}'`
echo INVERT: `date` >> timing

echo plotting
#implot in=$config.$dec.bm device=/xs units=s conflag=l conargs=1.4 region=quarter
echo IMPLOT: `date` >> timing

echo deconvolve
rm -r $config.$dec.cl $config.$dec.cm
clean map=$config.$dec.mp beam=$config.$dec.bm out=$config.$dec.cl
echo CLEAN: `date` >> timing
restor map=$config.$dec.mp beam=$config.$dec.bm out=$config.$dec.cm model=$config.$dec.cl
echo IMFIT: `date` >> timing

echo fit beam and get residual sidelobe levels
rm -r residual
imfit in=$config.$dec.bm object=gauss 'region=relpix,box(-20,-20,20,20)' out=residual options=residual
histo in=residual
echo FINISH: `date` >> timing
echo " " >> timing


echo print out results - summarize rms and beam sidelobe levels. RMS and TBRMS in mJy and mK
echo "   ---  RESULTS   ---   " >> timing
set RMS = `itemize in=$config.$dec.mp   | grep rms       | awk '{printf("%.1f   ", 1e3*$3)}'`
set BMAJ=`prthd in=$config.$dec.cm      | egrep Beam     | awk '{printf("%.2f   ", $3)}'`
set BMIN=`prthd in=$config.$dec.cm      | egrep Beam     | awk '{printf("%.2f   ", $5)}'`
set TBRMS = `calc "$RMS*.3/$freq*.3/$freq/2/1.38e3/(pi/(4*log(2))*$BMAJ*$BMIN/4.25e10)" | awk '{printf("%.0f ", $1)}'`
set SRMS = `histo in=residual | grep Rms       | awk '{printf("%.1f  ", 100*$4)}'`
set SMAX = `histo in=residual | grep Maximum   | awk '{printf("%.1f  ", 100*$3)}'`
set SMIN = `histo in=residual | grep Minimum   | awk '{printf("%.1f  ", 100*$3)}'`
grep records $config.$dec.uv/history >> timing
grep phases $config.$dec.uv/history >> timing
# get number of visibilities written and number unshadowed
set records = `grep records $config.$dec.uv/history | awk '{print $2}'`
set Nvis = `calc "100*$nvis/$records/$nchan" | awk '{printf("%.0f\n",$1)}'`
set uvrange = `uvcheck vis="$config.$dec.uv" | awk '{if(NR==6)print 0.3*$6, 0.3*$7}'`
echo " " >> timing
echo " Config  DEC  Nchan HA[hrs]  Rms[mJy]  Beam[arcsec] Tb_rms[mK] Sidelobe[%]:Rms,Max,Min Nvis[%] uvrange[m]" >> timing
echo  "$config  $dec  $nchan  $harange  $RMS   $BMAJ $BMIN    $TBRMS   $SRMS  $SMAX  $SMIN  $nvis $uvrange" >> timing
echo " "
echo  "$config  $dec  $nchan  $harange   $RMS   $BMAJ x $BMIN   $TBRMS   $SRMS   $SMAX   $SMIN   $Nvis $uvrange" >> Tb.results
mv timing Tb.header
tail Tb.results
