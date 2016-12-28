CON
  _xinfreq=5_000_000
  _clkmode=xtal1+pll16x

  LEDGroundBottom=0               'Ground for first row
  LEDGroundMiddle=1            'Ground for second row
  LEDGroundTop=2              'Ground for third row
  
PUB Main | i
  dira[LEDGroundBottom..LEDGroundTop]~~                      'Set the direction of pins 0 through 2 which links the LED columns to ground 
  dira[3..5]~~
  dira[16..18]~
  'outa[0..2]:=%000
  'outa[5]~~
  RunLED
  
PUB RunLED | i, wait
  i:=0
  repeat                                                    'Repeat loop to turn the LEDs on and off by row in LED cascade
    if ina[16..18]==%100
      outa[2..0]:=%000
      wait:=15
    if ina[16..18]==%010
      outa[2..0]:=%001
      wait:=10      
    if ina[16..18]==%001
      outa[2..0]:=%011          
      wait:=5
    RowLight(i,wait)
    i:=i+1
    if i>2
     i:=0

PUB RowLight(row,wait)
    if row==2
      outa[5]~~
      waitcnt((clkfreq/wait)+cnt)
      outa[5]~
    if row==1
      outa[4]~~
      waitcnt((clkfreq/wait)+cnt)
      outa[4]~
    if row==0
      outa[3]~~
      waitcnt((clkfreq/wait)+cnt)
      outa[3]~