# TODO

- Improvement: Better defaul Y-max values in slow graphs
  
## When using parallel pinging I must calculate effective RTTs instead of using the real RTTs. 

Look below for this comment:
"TODO: convert real RTTs to effective RTTs before adding record to bucket"

   
## There is a memory leak of about 26MB/hour (624MB/day)

## Other
    I can have the user choose some quality target and then scale and color the 
    graphs based on that. E.g. The user hits ctrl-Q, C and I setup the graphs 
    for VoIP *C*alls. A very rough guideline is below. It was produced by ChatGPT 
    with a bit of interogation to get something more or less close to the truth.
    
    Packet Loss

    | Application             |Ideal| OK  |Poor|Bad|
    |-------------------------|-----|-----|----|---|
    | Remote Desktop Usage (R)| 0%  | <1% |<2% | > |
    | VoIP Calls           (C)| 0%  | <1% |<3% | > |
    | Internet FPS Gaming  (G)| 0%  | <1% |<2% | > |
    | YouTube Viewing      (V)| 0%  | <2% |<6% | > |
    | Web Browsing         (W)| 0%  | <1% |<5% | > |

    RTT

    | Application             | Ideal  |  OK   | Poor  |Bad|
    |-------------------------|--------|-------|-------|---|
    | Remote Desktop Usage (R)| < 50 ms|<100 ms|<200 ms| > |
    | VoIP Calls           (C)| < 75 ms|<150 ms|<300 ms| > |
    | Internet FPS Gaming  (G)| < 50 ms|<100 ms|<150 ms| > |
    | YouTube Viewing      (V)| <100 ms|<200 ms|<500 ms| > |
    | Web Browsing         (W)| <100 ms|<200 ms|<300 ms| > |

    Jitter

    | Application             | Ideal | OK   | Poor |Bad|
    |-------------------------|-------|------|------|---|
    | Remote Desktop Usage (R)| N/A   | N/A  | N/A  |N/A|
    | VoIP Calls           (C)| <20 ms|<30 ms|<50 ms| > |
    | Internet FPS Gaming  (G)| <20 ms|<30 ms|<50 ms| > |
    | YouTube Viewing      (V)| N/A   | N/A  | N/A  |N/A|
    | Web Browsing         (W)| N/A   | N/A  | N/A  |N/A|
    
    (You can assume 500ms instead of N/A and you'll be fine)
    
    -------------------
	Use fping.exe or similar if found/requested
	    
    -------------------
    During default ping Internet I need an extra job to ping the default GW 
    And since I do, display graphs for the default GW also 
	Do not display 
    (hide the p95(RTT) graph if max is less than 2msec or <1/5*min(p95(RTT for Internet hosts))
    (hide the loss graph if max(loss) is 0% or <1/10*mean(loss of internet hosts))
    (hide the jitter graph if max(jitter) is less than 5ms or <1/10*mean(jitter of internet hosts))
    
    -------------------
    I visualize these cases in the real time graph at the TOP
        a column of red N's means no Networking; no replies from localhost, only beacon lines are returned
        a column of red L's means no LAN; no replies from default GW 
        a column of red I's means no Internet; no replies from any of the Internet hosts

    -------------------    
    I need a smarter way to set the y-max for most graphs so
      that when running the script from multiple windows or even from
      multiple PCs I get comparable results

     After the first period (typicaly 120") we set: 
     Real time RTT
        We use logarithmic(base 2) scale for Y. We may use one of these:
            30,60,120 or 120,240,480 or 480,960,1920
        We select the scale which has it's 1/3 point closer to min(RTT) 
        The color of the bar is green, cyam, orange, yellow, red
        based on how far from a good RTT it is
        Good RTT is either <=10 or <=20 or <=40msec depending on the 
        min(RTT) of the first 20pings 
        We select Good RTT as the number bigger than min(RTT)*1.2 from 10,20,40,80
        The user may force it with -MaxGoodRtt
        Lost packets should be all red with yellow stars in them
     p98(RTT) 
        We use logarithmic(base 2) scale for Y. We may use one of these:
            30,60,120 or 120,240,480 or 480,960,1920
        (30,60,120 means that the first 1/3 of the graph is at 30msec, 
            the 2nd at 60msec and the 3rd at 120)
        We select the scale which has it's 1/3 point closer to min(RTT) 
        Coloring is as for Real time RTT
     Jitter
        Should also have coloring (green to red) to show how good/bad VoIP will be

    -------------------    
     Per period stats must be recorded to a simple text file with this format (note the pading):
        Out-PingStats Statistics
        Destination(s) = 1.1.1.1, 1.1.1.2, 8.8.8.8, 8.8.4.4 
        m=minimum RTT(ms), p=98th percentile of RTT(ms), j=half the two-way jitter(ms), L=loss(%)
        2023/06/01 10:00, m=  7, p= 15, j= 12, L=  0.8
        2023/06/01 10:02, m=  7, p= 15, j= 12, L=  0.8
     Per hour stats are also output to a text file. Same layout and contains the max value
        of the hour.

## This mode of operation and display will be wonderful for detecting whether problems lie from your PC to your router or from your router to the Internet 

```
     P95, per 2' for 300', min=0, max=206, last=17 (ms)
 300|_________________________________________________________________________________________
    |______█_________█__________▄_________█_________▆________▅▇__________▂_________▄__________
   0|_▁__▂▁█_▁_▂_▃___█▅_▆▁_____▅█▁▁_▁__▁▁▁█▁▁▂▁▂█_▁▂█▂▂▁_▂▁_▁███▁▃▅_▁__▃▂█__▁_▁_▂__█_▁_▁__▁_▁▁
              `^Internet`         `         `         `         `         `         `
L300|_________________________________________________________________________________________
A   |______█_________█__________▄_________█_________▆________▅▇__________▂_________▄__________
N  0|_▁__▂▁█_▁_▂_▃___█▅_▆▁_____▅█▁▁_▁__▁▁▁█▁▁▂▁▂█_▁▂█▂▂▁_▂▁_▁███▁▃▅_▁__▃▂█__▁_▁_▂__█_▁_▁__▁_▁▁
              `^LAN     `         `         `         `         `         `         `
     LOSS%, per 2' for 300', min=0%, p95=23.33%, max=25.83%, last=0.833%
  30|______▃_________▃_________▃____________________▃______________________________▅__________
    |______█_________█_________█__________▅_________█_________▇_________▅__________█__________
   0|______█_________█_________█_________▃█_________█_____▁__▁█_________██_________█_________▁
              `^Internet`         `         `         `         `         `         `
  30|_________________________________________________________________________________________
    |______▃_________▃_________▃____________________▃_________▃_________▅__________▃__________
   0|______█_________█_________█_________▃▃_________█_____▁__▁█_________██_________█_________▁
              `^LAN     `         `         `         `         `         `         `
     ONE-WAY JITTER, per 2' for 300', min=0, p95=33, max=92, last=8 (ms)
  30|_____▂▲____________▂_______________________▲___▲________▲▲___█__▂_____________▆__________
    |_▂__▁██▃__▆_▅___▅__█______▃_______▃_____█_▄█__▃█_▁__▅▂__██__▅█__█_▅▆_______▃__█__________
   0|▃█▃▁████▅▁█▆█▅▂▂█▃_█▆▂▃▅▂▅█▅▆▆▁▆▃▂█▇▅█▄▆█▇██▃███▆█▆▃██▂███▆▆██_▄█▂██▄▄▆▄▂▅▂█▃▁█▂▃▄▅▃▂▆▁▆▆
              `^Internet `         `         `         `         `         `         `
  30|_____▂▲____________▂_______________________▲___▲________▲▲___█__▂_____________▆__________
    |_▂__▁██▃__▆_▅___▅__█______▃_______▃_____█_▄█__▃█_▁__▅▂__██__▅█__█_▅▆_______▃__█__________
   0|▃█▃▁████▅▁█▆█▅▂▂█▃_█▆▂▃▅▂▅█▅▆▆▁▆▃▂█▇▅█▄▆█▇██▃███▆█▆▃██▂███▆▆██_▄█▂██▄▄▆▄▂▅▂█▃▁█▂▃▄▅▃▂▆▁▆▆
              `^LAN     `         `         `         `         `         `         `
```

TODO: Hide histogram if console height is not enough
TODO: Print clock time every 10 or 20 vertical bars
      i.e. '22:26 instead of just ` (yes ' is better than `)
TODO: A function to install DejaVuSans Mono
      Download 
        https://dejavu-fonts.github.io/Download.html
        http://sourceforge.net/projects/dejavu/files/dejavu/2.37/dejavu-fonts-ttf-2.37.zip
      Install 
        https://blog.simontimms.com/2021/06/11/installing-fonts/
      (Changing the font that the console uses is harder)
TODO: Add argument to change folder where I save files (default=$env:temp)
TODO: Collect failures per target and display the top 3 or so failed%
      (maybe show them next to the histogram)
TODO: In Histogram show the actual max instead of ...MAX
TODO: When multiple scripts run simultaneously sync Y-max for all graphs
      if any of them was run with -SyncYAxis
TODO: Option to read input from saved file
TODO: In a perfect world this script could be discovering good pingable hosts
      as it is running instead of the hardcoded list.
      (I already have the helper_find_pingable_com_host function to use)
TODO: While we collect enough data points to have a decent histogram
      we do present the histogram. After that point we change visualization:
      Now every block that used to show the histogram has a color that
      represents how likely it was for the actual histogram to be reaching
      just at this block.
      (Use color scales A) or B) from
      http://www.andrewnoske.com/wiki/Code_-_heatmaps_and_color_gradients)
TODO: https://learn.microsoft.com/en-us/powershell/scripting/dev-cross-plat/performance/script-authoring-considerations?view=powershell-7.3
      If you must write many messages to the console, Write-Host can be an
      order of magnitude slower than [Console]::WriteLine()

TODO: I can use this NON-BLOCKING code to read the last key pressed
          if ([Console]::KeyAvailable) {$keyInfo = [Console]::ReadKey($true)}
          if ($keyinfo.Key -eq 'H' -and $keyinfo.Modifiers -eq 'Control') {...}
      $keyInfo.key is the most usefull property:
            KeyChar      Key Modifiers
            -------      --- ---------
                  - OemMinus         0
                  =  OemPlus         0
                  _ OemMinus     Shift
                  +  OemPlus     Shift
                  +      Add         0 # Numpad
                  - Subtract         0 # Numpad
                  q        Q         0
                  ;        Q         0 # Greek
                  0       D0         0
                  9       D9         0
                  0  NumPad0         0 # Numpad
                  9  NumPad9         0 # Numpad
                  (       D9     Shift
                  )       D0     Shift

TODO: togle visibility of graphs when user presses [R]ealtime [H]histogram [B]aseline [J]itter
TODO: When user presses E(Event) mark the x-axis of all time graphs with a leter
      (A for the first press, B for the 2nd, C, ...)

TODO: Without -GraphMax, lost pings are stored as 9999msec replies. In some parts of the code
    I take this into account and filter out 9999 values. See code with this expression:
    ... $RTT_values | ?{$_ -ne 9999} |...
    I don't always do it however. One case that this hurts is when deciding the max time
    to display on the histogram (without a user provided -GraphMax).

TODO: I could probably add a heatmap with 2 periods per character.
    If one period is the default 2min then with 15chars I can cover 1 hour.
    I am not sure how to convert the RTT, jitter and loss of 2mins to ONE color though
    Maybe the user can specify a use (e.g. VoIP, browsing, gaming) and based on that
    I can come up with a color for perfect, very good, good, poor, bad, very bad
    (NOTE to self: If I need a color scale I can use color scales A) or B)
    from http://www.andrewnoske.com/wiki/Code_-_heatmaps_and_color_gradients)


