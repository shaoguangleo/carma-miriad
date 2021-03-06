#!/bin/csh -vf

echo $0

goto start
  echo "          deconvolution method. mossdi, mosmem, default or joint. Default is mosmem"
  echo "          default and joint use the uvdata and images generated by mosmem or mossdi"

 hex1.csh ata-42 30 -4,4,.1 16 ata 0.01 mossdi
 hex1.csh ata-42 30 -4,4,.1 16 ata 0.01 mosmem
 hex1.csh ata-42 30 -4,4,.1 16 ata 0.01 default
 hex1.csh ata-42 30 -4,4,.1 16 ata 0.01 joint
goto end


start:
# test suite
foreach config (ata-42)
 foreach scale (12)
  foreach harange (-3,3,1)
   foreach sd_rms (0.01)
    foreach sd_ant (hatcreek)
     ./hex1.csh $config -30 $harange $scale $sd_ant $sd_rms mosmem
     ./hex1.csh $config -30 $harange $scale $sd_ant $sd_rms default
     ./hex1.csh $config -30 $harange $scale $sd_ant $sd_rms joint
    end
   end
  end
 end
end

goto end

foreach config (ata-98 ata-206 ata-350)
 foreach scale (16 12 20)
  foreach harange (-4,4,1 -6,6,.2)
   foreach sd_rms (0.01 0.025)
    foreach sd_ant (hatcreek ovro alma)
     hex7.csh     $config 30 $harange $scale $sd_ant $sd_rms mosmem
     hex7.csh $config 30 $harange $scale $sd_ant $sd_rms default
     hex7.csh   $config 30 $harange $scale $sd_ant $sd_rms joint
    end
   end
  end
 end
end

end:
