CON
  _xinfreq=5_000_000
  _clkmode=xtal1+pll16x

  
  'Pin assignments
  GovernorMotor=7                      
  TurbineMotor=6
  
  'LED constants
  fastLEDwait = 15
  mediumLEDwait = 10
  slowLEDwait = 5
  fastLEDmask = %000
  mediumLEDmask = %001
  slowLEDmask = %011

  'Duty Cycle variables you should experiment with                       
  fastTurbineDC = 50                   'You will need to experiment with these 8 values. We estimate that the turbine motor
  mediumTurbineDC = 33                 'spins twice as fast as the governor motor, so we set the Duty Cylce percentage values
  slowTurbineDC = 17                   'to reflect this. You want the two motors to spin at the same speed for fast, medium,and slow DC values.
  fastGovernorDC = 100                 'The fastGovernorDC value should ensure that the piston is lowered.
  mediumGovernorDC = 66                'The mediumGovernorDC value should ensure the piston is right in the middle.
  slowGovernorDC = 33                  'The slowGovernorDC value should ensure the piston is raised.
  beforePistonDropDC = 44              'Experiment w/ this number so that the governor speeds up as high as possible w/o lowering the piston
  beforePistonRaiseDC = 45             'Experiment w/ this number so that the governor slows down as low as possible w/o raising the piston
  
OBJ
pst: "PST_Driver"

VAR
long Stack2[100], Stack3[100], Stack4[100], Stack5[100], governorDC, turbineDC
byte switchState, prevSwitchState, mode, prevMode
byte wait, mask

PUB Main | i
'This main method runs on Cog 0. We reserved Cog 1 for the PST to debug. Cog 2 runs the steam LEDs. Cog 3 runs the PWM for the
'motors. Cog 4 runs the PlayWithTrain method.

  'pst.start                     'Cog 1

' Set Pin Directions
  dira[0..2]~~                  'Set the direction of pins 0 through 2 which links the LED columns to ground 
  dira[3..5]~~                  'LED Control Pins
  dira[11..15]~                 'Mode Pins
  dira[16..18]~                 'Selector Switch Pins
  dira[6..7]~~                  'PWM Pins
  'Pins 8-10 are not used
 
' Check Mode
  prevMode:=999                                           'Initialize the checking variable once
                                  
  repeat                                                  'Repeat this loop forever and check mode
    mode:=ina[15..11]                                     'Set mode variable based on master propeller
    if mode <> prevMode                                   'Check for a change in mode
      prevMode:=mode                                      'Update the prevMode variable
      cogstop(2)                                          'Stop cogs
      cogstop(3)
      cogstop(4)
      
      if mode==12 OR mode==1                              'Check for mode 12: Slide A, High level overview OR mode 1: Attract
        wait:=mediumLEDwait                               'Set LED speed to medium
        mask:=mediumLEDmask                               'Set LED mask to middle
        coginit(2,RunLED,@Stack2)                         'Start LEDs
        governorDC:=mediumGovernorDC                      'Set governor speed to medium
        turbineDC:=mediumTurbineDC                        'Set turbine speed to medium
        coginit(3,PWM,@Stack3)                            'Start motors
        
      if mode==13                                         'Check for mode 13: Slide B, Load increases -> turbine slows, governor slows without raising piston
        turbineDC:=slowTurbineDC                          'Lower turbine speed to indicate a load
        governorDC:=beforePistonRaiseDC                   'Set speed so that the governor slows down w/o raising the piston
        coginit(3,PWM,@Stack3)                            'Start motors
        wait:=mediumLEDwait                               'Set LED speed to medium
        mask:=mediumLEDmask                               'Set LED mask to middle
        coginit(2,RunLED,@Stack2)                         'Start LEDs
        
      if mode==14                                         'Check for mode 14: Slide C, Governor slows to raise piston, fuel (LEDs) increases 
        turbineDC:=slowTurbineDC                          'Lower turbine speed to indicate a load
        governorDC:=slowGovernorDC                        'Lower governor speed to raise the lever
        coginit(3,PWM,@Stack3)                            'Start motors
        wait:=fastLEDwait                                 'Set LED speed to fast
        mask:=fastLEDmask                                 'Set LED mask to fast
        coginit(2,RunLED,@Stack2)                         'Start LEDs
        
      if mode==15                                         'Check for mode 15: Slide D, Turbine speeds up, governor speeds up without lowering piston
        turbineDC:=mediumTurbineDC                        'Raise turbine speed back to the medium speed
        governorDC:=beforePistonDropDC                    'Set speed so that the governor speeds up w/o lowering the piston
        coginit(3,PWM,@Stack3)                            'Start motors
        wait:=fastLEDwait                                 'Set LED speed to medium
        mask:=fastLEDmask                                 'Set LED mask to middle
        coginit(2,RunLED,@Stack2)                         'Start LEDs

      if mode==16                                         'Check for mode 16: Slide E, Governor speeds up to lower piston, fuel (LEDs) decreases -> equilibrium
        turbineDC:=mediumTurbineDC                        'Maintain turbine speed at the medium speed
        governorDC:=mediumGovernorDC                      'Raise governor speed to lower the lever
        coginit(3,PWM,@Stack3)                            'Start motors
        wait:=mediumLEDwait                               'Set LED speed to medium
        mask:=mediumLEDmask                               'Set LED mask to middle
        coginit(2,RunLED,@Stack2)                         'Start LEDs

      if mode==17                                         'Check for mode 17: Slide F, user plays with train
        coginit(4,PlayWithTrain,@Stack4)                  'Start the PlayWithTrain method

' Calling LED Code - waits should be either 5, 10, or 15 and masks should be %000, %001, or %011

PUB PWM
  dira[6..7]~~                          'Set directions of motors to be outputs
  ctra[5..0]:=GovernorMotor             'Set ctra to control the governor motor's pin
  ctra[30..26]:=%00100                  'Set NCO mode

  ctrb[5..0]:=TurbineMotor              'Set ctrb to control turbine motor's pin
  ctrb[30..26]:=%00100                  'Set NCO mode

  frqa:=1                               'Set the frqa to count up by 1
  frqb:=1                               'Set the frqb to count up by 1

  repeat                                'Repeat this to keep the motors spinning
    phsa:=-(100*governorDC)             'Pulse width modulation code
    phsb:=-(100*turbineDC)
    waitcnt(10_000+cnt)
    
PUB RunLED | i                    'Not sure how this works, we inherited the code, but it works so don't change it.
  i:=0                            'Initialize i
  dira[0..5]~~                    'Set the directions of pins 0-5 to be outputs
  repeat                          'Repeat loop to turn the LEDs on and off by row in LED cascade
    outa[2..0]:=mask              'Sets which LEDs are part of the cascade to show different levels. 
    if i==2                       
      outa[5]~~
      waitcnt((clkfreq/wait)+cnt)
      outa[5]~
    if i==1
      outa[4]~~
      waitcnt((clkfreq/wait)+cnt)
      outa[4]~
    if i==0
      outa[3]~~
      waitcnt((clkfreq/wait)+cnt)
      outa[3]~
    i:=i+1                        'Increment i
    if i>2                        'Keep i in the determined bounds
      i:=0

PUB PlayWithTrain
  dira[16..18]~
  prevSwitchState:=15                                   'Set the prevSwitchState once in the beginning
  repeat                                                'Repeat this loop until another mode gets called and kills this cog
    switchState:=ina[16..18]                            'Set switchState based on the knob                                                       
    if switchState <> prevSwitchState                   'Check if switchState has changed
      prevSwitchState:=switchState                      'Set prevSwitchState
      cogstop(2)                                        'Stop cogs
      cogstop(3)
      if switchState==%100                              'Selector Switch top position (train going uphill)
        governorDC:=slowGovernorDC                      'Set governor speed to slow
        turbineDC:=slowTurbineDC                        'Set turbine speed to slow
        coginit(3,PWM,@Stack3)                          'Start motors
        wait:=mediumLEDwait                             'Set LED speed to medium
        mask:=mediumLEDmask                             'Set LED mask to medium
        coginit(2,RunLED,@Stack2)                       'Start LEDs
        waitcnt(clkfreq+cnt)                            'Wait for the piston to be raised
        wait:=fastLEDwait                               'Set LED speed to fast
        mask:=fastLEDmask                               'Set LED mask to fast
        waitcnt(clkfreq+cnt)                            'Wait for effect
        governorDC:=beforePistonDropDC                  'Set speed so that the governor speeds up w/o lowering the piston
        turbineDC:=mediumTurbineDC                      'Set turbine speed to medium
 
      elseif switchState==%001                          'Selector Switch middle position (level)
        wait:=mediumLEDwait                             'Set LED speed to medium
        mask:=mediumLEDmask                             'Set LED mask to medium
        coginit(2,RunLED,@Stack2)                       'Start LEDs
        governorDC:=mediumGovernorDC                    'Set governor speed to medium
        turbineDC:=mediumTurbineDC                      'Set turbine speed to medium
        coginit(3,PWM,@Stack3)                          'Start motors
        
      elseif switchState==%010                          'Selector Switch lower position (train going downhill)
        governorDC:=fastGovernorDC                      'Set governor speed to fast
        turbineDC:=fastTurbineDC                        'Set turbine speed to fast
        coginit(3,PWM,@Stack3)                          'Start motors
        wait:=mediumLEDwait                             'Set LED speed to medium
        mask:=mediumLEDmask                             'Set LED mask to medium
        coginit(2,RunLED,@Stack2)                       'Start LEDs
        waitcnt(clkfreq+cnt)                            'Wait for the piston to be lowered
        wait:=slowLEDwait                               'Set LED speed to slow
        mask:=slowLEDmask                               'Set LED mask to slow 
        waitcnt(clkfreq+cnt)                            'Wait for effect
        governorDC:=beforePistonRaiseDC                 'Set speed so that the governor slows down w/o raising the piston
        turbineDC:=mediumTurbineDC                      'Set turbine speed to medium
        