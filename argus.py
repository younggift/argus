#! /usr/bin/python
# -*- coding: utf-8 -*-

import sys
import os
import re
import stat

########################
__usage__ = "usage: %argus.py [--help]| -s <scenario_name>"
__version__ = "argus gift.young@gmail.com 2011-03-06"
from optparse import OptionParser
# for saving
# argus.py -s <senario_name>
# for loading
# argus.py -l <senario_name>
p = OptionParser(usage=__usage__, version=__version__, description=__doc__)  
p.add_option('-s','--save', dest="filename", metavar="filename",
             help="save current setting")
(opt, args) = p.parse_args()

regex_output = re.compile(r"""
#VGA1 connected 1080x1920+0+0 (normal left inverted right x axis y axis) 509mm x 286mm
    ^
    (?P<output>[A-Za-z0-9\-]*)[ ]                                 # VGA1 
    (?P<connect>(dis)?connected)[ ]                               # connected
    (?P<mode_width>[0-9]*) x (?P<mode_height>[0-9]*)              # 1080x1920
    [+] (?P<pos_x>[0-9]*) [+] (?P<pos_y>[0-9]*) [ ]               # +0+0
    .*
    """, re.X)

regex_output_rotate = re.compile(r"""
#VGA1 connected 1080x1920+0+0 left (normal left inverted right x axis y axis) 509mm x 286mm
    .*
    [+] [0-9]* [ ]                   # +0
    (?P<rotate> (left | right) ) [ ]    # left
    [(]
    .*
    """, re.X)

array_output =  []
array_pos_x = []
array_pos_y =  []
array_rotate =  []
array_mode_width = []
array_mode_height = []

for line in os.popen('xrandr -q'):
    state=regex_output.match(line)
    if state and state.group('connect')=='connected':
        output = state.group('output')
        pos_x = state.group('pos_x')
        pos_y = state.group('pos_y')
        rotate_match = regex_output_rotate.match(line)
        mode_width = state.group('mode_width')
        mode_height = state.group('mode_height')
        if rotate_match:
            rotate = rotate_match.group('rotate')
            if rotate == 'left' or rotate == 'right':
                mode_width, mode_height = mode_height, mode_width
        else:
            rotate = 'normal'
        array_output.append(output)
        array_pos_x.append(pos_x)
        array_pos_y.append(pos_y)
        array_rotate.append(rotate)
        array_mode_width.append(mode_width)
        array_mode_height.append(mode_height)

array_cmd = []
for i in range(0,len(array_output)):
    array_cmd.append("xrandr --output " + array_output[i] + " --pos " + array_pos_x[i] + "x" + array_pos_y[i] +
                     " --mode " +array_mode_width[i]+ "x" +array_mode_height[i]+ " --rotate " +array_rotate[i])

s = '#!/bin/bash\n'
for cmd in array_cmd:
    s+= (cmd+'\n')

filename = opt.filename
f = file(filename, 'w')
f.write(s)
f.close()
os.popen("chmod 755 "+filename)

