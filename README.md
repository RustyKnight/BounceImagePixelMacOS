# BounceImagePixelMacOS

A simple animation test

Inspired by [Click to form an image](https://codepen.io/allanpope/pen/LVWYYd) and [move dot between 2 points jframe](https://stackoverflow.com/questions/70718553/move-dot-between-2-points-jframe/70718933#70718933), written using Swift on MacOS

**This is an experiment**

<img src="Bouncy01.gif">

# Requirements

![Swift](https://img.shields.io/badge/Swift-5.5-orange) ![MacOS](https://img.shields.io/badge/MacOS-11.3-orange)

# Why?

Why not?  This is an experiment in animation and it's annoyingly fun.

One thing to remember, this example is animating the pixles of a 300x300 image (90000 individual objects)

## Approach #1

The first approach was to try and see if we could animate all 90, 000 pixels using either direct drawing or using (really small) `NSView`s.  Neither approach worked

## Approach #2

The second approach was to make a pixelated version of the image and animated the blocks instead (reducing the amount which needs to be animated).  This is done via basic view/core animation workflows (not overly optimised)

## Approach #3

Would be to look at Sprit and Scene Kits
