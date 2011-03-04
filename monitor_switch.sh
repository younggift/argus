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
#++++++++++++++++
# modified by Young <gift.young@gmail.com>
# based on chips617's work at [http://ubuntuforums.org/showthread.php?t=1045417].

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

# # window title bar height (default title bar height in Gnome)
h_tbar=29
## todo

# # focus on active window
window=`xdotool getactivewindow`

# # get active window size and position
x=`xwininfo -id $window | grep "Absolute upper-left X" | awk '{print $4}'`
y=`xwininfo -id $window | grep "Absolute upper-left Y" | awk '{print $4}'`
w=`xwininfo -id $window | grep "Width" | awk '{print $2}'`
h=`xwininfo -id $window | grep "Height" | awk '{print $2}'`

# # window on A monitor
if  [ "$x" -ge $x_A_monitor ] &&
    [ "$x" -le $[$x_A_monitor + $w_A_monitor] ] &&
    [ "$y" -ge $y_A_monitor ] &&
    [ "$y" -le $[$y_A_monitor + $h_A_monitor ] ] ; then

    new_x=$(($x-$x_A_monitor+$x_B_monitor))
    new_y=$(($y-$y_A_monitor+$y_B_monitor-$h_tbar))
    xdotool windowmove $window $new_x $new_y
	# retain maximization
    if [ "$w" -eq "$w_A_monitor" ]; then
	xdotool windowsize $window 100% 100%
	# adjust height
    elif [ "$h" -gt $(($h_B_monitor-$h_tbar)) ]; then
	xdotool windowsize $window $w $(($h_B_monitor-$h_tbar))
    fi
# # window on B monitor
else
    new_x=$(($x-$x_B_monitor+$x_A_monitor))
    new_y=$(($y-$y_B_monitor+$y_A_monitor-$h_tbar))
    xdotool windowmove $window $new_x $new_y
	# retain maximization
    if [ "$w" -eq "$w_B_monitor" ]; then
	xdotool windowsize $window 100% 100%
	# adjust height
    elif [ "$h" -gt $(($h_A_monitor-$h_tbar)) ]; then
	xdotool windowsize $window $w $(($h_A_monitor-$h_tbar))
    fi

fi

