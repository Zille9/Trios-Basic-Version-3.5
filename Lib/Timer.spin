'' ===========================================================================
''  VGA High-Res Text UI Elements Base UI Support Functions  v1.2
''
''  FILE: Timer.spin
''  Author: Allen Marincak
''  Copyright (c) 2009 Allen MArincak
''  See end of file for terms of use
'' ===========================================================================
''
'' ============================================================================
''  Timer function
'' ============================================================================
''
'' Starts a new cog to provide timing functionality.
''
'' There are 8 timers available, the code running on the new cog simply
'' decrements each timer value at the rate specified  in the start() call.
''
'' Only the first object to create this needs to call the START method. That
'' will launch it on a new COG, other objects can reference it in the OBJ
'' section but do not need to start it, just call the public methods.
'' ============================================================================

_CLKMODE     = XTAL1 + PLL16X
_XINFREQ     = 5_000_000

DAT
' stack size determined StackLengthAJM.spin
  cog         long 0                            'cog execute is running on
  stack       long 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
  timers      long 0,0,0,0,0,0,0,0,0,0,0,0      'timer values (16 bit)


PUB start( period ) : okay1
''
'' Launches TIMER TASK on new cog, returns 0 on error, else the cog that was
'' started up.
''    - period is the fractional part of a second to operate at
''      example:  10 = 1/10th of a second
''                30 = 1/30th of a second
''               100 = 1/100th of a second

  longfill( @timers, 0, 12 )



  cog := cognew( execute( period, @timers ), @stack ) + 1
  okay1 := cog

Pub Stop
  if Cog==-1
    return
  cogstop(Cog)
  Cog:=-1

PUB set( tmrid, val )
'' Sets a registered timer with a 16 bit value. 

    timers[tmrid] := val


PUB isClr( tmrid ): clr
'' Checks the status of the registered timer.
'' returns 1 if it has expired (zeroed)
''         0 if is still running

  if timers[tmrid] == 0
     clr:= 1

PUB read( tmrid )
'' returns the current count of a registered timer.

  return timers[tmrid]

PRI execute( period, ptr_tmrs ) | idx
'' new cog executes this, it just decrements the timers
                                        ' __________________ Korrekturwert
  repeat                                '|
    waitcnt(  cnt + clkfreq / (period))' + 655))
    repeat idx from 0 to 11
      if idx<8
         if long[ptr_tmrs][idx] <> 0
            long[ptr_tmrs][idx] -= 1
      else
         long[ptr_tmrs][idx]+=1


{{
┌────────────────────────────────────────────────────────────────────────────┐
│                     TERMS OF USE: MIT License                              │                                                            
├────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy│
│of this software and associated documentation files (the "Software"), to    │
│deal in the Software without restriction, including without limitation the  │
│rights to use, copy, modify, merge, publish, distribute, sublicense, and/or │
│sell copies of the Software, and to permit persons to whom the Software is  │
│furnished to do so, subject to the following conditions:                    │
│                                                                            │
│The above copyright notice and this permission notice shall be included in  │
│all copies or substantial portions of the Software.                         │
│                                                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  │
│IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,    │
│FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE │
│AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER      │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING     │
│FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS│
│IN THE SOFTWARE.                                                            │
└────────────────────────────────────────────────────────────────────────────┘
}}   
