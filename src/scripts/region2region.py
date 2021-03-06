#! /bin/env python
#
#   convert pixel coordinate pairs from one dataset to another
#

import sys,math,os,string

def read_list(file):
    """read XY table of pixel coords
    """
    fp = open(file)
    lines = fp.readlines()
    fp.close()
    print "Found %d lines in %s" % (len(lines),file)
    xy = []
    for line in lines:
        if line[0] == '#': continue
        words = line.split()
        x = float(words[0])
        y = float(words[1])
        xy.append( (x,y) )
    return xy


def read_saoregion(file):
    """read an saoregion file
        polygon(x1,y1,x2,y2,.....)
    """
    fp = open(file)
    lines = fp.readlines()
    fp.close()
    print "Found %d lines in %s" % (len(lines),file)
    xy = []
    for line in lines:
        if line[0] == '#': continue
        words = line.split('(')
        xypairs = words[1].split(')')[0].split(',')
        x=[]
        y=[]
        for i in range(len(xypairs)/2):
            x.append(xypairs[2*i])
            y.append(xypairs[2*i+1])
        return (words[0],x,y)
    return 0

# MIRIAD
#  grep through a logfile for the kth' occurence of a word
#  in return the nth word in that line
def grepknlog(log,word,kth=1,nth=1):
    f = open(log,"r")
    v = f.read()
    va=string.split(v,"\n")
    f.close()
    match = 0
    for s in va:
        if string.find(s,word)>=0:
            match = match + 1
            if match == kth:
                sa=string.split(s)
                return sa[nth-1]
    print 'No match on' + word
    return "no-match"

# MIRIAD
#   convert a list of strings to a command string
def cmd(cmdlist):
    str = cmdlist[0] 
    for arg in cmdlist[1:]:
        str = str + ' ' +  arg
    return str

# MIRIAD
#   execute a miriad 'command' (a list of strings) and accumulate a log 
def miriad(command,log=0):
    if (log != 0):
        mycmd = cmd(command) + '> %s.log 2>&1' % command[0]
    else:
        mycmd = cmd(command) + logger;
    print "MIRIAD:  ",mycmd
    return os.system(mycmd)

def impos(map,coord,type):
    cmd = [
        'impos',
        'in=%s' % map,
        'coord=%s' % coord,
        'type=%s' % type
        ]
    return cmd


# impos in=oldfile coord=x,y type=abspix
# grep for the first 'Axis 1' and 'Axis 2' , which is the RA/DEC , $5 in awk
#    save them as ra,dec
# impos in=newfile coord=ra,dec type=hms,dms
# grep for the third 'Axis 1' and 'Axis 2' , which is the abspix,  $5 in awk

if __name__ == "__main__":
    file = sys.argv[1]
    map1 = sys.argv[2]
    map2 = sys.argv[3]
    if False:
        xylist = read_list(file)
        for xy in xylist:
            coord1 = "%s,%s" % (xy)
            print coord1
            miriad(impos(map1,coord1,'abspix'),1)
            ra  = grepknlog('impos.log','Axis 1:',1,5)
            dec = grepknlog('impos.log','Axis 2:',1,5)
            coord2 = "%s,%s" % (ra,dec)
            miriad(impos(map2,coord2,'hms,dms'),1)
            x2 = grepknlog('impos.log','Axis 1:',3,5)
            y2 = grepknlog('impos.log','Axis 2:',3,5)
            print "OLD/NEW: ",xy,x2,y2
    else:
        wxylist = read_saoregion(file)
        print wxylist
        new = '%s(' % wxylist[0]
        first = True
        for x,y in zip(wxylist[1],wxylist[2]):
            print x,y
            #..
            x2 = x
            y2 = y
            if first:
                new = new + x2 + ','
                first = False
            else:
                new = new + ',' + x2 + ','
            new = new + y2
        new = new + ')'
        print new

            
            


