About the PopShop
=================

The PopShop is a co-working space in Ithaca, NY, started by a group of entrepreneurial Cornell University students to encourage interdisciplinary hacking and general awesomeness.  In April 12, we held an all-night hack-a-thon, where we built this system for controlling the space's lighting and music using gestures mapped against the walls and table.  This entire system was built between 4PM on 4/17 and 8AM on 4/18.

Learn more about the PopShop:	http://www.popright.in  
Like the PopShop on Facebook:	http://www.facebook.com/poprightin  
Follow us on Twitter:			http://www.twitter.com/poprightin

Hack-the-PopShop Info
=====================

Image Recognition software paired with a lightweight server and some 120VAC Hardware control is used to automate Cornell University's PopShop Co-working Space.  A MATLAB script grabs webcam images off the PopShop's streaming video feed, which captures a table and wall control grid.  The Matlab script uses thresholding to ID when certain fautes are modified.  For the lights, serial commands are sent to an arduino which controls a 120VAC Relay.  For the music, a lightweight server initializes a connection between the computer running MATLAB, and another computer on the network that control's the PopShop's tunes.

Contributers
============

Jeremy Blum:	Hardware Hacker  
Jason Wright:	Matlab Hacker  
Sam Sinensky:	Network/Math Hacker

Open Source License
===================

These files are distributed under the GNU GPL Open Source License. Further information can be found in the LICENSE.md file.