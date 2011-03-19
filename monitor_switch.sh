#!/bin/bash
#++++++++++++++++
# Monitor Switch
#
# Moves currently focused window from one monitor to the other.
# Designed for a system with two monitors.
# Script should be triggered using a keyboard shortcut.
# If the window is maximized it should remain maximized after being moved.
# If the window is not maximized it should retain its current size, unless
# height is too large for the destination monitor, when it will be trimmed.
#---------------------------------------------
# dependence on xrandr, wmctrl, xprop, xwininfo, awk
#
# modified by Young <gift.young@gmail.com>
# based on chips617's work at [http://ubuntuforums.org/showthread.php?t=1045417].
# based on Raphael Wimmer's work at [http://my.opera.com/raphman/blog/show.dml/302528]

# bugs knonw:
# 1. If the left-top conner of the active window is out of your monitors, we cannot determin which monitor is on, therefore we suppose it is on monitor B.
# 2. if one of the monitor is rotated left, the shortcut will be disabled.
# History:
# 2011-1-31 The monitors can be at any position, not only left and right.
# 2007-11 the original chips617's work

# resolution and position of monitors
count=0
while read line
do
   keys[$((++count))]="${line}"
done <<EOF
$( xrandr -q | grep  " connected" | awk '{print $3}' | awk -F'[x+]' '{printf("%s\n%s\n%s\n%s\n",$1, $2, $3, $4)}' )
EOF
w_A_monitor=${keys[1]}
h_A_monitor=${keys[2]}
x_A_monitor=${keys[3]}
y_A_monitor=${keys[4]}
w_B_monitor=${keys[5]}
h_B_monitor=${keys[6]}
x_B_monitor=${keys[7]}
y_B_monitor=${keys[8]}

# get active window
# window=`xdotool getactivewindow`
activeWinLine=$(xprop -root | grep "_NET_ACTIVE_WINDOW(WINDOW)")
window="${activeWinLine:40}"

# window title bar height
# h_tbar=29
xWinDecorLine=$(xprop -id $window | grep "_NET_FRAME_EXTENTS(CARDINAL)")
h_tbar=${xWinDecorLine:37 :2}

# get active window size and position
x=`xwininfo -id $window | grep "Absolute upper-left X" | awk '{print $4}'`
y=`xwininfo -id $window | grep "Absolute upper-left Y" | awk '{print $4}'`
w=`xwininfo -id $window | grep "Width" | awk '{print $2}'`
h=`xwininfo -id $window | grep "Height" | awk '{print $2}'`

# calculate the new position of the window ...
## if the window was on A monitor
if  [ "$x" -ge $x_A_monitor ] &&
    [ "$x" -le $[$x_A_monitor + $w_A_monitor] ] &&
    [ "$y" -ge $y_A_monitor ] &&
    [ "$y" -le $[$y_A_monitor + $h_A_monitor ] ] ; then
    x_target_monitor=$x_B_monitor
    y_target_monitor=$y_B_monitor
    w_target_monitor=$w_B_monitor
    h_target_monitor=$h_B_monitor
    x_source_monitor=$x_A_monitor
    y_source_monitor=$y_A_monitor
## if the window was on B monitor
else
    x_target_monitor=$x_A_monitor
    y_target_monitor=$y_A_monitor
    w_target_monitor=$w_A_monitor
    h_target_monitor=$h_A_monitor
    x_source_monitor=$x_B_monitor
    y_source_monitor=$y_B_monitor
fi
new_x=$(($x-$x_source_monitor+$x_target_monitor))
new_y=$(($y-$y_source_monitor+$y_target_monitor-$h_tbar))


# ... and the width or the height up to the edge of the target monitor
if (($w > $w_target_monitor))
then
    w=$w_target_monitor
fi
if (($h > $h_target_monitor))
then
    h=$h_target_monitor
fi


# move the window to another monitor
# if maximized store info and de-maximize
winState=$(xprop -id $window | grep "_NET_WM_STATE(ATOM)"  )  

if [[ `echo ${winState} | grep "_NET_WM_STATE_MAXIMIZED_HORZ"` != ""  ]]
then 
    maxH=1
    wmctrl -i -r $window -b remove,maximized_horz 
fi

if [[ `echo ${winState} | grep "_NET_WM_STATE_MAXIMIZED_VERT"` != ""  ]]
then
    maxV=1
    wmctrl -i -r $window -b remove,maximized_vert
fi

# do move
wmctrl -i -r $window -e 0,$new_x,$new_y,$w,$h
# the following lines are for debug.
# echo x x_source_monitor x_target_monitor
# echo $x $x_source_monitor $x_target_monitor
# echo y y_source_monitor y_target_monitor
# echo $y  $y_source_monitor $y_target_monitor
# echo h $h w $w
# echo new_x $new_x
# echo new_y $new_y

# restore maximization
((${maxV})) && wmctrl -i -r $window -b add,maximized_vert
((${maxH})) && wmctrl -i -r $window -b add,maximized_horz

# raise window (seems to be necessary sometimes)
#wmctrl -i -a $window

# and bye
exit 0