PUB Main | i
' Check Mode
  prevMode:=999                                           'Initialize the checking variable once
                                  
  repeat                                                  'Repeat this loop forever and check mode
    mode:=ina[15..11]                                     'Set mode variable based on master propeller
    if mode <> prevMode                                   'Check for a change in mode
      prevMode:=mode                                      'Update the prevMode variable
      'Stop your cogs here
      if mode==12                                         'Check for a relevant mode
        'Start your cogs and do your stuff