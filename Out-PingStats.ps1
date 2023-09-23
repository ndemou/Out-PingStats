<#
    v0.24.0

v0.24.0: 
- Stand alone code with no depedencies! (droped the ThreadJob module depedency)
- Brand new parallel pinging strategy 
  I only ping 4 well known hosts (all aces, all eights), using ping.exe
- Displays p95(RTT) that everyone understands instead of baseline and variance 
- Removed some dead code (e.g. for DNS querying)

TODO: 
	***IMPORTANT TODO*** 
	When using parallel pinging I must calculate effective RTTs instead of 
	using the real RTTs. Look below for this comment:
	"TODO: convert real RTTs to effective RTTs before adding record to bucket"
	
	-------------------
	During default ping Internet I need an extra job to ping the default GW 
	And since I do, display graphs for the default GW also 
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

	-------------------
TODO: This mode of operation and display will be wonderful for detecting whether problems 
      lie from your PC to your router or from your router to the Internet 

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
#>

<# General notes

WHY DO I ONLY PING ALL ACES, ALL EIGHTS
      Hosts like all aces and all eights had 0.8% packet loss in my tests, 
	  so pinging just the 4 well known IPs 1.1.1.1, 1.1.1.2, 8.8.8.8, 8.8.4.4 is more than enough to avoid false negatives
      >99.999% of the time 

BEACON PING
    I use a beacon ping to 127.0.0.1 to run at the same rate as the main pings
      Main loop uses replies from localhost as a reference "sampling clock".
	  This is usefull because ping.exe timeout(1.5sec) is larger than the ping period (every 1sec)
	  there can be silence periods where I will simple get no data back from 
	  parallel Multi Pings. During these silent periods localhost will respond
	  and main-loop will be able to detect timeouts
	  It will also be handy when we run on a laptop that goes to sleep.
	  where localhost will also stop responding 

#>
<# Re: targets for pinging 
   ===========================================
   THE BASIC FACTS
   ---------------
   The hosts of one line are queried/pinged in order ONE AFTER THE OTHER
   Every line is queried/pinged IN PARALLEL WITH EVERY OTHER LINE

   ADVICE
   ------
   It's best to have AT LEAST 4 hosts in each line so that if you ping
   every 1/2sec you are pinging each host at a slow pace of 1 ping per 2 seconds

   MORE DETAILS
   ------------
   Although you may be tempted to think that all hosts of one column are
   pinged in parallel that will only be true if all hosts respond without
   timing out. As soon as one host times out the order is messed up.
   So after a while the only thing you can be sure of is that
   some host of some line is pinged in parallel with a random
   host of another line, and some random host of another line
   and so on...
#>

# Re: colored printing
$ESC     = [char]27
$COL_RST ="$ESC[0m"
$fr =  84; $fg = 255; $fb = 255; $COL_TITLE="$ESC[38;2;$fr;$fg;${Fb}m"
$fr = 107; $fg = 235; $fb = 163; $COL_H1   ="$ESC[38;2;$fr;$fg;${Fb}m"
$fr = 255; $fg =   0; $fb =   0; $col_hilite  ="$ESC[38;2;$fr;$fg;${Fb}m"
$fr =  25; $fg = 163; $fb = 147; $COL_IMP_LOW="$ESC[38;2;$fr;$fg;${Fb}m"

# Most graph colors
$Br =  14; $Bg =  70; $Bb =  70
$fr = 243; $fg = 151; $fb = 214; $COL_GRAPH      ="$esc[38;2;$Fr;$Fg;${Fb}m$esc[48;2;$Br;$Bg;${Bb}m"
$fr = 107; $fg = 235; $fb = 163; $COL_GRAPH_LOW  ="$esc[38;2;$Fr;$Fg;${Fb}m$esc[48;2;$Br;$Bg;${Bb}m"
$fr =   0; $fg =   0; $fb =   0; $COL_GRAPH_EMPTY="$esc[38;2;$Fr;$Fg;${Fb}m$esc[48;2;$Br;$Bg;${Bb}m"
$fr = 255; $fg =   0; $fb =   0; $COL_GRAPH_HILITE  ="$ESC[38;2;$fr;$fg;${Fb}m"
$Br = 243; $Bg = 151; $Bb = 214
$fr = 255; $fg =   0; $fb =   0; $COL_GRAPH_HI="$esc[38;2;$Fr;$Fg;${Fb}m$esc[48;2;$Br;$Bg;${Bb}m"

# LOSS_BAR_GRAPH_THEME
$Br =  14; $Bg =  70; $Bb =  70
$fr = 255; $fg =  50; $fb =  80; $col_base      ="$esc[38;2;$Fr;$Fg;${Fb}m$esc[48;2;$Br;$Bg;${Bb}m"
$fr = 107; $fg = 235; $fb = 163; $col_low  ="$esc[38;2;$Fr;$Fg;${Fb}m$esc[48;2;$Br;$Bg;${Bb}m"
$fr =   0; $fg =   0; $fb =   0; $col_empty="$esc[38;2;$Fr;$Fg;${Fb}m$esc[48;2;$Br;$Bg;${Bb}m"
$fr = 255; $fg = 255; $fb =   0; $col_hilite  ="$ESC[38;2;$fr;$fg;${Fb}m"
$Br = 255; $Bg =  50; $Bb =  80
$fr = 255; $fg = 255; $fb =   0; $col_HI="$esc[38;2;$Fr;$Fg;${Fb}m$esc[48;2;$Br;$Bg;${Bb}m"
$LOSS_BAR_GRAPH_THEME=@{base=$col_base;
    low=$col_low;
    empty=$col_empty;
    hilite=$col_hilite;
    HI=$col_HI
}

# RTTMIN_BAR_GRAPH_THEME
$Br =  14; $Bg =  70; $Bb =  70
$fr = 107; $fg = 235; $fb = 163; $col_base      ="$esc[38;2;$Fr;$Fg;${Fb}m$esc[48;2;$Br;$Bg;${Bb}m"
$fr = 107; $fg = 235; $fb = 255; $col_low  ="$esc[38;2;$Fr;$Fg;${Fb}m$esc[48;2;$Br;$Bg;${Bb}m"
$fr =   0; $fg =   0; $fb =   0; $col_empty="$esc[38;2;$Fr;$Fg;${Fb}m$esc[48;2;$Br;$Bg;${Bb}m"
$fr = 255; $fg =   0; $fb =   0; $col_hilite  ="$ESC[38;2;$fr;$fg;${Fb}m"
$Br = 243; $Bg = 151; $Bb = 214
$fr = 255; $fg =   0; $fb =   0; $col_HI="$esc[38;2;$Fr;$Fg;${Fb}m$esc[48;2;$Br;$Bg;${Bb}m"
$RTTMIN_BAR_GRAPH_THEME=@{base=$col_base ;
    low=$col_low ;
    empty=$col_empty ;
    hilite=$col_hilite ;
    HI=$col_HI
}

# Jitter graph colors
$Br =  14; $Bg =  70; $Bb =  70
$fr = 200; $fg = 200; $fb = 200; $col_base      ="$esc[38;2;$Fr;$Fg;${Fb}m$esc[48;2;$Br;$Bg;${Bb}m"
$fr = 107; $fg = 235; $fb = 163; $col_low  ="$esc[38;2;$Fr;$Fg;${Fb}m$esc[48;2;$Br;$Bg;${Bb}m"
$fr =   0; $fg =   0; $fb =   0; $col_empty="$esc[38;2;$Fr;$Fg;${Fb}m$esc[48;2;$Br;$Bg;${Bb}m"
$fr = 255; $fg =   0; $fb =   0; $col_hilite  ="$ESC[38;2;$fr;$fg;${Fb}m"
$Br = 243; $Bg = 151; $Bb = 214
$fr = 255; $fg =   0; $fb =   0; $col_HI="$esc[38;2;$Fr;$Fg;${Fb}m$esc[48;2;$Br;$Bg;${Bb}m"
$JITTER_BAR_GRAPH_THEME=@{base=$col_base ;
    low=$col_low ;
    empty=$col_empty ;
    hilite=$col_hilite ;
    HI=$col_HI
}

#----------------------------------------------------------------
# What chars to use to draw bars
#----------------------------------------------------------------
    # HIGH RESOLUTION Use these, if you have rich fonts like deja vus
    #-----------------------------------------------------------
    # chars used to draw the horizontal bars
    $HR_BAR_CHR_H_COUNT = 8
    $HR_BAR_CHR_H_ = " " + `
        [char]0x258F + [char]0x258E + [char]0x258D + [char]0x258C + `
        [char]0x258B + [char]0x258A + [char]0x2589
    $HR_BAR_CHR_FULL = [string][char]0x2589

    # chars used to draw the vertical bars
    $HR_BAR_CHR_V_COUNT = 8
    $HR_BAR_CHR_V_ = '_' + `
        [char]0x2581 + [char]0x2582 + [char]0x2583 + [char]0x2584 + `
        [char]0x2585 + [char]0x2586 + [char]0x2587 + [char]0x2588

    # LOW RESOLUTION Use these, for less rich fonts like consolas & courier
    #-----------------------------------------------------------
    # chars used to draw the horizontal bars
    $LR_BAR_CHR_H_COUNT = 3
    $LR_BAR_CHR_H_ = " " + [char]9612 + [char]9608
    $LR_BAR_CHR_FULL = [string][char]9608

    # chars used to draw the vertical bars # _‗₌▄◘█
    $LR_BAR_CHR_V_COUNT = 5
    $LR_BAR_CHR_V_ = '_' +[char]8215 +[char]8332 +[char]9604 +[char]9688 +[char]9608

#----------------------------------------------------------------

$BarGraphSamples = $Host.UI.RawUI.WindowSize.Width - 6
$HistBucketsCount=10
$DebugMode=0
$script:AggPeriodSeconds = 0
$script:status = ""


<#
#################################################################################
# The code of Start-MultiPings is very close to this quick'n'dirty working code:
#################################################################################

echo "$(get-date -Format "hh:mm:ss") STARTING";
Start-Job -ScriptBlock {           $hostn="127.0.0.1"; while ($true) {ping -t $hostn | sls "time[<=]" | %{ echo "$(get-date -UFormat %s ) $hostn $_"}}}
Start-Job -ScriptBlock {sleep 0.5; $hostn="127.0.0.1"; while ($true) {ping -t $hostn | sls "time[<=]" | %{ echo "$(get-date -UFormat %s ) $hostn $_"}}}
Start-Job -ScriptBlock {           $hostn="1.1.1.1"  ; while ($true) {ping -t $hostn | sls "time[<=]" | %{ echo "$(get-date -UFormat %s ) $hostn $_"}}}
Start-Job -ScriptBlock {sleep 0.1; $hostn="1.1.1.2"  ; while ($true) {ping -t $hostn | sls "time[<=]" | %{ echo "$(get-date -UFormat %s ) $hostn $_"}}}
Start-Job -ScriptBlock {sleep 0.2; $hostn="8.8.8.8"  ; while ($true) {ping -t $hostn | sls "time[<=]" | %{ echo "$(get-date -UFormat %s ) $hostn $_"}}}
Start-Job -ScriptBlock {sleep 0.3; $hostn="8.8.4.4"  ; while ($true) {ping -t $hostn | sls "time[<=]" | %{ echo "$(get-date -UFormat %s ) $hostn $_"}}}
echo "$(get-date -Format "hh:mm:ss") MONITORING"; while ($true) {get-job | receive-job; sleep 1}

#>
$CodeOfMultiPings = @'
'@

$CodeOfSpecialPing = @'
Function Start-SpecialPing {
    # Allows custom interval with msec accuracy.
    # Will try to keep the pings per second at 1000/$Interval
    # by sending the next ping earlier if the previous one 
	# returned after more than $Interval msecs.
    # NOTE that in case of failure, it does not return 0 but
    # the elapsed time
    Param(
        [string]$target="",
        [int]$TimeOut = 999,
        [int]$Interval = 500
    )

    $ping_count = 0
    $ts_first_ping = (Get-Date)
    while ($True) {
        $sent_at = (Get-Date)
        # $sent_at.ticks / 10000 milliseconds counter
        $Ping = [System.Net.NetworkInformation.Ping]::New()
        try {
            $ret = $Ping.Send($target, $TimeOut)
        } catch {
            $ret =[PSCustomObject]@{`
                Status = $Error[0].Exception.GetType().FullName; `
                RTT = 9999; `
                group_id = $target; `
                target = $target `
            }
        }
        $ts_end = (Get-Date)
        $ping_count += 1
        if ($ret.Status -ne 'Success') {
            $RTT = [int](($ts_end.ticks - $sent_at.ticks)/10000)
        } else {
            $RTT = $ret.RoundtripTime
        }

        if ($ping_count -eq 1) {
            $total_elapsed_ms = $RTT
            $expected_elapsed_ms = 0
            $diff = $RTT
            $ts_first_ping = $sent_at
        } else {
            $total_elapsed_ms = [int](($ts_end.ticks - $ts_first_ping.ticks)/10000)
            $expected_elapsed_ms = [int](($ping_count-1) * $Interval)
            $diff = $total_elapsed_ms - $expected_elapsed_ms
        }

        $sleep_ms = [math]::max(0, $Interval - $diff)
        # return this:
        [PSCustomObject]@{`
            sent_at = $sent_at; `
            Status = $ret.Status.tostring(); `
            RTT = $RTT; `
            ping_count = $ping_count; `
            group_id = $target; `
            target = $target; `
            debug = ''
        }
<# this is good for debugging only
[PSCustomObject]@{RTT = $RTT; `
Status=$ret.Status; `
sent_at = $sent_at; `
ping_count=$ping_count; `
total_ms=$total_elapsed_ms;
expected_ms=$expected_elapsed_ms; `
diff=($total_elapsed_ms - $expected_elapsed_ms); `
sleep_ms = $sleep_ms
}
#>
        if ($sleep_ms -gt 0) {start-sleep -Milliseconds $sleep_ms}

    }
}
'@

Set-strictmode -version latest

filter isNumeric($x) {
    return $x -is [int16]  -or $x -is [int32]  -or $x -is [int64]  `
       -or $x -is [uint16] -or $x -is [uint32] -or $x -is [uint64] `
       -or $x -is [float] -or $x -is [double] -or $x -is [decimal]
}
function std_num_le($x) {
    # select the maximum of these standard numbers that is
    # Less-than or Equal to $x
    # 1,2,5, 10,20,50, 100,200,500, 1000,2000,5000, ...
    $power = [math]::floor([math]::log($x + 1, 10))
    $candidate = [math]::pow(10, $power)
    if ($candidate -gt $x) {$candidate = $candidate / 10}
    if ($candidate*5 -le $x) {$candidate = $candidate * 5}
    if ($candidate*2 -le $x) {$candidate = $candidate * 2}
    $candidate
}
function std_num_ge($x) {
    # select the maximum of these standard numbers that is
    # Greater-than or Equal to $x
    # 1.5, 3, 6, 9,  15, 30, 60, 90,  150, 300, 600, 900, ...
    # I have no idead how this code works (yes I wrote it)
    $power = [math]::ceiling([math]::log($x + 1, 10))
    $candidate = [math]::pow(10, $power)
    <# ^^^ these two lines do this magic:
    The $candidate for $x=  9 is   10
    The $candidate for $x= 10 is  100
    The $candidate for $x= 20 is  100
    The $candidate for $x= 90 is  100
    The $candidate for $x=100 is 1000
                          ...     ...
    #>
    if (($candidate*1.5 -ge $x) -and ($candidate*0.9  -lt $x)) {return ($candidate * 1.5)}
    if (($candidate*0.9 -ge $x) -and ($candidate*0.6  -lt $x)) {return ($candidate * 0.9)}
    if (($candidate*0.6 -ge $x) -and ($candidate*0.3  -lt $x)) {return ($candidate * 0.6)}
    if (($candidate*0.3 -ge $x) -and ($candidate*0.15 -lt $x)) {return ($candidate * 0.3)}
    return ($candidate * 0.15)
}
function aprox_num($num) {
    # rounds $num to "enough" decimals
    # see get_enough_decimal_digits for understanding enough
    try {
        return [math]::round($num, (get_enough_decimal_digits $num))
    } catch {
        return "???"
    }
}
function within_same_second($time1, $time2) {
	# returns true if both times are within the same integer second
	# (note that this is not always the same as being less than 1sec appart)
    if ($time1.second -eq $time2.second) {
        return ([math]::abs(($time2 - $time1).TotalSeconds) -lt 1)
    } else {return $false}
}
function get_enough_decimal_digits($num) {
    <#
    Return how many decimal digits are "enough" for printing $num without
    loosing too much precission. See examples

    PS C:\> $num = 12.123456; [math]::round($num, (get_enough_decimal_digits $num))
    12.12
    PS C:\> $num = 123.123456; [math]::round($num, (get_enough_decimal_digits $num))
    123.1
    PS C:\> $num = 1234.123456; [math]::round($num, (get_enough_decimal_digits $num))
    1234
    PS C:\> $num = 1.123456; [math]::round($num, (get_enough_decimal_digits $num))
    1.123
    PS C:\> $num = 0.123456; [math]::round($num, (get_enough_decimal_digits $num))
    0.123
    PS C:\> $num = 0.0123456; [math]::round($num, (get_enough_decimal_digits $num))
    0.0123
    PS C:\> $num = 0.00123456; [math]::round($num, (get_enough_decimal_digits $num))
    0.00123
    #>
    # how many digits do we need for the integer part
    $integer_digits = ("{0}" -f [int]$num).length
    if ($num -eq 0) {
        $decimal_digits = 0
    } elseif ([int]$num -eq 0) {
        $decimal_digits = [math]::abs([math]::floor([math]::log10($num))) + 2
    } elseif ($integer_digits -ge 4) {
        # integer part is too large -- no decimals
        $decimal_digits = 0
    } else {
        $decimal_digits = 4-$integer_digits
    }
    return $decimal_digits
}
function get_aprox_median($series){
    # Returns the integer part of the median of $series after ignoring any 9999 items
    # It returns 9999 if series is empty (or contains only 9999 items)
	#
    # Regarding "aprox": if $series has odd number of items we 
	# calculate the corect median but if it has even number of items 
	# we calculate an aproximation. Specificaly the value of the element 
	# just before the midle one instead of the average of that and the next one.
    $sorted = [array]($series  | ?{$_ -ne 9999} | sort-object)
    if ($sorted) {
        [int]$sorted[[int]($sorted.count/2)]
    } else {
        9999 # $series is empty or contains only 9999
    }
}
function get_baseline($Baseline, $RTT_list){
    # Calculates a "Baseline" given a series of RTTs and the current 
    # Baseline. The baseline will eventually be the minimum of all the values 
	# but if the minimum changes fast the baseline follows _slowly_ 
	# If however the minimum strays too far from the baseline, baseline
	# gets adjusted with one big step.
	#
    # (Remember that RTT values are "normalized" by getting moved towards the 
    #  baseline so it's important for the baseline not to jitter around since 
    #  that jitter  will also appear on all the RTTs that follow it)
    $old_Baseline = $Baseline
    $calculated_baseline_now = ($RTT_list | ?{$_ -ne 9999} | measure -Minimum).Minimum
    if ($Baseline -eq $null) {
        # Initial value
        $Baseline = $calculated_baseline_now
    } elseif ([math]::abs($calculated_baseline_now - $old_Baseline) -gt 50) {
        # Difference too big, we are forced to make a big jump :-(
        Write-Verbose "get_baseline was forced to jump from $Baseline to $calculated_baseline_now"
        $Baseline = $calculated_baseline_now
    } elseif ($calculated_baseline_now -gt $old_Baseline) {
        # we will jump by +1...4 msec
        $Baseline += [math]::Ceiling(($calculated_baseline_now - $old_Baseline)/10)
    } elseif ($calculated_baseline_now -lt $old_Baseline) {
        # we will jump by -1...4 msec
        $Baseline -= [math]::Ceiling(($old_Baseline - $calculated_baseline_now)/10)
    }
    return $Baseline
}
function stats_of_series($series){
    # returns min, median, 95th percentile, max
    # TODO median is not real median if $series has even number of elements
    $sorted = [array]($series | sort-object)
    $min =  $sorted[0]
    $p5_position = ([int]($sorted.count * 0.05) -1)
    $p5_position = [math]::max(0, $p5_position)
    $p5 = $sorted[$p5_position]
    $median = $sorted[[int]($sorted.count/2)]
    $p95_position = ([int]($sorted.count * 0.95) -1)
    $p95_position = [math]::max(0, $p95_position)
    $p95 = $sorted[$p95_position]
    $max = $sorted[-1]
    return @{
        min = $min;
        p5 = $p5;
        median = $median;
        p95 = $p95;
        max = $max;
    }
}
function p95_of_jitter($RTT_values){
    # computes the 95th percentile of the jitter for the RTTs
    # NOTE I CHOSE TO IGNORE LOST PACKETS
    # (I could consider the jitter to also be 9999)
    write-verbose "RTTs = $($RTT_values -join ',')"
    $prev = $RTT_values | select -first 1
    $jitter = @($RTT_values | select -last ($RTT_values.count -1) | %{
        if (($_ -ne 9999) -and ($prev -ne 9999)) {
            # /2 is a very rough approximation of oneway jitter.
            # (rough because I assume that half the jitter is from sending
            # the packet and half from receiving. That's not always true. E.g.
            # if upload is satturated I can have a lot of jitter mostly while
            # sending and hardly any while receiving.)
            echo ([math]::round([math]::abs($_ - $prev)/2, 0))
        }
        $prev = $_
    })
    write-verbose "jitter = $($jitter -join ',')"
    $p95 = (stats_of_series $jitter).p95
    write-verbose "p95 of jitter = $p95"
    return $p95
}
function Get-FontName {
    if ([System.Environment]::OSVersion.Platform -like 'Win*') {
        if ( -not ('Win32test.ConsoleTest' -as [type]) ) {
        $defConsoleTest = @'
        using System.Runtime.InteropServices;
        using System;

        namespace Win32test
        {
            public static class ConsoleTest
            {
                [DllImport( "kernel32.dll",
                            CharSet = CharSet.Unicode, SetLastError = true)]
                extern static bool GetCurrentConsoleFontEx(
                    IntPtr hConsoleOutput,
                    bool bMaximumWindow,
                    ref CONSOLE_FONT_INFOEX lpConsoleCurrentFont);

                private enum StdHandle
                {
                    OutputHandle = -11  // The standard output device.
                }

                [DllImport("kernel32")]
                private static extern IntPtr GetStdHandle(StdHandle index);

                public static string GetFontName()
                {
                    // Instantiating CONSOLE_FONT_INFOEX and setting cbsize
                    CONSOLE_FONT_INFOEX ConsoleFontInfo = new CONSOLE_FONT_INFOEX();
                    ConsoleFontInfo.cbSize = (uint)Marshal.SizeOf(ConsoleFontInfo);

                    GetCurrentConsoleFontEx( GetStdHandle(StdHandle.OutputHandle),
                                             false,
                                             ref ConsoleFontInfo);

                    return  ConsoleFontInfo.FaceName ;
                }

                [StructLayout(LayoutKind.Sequential)]
                private struct COORD
                {
                    public short X;
                    public short Y;

                    public COORD(short x, short y)
                    {
                    X = x;
                    Y = y;
                    }
                }

                // learn.microsoft.com/en-us/windows/console/console-font-infoex
                [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
                private struct CONSOLE_FONT_INFOEX
                {
                    public uint  cbSize;
                    public uint  nFont;
                    public COORD dwFontSize;
                    public int   FontFamily;
                    public int   FontWeight;
                    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
                    public string FaceName;
                }
            }
        }
'@
        Add-Type -TypeDefinition $defConsoleTest
        }


        return [Win32test.ConsoleTest]::GetFontName()
    } else {
        # for non-windows OS I assume courier
        return 'Courier'
    }
}
function configure_graph_charset {
    if ($script:HighResFont -eq -1) {
        $font = (Get-FontName)
        echo "Console uses font: $font"
        $script:HighResFont=-not ($font -in @('courier','consolas'))
    }
    if (!($script:HighResFont)) {
        $script:status += "(Low-Res)"
        echo "(Low resolution font)"
    }

    if ($script:HighResFont) {
        $script:BAR_CHR_H_COUNT = $HR_BAR_CHR_H_COUNT
        $script:BAR_CHR_H_ =      $HR_BAR_CHR_H_
        $script:BAR_CHR_FULL =    $HR_BAR_CHR_FULL
        $script:BAR_CHR_V_COUNT = $HR_BAR_CHR_V_COUNT
        $script:BAR_CHR_V_ =      $HR_BAR_CHR_V_
    } else {
        $script:BAR_CHR_H_COUNT = $LR_BAR_CHR_H_COUNT
        $script:BAR_CHR_H_ =      $LR_BAR_CHR_H_
        $script:BAR_CHR_FULL =    $LR_BAR_CHR_FULL
        $script:BAR_CHR_V_COUNT = $LR_BAR_CHR_V_COUNT
        $script:BAR_CHR_V_ =      $LR_BAR_CHR_V_
    }
}
function y_axis_max($min, $max, $y_min, $min_range) {
    # select a Y-axis max
    # for a graph with values from $min to $max
    # having and Y-axis min of $y_min
    # and requiring a range of at least $min_range
    #
    $y_max = (std_num_ge ([math]::max($y_min + $min_range, $max)))
    if ($y_max -eq $y_min) {
         $y_max = (std_num_ge ($y_max + 1))
    }
    return $y_max
}
function percent_to_bar($percent, $Chars_for_100perc) {
    # used by render_histogram
    try {
        $float_length = [double]($percent/100*$Chars_for_100perc)
    } catch {
        return ""
    }
    $full_blocks = [int][Math]::floor($float_length)
    $remeinder = [int]([Math]::floor(($float_length - [Math]::floor($float_length)) * $script:BAR_CHR_H_COUNT))
    $eights = $script:BAR_CHR_H_[$remeinder]
    $bar = $script:BAR_CHR_FULL * $full_blocks
    if ($remeinder -ne 0) {$bar += $script:BAR_CHR_H_[$remeinder]}
    return $bar
}
function series_to_histogram($y_values) {
    # returns an array with the values of the histogram
    $buckets = @(0..$HistBucketsCount)
    For ($i=0; $i -le $HistBucketsCount; $i++) { $buckets[$i] = 0 }

    $stats = (stats_of_series $y_values)

    if ($GraphMin -eq -1) { # by default Y axis min is min
        $y_min = [int]$stats.min
    } else {
        $y_min = $GraphMin
    }
    if ($GraphMax -eq -1) { # by default Y axis max is the 95 percentile + 10% but no more than 999
        $y_max = [math]::min(999, [int]($stats.p95 * 1.1))
    } else {
        $y_max = $GraphMax
    }
    if ($y_max -lt ($y_min + $HistBucketsCount)) {$y_max = $y_min + $HistBucketsCount}

    $y_values | %{
        $ms = $_
        if ($ms -eq 9999) {
            $buckets[$HistBucketsCount] += 1  # $buckets[$HistBucketsCount] counts failures
        } else {
            # line about a reply
            $norm_ms = [math]::min($y_max-1,[math]::max($y_min,$ms))
            [double]$bucket = ($norm_ms-$y_min)/($y_max-$y_min)
            [double]$bucket = [Math]::Floor($bucket*$HistBucketsCount)
            #echo "$ms => +1 in bucket #$bucket"
            $buckets[$bucket] += 1
        }
    }
    return @($buckets, $y_min, $y_max)
}
function render_histogram($y_values) {
    ($buckets, $y_min, $y_max) = (series_to_histogram $y_values)
    # the following fancy line makes sure I buckets divided exactly at integer values
    $y_max = [math]::Ceiling(($y_max - $y_min) / $HistBucketsCount) * $HistBucketsCount + $y_min

    #echo "HIST min=$y_min, max=$y_max "

    [double]$perc_cumul = 0
    [double]$max_perc = 0
    For ($i=0; $i -le $HistBucketsCount; $i++) {
        [double]$percent = [Math]::Round(100 * $buckets[$i] / $y_values.count,1)
        $max_perc = [Math]::max($max_perc, $percent)
    }

    # 28 characters are available
    # if max percent is 0.5 then by setting scale to 28/0.5=56 chars the 50% will fill 28 chars
    $Chars_for_100perc = 28/($max_perc/100)
    For ($i=0; $i -lt $HistBucketsCount; $i++) {
        [double]$from = $y_min + $i * ($y_max-$y_min)/$HistBucketsCount
        [double]$to = $y_min + ($i+1) * ($y_max-$y_min)/$HistBucketsCount
        $count = $buckets[$i]
        [double]$percent = [Math]::Round(100 * $buckets[$i] / $y_values.count,1)
        $perc_cumul = [Math]::min(100, [Math]::Round($perc_cumul + $percent,1))
        $max_perc = [Math]::max($max_perc, $percent)

        if ($i -eq 0) {
            $from_str="{0,3}" -f $y_min 
            $cumul_str=" Cumul"
        } else {
            $from_str="{0,3}" -f $from; $cumul_str=" {0,3}% " -f $perc_cumul
        }
        if ($i -eq ($HistBucketsCount - 1)) {
            $to_str="MAX"
        } else {
            $to_str="{0,3}" -f $to
        }
        $bars = (percent_to_bar $percent  $Chars_for_100perc)
        $spaces = 28-($bars.length)
        $spaces = " " * [math]::max(0,$spaces)
        $bars = "{0}{1}" -f $bars, $spaces
        "{0}...{1} $COL_IMP_LOW{2,4}$COL_RST {3,4}%$COL_IMP_LOW{4,5}$COL_GRAPH{5}$COL_RST" -f $from_str, $to_str, $count, $percent, $cumul_str, $bars
    }
    $failed_perc = $buckets[$HistBucketsCount] # failures
    [double]$percent = [Math]::Round(100 * $failed_perc / ($y_values.count),1)

    if ($percent -gt 0) {$color = $col_hilite} else {$color = $COL_H1}
    "Failures: {0}{1,4} {2,4}%      {3}{4}" -f $color, $failed_perc, $percent, (percent_to_bar $percent  $Chars_for_100perc), $COL_RST
}
function render_bar_graph($y_values, $title="", $options="", $special_value, $default_y_min, $default_y_max, $theme) {
    # It can display 24 or 25 different heights
    # (25 if you count a zero height that gives an empty bar as an increment,
    #  24 if you count only heights that give a visible line with "▁" being the lowest)
    #
    # - Everything except $y_values is optional
    # - If you specify $col_base you must specify ALL other colors too
    # - A special value of your choosing will be displayed... specially (***)
    # - if $options contains "<H_grid>" you get horizontal grid lines
    # - if $options contains "<min_no_color>" you get no coloring for when y=Y-axis-min
    # - if $options contains "<stats>" then these special strings in $title:
    #      <min> <median> <p95> <p5> <max> <last>
    #   will be replaced with statistical info about y_values

    # if (!(($y_values.pstypenames -eq 'System.Object[]') -or ($y_values.pstypenames -eq 'System.Collections.Queue'))) {return}

    if (!($theme)) {
        $col_base =   $COL_GRAPH
        $col_low =    $COL_GRAPH_LOW
        $col_empty =  $COL_GRAPH_EMPTY
        $col_hilite = $COL_GRAPH_HILITE
        $col_hi =     $COL_GRAPH_HI
    } else {
        $col_base    = $theme.base
        $col_low     = $theme.low
        $col_empty   = $theme.empty
        $col_hilite  = $theme.hilite
        $col_hi      = $theme.hi
    }

    if (($options -like "*<stats>*") -or (($abs_min -eq $null) -and (($default_y_min -eq $null) -or ($default_y_max -eq $null)))) {
        # calculate some statistical properties
        # (we either need to display them or use them to calacl Y axis limits)
        $stats = (stats_of_series $y_values)
        ($abs_min, $p5, $median, $p95, $abs_max) = ($stats.min, $stats.p5, $stats.median, $stats.p95, $stats.max)
    }

    if ($default_y_min -eq $null) {
        # calculate a sensible Y axis min based on 5th percentile
        $Y_min = [Math]::max($abs_min, $p5*0.9)
    } else {
        $Y_min = $default_y_min
    }
    if ($default_y_max -eq $null) {
        # by default Y axis max is the 95 percentile + 10%
        $Y_max = [int]($p95 * 1.1)
    } else {
        $Y_max = $default_y_max
    }
    if ($Y_min -eq $Y_max) {$Y_max = $Y_min + 1}

    $Y_max_str = "{0,4}" -f $Y_max
    $width = $Y_max_str.length
    $Y_min_str = "{0,$width}" -f $Y_min
    $width = $Y_min_str.length

    $topline="{0,$width}|" -f $Y_max
    $midline="{0,$width}|" -f " " # (($Y_min + $Y_max)/2)
    $botline="{0,$width}|" -f $Y_min

    $topline += $col_base
    $midline += $col_base
    $botline += $col_base

    $Y_max = $Y_max + 0.1 # will make graphs like for 1,1,2,1,1 more beutiful

    if ($options -like "*<H_grid>*") {$space = $col_empty + "_" + $col_base} else {$space = " "}
    $y_values | %{
        if ($_ -eq $special_value) {
            $topline += $col_hilite + '*' + $col_base
            $midline += $col_hilite + '*' + $col_base
            $botline += $col_hilite + '*' + $col_base
        } elseif ($_ -lt $Y_min ) {
            $topline += $space
            $midline += $space
            $botline += $col_low + [char]0x25bc + $col_base
        } elseif ($_ -eq $Y_min ) {
            $topline += $space
            $midline += $space
            if ($options -like "*<min_no_color>*") {
                $botline += $space
            } else {
                $botline += '_'
            }
        } else {
            #             16__         __24
            #                 | __17  |
            #           __9   ||      |
            #      8__ |      ||      |
            #         ||      |v      v
            #  _0     |v      v▁▂▃▄▅▆▇█
            # |       v▁▂▃▄▅▆▇█████████
            # v▁▂▃▄▅▆▇█████████████████
            # 0123456789012345678901234
            $step = (($Y_max - $Y_min) / $script:BAR_CHR_V_COUNT / 3) # 3 lines
            $quantized = [Math]::Round( ($_ - $Y_min) / $step, 0)
            if ($quantized -gt (3 * $script:BAR_CHR_V_COUNT)) {
                $topline += $col_hi + [char]0x25B2 + $col_base# '▲'
                $midline += [char]0x2588 # '█'
                $botline += [char]0x2588 # '█'
            } elseif ($quantized -ge (2 * $script:BAR_CHR_V_COUNT)) {
                $topline += $script:BAR_CHR_V_[$quantized - (2 * $script:BAR_CHR_V_COUNT) ]
                $midline += [char]0x2588 # '█'
                $botline += [char]0x2588 # '█'
            } elseif ($quantized -ge (1 * $script:BAR_CHR_V_COUNT)) {
                $topline += $space
                $midline += $script:BAR_CHR_V_[$quantized - (1 * $script:BAR_CHR_V_COUNT) ]
                $botline += [char]0x2588 # '█'
            } else {
                $topline += $space
                $midline += $space
                $botline += $script:BAR_CHR_V_[$quantized]
            }
        }

        # echo "max=$Y_max min=$Y_min chars=$chars_max step=$step quantized=$quantized"
        # echo "$topline<"
        # echo "$midline<"
        # echo "$botline<"
        # echo ""
    }

    $topline += $COL_RST
    $midline += $COL_RST
    $botline += $COL_RST

    # ($abs_min, $median, $p95, $abs_max)
    if ($title) {
        if ($options -like "*<stats>*") {
            $abs_min = (aprox_num $abs_min)
            $median = (aprox_num $median)
            $p5 = (aprox_num $p5)
            $p95 = (aprox_num $p95)
            $abs_max = (aprox_num $abs_max)
            $last = (aprox_num ($y_values | select -last 1))

            $title = $title -replace "<min>", "$abs_min"
            $title = $title -replace "<median>", "$median"
            $title = $title -replace "<p5>", "$p5"
            $title = $title -replace "<p95>", "$p95"
            $title = $title -replace "<max>", "$abs_max"
            $title = $title -replace "<last>", "$last"
        }
        $ticks = $('`         '*[math]::ceiling($y_values.count/10))
        if ($y_values.count % 10) {$ticks = $ticks.Substring(10 - $y_values.count % 10)}
    }

    echo "${COL_TITLE}$(" " * ($width)) $title${COL_RST}"
    echo $topline
    echo $midline
    echo $botline
    echo "${COL_TITLE}$(" " * ($width)) $ticks${COL_RST}"
    # echo "Oldest-> $y_values"
}
function render_slow_updating_graphs() {
    # describe the sampling period and the total time we collect samples
    # e.g. per 2' for 14'
    $AggPeriodDescr = "per $([math]::round($AggregationSeconds/60,1))' "+`
        "for $([math]::round($AggregationSeconds*$p95_values.count/60,1))'"

    # X axis limits
    $MaxItems = $Host.UI.RawUI.WindowSize.Width - 6

    # display $p95_values
    #------------------------------
    $values = @($p95_values | select -last $MaxItems)
    $stats = (stats_of_series $values)
    $y_min = 0
	if ($GraphMax -ne -1) {$y_max = $GraphMax} else {
		$y_max = (y_axis_max $stats.min $stats.max $y_min 10)
		if ($y_max -eq $y_min) {$y_max = (std_num_ge $y_max + 1)}
	}
    $title = "RTT 95th PERCENTILE, $AggPeriodDescr, min=<min>, p95=<p95>, max=<max>, last=<last> (ms)"
    render_bar_graph $values $title "<stats><H_grid>" 9999 `
        $y_min $y_max

    # display the lost% bar graph
    #------------------------------
    $stats = (stats_of_series $Loss_values)
    $y_min = 0
	if ($stats.max -le 6) {$y_max = 6} else {$y_max = 24}
    $title = "LOSS%, $AggPeriodDescr, min=<min>%, p95=<p95>%, max=<max>%, last=<last>%"
    render_bar_graph @($Loss_values | select -last $MaxItems) $title "<stats><H_grid><min_no_color>" 100 `
        $y_min $y_max $LOSS_BAR_GRAPH_THEME

    # display the jitter bar graph
    #------------------------------
    $title = "ONE-WAY JITTER, $AggPeriodDescr, min=<min>, p95=<p95>, max=<max>, last=<last> (ms)"
    $stats = (stats_of_series $Jitter_values)
    $y_min = 0
    $y_max = 30
    render_bar_graph @($Jitter_values | select -last $MaxItems) $title "<stats><H_grid>" $null `
        $y_min $y_max $JITTER_BAR_GRAPH_THEME
}
function render_all($last_input, $PingsPerSec, $ShowCountOfFailedResponders) {
    if (($BarGraphSamples -eq -1) -or (!(Test-Path variable:script:EffBarsThatFit))) {
        $script:EffBarsThatFit = $Host.UI.RawUI.WindowSize.Width - 6
    }

    [long]$secs = [math]::ceiling(($(get-date) - $SamplingStart).TotalSeconds)

    # display the header
    $header = "$Title - $all_pings_cnt pings, $secs`", ~$($PingsPerSec)pings/s, " + `
        "min=$all_min_RTT, max=$($all_max_RTT)ms, lost=$all_lost_cnt"
    echo "$COL_H1$header$COL_RST"

    if ($last_input.Status -ne 'Success') {
        # instead of the status line show last failure in red
    echo "${col_hilite}Last ping failed: $($last_input.Status)$COL_RST"
    } else {
        # show status if any
        echo "$COL_IMP_LOW     $($script:status)$COL_RST"
    }

    # display the RTT bar graph
    $graph_values =  @($RTT_values | select -last $script:EffBarsThatFit)
    # decide Y axis limits
    $stats = (stats_of_series ($graph_values | ?{$_ -ne 9999}))
    ($time_graph_abs_min, $p5, $p95, $time_graph_abs_max) = ($stats.min, $stats.p5, $stats.p95, $stats.max)
	$title = "LAST RTTs,  $($graph_values.count) pings, min=<min>, p95=<p95>, max=$($stats.max), last=<last> (ms)"

    $y_min = (std_num_le $stats.min)
    if ($y_min -lt 10) {$y_min = 0}
    $max_to_show = $stats.p95
    if ($stats.max -gt $stats.p95*3) {
        $max_to_show = $stats.p95 * 3
    } elseif (($stats.max -gt $stats.p95) -and ($stats.max -le $stats.p95*2)) {
        $max_to_show = $stats.p95 * 2
    } else {
        $max_to_show = $stats.p95 
    }
    $y_max = (y_axis_max $stats.min $max_to_show $y_min 9)
    if ($GraphMin -ne -1) {$y_min = $GraphMin}
    if ($GraphMax -ne -1) {$y_max = $GraphMax}
    render_bar_graph $graph_values "$title"  "<stats><H_grid>" 9999 $y_min $y_max
    # display the histogram
    if ($RTT_values.count) {
        #echo ([string][char]9472*75)
        echo "    ${COL_TITLE}RTT HISTOGRAM, last $HistSamples samples, p95=${COL_H1}${p95}${COL_TITLE}ms$COL_RST"
        render_histogram @($RTT_values | select -last $HistSamples)
        $p95 = [int](stats_of_series $RTT_values).p95
        #echo ""
    }

    if ($p95_values.count) {
        render_slow_updating_graphs $ShowCountOfFailedResponders
        if (Test-Path variable:script:SCREEN_DUMP_FILE) {
            $filename = ($script:SCREEN_DUMP_FILE -replace ($env:TEMP -replace '\\','\\'), '$env:TEMP')
            echo "$COL_IMP_LOW     (Saving to $filename)"
        }
        $error = $null # empty $error which collects errors from pings 
        [gc]::Collect() # force garbage collection
    }

    if ($DebugMode) {
        #echo "AggPeriodSeconds=$script:AggPeriodSeconds"
        #echo "p95_values=$p95_values"
        echo "Jitter_values=$Jitter_values"
        #sleep 0.1
    }
}
function append_to_pingtimes($ToSave_values, $file) {
    # Record EVERY ping response to a text file named like:
    # First line is
    #     pingrec-v1,2022-05-12,5 pings/sec,google.com
    # Then we have one line per minute starting with the timestamp "hhmm:"
    # Finaly one char per ping follows. The char is [char](ttl+34)
    # (e.g. "A" for 33msec, "B" for 34msec...)
    # Notably the time out is comming as a -1 value (not a 9999 value
    # like in the rest of the code) and thus it is recorded as a "!"

    $line = (get-date -format 'HHmm:')
    $ToSave_values | %{
        $line += [char]($_ + 34)
    }
    $line >> $file
}
function Format-PingTimes {
<#
.SYNOPSIS
Visualizes ping times in histogram and bar graphs

.DESCRIPTION
Pipe the output of Test-Connection to this cmdlet and it will present
the ping times in histograms and bar graphs.

You need a monospace font containing the unicode block characters: ▁▂▃▄▅▆▇█▉
DejaVu sans mono is good (Consolas is not)

.EXAMPLE
Test-Connection google.com -ping -Continuous | Format-PingTimes

.PARAMETER Items
Receives ping lines from standard input. Just pipe ping to this cmdlet and ignore this parameter.
#>
<#
If I need a color scale I can use color scales A) or B) from http://www.andrewnoske.com/wiki/Code_-_heatmaps_and_color_gradients
#>

        [CmdletBinding()]
        param (
            [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
            [object[]]$Items,

            [Parameter(Position=1)]
            [string]$Property,

            [string]$Title = "",
            [string]$Target = "",

            [double]$GraphMax = -1,
            [double]$GraphMin = -1,
            [double]$UpdateScreenEvery = 1,
            [int]$HistBucketsCount=10,
            [int]$AggregationSeconds=120, # 2 mins
            [int]$HistSamples=100,
            [char]$Visual = '=',
            [int]$DebugMode = 0,
            [int]$HighResFont = -1, # -1=auto
            [int]$PingsPerSec = 5,

            [int]$BarGraphSamples = -1
            )
    begin {
        if (!($DebugMode)) {clear}
        $all_min_RTT = [int]::MaxValue
        $all_max_RTT = 0
        $all_pings_cnt = 0
        $all_lost_cnt = 0

        $AggPeriodStart = $(get-date)
        $ScrUpdPeriodStart = $AggPeriodStart

        $RTT_values = New-Object System.Collections.Queue
        $ToSave_values = @()
        $p95_values = New-Object System.Collections.Queue
        $Jitter_values = New-Object System.Collections.Queue
        $Loss_values = New-Object System.Collections.Queue

        if ($BarGraphSamples -eq -1) {
            $script:EffBarsThatFit = $Host.UI.RawUI.WindowSize.Width - 6
        } else {
            $script:EffBarsThatFit = $BarGraphSamples
        }
        $old_window_width = $Host.UI.RawUI.WindowSize.Width

        $script:full_redraw = $false
        $SamplingStart = (get-date)
        $bumpy_start_cleanup_done = $false
    }
    process {
        $Items  | %{
            # echo "Item: $($_.GetType().Name) $($_.status) $($_.RTT) $($_.status) "
            # echo $_
            # echo ""

            #echo $_, ($_.Status -eq 'Success')
            if ($_.Status -eq 'Success') {
                [int]$ms = $_.RTT
                if ($ms -lt $all_min_RTT) {$all_min_RTT=$ms}
                if ($ms -gt $all_max_RTT) {$all_max_RTT=$ms}
                $all_pings_cnt += 1
                if ($all_pings_cnt -eq 1) {
                    $SamplingStart = (get-date)
                }
            } else {
                # Failure (e.g. a timeout or anything else except a reply)
                $ms = 9999 # <-- means failure
                $all_pings_cnt += 1
                $all_lost_cnt  += 1
            }

            # $RTT_values is used both to show the bar graph and for the histogram
            # We need $HistSamples samples for the histogram and EffBarsThatFit
            # for the bar graph. I add another 100 so that if the user enlarges the
            # screen the graph will imidiately show more values.
            $max_values_to_keep = [math]::max($script:EffBarsThatFit + 100, $HistSamples)

            # populate $RTT_values
            #-----------------------------
            $RTT_values.enqueue($ms)
			
            # keep $ms to a list of values that we will right to the ops....pingrec file
            if ($ms -eq 9999) {$ToSave_values += @(-1)} else {$ToSave_values += @($ms)}

            # keep at most $script:EffBarsThatFit measurements in RTT_values
            while ($RTT_values.count -gt $max_values_to_keep) {
                $foo = $RTT_values.dequeue()
            }

            # other things to do with input
            $last_input = $_

            if (!($Title)) {
                if ($Target -eq '') {
                    $Title = $Title + "Internet hosts"
                } else {
                    $Title = $Title + $Target
                }
            }
        }

        # populate the slow updating graphs
        #--------------------------------------
        if ($DebugMode) {
            $script:AggPeriodSeconds = 0
            if (($all_pings_cnt -gt 0) -and (($all_pings_cnt % $AggregationSeconds) -eq 0)) {
                $script:AggPeriodSeconds = $AggregationSeconds
            }
        } else {
            $script:AggPeriodSeconds = ($(get-date) - $AggPeriodStart).TotalSeconds
        }

        $save_screen_to_file = $false # a flat that is set once pper AggPeriodSeconds

        if (($script:AggPeriodSeconds -ge $AggregationSeconds) -and ($RTT_values.count -gt 2)) {
            # This code executes once every AggPeriodSeconds
			#------------------------------------------------
			
            $AggPeriodStart = (get-date) # FIXME must subtract as many seconds as we are already after the AggregationSeconds
            if (!($DebugMode)) {$script:full_redraw = $true}

            # a lot of data are derived from the last $AggregationSeconds values of $RTT_values
            # so we keep them here for convenience
            $last_hist_secs_values = @($RTT_values | select -Last ($AggregationSeconds * $PingsPerSec))
            $last_hist_secs_values_no_lost = @($RTT_values | ?{$_ -ne 9999} | select -Last ($AggregationSeconds * $PingsPerSec))

            
            # populate the 95 percentiles bar graph
            if ($last_hist_secs_values_no_lost) {
                $stats = (stats_of_series $last_hist_secs_values_no_lost)
                $p95_values.enqueue($stats.p95)
                if (($DebugData) -and ($all_pings_cnt -lt 20000)) {
                    "p95_values=$($stats.p95 - $stats.min) from these data: $last_hist_secs_values_no_lost" >> "$($env:TEMP)\ops.$ts.data"
                }

            } else {
                # all pings were lost...
                $p95_values.enqueue(0)
            }

            # populate the jitter bar graph
            $jitter = (p95_of_jitter $last_hist_secs_values)
            $Jitter_values.enqueue($jitter)

            # populate the lost% bar graph
            $lostperc = (($last_hist_secs_values | ?{$_ -eq 9999} | measure-object).count)*100/($last_hist_secs_values.count)
            $Loss_values.enqueue($lostperc)

            # keep at most $script:EffBarsThatFit (same as for the time graph
            while ($p95_values.count -gt ($script:EffBarsThatFit+100)) {
                $foo = $p95_values.dequeue()
                $foo = $Jitter_values.dequeue()
                $foo = $Loss_values.dequeue()
            }

            append_to_pingtimes $ToSave_values $script:PINGREC_FILE
            $ToSave_values = @()

            # signal that it is time to update the file with the current screen
            $save_screen_to_file = $true
        }



        if ($RTT_values.count -lt 0) {
            echo "No reply yet. Last record: $last_input"
        } else {
            $GetDate = $(get-date)
            if (($GetDate - $ScrUpdPeriodStart).TotalSeconds -ge $UpdateScreenEvery) {

                $ScrUpdPeriodStart = $GetDate

                # This try/catch is an ugly hack because when pinging a host
                # with no network (e.g. cable unpluged), render_all raises
                # "Cannot index into a null array."
                try {
                    $screen = render_all $last_input $PingsPerSec ($target -eq '')
                } catch {
                    $screen = "Render_all error: $($error[0])`n$last_input"
                }
                if ($DebugMode) {
                    $spacer = "~"
                } else{
                    $host.UI.RawUI.CursorPosition = @{ x = 0; y = 0 }
                    $spacer = " "
                }
                if (($Host.UI.RawUI.WindowSize.Width -ne $old_window_width) -or ($script:full_redraw)) {
                    if (!($DebugMode)) {clear}
                    $script:full_redraw = $false
                    $old_window_width = $Host.UI.RawUI.WindowSize.Width
                }

                [Console]::CursorVisible = $false
                $screen | %{
                    write-host -nonewline "$_"
                    $spaces = $Host.UI.RawUI.WindowSize.Width - $host.UI.RawUI.CursorPosition.x -1
                    write-host -nonewline -foregroundcolor darkgray ($spacer * [math]::max(0,$spaces))
                    write-host ""
                }
                [Console]::CursorVisible = $true

                if ($save_screen_to_file) {
                    # save current screen to SCREEN_DUMP_FILE
                    #------------------------------------------
                    $screen > $script:SCREEN_DUMP_FILE
                }
#>
            }
        }
    }
    end {
        # nothing to do
    }
}
function parse_ping_exe_output($line) {		
	# Converts lines from the output of ping.exe to a PSCustomObject
	# The lines are like this:  1694902800.56886 Reply from 8.8.4.4: bytes=32 time=71ms TTL=115
	# EXAMPLE:
	# PS C:\> parse_ping_exe_output "1694902800.56886 Reply from 8.8.4.4: bytes=32 time=71ms TTL=115"
	# 	sent_at       : 9/16/2023 22:20:01
	# 	RTT           : 71
	# 	destination   : 8.8.4.4
	# 	parsing_error :
	# 	Status        :
	# 
	# PS C:\> parse_ping_exe_output "foo bar"
	# 	sent_at       : 9/17/2023 10:53:26
	# 	RTT           : 9999
	# 	destination   :
	# 	parsing_error : Line doesn't match expected format: foo bar
	# 	Status        :
	#
	
 	if ($line -match '[0-9.]+ Reply from [0-9.]+: bytes=.* time[<=][0-9]+ms ') {
		try {
			$fields = $line -split ' '
			$timestamp = $fields[0]
			$destination = $fields[3] -replace ':'
			$RTT = [int]($fields[5] -replace "time[<=]" -replace '[a-z]+')
			[PSCustomObject]@{`
				sent_at = ((Get-Date "1970-01-01 00:00:00").AddSeconds($timestamp - $RTT/1000)); `
				RTT = $RTT; `
				destination = $destination; `
				parsing_error = ""
				Status = $null; `
				}		
		} catch {
			[PSCustomObject]@{`
				sent_at = (get-date); `
				RTT = 9999; `
				destination = $null; `
				parsing_error = "$($Error[0].Exception.GetType().FullName) for line: $line"
				Status = $null; `
			}
		}
	} else {
		[PSCustomObject]@{`
			sent_at = (get-date); `
			RTT = 9999; `
			destination = $null; `
			parsing_error = "Line doesn't match expected format: $line"
			Status = $null; `
		}
	}
}
function process_single_host_PSOC($record) {
	# success_percent is meaningfull for paralel multi pings only
	# It is a decimal from 0 to 1, with 1 meaning 100% of all the 
	# pings of this "bucket" were replied
	if ($record.status -eq 'Success') {$success_percent = 1} else {$success_percent = 0}
	$output = [PSCustomObject]@{`
		sent_at = $record.sent_at; `
		Status = $record.status; `
		RTT = $record.RTT; `
		destination = $record.target; `
		success_percent = $success_percent; `
		warning = ""
	}
	return $output
}

$script:first_bucket_ever = $true 
$script:bucket = @()
$script:last_record = [PSCustomObject]@{sent_at = (get-date -Year 2000)}
function process_parallel_host_PSOC($record) {
	# Aggregate all $data_sorted grouped by int(sent_at) and output 
	# this aggregate value for the rest of the code. 
	# Use this aggregation logic: 
	# 	For every unique second :
	#      Put all non-localhost replies in an array $bucket
	# 	   If the bucket contains no replies set Status='failure' and RTT to
	#         RTT = 9999
	#      If not calculate the RTT as:
	#         RTT = min(effective_RTT of all hosts)
	#      Finally output a PSCustomObject for format-pingtimes to consume

	# NOTE:
	# 	If some second does not appear in $data_sorted it means that not even
	# 	localhost replied (most likely the system was sleeping)
	#   So we ignore these seconds 
	#   TODO: in the future I could be printing a column of X or something. 
	#   Not a column for every second of course because hours may have passed 
	#   with the system on sleep)
		
	$output = $null
	
	# ?{$_} ignores some $null data -- don't know why they are there
	if (within_same_second $record.sent_at $script:last_record.sent_at) {
		# ping-reply record for the same second as the previous one
		if ($record.destination -like '127.*') {
			# ignore replies from local host
		} else {
			# just collect replies to $script:bucket for latter processing
			$script:bucket += @($record)
		}
	} else {
		# ping-reply record for a new second 
		# Before dealing with the new record, process the $script:bucket for the previous second
		if ($script:first_bucket_ever) {
			# do nothing for the first bucket ever
			$script:first_bucket_ever = $false
		} else {
			if (!($script:bucket)) {
				# bucket is empty (no replies from any host except localhost)
				$output = [PSCustomObject]@{`
					sent_at = (get-date); `
					Status = 'failure'; `
					RTT = 9999; `
					destination = 'Internet'; `
					success_percent = 0; `
					warning = ""
				}
			} else {
				# good, bucket was not empty
				$how_many_hosts_replied = (($script:bucket | Measure-Object).count)
				# write-host -fore blue "`$how_many_hosts_replied = $how_many_hosts_replied"
				$output = [PSCustomObject]@{`
					sent_at = $script:bucket[0].sent_at; `
					Status = 'Success'; `
					RTT = ($script:bucket | Measure-Object -Property RTT -Minimum | Select-Object -ExpandProperty Minimum); `
					destination = 'Internet'; `
					success_percent = (4/$how_many_hosts_replied); `
					warning = ""
				}
			}
		}
		# After we are done with the $script:bucket for the previous second, create a new $script:bucket
		if ($record.destination -like '127.*') {
			$script:bucket = @()
		} else {
			# TODO: convert real RTTs to effective RTTs before adding record to bucket
			#    effective_RTT = real_RTT + dbb
			# WHERE:
			#    dbb = (RTT baseline of all hosts) - (RTT baseline of this host) 
			$script:bucket = @($record)
		}
	}
	
	$script:last_record = $record
	
	return $output
}

function Out-PingStats {
<#
.SYNOPSIS
Ping a host and present statistics about the connection quality
.DESCRIPTION
You need a monospace font containing the unicode block characters
DejaVu sans mono is good (Consolas is not)

.EXAMPLE
Out-PingStats google.com

.PARAMETER Destination
The host to ping

.PARAMETER PingsPerSec
Pings per second to perform. Note that if you set this too high there are 2 gotchas:
A) Code that renders the screen is rather slow and ping replies will pile up
   (when you stop the program, take a note of "Discarded N pings" message.
   If N is more than two times your PingsPerSec you've hit this gotcha)
B) The destination host may drop some of your ICMP echo requests(pings)
#>

    [CmdletBinding()]
    param (
        [Parameter(Position=1)]
        [string]$Target = "",
        [string]$Title = "",
        [double]$GraphMax = -1,
        [int]$PingsPerSec = 5,
        [double]$GraphMin = -1,
        [int]$HistBucketsCount=10,
        [int]$AggregationSeconds=120, # 2 mins
        [int]$HistSamples=-1,
        [char]$Visual = '=',
        [int]$DebugMode = 0,
        [switch]$DebugData,
        [int]$HighResFont = -1, # -1=auto

        [double]$UpdateScreenEvery = 1,
        [int]$BarGraphSamples = -1

    )

    # create a hash table to hold the last N RTTs of each group
    # in order to compute the average of mins which will allow us
    # to "normalize" the different groups close to a common baseline
    $max_values_to_keep = 40
    $last_RTTs = @{}
    $Median_of_last_RTTs = @{}
    $Baseline = $null
    #----------------

    $script:HighResFont = $HighResFont
    try {
        $ts = (get-date -format 'yyyy-MM-dd_HH.mm.ss')
        $script:SCREEN_DUMP_FILE = "$($env:TEMP)\ops.$ts.screen"
        $script:PINGREC_FILE = "$($env:TEMP)\ops.$ts.pingrec"
		$script:STATS_FILE = "$($env:TEMP)\ops.$ts.stats"
        "pingrec-v1,$ts,$PingsPerSec pings/sec" > $script:PINGREC_FILE
        if (!($Title)) {
            $Title = "$Target"
        }
        if ($HistSamples -eq -1) {
            # by default make histogram from 1min samples
            # BUT AT LEAST FROM 100 SAMPLES if 1min has less
            $HistSamples = [math]::max(100, $PingsPerSec * 60)
        }

        configure_graph_charset

        $parallel_testing = ($target -eq '')

        $jobs = @()
        if ($parallel_testing) {
			# We start two "beacon" pings to localhost and 4 pings to a few well known hosts
			# if we loose the beacon pings it means we have no networking layer
			# (probably system is going to/coming from sleep)
			# The output is a stream of lines like these:
			#	1694902803.02123 Reply from 127.0.0.1: bytes=32 time<1ms TTL=128
			#	1694902803.21696 Reply from 1.1.1.1: bytes=32 time=26ms TTL=55
			#	1694902803.21696 Reply from 1.1.1.2: bytes=32 time=17ms TTL=55
			#	1694902800.29343 Reply from 8.8.8.8: bytes=32 time=31ms TTL=115
			#	1694902800.56886 Reply from 8.8.4.4: bytes=32 time=71ms TTL=115

			# about the mysterious sleep 1: most of the times I get a reply from localhost
			# before any of the others and the rest of the code will happily report
			# a timeout to the Internet.
			$jobs+=@((Start-Job -ScriptBlock {sleep 1; $hostn="127.0.0.1";while($true){ping -t $hostn|sls "time[<=]"|%{ echo "$(get-date -UFormat %s) $_"}}}))
			$jobs+=@((Start-Job -ScriptBlock {$hostn="1.1.1.1"  ;while($true){ping -t $hostn|sls "time[<=]"|%{ echo "$(get-date -UFormat %s) $_"}}}))
			$jobs+=@((Start-Job -ScriptBlock {$hostn="1.1.1.2"  ;while($true){ping -t $hostn|sls "time[<=]"|%{ echo "$(get-date -UFormat %s) $_"}}}))
			$jobs+=@((Start-Job -ScriptBlock {$hostn="8.8.8.8"  ;while($true){ping -t $hostn|sls "time[<=]"|%{ echo "$(get-date -UFormat %s) $_"}}}))
			$jobs+=@((Start-Job -ScriptBlock {$hostn="8.8.4.4"  ;while($true){ping -t $hostn|sls "time[<=]"|%{ echo "$(get-date -UFormat %s) $_"}}}))
        } else {
            $group_id = $target
            $last_RTTs[$group_id] = New-Object System.Collections.Queue
            $last_RTTs[$group_id].enqueue(99)
            $Median_of_last_RTTs[$group_id] = 0

            $jobs += [array](
                start-job -ArgumentList $PingsPerSec, $target, $CodeOfSpecialPing -ScriptBlock {
                    $PingsPerSec = $args[0]
                    $target = $args[1]
                    $CodeOfSpecialPing = $args[2]
                    . Invoke-Expression $CodeOfSpecialPing
                    Start-SpecialPing  -Target $target -Interval (1000/$PingsPerSec)
                }
            )
        }

        if ($DebugMode) {
            echo "last_RTTs: $($last_RTTs.keys -join ', ')"
            echo ""
            echo "Median_of_last_RTTs: $($Median_of_last_RTTs.keys -join ', ')"
            echo ""
        }


        # MAIN LOOP
        #--------------------------------------
        # We collect the output of the ping-jobs (see above)
        # and pipe it to Format-PingTimes
        $ping_count = 0
        $bucket = @()
        $bucket_time = (get-date)
        $last_success_at = $bucket_time
        write-verbose "Init bucket_time=$bucket_time"
        & {
            while ($true) {
                # Test-Connection $Destination -ping -Continuous
                $data = @()
                while (!($data)) {
                    sleep -milliseconds 2000 # with 0.5 or less it overwhelms one CPU core...(???)

                    foreach ($job in $jobs) {
                        if ($parallel_testing) {
							if (($job | get-job).HasMoreData) {
								# receive-job is a stream of lines(strings) like these:
								#	1694902803.02123 Reply from 127.0.0.1: bytes=32 time<1ms TTL=128
								#	1694902803.21696 Reply from 1.1.1.1: bytes=32 time=26ms TTL=55
								#	1694902803.21696 Reply from 1.1.1.2: bytes=32 time=17ms TTL=55
								#	1694902800.29343 Reply from 8.8.8.8: bytes=32 time=31ms TTL=115
								#	1694902800.56886 Reply from 8.8.4.4: bytes=32 time=71ms TTL=115
								#
								# Ping.exe has a timeout of 1.5sec, so a reply to one host may come 
								# 1499msec after the request, and a reply to another host may come in 1msec
								# AS A RESULT THE TIMESTAMPS MAY BE OUT OF ORDER BY AS MUCH AS 1.5sec
								#
								# parse_ping_exe_output gives a PSCustomObject stream like this:
								#     sent_at  (it is calculated as timestamp - RTT)
								#              (if parsing failed we set it to current time)
								#     RTT
								#     destination    # host addr
								#     Status = $null 
								#     parsing_error "" or a human readable parsing error
								#
								$parsed_lines += [array]($job | receive-job | %{ parse_ping_exe_output $_} )								

								# From $parsed_lines, extract only the records having parsing_error="" and sent_at at least 
								# 1.99secs in the past*, move them to array $data
								# (Keep the other records in $parsed_lines for latter)
								# Ignore lines that failed parsing (just show parsing errors somewhere)
								#     							*: See note about "OUT OF ORDER" above
								# 
								$records_kept = @()
								$parsed_lines | ?{$_} | %{
									if ((((Get-Date) - $_.sent_at).TotalSeconds -lt 2) -and (!($_.parsing_error))) {
										$records_kept += [array]$_ # replies within last 2sec -- keep them for later
									} else {
										$data += [array]$_ # replies ready for consumption
									}
								}
								$parsed_lines = $records_kept # kept for later
							}
						} else {
							if (($job | get-job).HasMoreData) {$data += [array]($job | receive-job)}
						}
                    }

                    # $data
                    if ($data) {
						$data_sorted = ($data | ?{$_} | sort-object -property sent_at)
						$data = @()
                        if ($parallel_testing) {
                            # parallel host mode of operation 
                            $data_sorted | %{
								if ($DebugMode) {write-host -fore cyan $_}
								$out = (process_parallel_host_PSOC $_)
								if (($DebugMode) -and $out) {write-host -fore magenta $out}
								echo $out
							}
                        } else {
                            # non-parallel single host mode of operation 
                            $data_sorted | %{$out = (process_single_host_PSOC $_); if ($DebugMode) {write-host $out}; echo $out}
                        }
                    }
                }
            }
        } `
         | ?{$_} | Format-PingTimes `
            -Target $Target `
            -PingsPerSec $PingsPerSec `
            -UpdateScreenEvery $UpdateScreenEvery `
            -Title $Title -GraphMax $GraphMax `
            -GraphMin $GraphMin `
            -HistBucketsCount $HistBucketsCount `
            -AggregationSeconds $AggregationSeconds `
            -HistSamples $HistSamples `
            -DebugMode $DebugMode `
            -BarGraphSamples $BarGraphSamples `
            -HighResFont $script:HighResFont

        #>
    }
    finally { # when done
        # AFTER A CTRL-C
        #-----------------------------------
        $job_exists = $false; foreach ($job in $jobs) {if ($job) {$job_exists=$true}}
        if ($job_exists) {
            write-host  -foregroundcolor white -backgroundcolor black "Cleaning up..."
            $discarded_count = 0
            try {
                $discarded_count = 0
                foreach ($job in $jobs) {
                    if ($job) {$discarded_count += ([array]($job | receive-job) | measure).count}
                }
            } catch {
                Write-Host "Failed to retrieve output from background pings, $($error[0])"
            }
			if (!($DebugMode)) {
				Write-Host  "Removing jobs..."
				foreach ($job in $jobs) {Remove-Job $job -Force}
				write-host -foregroundcolor white -backgroundcolor black "Discarded $discarded_count pings."
			} else {
				if (get-job) {
					Write-Host  "Please remove jobs manually`n   get-job | remove-job -force" -fore yellow
				}
			}
        }
    }
}

function helper_find_pingable_com_host($CheckAfterHost='') {
	# TODO: I don't need this function any more
    # discovers pingable IPs and prints a list of them with RTTs in the lower first quartile
    # it prints the IPs with lower RTTs first
    
    $HOSTS_TO_PING_IN_PARALLEL = 32
    $HOSTS_TO_PING_IN_SERIES = 8
    $PERCENT_OF_RESPONDING_HOSTS = 0.12 # aproximation err to a lower percent

    $Hosts_to_try = $HOSTS_TO_PING_IN_PARALLEL*$HOSTS_TO_PING_IN_SERIES*4/$PERCENT_OF_RESPONDING_HOSTS
    $hosts_count = 0
    foreach ($char in [char[]]'abcdghijklmnopqrstuvwxyz') {
        $c1=$char
        foreach ($char in [char[]]'abcdefghijklmnopqrstuvwxyz') {
            $c2=$char
            foreach ($char in [char[]]' abcdefghijklmnopqrstuvwxyz') {
                $c3=$char
                $h="$c1$c2$c3.com".trim()
                if ($h -gt $CheckAfterHost) {
                    Start-ThreadJob -ThrottleLimit 100 -ArgumentList $h -ScriptBlock {
                        ping -n 1 $args[0]
                    }
                    $hosts_count += 1
                    if ($hosts_count -gt ($Hosts_to_try)) {break}
                }
            }
            if ($hosts_count -gt ($Hosts_to_try)) {break}
        }
        if ($hosts_count -gt ($Hosts_to_try)) {break}
    }

    $HostRtt = @{}
    $low_RTT_IPs = @{}

    sleep 5
    $failed_hosts = 0
    $tried_hosts = 0
    while (($HostRtt.count -lt ($HOSTS_TO_PING_IN_PARALLEL*$HOSTS_TO_PING_IN_SERIES*4)) -and ((get-job  -State 'Running') -or (get-job  -State 'NotStarted'))) {
        get-job  -State 'completed' | %{
            $out=(Receive-Job -id $_.id)
            if (!($out -like 'Ping statistics for 127.*') -and ($out -match 'Received = [^0]') -and ($out -like '*Minimum*')) {
                $hostn = ($out | sls 'Pinging').line -replace 'Pinging ' -replace ' .*'
                $real_ip = ($out | sls 'Pinging').line -replace '^.*\[' -replace '].*'
                $RTT = [int](($out | sls Minimum).line -replace '^.*= ' -replace 'ms')
                $HostRtt[$real_ip] = @{hostn=$hostn; RTT=$RTT}
                #echo $hostn
            } else {
                $failed_hosts += 1
            }
            $tried_hosts += 1
            remove-job -id $_.id
        }
        # 25% percentile of RTTs
        $RTT_p25 = ($HostRtt.Values | %{$_.RTT}  | sort | select -First ([int]($HostRtt.count/4)) | select -last 1)

        echo "Tried $tried_hosts, last was $hostn, $($HostRtt.keys.count)($([int](100*$HostRtt.keys.count/$tried_hosts))%) hosts responding, , , 1/4 of the found hosts have RTT <= $RTT_p25 ms"
        sleep 10
    }
    echo "LAST HOST CHECKED: $hostn"

    get-job | Remove-Job -force

    $line=''; $cnt=0;
    $HostRtt.keys | ? {$HostRtt[$_].RTT -le $RTT_p25} | %{
        [PSCustomObject]@{ hostn = $HostRtt[$_].hostn; RTT = $HostRtt[$_].RTT }
    } | sort -Property RTT | %{$_.hostn} | %{
        $line +=  "'$_',"
        $cnt+=1
        if ($cnt % 8 -eq 0) {
            $line = "@($line)" -replace ',\)','),'
            echo "$line"
            $line=''
        }
    }
}

function helper_find_pingable_close_hosts($min_hops=2, $max_hops=4) {
    # discovers pingable IPs "close" to us 
    # Close is defined as being from 2 to 4 hops 
    # (these are the default limits) 

    write-host "Please wait tracert'ing"
    $out = (tracert -h 4 -d google.com)
    $match = ($out  | sls "^ *[0-9].* ms ")
    if (!($match)) {
        Write-Error "ERROR: no results from tracert"
        return
    }
    #PS> ($out  | sls "^ *[0-9].* ms ").line -replace '^ *| *$'
    #1     4 ms     4 ms     2 ms  10.2.11.10
    #2    20 ms     9 ms    10 ms  10.13.255.62
    #3     8 ms     8 ms     9 ms  62.169.224.64
    #4     8 ms     8 ms     8 ms  185.3.220.7
    
    $tracert_ips = (($out  | sls "^ *[0-9].* ms ").line -replace '^ *| *$' | %{
        # each line of tracert output
        $hop = [int]($_ -replace ' .*')
        $ip = ($_ -replace '^.* ')
        if (($hop -ge $min_hops) -and ($hop -le $max_hops)) {
            write-host "next hop $ip"
            echo $ip
        }
    })
    
    # build a list of /24 networks that we see in the next hops
    $networks = ($tracert_ips | %{$_ -replace '[0-9]+$' } | sort -uniq)

    # build a list of IPs we may try to ping 
    # 254 IPs (1...254) per network (at most 4 networks)
    $hosts_to_try = @()
    $networks | select -first 4 | %{
        $network = $_
        1..254 | %{
            $octet = $_
            $hosts_to_try += [array]"$network$octet"
        }
    }
    write-host "$($hosts_to_try.count) IPs to try"


    $hosts_to_try | select -first 3 | %{
        Start-ThreadJob -ThrottleLimit 50 -ArgumentList $_ -ScriptBlock {
            ping -n 2 $args[0]
        } > $null
    }
    $failed_hosts = 0
    $tried_hosts = 0
    $IPs = @()
    while ((get-job  -State 'Running') -or (get-job  -State 'NotStarted')) {
        get-job  -State 'completed' | %{
            $out=(Receive-Job -id $_.id)
            if (!($out -like 'Ping statistics for 127.*') -and ($out -match 'Received = [^0]')) {
                $IP = ($out | sls 'Pinging').line -replace '^.*Pinging ' -replace ' with.*'
                $IPs += [array]$IP
                # Write-host "Found responding host at $IP"
            } else {
                $failed_hosts += 1
            }
            $tried_hosts += 1
            remove-job -id $_.id
        }

        if ($tried_hosts) {
            write-host "Tried $tried_hosts, $($IPs.count) hosts responding ($([int](100*$IPs.count/$tried_hosts))%)"
        }

        $hosts_to_try | select -first 50 | %{
            Start-ThreadJob -ThrottleLimit 50 -ArgumentList $_ -ScriptBlock {
                ping -n 2 $args[0]
            } > $null
        }
        $remain = [math]::max(0, ($hosts_to_try.count) - 50)
        if ($remain) {
            $hosts_to_try = ($hosts_to_try | select -last $remain)
        } else {
            $hosts_to_try = @()
        }
        sleep 5
    }
    
    get-job | Remove-Job -force

    return $IPs 
}

# $args_json = (($args | ConvertTo-Json ) -replace '\r\n',' ')
Out-PingStats @args
