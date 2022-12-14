<#
v0.9.5

TODO: Addd a mode of operation where we ping a few different hosts and 
      record as RTT the min or medial RTT of all. This will assure that
      issues at one host will not "tante" our perception of the link quality
TODO: Save files in %temp% by default
      and add argument to change folder
TODO: Don't write stats to ps1, just print screen to .txt
TODO: When multiple scripts run simultaneously sync Y-max for all graphs
TODO: Option to read input from saved file 
TODO: Hide histogram if console height is not enough
TODO: Print clock time every 10vertical bars('22:26) instead of just "`"
TODO: While we collect enough data points to have a decent histogram 
      we do present the histogram. After that point we change visualization:
      Now every block that used to show the histogram has a color that 
      represents how likely it was for the actual histogram to reach this 
      block.
      (Use color scales A) or B) from
      http://www.andrewnoske.com/wiki/Code_-_heatmaps_and_color_gradients)
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

Set-strictmode -version latest

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

    # chars used to draw the vertical bars # _???????????????
    $LR_BAR_CHR_V_COUNT = 5
    $LR_BAR_CHR_V_ = '_' +[char]8215 +[char]8332 +[char]9604 +[char]9688 +[char]9608

#----------------------------------------------------------------

$BarGraphSamples = $Host.UI.RawUI.WindowSize.Width - 6
$BucketsCount=10
$DebugMode=0
$script:AggPeriodSeconds = 0
$script:status = ""


function std_num_le($x) {
    # select the maximum of these standard numbers that is 
    # Less-than or Equal to $x
    # 1,2,5, 10,20,50, 100,200,500, 1000,2000,5000, ...
    $power = [math]::floor([math]::log($x + 1, 10))
    $candidate = [math]::pow(10, $power)
    if ($candidate*5 -le $x) {$candidate = $candidate * 5}
    if ($candidate*2 -le $x) {$candidate = $candidate * 2}
    $candidate
}

function std_num_ge($x) {
    # select the maximum of these standard numbers that is 
    # Greater-than or Equal to $x
    # 1,2,5, 10,20,50, 100,200,500, 1000,2000,5000, ...
    $power = [math]::ceiling([math]::log($x + 1, 10))
    $candidate = [math]::pow(10, $power)
    if ($candidate/5 -ge $x) {$candidate = $candidate / 5}
    if ($candidate/2 -ge $x) {$candidate = $candidate / 2}
    $candidate
}

function Get-FontName() {
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


function Format-PingTimes {
<#
.SYNOPSIS
Visualizes ping times in histogram and bar graphs

.DESCRIPTION
Pipe the output of Test-Connection to this cmdlet and it will present
the ping times in histograms and bar graphs.

You need a monospace font containing the unicode block characters: ???????????????????????????
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

            [string]$Destination,
            [int]$PingsPerSec,
            [double]$GraphMax = -1,
            [double]$GraphMin = -1,
            [double]$UpdateScreenEvery = 1,
            [int]$BucketsCount=10,
            [int]$AggregationSeconds=120, # 2 mins
            [int]$HistSamples=100,
            [char]$Visual = '=',
            [int]$DebugMode = 0,
            [int]$HighResFont = -1, # -1=auto

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
        $Variance_values = New-Object System.Collections.Queue
        $Baseline_values = New-Object System.Collections.Queue
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
    }
    process {
        $Items  | %{
            if ($DebugMode) {echo $_}
            $all_pings_cnt += 1
            if ($_.Status -eq 'Success') {
                [int]$ms = $_.RoundtripTime
                if ($ms -lt $all_min_RTT) {$all_min_RTT=$ms}
                if ($ms -gt $all_max_RTT) {$all_max_RTT=$ms}
            } else {
                # Failure (e.g. a timeout or anything else except a reply)
                $ms = 9999 # <-- means failure
                $all_lost_cnt  += 1
            }
            $all_pings_cnt += 1
            if ($all_pings_cnt -eq 1) {
                $SamplingStart = (get-date)
            }

            # $RTT_values is used both to show the bar graph and for the histogram
            # We need $HistSamples samples for the histogram and EffBarsThatFit
            # for the bar graph. I add another 100 so that if the user enlarges the
            # screen the graph will imidiately show more values.
            $max_values_to_keep = [math]::max($script:EffBarsThatFit + 100, $HistSamples)

            # populate $RTT_values
            #-----------------------------
            $RTT_values.enqueue($ms)
            $ToSave_values += @($ms)
            # keep at most $script:EffBarsThatFit measurements in RTT_values
            while ($RTT_values.count -gt $max_values_to_keep) {$foo = $RTT_values.dequeue()}

            # other things to do with input
            $last_input = $_

            if (!($Title)) {
                $Title = $Title + $Destination
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
        if (($script:AggPeriodSeconds -ge $AggregationSeconds) -and ($RTT_values.count -gt 2)) {
            $AggPeriodStart = (get-date)
            if (!($DebugMode)) {$script:full_redraw = $true}

            # a lot of data are derived from the last $AggregationSeconds values of $RTT_values
            # so we keep them here for convenience
            $last_hist_secs_values = @($RTT_values | select -Last ($AggregationSeconds * $PingsPerSec))
            $last_hist_secs_values_no_lost = @($RTT_values | ?{$_ -ne 9999} | select -Last ($AggregationSeconds * $PingsPerSec))

            # populate the 95 percentiles bar graph
            if ($last_hist_secs_values_no_lost) {
                $stats = (stats_of_series $last_hist_secs_values_no_lost)
                $Variance_values.enqueue($stats.p95 - $stats.min)
                $Baseline_values.enqueue($stats.min)
            } else {
                # all pings were lost...
                $Variance_values.enqueue(0)
                $Baseline_values.enqueue(9999)
            }

            # populate the jitter bar graph
            $jitter = (p95_of_jitter $last_hist_secs_values)
            $Jitter_values.enqueue($jitter)

            # populate the lost% bar graph
            $lostperc = (($last_hist_secs_values | ?{$_ -eq 9999} | measure-object).count)*100/($last_hist_secs_values.count)
            $Loss_values.enqueue($lostperc)

            # keep at most $script:EffBarsThatFit (same as for the time graph
            while ($Variance_values.count -gt $script:EffBarsThatFit) {
                $foo = $Variance_values.dequeue()
                $foo = $Baseline_values.dequeue()
                $foo = $Jitter_values.dequeue()
                $foo = $Loss_values.dequeue()
            }

            # we also save the slow updating graph values to disk
            #------------------------------------------
            $file =  $script:LOG_FILE
            echo "# You can run the following commands to get a nice graph" > "$file.tmp"
            echo "# $(get-date -format 'yyyy-MM-dd HH:mm:ss') $Title" >> "$file.tmp"
            echo "echo ''" >> "$file.tmp"
            echo "`$SamplingStart = (get-date)" >> "$file.tmp"
            echo "`$PingsPerSec=$PingsPerSec" >> "$file.tmp"
            echo "`$HistSamples=$HistSamples" >> "$file.tmp"
            echo "`$all_min_RTT=$all_min_RTT" >> "$file.tmp"
            echo "`$all_max_RTT=$all_max_RTT" >> "$file.tmp"
            echo "`$all_pings_cnt=$all_pings_cnt" >> "$file.tmp"
            echo "`$all_lost_cnt=$all_lost_cnt" >> "$file.tmp"
            $escaped = $Title -replace "'","``'"
            echo "`$Title='$($escaped)'" >> "$file.tmp"

            $list = (($RTT_values | %{ aprox_num $_}) -join ",")
            echo "`$RTT_values=@($list)" >> "$file.tmp"
            $list = (($Variance_values | %{ aprox_num $_}) -join ",")
            echo "`$Variance_values=@($list)" >> "$file.tmp"
            $list = (($Baseline_values | %{ aprox_num $_}) -join ",")
            echo "`$Baseline_values=@($list)" >> "$file.tmp"
            $list = (($Jitter_values | %{ aprox_num $_})  -join ",")
            echo "`$Jitter_values=@($list)" >> "$file.tmp"
            $list = (($Loss_values  | %{ aprox_num $_}) -join ",")
            echo "`$Loss_values=@($list)" >> "$file.tmp"
            echo "`$AggregationSeconds=$AggregationSeconds" >> "$file.tmp"
            echo "`$HistSamples=$HistSamples" >> "$file.tmp"
            echo "`$GraphMin=$GraphMin" >> "$file.tmp"
            echo "`$GraphMax=$GraphMax" >> "$file.tmp"
            echo "render_all" >> "$file.tmp"

            if (test-path "$file") {remove-item "$file"}
            move-item "$file.tmp" "$file"
            
            # Record EVERY ping response to a text file named like:
            # google.com.2022-12-16_19.01.21.pingtimes
            # First line is
            #     pingrec-v1,2022-05-12,5 pings/sec,google.com
            # Then we have one line per minute starting with the timestamp "hhmm:"
            # Finaly one char per ping follows. The char is [char](ttl+32)
            # (e.g. "A" for 33msec, "B" for 34msec...)

            $line = (get-date -format 'HHmm:')
            $ToSave_values | %{
                $line += [char]($_ + 32)
            }
            $line >> $RTT_FILE
            $ToSave_values = @()

        }

        if ($RTT_values.count -eq 0) {
            echo "No reply yet. Last record: $last_input"
        } else {
            $GetDate = $(get-date)
            if (($GetDate - $ScrUpdPeriodStart).TotalSeconds -ge $UpdateScreenEvery) {
                $ScrUpdPeriodStart = $GetDate

                $screen = (render_all $last_input $PingsPerSec)
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
            }
        }
    }
    end {
        # nothing to do
    }
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

function aprox_num($num) {
    # rounds $num to "enough" decimals
    # see get_enough_decimal_digits for understanding enough
    try {
        return [math]::round($num, (get_enough_decimal_digits $num))
    } catch {
        return "???"
    }
}

filter isNumeric($x) {
    return $x -is [int16]  -or $x -is [int32]  -or $x -is [int64]  `
       -or $x -is [uint16] -or $x -is [uint32] -or $x -is [uint64] `
       -or $x -is [float] -or $x -is [double] -or $x -is [decimal]
}

function stats_of_series($series){
    # returns min, median, 95th percentile, max
    # TODO median is not real median if $series has even number of elements
    if (!($series)) {
        return @{
            min = $null;
            p5 = $null;
            median = $null;
            p95 = $null;
            max = $null;
        }
    }
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
function series_to_histogram($y_values) {
    # returns an array with the values of the histogram
    $buckets = @(0..$BucketsCount)
    For ($i=0; $i -le $BucketsCount; $i++) { $buckets[$i] = 0 }

    $stats = (stats_of_series ($y_values | ?{$_ -ne 9999}))

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
    if ($y_max -lt ($y_min + $BucketsCount)) {$y_max = $y_min + $BucketsCount}

    $y_values | %{
        $ms = $_
        if ($ms -eq 9999) {
            $buckets[$BucketsCount] += 1  # $buckets[$BucketsCount] counts failures
        } else {
            # line about a reply
            $norm_ms = [math]::min($y_max-1,[math]::max($y_min,$ms))
            [double]$bucket = ($norm_ms-$y_min)/($y_max-$y_min)
            [double]$bucket = [Math]::Floor($bucket*$BucketsCount)
            #echo "$ms => +1 in bucket #$bucket"
            $buckets[$bucket] += 1
        }
    }
    return @($buckets, $y_min, $y_max)
}

function Show_bar_graph($y_values, $title="", $options="", $special_value, `
    $default_y_min, $default_y_max, $theme) {
    # It can display 24 or 25 different heights
    # (25 if you count a zero height that gives an empty bar as an increment,
    #  24 if you count only heights that give a visible line with "???" being the lowest)
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
            #  _0     |v      v????????????????????????
            # |       v????????????????????????????????????????????????
            # v????????????????????????????????????????????????????????????????????????
            # 0123456789012345678901234
            $step = (($Y_max - $Y_min) / $script:BAR_CHR_V_COUNT / 3) # 3 lines
            $quantized = [Math]::Round( ($_ - $Y_min) / $step, 0)
            if ($quantized -gt (3 * $script:BAR_CHR_V_COUNT)) {
                $topline += $col_hi + [char]0x25B2 + $col_base# '???'
                $midline += [char]0x2588 # '???'
                $botline += [char]0x2588 # '???'
            } elseif ($quantized -ge (2 * $script:BAR_CHR_V_COUNT)) {
                $topline += $script:BAR_CHR_V_[$quantized - (2 * $script:BAR_CHR_V_COUNT) ]
                $midline += [char]0x2588 # '???'
                $botline += [char]0x2588 # '???'
            } elseif ($quantized -ge (1 * $script:BAR_CHR_V_COUNT)) {
                $topline += $space
                $midline += $script:BAR_CHR_V_[$quantized - (1 * $script:BAR_CHR_V_COUNT) ]
                $botline += [char]0x2588 # '???'
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

function percent_to_bar($percent, $Chars_for_100perc) {
    # used by show_histogram
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

function show_histogram($y_values) {
    ($buckets, $y_min, $y_max) = (series_to_histogram $y_values)
    # the following fancy line makes sure I buckets divided exactly at integer values
    $y_max = [math]::Ceiling(($y_max - $y_min) / $BucketsCount) * $BucketsCount + $y_min

    #echo "HIST min=$y_min, max=$y_max "

    [double]$perc_cumul = 0
    [double]$max_perc = 0
    For ($i=0; $i -le $BucketsCount; $i++) {
        [double]$percent = [Math]::Round(100 * $buckets[$i] / $y_values.count,1)
        $max_perc = [Math]::max($max_perc, $percent)
    }

    # 28 characters are available
    # if max percent is 0.5 then by setting scale to 28/0.5=56 chars the 50% will fill 28 chars
    $Chars_for_100perc = 28/($max_perc/100)
    For ($i=0; $i -lt $BucketsCount; $i++) {
        [double]$from = $y_min + $i * ($y_max-$y_min)/$BucketsCount
        [double]$to = $y_min + ($i+1) * ($y_max-$y_min)/$BucketsCount
        $count = $buckets[$i]
        [double]$percent = [Math]::Round(100 * $buckets[$i] / $y_values.count,1)
        $perc_cumul = [Math]::min(100, [Math]::Round($perc_cumul + $percent,1))
        $max_perc = [Math]::max($max_perc, $percent)

        if ($i -eq 0) {$from_str="min"; $cumul_str=" Cumul"} else {$from_str="{0,3}" -f $from; $cumul_str=" {0,3}% " -f $perc_cumul}
        if ($i -eq ($BucketsCount - 1)) {$to_str="MAX"} else {$to_str="{0,3}" -f $to}
        $bars = (percent_to_bar $percent  $Chars_for_100perc)
        $spaces = 28-($bars.length)
        $spaces = " " * [math]::max(0,$spaces)
        $bars = "{0}{1}" -f $bars, $spaces
        "{0}...{1} $COL_IMP_LOW{2,4}$COL_RST {3,4}%$COL_IMP_LOW{4,5}$COL_GRAPH{5}$COL_RST" -f $from_str, $to_str, $count, $percent, $cumul_str, $bars
    }
    $failed_perc = $buckets[$BucketsCount] # failures
    [double]$percent = [Math]::Round(100 * $failed_perc / ($y_values.count),1)

    if ($percent -gt 0) {$color = $col_hilite} else {$color = $COL_H1}
    "Failures: {0}{1,4} {2,4}%      {3}{4}" -f $color, $failed_perc, $percent, (percent_to_bar $percent  $Chars_for_100perc), $COL_RST
}

function p95_of_jitter($RTT_values){
    # computes the 95th percentile of the jitter for the RTTs
    write-verbose "RTTs = $($RTT_values -join ',')"
    $prev = $RTT_values | select -first 1
    $jitter = @($RTT_values | select -last ($RTT_values.count -1) | %{
        if (($_ -eq 9999) -or ($prev -eq 9999)) {
            echo 9999
        } else {
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

function render_slow_updating_graphs() {
    # describe the sampling period and the total time we collect samples
    # e.g. per 2' for 14'
    $AggPeriodDescr = "per $([math]::round($AggregationSeconds/60,1))' "+`
        "for $([math]::round($AggregationSeconds*$Variance_values.count/60,1))'"

    # X axis limits
    $MaxItems = $Host.UI.RawUI.WindowSize.Width - 6

    # display $Baseline_values
    #------------------------------
    $values = @($Baseline_values | select -last $MaxItems)
    $stats = (stats_of_series $values)
    if ($GraphMin -ne -1) {$y_min = $GraphMin} else {
        $y_min = (std_num_le $stats.min)
        if ($y_min -lt 10) {$y_min = 0}
    }
    if ($GraphMax -ne -1) {$y_max = $GraphMax} else {$y_max = (y_axis_max $stats.min $stats.max $y_min 9)}    
    $title = "RTT BASELINE(min),  $AggPeriodDescr, min=<min>, p95=<p95>, max=<max>, last=<last> (ms)"
    Show_bar_graph $values $title "<stats><H_grid>" 9999 `
        $y_min $y_max $RTTMIN_BAR_GRAPH_THEME
    echo ""

    # display $Variance_values
    #------------------------------
    $values = @($Variance_values | select -last $MaxItems)
    $stats = (stats_of_series $values)
    $y_min = (std_num_le $stats.min)
    if ($y_min -lt 10) {$y_min = 0}
    $y_max = (y_axis_max $stats.min $stats.max $y_min 10)
    if ($y_max -eq $y_min) {$y_max = (std_num_ge $y_max + 1)}
    $title = "RTT VARIANCE(p95-min), $AggPeriodDescr, min=<min>, max=<max>, last=<last> (ms)"
    Show_bar_graph $values $title "<stats><H_grid>" 9999 `
        $y_min $y_max
    echo ""

    # display the lost% bar graph
    #------------------------------
    $stats = (stats_of_series $Loss_values)
    $y_min = 0
    $y_max = (y_axis_max $stats.min $stats.max 0 4)
    $title = "LOSS%, $AggPeriodDescr, min=<min>%, p95=<p95>%, max=<max>%, last=<last>%"
    Show_bar_graph @($Loss_values | select -last $MaxItems) $title "<stats><H_grid><min_no_color>" 100 `
        $y_min $y_max $LOSS_BAR_GRAPH_THEME
    echo ""

    # display the jitter bar graph
    #------------------------------
    $title = "ONE-WAY JITTER, $AggPeriodDescr, min=<min>, p95=<p95>, max=<max>, last=<last> (ms)"
    $stats = (stats_of_series $Jitter_values)
    $y_min = 0
    $y_max = 30
    if ($stats.max -le 10) {$y_max = 10}
    Show_bar_graph @($Jitter_values | select -last $MaxItems) $title "<stats><H_grid>" $null `
        $y_min $y_max $JITTER_BAR_GRAPH_THEME
}

function render_all($last_input) {
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
    $stats = (stats_of_series ($graph_values | ?{$_ -ne 9999}))
    #echo ([string][char]9472*75)
    $title = "LAST RTTs,  $($graph_values.count) pings, min=$($stats.min), p95=$($stats.p95), max=$($stats.max), last=<last> (ms)"
    # decide Y axis limits
    ($time_graph_abs_min, $p5, $p95, $time_graph_abs_max) = ($stats.min, $stats.p5, $stats.p95, $stats.max)

    $y_min = (std_num_le $stats.min)
    if ($y_min -lt 10) {$y_min = 0}
    $y_max = (y_axis_max $stats.min $stats.max $y_min 9)
    if ($GraphMin -ne -1) {$y_min = $GraphMin}
    if ($GraphMax -ne -1) {$y_max = $GraphMax}
    Show_bar_graph $graph_values "$title"  "<stats><H_grid>" 9999 $y_min $y_max
    echo ""

    # display the histogram
    if ($RTT_values.count) {
        #echo ([string][char]9472*75)
        echo "    ${COL_TITLE}RTT HISTOGRAM, last $HistSamples samples, p95=${COL_H1}${p95}${COL_TITLE}ms$COL_RST"
        show_histogram @($RTT_values | select -last $HistSamples)
        $p95 = [int](stats_of_series $RTT_values).p95
        echo ""
    }

    if ($Variance_values.count) {
        render_slow_updating_graphs
        if (Test-Path variable:script:LOG_FILE) {
            echo "$COL_IMP_LOW     (Saving to $($script:LOG_FILE))"
        }
    }

    if ($DebugMode) {
        #echo "AggPeriodSeconds=$script:AggPeriodSeconds"
        #echo "Variance_values=$Variance_values"
        echo "Jitter_values=$Jitter_values"
        #sleep 0.1
    }
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
        [string]$Destination = "google.com",
        [string]$Title = "",
        [double]$GraphMax = -1,
        [int]$PingsPerSec = 5,
        [double]$GraphMin = -1,
        [int]$BucketsCount=10,
        [int]$AggregationSeconds=120, # 2 mins
        [int]$HistSamples=-1,
        [char]$Visual = '=',
        [int]$DebugMode = 0,
        [int]$HighResFont = -1, # -1=auto

        [double]$UpdateScreenEvery = 1,
        [int]$BarGraphSamples = -1

    )

    $script:HighResFont = $HighResFont 
    try {
        $ts = (get-date -format 'yyyy-MM-dd_HH.mm')
        $script:LOG_FILE="pingtimes.$Destination.$ts.ps1"
        $script:RTT_FILE="$Destination.$ts.pingrec"
        "pingrec-v1,$ts,$PingsPerSec pings/sec,$Destination" > $RTT_FILE
        if (!($Title)) {
            $Title = $Destination
        }
        if ($HistSamples -eq -1) {
            # by default make histogram from 1min samples
            # BUT AT LEAST FROM 100 SAMPLES if 1min has less
            $HistSamples = [math]::max(100, $PingsPerSec * 60)
        }
		
		configure_graph_charset

        $jobs = (
        start-job -ArgumentList $PingsPerSec, $Destination, `
            -ScriptBlock {

                Function Start-SpecialPing {
                    # Allows custom interval with msec accuracy.
                    # Will try hard to send 1000/$Interval pings per second
                    # by adjusting the delay between two consequtive pings.
                    # NOTE that in case of failure, it does not return 0 but
                    # the elapsed time 
                    Param(
                        [string]$ComputerName="8.8.8.8",
                        [int]$TimeOut = 500,
                        [int]$Interval = 50
                    )

                    $ping_count = 0
                    $ts_first_ping = (Get-Date)
                    while ($True) {
                        $ts_start = (Get-Date)
                        # $ts_start.ticks / 10000 milliseconds counter
                        $Ping = [System.Net.NetworkInformation.Ping]::New()
                        $ret = $Ping.Send($ComputerName, $TimeOut)
                        $ts_end = (Get-Date)
                        $ping_count += 1
                        if ($ret.Status -ne 'Success') {
                            $RoundtripTime = [int](($ts_end.ticks - $ts_start.ticks)/10000)
                        } else {
                            $RoundtripTime = $ret.RoundtripTime
                        }

                        if ($ping_count -eq 1) {
                            $total_elapsed_ms = $RoundtripTime
                            $expected_elapsed_ms = 0
                            $diff = $RoundtripTime
                            $ts_first_ping = $ts_start
                        } else {
                            $total_elapsed_ms = [int](($ts_end.ticks - $ts_first_ping.ticks)/10000)
                            $expected_elapsed_ms = [int](($ping_count-1) * $Interval)
                            $diff = $total_elapsed_ms - $expected_elapsed_ms
                        }

                        $sleep_ms = [math]::max(0, $Interval - $diff)
                        # return this:
                        [PSCustomObject]@{RoundtripTime = $RoundtripTime; `
                            Status=$ret.Status.tostring(); `
                            ts_start = $ts_start; `
                            ping_count=$ping_count
                        }
<# this is good for debugging only
        [PSCustomObject]@{RoundtripTime = $RoundtripTime; `
            Status=$ret.Status; `
            ts_start = $ts_start; `
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
                $PingsPerSec = $args[0]
                $Destination = $args[1]
                Start-SpecialPing  -Interval (1000/$PingsPerSec) -TimeOut 500 -ComputerName $Destination
            }
        )            
        
		function Get-ChildProcesses($parent_pid) {
			$children = (Get-WmiObject win32_process -filter "Name!='conhost.exe' AND ParentProcessId=$parent_pid" | select -property name, ProcessId)
			if ($children) {
				return ($children).ProcessId
			}
		}

        echo "Finding children..."
        # Every job we start starts a powershell.exe process 
        # Each of them starts a conhost.exe
        # These are the pids of all powershell.exe processes:		
        $children_PS_pids = @()
        $children_PS_pids += (Get-WmiObject win32_process -filter "Name='powershell.exe' AND ParentProcessId=$PID"`
            | select -property ProcessId).ProcessId
        echo "    $children_PS_pids"
        # $children_PS_pids | %{ Show-Processes $_ } 
        echo "Waiting for $($children_PS_pids.count) sec..."
        echo "Finding grand children except conhost.exe if any..."
        $grand_children = @()
        $children_PS_pids | %{ $grand_children += (Get-ChildProcesses $_) }
        echo "    $grand_children"
        # $grand_children | %{ Show-Processes $_ } 
        
        # MAIN LOOP
        #--------------------------------------
        # We collect the output of the ping-jobs (see above)
        # and pipe it to Format-PingTimes
        & {while ($true) {
            # Test-Connection $Destination -ping -Continuous
            $data = $null
            while (!($data)) {
                sleep 1 # with 0.5 or less it overwhelms one CPU core...(???)
                if (($jobs | get-job).HasMoreData) {
                    $data = ($jobs| receive-job)
                }
            }
            $data
        }} | Format-PingTimes `
                -PingsPerSec $PingsPerSec `
                -Destination $Destination `
                -UpdateScreenEvery $UpdateScreenEvery -Title $Title -GraphMax $GraphMax `
                -GraphMin $GraphMin -BucketsCount $BucketsCount `
                -AggregationSeconds $AggregationSeconds -HistSamples $HistSamples `
                -DebugMode $DebugMode -BarGraphSamples $BarGraphSamples `
                -HighResFont $script:HighResFont
    }
    finally { # when done
        # AFTER A CTRL-C
        #-----------------------------------
        if ($jobs) {
            write-host  -foregroundcolor white -backgroundcolor black "Cleaning up..."
			$discarded_count = 0
            try {
                $discarded_count = [array]($jobs| receive-job)
				if ($discarded_count) {
					$discarded_count = $discarded_count.count
				}
            } catch {
				Write-Host "Failed to retrieve output from background pings, $($error[0])"
            }
            Write-Host  "Stoping background pings $($grand_children)..."
			# $grand_children | stop-process -force
			# write-host "taskkill.exe /F /PID $($grand_children -join ' /PID ')"
			if ($grand_children) {
				# this will taskkill all ping.exe
				iex "taskkill.exe /T /F /PID $($grand_children -join ' /PID ')" > $null
			} 
            Write-Host  "Removing jobs..."
			Remove-Job $jobs -Force
            write-host -foregroundcolor white -backgroundcolor black "Discarded $discarded_count pings."
        }
    }
}

Out-PingStats @args
<#
v0.9.4

TODO: Save files in %temp% by default
      and add argument to change folder
TODO: Don't write stats to ps1, just print screen to .txt
TODO: When multiple scripts run simultaneously sync Y-max for all graphs
TODO: Option to read input from saved file 
TODO: Hide histogram if console height is not enough
TODO: Print clock time every 10vertical bars('22:26) instead of just "`"
TODO: While we collect enough data points to have a decent histogram 
      we do present the histogram. After that point we change visualization:
      Now every block that used to show the histogram has a color that 
      represents how likely it was for the actual histogram to reach this 
      block.
      (Use color scales A) or B) from
      http://www.andrewnoske.com/wiki/Code_-_heatmaps_and_color_gradients)
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

Set-strictmode -version latest

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

    # chars used to draw the vertical bars # _???????????????
    $LR_BAR_CHR_V_COUNT = 5
    $LR_BAR_CHR_V_ = '_' +[char]8215 +[char]8332 +[char]9604 +[char]9688 +[char]9608

#----------------------------------------------------------------

$BarGraphSamples = $Host.UI.RawUI.WindowSize.Width - 6
$BucketsCount=10
$DebugMode=0
$script:AggPeriodSeconds = 0
$script:status = ""


function std_num_le($x) {
    # select the maximum of these standard numbers that is 
    # Less-than or Equal to $x
    # 1,2,5, 10,20,50, 100,200,500, 1000,2000,5000, ...
    $power = [math]::floor([math]::log($x + 1, 10))
    $candidate = [math]::pow(10, $power)
    if ($candidate*5 -le $x) {$candidate = $candidate * 5}
    if ($candidate*2 -le $x) {$candidate = $candidate * 2}
    $candidate
}

function std_num_ge($x) {
    # select the maximum of these standard numbers that is 
    # Greater-than or Equal to $x
    # 1,2,5, 10,20,50, 100,200,500, 1000,2000,5000, ...
    $power = [math]::ceiling([math]::log($x + 1, 10))
    $candidate = [math]::pow(10, $power)
    if ($candidate/5 -ge $x) {$candidate = $candidate / 5}
    if ($candidate/2 -ge $x) {$candidate = $candidate / 2}
    $candidate
}

function Get-FontName() {
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


function Format-PingTimes {
<#
.SYNOPSIS
Visualizes ping times in histogram and bar graphs

.DESCRIPTION
Pipe the output of Test-Connection to this cmdlet and it will present
the ping times in histograms and bar graphs.

You need a monospace font containing the unicode block characters: ???????????????????????????
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
            [string]$Destination = "",

            [double]$GraphMax = -1,
            [double]$GraphMin = -1,
            [double]$UpdateScreenEvery = 1,
            [int]$BucketsCount=10,
            [int]$AggregationSeconds=120, # 2 mins
            [int]$HistSamples=100,
            [char]$Visual = '=',
            [int]$DebugMode = 0,
            [int]$HighResFont = -1, # -1=auto

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
        $Variance_values = New-Object System.Collections.Queue
        $Baseline_values = New-Object System.Collections.Queue
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
    }
    process {
        $Items  | %{
            #echo $_, ($_.Status -eq 'Success')
            if ($_.Status -eq 'Success') {
                [int]$ms = $_.RoundtripTime
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

            if ($ms) {
                # $RTT_values is used both to show the bar graph and for the histogram
                # We need $HistSamples samples for the histogram and EffBarsThatFit
                # for the bar graph. I add another 100 so that if the user enlarges the
                # screen the graph will imidiately show more values.
                $max_values_to_keep = [math]::max($script:EffBarsThatFit + 100, $HistSamples)

                # populate $RTT_values
                #-----------------------------
                $RTT_values.enqueue($ms)
                $ToSave_values += @($ms)
                # keep at most $script:EffBarsThatFit measurements in RTT_values
                while ($RTT_values.count -gt $max_values_to_keep) {$foo = $RTT_values.dequeue()}
            }

            # other things to do with input
            $last_input = $_

            if (!($Title)) {
                $Title = $Title + $Destination
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
        if (($script:AggPeriodSeconds -ge $AggregationSeconds) -and ($RTT_values.count -gt 2)) {
            $AggPeriodStart = (get-date)
            if (!($DebugMode)) {$script:full_redraw = $true}

            # a lot of data are derived from the last $AggregationSeconds values of $RTT_values
            # so we keep them here for convenience
            $last_hist_secs_values = @($RTT_values | select -Last ($AggregationSeconds * $PingsPerSec))
            $last_hist_secs_values_no_lost = @($RTT_values | ?{$_ -ne 9999} | select -Last ($AggregationSeconds * $PingsPerSec))

            # populate the 95 percentiles bar graph
            if ($last_hist_secs_values_no_lost) {
                $stats = (stats_of_series $last_hist_secs_values_no_lost)
                $Variance_values.enqueue($stats.p95 - $stats.min)
                $Baseline_values.enqueue($stats.min)
            } else {
                # all pings were lost...
                $Variance_values.enqueue(0)
                $Baseline_values.enqueue(9999)
            }

            # populate the jitter bar graph
            $jitter = (p95_of_jitter $last_hist_secs_values)
            $Jitter_values.enqueue($jitter)

            # populate the lost% bar graph
            $lostperc = (($last_hist_secs_values | ?{$_ -eq 9999} | measure-object).count)*100/($last_hist_secs_values.count)
            $Loss_values.enqueue($lostperc)

            # keep at most $script:EffBarsThatFit (same as for the time graph
            while ($Variance_values.count -gt $script:EffBarsThatFit) {
                $foo = $Variance_values.dequeue()
                $foo = $Baseline_values.dequeue()
                $foo = $Jitter_values.dequeue()
                $foo = $Loss_values.dequeue()
            }

            # we also save the slow updating graph values to disk
            #------------------------------------------
            $file =  $script:LOG_FILE
            echo "# You can run the following commands to get a nice graph" > "$file.tmp"
            echo "# $(get-date -format 'yyyy-MM-dd HH:mm:ss') $Title" >> "$file.tmp"
            echo "echo ''" >> "$file.tmp"
            echo "`$SamplingStart = (get-date)" >> "$file.tmp"
            echo "`$PingsPerSec=$PingsPerSec" >> "$file.tmp"
            echo "`$HistSamples=$HistSamples" >> "$file.tmp"
            echo "`$all_min_RTT=$all_min_RTT" >> "$file.tmp"
            echo "`$all_max_RTT=$all_max_RTT" >> "$file.tmp"
            echo "`$all_pings_cnt=$all_pings_cnt" >> "$file.tmp"
            echo "`$all_lost_cnt=$all_lost_cnt" >> "$file.tmp"
            $escaped = $Title -replace "'","``'"
            echo "`$Title='$($escaped)'" >> "$file.tmp"

            $list = (($RTT_values | %{ aprox_num $_}) -join ",")
            echo "`$RTT_values=@($list)" >> "$file.tmp"
            $list = (($Variance_values | %{ aprox_num $_}) -join ",")
            echo "`$Variance_values=@($list)" >> "$file.tmp"
            $list = (($Baseline_values | %{ aprox_num $_}) -join ",")
            echo "`$Baseline_values=@($list)" >> "$file.tmp"
            $list = (($Jitter_values | %{ aprox_num $_})  -join ",")
            echo "`$Jitter_values=@($list)" >> "$file.tmp"
            $list = (($Loss_values  | %{ aprox_num $_}) -join ",")
            echo "`$Loss_values=@($list)" >> "$file.tmp"
            echo "`$AggregationSeconds=$AggregationSeconds" >> "$file.tmp"
            echo "`$HistSamples=$HistSamples" >> "$file.tmp"
            echo "`$GraphMin=$GraphMin" >> "$file.tmp"
            echo "`$GraphMax=$GraphMax" >> "$file.tmp"
            echo "render_all" >> "$file.tmp"

            if (test-path "$file") {remove-item "$file"}
            move-item "$file.tmp" "$file"
            
            # Record EVERY ping response to a text file named like:
            # google.com.2022-12-16_19.01.21.pingtimes
            # First line is
            #     pingrec-v1,2022-05-12,5 pings/sec,google.com
            # Then we have one line per minute starting with the timestamp "hhmm:"
            # Finaly one char per ping follows. The char is [char](ttl+32)
            # (e.g. "A" for 33msec, "B" for 34msec...)

            $line = (get-date -format 'HHmm:')
            $ToSave_values | %{
                $line += [char]($_ + 32)
            }
            $line >> $RTT_FILE
            $ToSave_values = @()

        }

        if ($RTT_values.count -eq 0) {
            echo "No reply yet. Last record: $last_input"
        } else {
            $GetDate = $(get-date)
            if (($GetDate - $ScrUpdPeriodStart).TotalSeconds -ge $UpdateScreenEvery) {
                $ScrUpdPeriodStart = $GetDate

                $screen = render_all $last_input
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
            }
        }
    }
    end {
        # nothing to do
    }
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

function aprox_num($num) {
    # rounds $num to "enough" decimals
    # see get_enough_decimal_digits for understanding enough
    try {
        return [math]::round($num, (get_enough_decimal_digits $num))
    } catch {
        return "???"
    }
}

filter isNumeric($x) {
    return $x -is [int16]  -or $x -is [int32]  -or $x -is [int64]  `
       -or $x -is [uint16] -or $x -is [uint32] -or $x -is [uint64] `
       -or $x -is [float] -or $x -is [double] -or $x -is [decimal]
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
function series_to_histogram($y_values) {
    # returns an array with the values of the histogram
    $buckets = @(0..$BucketsCount)
    For ($i=0; $i -le $BucketsCount; $i++) { $buckets[$i] = 0 }

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
    if ($y_max -lt ($y_min + $BucketsCount)) {$y_max = $y_min + $BucketsCount}

    $y_values | %{
        $ms = $_
        if ($ms -eq 9999) {
            $buckets[$BucketsCount] += 1  # $buckets[$BucketsCount] counts failures
        } else {
            # line about a reply
            $norm_ms = [math]::min($y_max-1,[math]::max($y_min,$ms))
            [double]$bucket = ($norm_ms-$y_min)/($y_max-$y_min)
            [double]$bucket = [Math]::Floor($bucket*$BucketsCount)
            #echo "$ms => +1 in bucket #$bucket"
            $buckets[$bucket] += 1
        }
    }
    return @($buckets, $y_min, $y_max)
}

function Show_bar_graph($y_values, $title="", $options="", $special_value, `
    $default_y_min, $default_y_max, $theme) {
    # It can display 24 or 25 different heights
    # (25 if you count a zero height that gives an empty bar as an increment,
    #  24 if you count only heights that give a visible line with "???" being the lowest)
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
            #  _0     |v      v????????????????????????
            # |       v????????????????????????????????????????????????
            # v????????????????????????????????????????????????????????????????????????
            # 0123456789012345678901234
            $step = (($Y_max - $Y_min) / $script:BAR_CHR_V_COUNT / 3) # 3 lines
            $quantized = [Math]::Round( ($_ - $Y_min) / $step, 0)
            if ($quantized -gt (3 * $script:BAR_CHR_V_COUNT)) {
                $topline += $col_hi + [char]0x25B2 + $col_base# '???'
                $midline += [char]0x2588 # '???'
                $botline += [char]0x2588 # '???'
            } elseif ($quantized -ge (2 * $script:BAR_CHR_V_COUNT)) {
                $topline += $script:BAR_CHR_V_[$quantized - (2 * $script:BAR_CHR_V_COUNT) ]
                $midline += [char]0x2588 # '???'
                $botline += [char]0x2588 # '???'
            } elseif ($quantized -ge (1 * $script:BAR_CHR_V_COUNT)) {
                $topline += $space
                $midline += $script:BAR_CHR_V_[$quantized - (1 * $script:BAR_CHR_V_COUNT) ]
                $botline += [char]0x2588 # '???'
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

function percent_to_bar($percent, $Chars_for_100perc) {
    # used by show_histogram
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

function show_histogram($y_values) {
    ($buckets, $y_min, $y_max) = (series_to_histogram $y_values)
    # the following fancy line makes sure I buckets divided exactly at integer values
    $y_max = [math]::Ceiling(($y_max - $y_min) / $BucketsCount) * $BucketsCount + $y_min

    #echo "HIST min=$y_min, max=$y_max "

    [double]$perc_cumul = 0
    [double]$max_perc = 0
    For ($i=0; $i -le $BucketsCount; $i++) {
        [double]$percent = [Math]::Round(100 * $buckets[$i] / $y_values.count,1)
        $max_perc = [Math]::max($max_perc, $percent)
    }

    # 28 characters are available
    # if max percent is 0.5 then by setting scale to 28/0.5=56 chars the 50% will fill 28 chars
    $Chars_for_100perc = 28/($max_perc/100)
    For ($i=0; $i -lt $BucketsCount; $i++) {
        [double]$from = $y_min + $i * ($y_max-$y_min)/$BucketsCount
        [double]$to = $y_min + ($i+1) * ($y_max-$y_min)/$BucketsCount
        $count = $buckets[$i]
        [double]$percent = [Math]::Round(100 * $buckets[$i] / $y_values.count,1)
        $perc_cumul = [Math]::min(100, [Math]::Round($perc_cumul + $percent,1))
        $max_perc = [Math]::max($max_perc, $percent)

        if ($i -eq 0) {$from_str="min"; $cumul_str=" Cumul"} else {$from_str="{0,3}" -f $from; $cumul_str=" {0,3}% " -f $perc_cumul}
        if ($i -eq ($BucketsCount - 1)) {$to_str="MAX"} else {$to_str="{0,3}" -f $to}
        $bars = (percent_to_bar $percent  $Chars_for_100perc)
        $spaces = 28-($bars.length)
        $spaces = " " * [math]::max(0,$spaces)
        $bars = "{0}{1}" -f $bars, $spaces
        "{0}...{1} $COL_IMP_LOW{2,4}$COL_RST {3,4}%$COL_IMP_LOW{4,5}$COL_GRAPH{5}$COL_RST" -f $from_str, $to_str, $count, $percent, $cumul_str, $bars
    }
    $failed_perc = $buckets[$BucketsCount] # failures
    [double]$percent = [Math]::Round(100 * $failed_perc / ($y_values.count),1)

    if ($percent -gt 0) {$color = $col_hilite} else {$color = $COL_H1}
    "Failures: {0}{1,4} {2,4}%      {3}{4}" -f $color, $failed_perc, $percent, (percent_to_bar $percent  $Chars_for_100perc), $COL_RST
}

function p95_of_jitter($RTT_values){
    # computes the 95th percentile of the jitter for the RTTs
    write-verbose "RTTs = $($RTT_values -join ',')"
    $prev = $RTT_values | select -first 1
    $jitter = @($RTT_values | select -last ($RTT_values.count -1) | %{
        if (($_ -eq 9999) -or ($prev -eq 9999)) {
            echo 9999
        } else {
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

function render_slow_updating_graphs() {
    # describe the sampling period and the total time we collect samples
    # e.g. per 2' for 14'
    $AggPeriodDescr = "per $([math]::round($AggregationSeconds/60,1))' "+`
        "for $([math]::round($AggregationSeconds*$Variance_values.count/60,1))'"

    # X axis limits
    $MaxItems = $Host.UI.RawUI.WindowSize.Width - 6

    # display $Baseline_values
    #------------------------------
    $values = @($Baseline_values | select -last $MaxItems)
    $stats = (stats_of_series $values)
    if ($GraphMin -ne -1) {$y_min = $GraphMin} else {
        $y_min = (std_num_le $stats.min)
        if ($y_min -lt 10) {$y_min = 0}
    }
    if ($GraphMax -ne -1) {$y_max = $GraphMax} else {$y_max = (y_axis_max $stats.min $stats.max $y_min 9)}    
    $title = "RTT BASELINE(min),  $AggPeriodDescr, min=<min>, p95=<p95>, max=<max>, last=<last> (ms)"
    Show_bar_graph $values $title "<stats><H_grid>" 9999 `
        $y_min $y_max $RTTMIN_BAR_GRAPH_THEME
    echo ""

    # display $Variance_values
    #------------------------------
    $values = @($Variance_values | select -last $MaxItems)
    $stats = (stats_of_series $values)
    $y_min = (std_num_le $stats.min)
    if ($y_min -lt 10) {$y_min = 0}
    $y_max = (y_axis_max $stats.min $stats.max $y_min 10)
    if ($y_max -eq $y_min) {$y_max = (std_num_ge $y_max + 1)}
    $title = "RTT VARIANCE(p95-min), $AggPeriodDescr, min=<min>, max=<max>, last=<last> (ms)"
    Show_bar_graph $values $title "<stats><H_grid>" 9999 `
        $y_min $y_max
    echo ""

    # display the lost% bar graph
    #------------------------------
    $stats = (stats_of_series $Loss_values)
    $y_min = 0
    $y_max = (y_axis_max $stats.min $stats.max 0 4)
    $title = "LOSS%, $AggPeriodDescr, min=<min>%, p95=<p95>%, max=<max>%, last=<last>%"
    Show_bar_graph @($Loss_values | select -last $MaxItems) $title "<stats><H_grid><min_no_color>" 100 `
        $y_min $y_max $LOSS_BAR_GRAPH_THEME
    echo ""

    # display the jitter bar graph
    #------------------------------
    $title = "ONE-WAY JITTER, $AggPeriodDescr, min=<min>, p95=<p95>, max=<max>, last=<last> (ms)"
    $stats = (stats_of_series $Jitter_values)
    $y_min = 0
    $y_max = 30
    if ($stats.max -le 10) {$y_max = 10}
    Show_bar_graph @($Jitter_values | select -last $MaxItems) $title "<stats><H_grid>" $null `
        $y_min $y_max $JITTER_BAR_GRAPH_THEME
}

function render_all($last_input, $PingsPerSec) {
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
    #echo ([string][char]9472*75)
    $title = "LAST RTTs,  $($graph_values.count) pings, min=<min>, p95=<p95>, max=<max>, last=<last> (ms)"
    # decide Y axis limits
    $stats = (stats_of_series ($graph_values | ?{$_ -ne 9999}))
    ($time_graph_abs_min, $p5, $p95, $time_graph_abs_max) = ($stats.min, $stats.p5, $stats.p95, $stats.max)

    $y_min = (std_num_le $stats.min)
    if ($y_min -lt 10) {$y_min = 0}
    $y_max = (y_axis_max $stats.min $stats.max $y_min 9)
    if ($GraphMin -ne -1) {$y_min = $GraphMin}
    if ($GraphMax -ne -1) {$y_max = $GraphMax}
    Show_bar_graph $graph_values "$title"  "<stats><H_grid>" 9999 $y_min $y_max
    echo ""

    # display the histogram
    if ($RTT_values.count) {
        #echo ([string][char]9472*75)
        echo "    ${COL_TITLE}RTT HISTOGRAM, last $HistSamples samples, p95=${COL_H1}${p95}${COL_TITLE}ms$COL_RST"
        show_histogram @($RTT_values | select -last $HistSamples)
        $p95 = [int](stats_of_series $RTT_values).p95
        echo ""
    }

    if ($Variance_values.count) {
        render_slow_updating_graphs
        if (Test-Path variable:script:LOG_FILE) {
            echo "$COL_IMP_LOW     (Saving to $($script:LOG_FILE))"
        }
    }

    if ($DebugMode) {
        #echo "AggPeriodSeconds=$script:AggPeriodSeconds"
        #echo "Variance_values=$Variance_values"
        echo "Jitter_values=$Jitter_values"
        #sleep 0.1
    }
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
        [string]$Destination = "google.com",
        [string]$Title = "",
        [double]$GraphMax = -1,
        [int]$PingsPerSec = 5,
        [double]$GraphMin = -1,
        [int]$BucketsCount=10,
        [int]$AggregationSeconds=120, # 2 mins
        [int]$HistSamples=-1,
        [char]$Visual = '=',
        [int]$DebugMode = 0,
        [int]$HighResFont = -1, # -1=auto

        [double]$UpdateScreenEvery = 1,
        [int]$BarGraphSamples = -1

    )

    $script:HighResFont = $HighResFont 
    try {
        $ts = (get-date -format 'yyyy-MM-dd_HH.mm')
        $script:LOG_FILE="pingtimes.$Destination.$ts.ps1"
        $script:RTT_FILE="$Destination.$ts.pingrec"
        "pingrec-v1,$ts,$PingsPerSec pings/sec,$Destination" > $RTT_FILE
        if (!($Title)) {
            $Title = $Destination
        }
        if ($HistSamples -eq -1) {
            # by default make histogram from 1min samples
            # BUT AT LEAST FROM 100 SAMPLES if 1min has less
            $HistSamples = [math]::max(100, $PingsPerSec * 60)
        }
		
		configure_graph_charset

        $jobs = (
        start-job -ArgumentList $PingsPerSec, $Destination, `
            -ScriptBlock {

                Function Start-SpecialPing {
                    # Allows custom interval with msec accuracy.
                    # Will try hard to send 1000/$Interval pings per second
                    # by adjusting the delay between two consequtive pings.
                    # NOTE that in case of failure, it does not return 0 but
                    # the elapsed time 
                    Param(
                        [string]$ComputerName="8.8.8.8",
                        [int]$TimeOut = 500,
                        [int]$Interval = 50
                    )

                    $ping_count = 0
                    $ts_first_ping = (Get-Date)
                    while ($True) {
                        $ts_start = (Get-Date)
                        # $ts_start.ticks / 10000 milliseconds counter
                        $Ping = [System.Net.NetworkInformation.Ping]::New()
                        $ret = $Ping.Send($ComputerName, $TimeOut)
                        $ts_end = (Get-Date)
                        $ping_count += 1
                        if ($ret.Status -ne 'Success') {
                            $RoundtripTime = [int](($ts_end.ticks - $ts_start.ticks)/10000)
                        } else {
                            $RoundtripTime = $ret.RoundtripTime
                        }

                        if ($ping_count -eq 1) {
                            $total_elapsed_ms = $RoundtripTime
                            $expected_elapsed_ms = 0
                            $diff = $RoundtripTime
                            $ts_first_ping = $ts_start
                        } else {
                            $total_elapsed_ms = [int](($ts_end.ticks - $ts_first_ping.ticks)/10000)
                            $expected_elapsed_ms = [int](($ping_count-1) * $Interval)
                            $diff = $total_elapsed_ms - $expected_elapsed_ms
                        }

                        $sleep_ms = [math]::max(0, $Interval - $diff)
                        # return this:
                        [PSCustomObject]@{RoundtripTime = $RoundtripTime; `
                            Status=$ret.Status.tostring(); `
                            ts_start = $ts_start; `
                            ping_count=$ping_count
                        }
<# this is good for debugging only
        [PSCustomObject]@{RoundtripTime = $RoundtripTime; `
            Status=$ret.Status; `
            ts_start = $ts_start; `
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
                $PingsPerSec = $args[0]
                $Destination = $args[1]
                Start-SpecialPing  -Interval (1000/$PingsPerSec) -TimeOut 500 -ComputerName $Destination
            }
        )            
        
		function Get-ChildProcesses($parent_pid) {
			$children = (Get-WmiObject win32_process -filter "Name!='conhost.exe' AND ParentProcessId=$parent_pid" | select -property name, ProcessId)
			if ($children) {
				return ($children).ProcessId
			}
		}

        echo "Finding children..."
        # Every job we start starts a powershell.exe process 
        # Each of them starts a conhost.exe
        # These are the pids of all powershell.exe processes:		
        $children_PS_pids = @()
        $children_PS_pids += (Get-WmiObject win32_process -filter "Name='powershell.exe' AND ParentProcessId=$PID"`
            | select -property ProcessId).ProcessId
        echo "    $children_PS_pids"
        # $children_PS_pids | %{ Show-Processes $_ } 
        echo "Waiting for $($children_PS_pids.count) sec..."
        echo "Finding grand children except conhost.exe if any..."
        $grand_children = @()
        $children_PS_pids | %{ $grand_children += (Get-ChildProcesses $_) }
        echo "    $grand_children"
        # $grand_children | %{ Show-Processes $_ } 
        
        # MAIN LOOP
        #--------------------------------------
        # We collect the output of the ping-jobs (see above)
        # and pipe it to Format-PingTimes
        & {while ($true) {
            # Test-Connection $Destination -ping -Continuous
            $data = $null
            while (!($data)) {
                sleep 1 # with 0.5 or less it overwhelms one CPU core...(???)
                if (($jobs | get-job).HasMoreData) {
                    $data = ($jobs| receive-job)
                }
            }
            $data
        }} | Format-PingTimes `
                -Destination $Destination `
                -UpdateScreenEvery $UpdateScreenEvery -Title $Title -GraphMax $GraphMax `
                -GraphMin $GraphMin -BucketsCount $BucketsCount `
                -AggregationSeconds $AggregationSeconds -HistSamples $HistSamples `
                -DebugMode $DebugMode -BarGraphSamples $BarGraphSamples `
                -HighResFont $script:HighResFont
    }
    finally { # when done
        # AFTER A CTRL-C
        #-----------------------------------
        if ($jobs) {
            write-host  -foregroundcolor white -backgroundcolor black "Cleaning up..."
			$discarded_count = 0
            try {
                $discarded_count = [array]($jobs| receive-job)
				if ($discarded_count) {
					$discarded_count = $discarded_count.count
				}
            } catch {
				Write-Host "Failed to retrieve output from background pings, $($error[0])"
            }
            Write-Host  "Stoping background pings $($grand_children)..."
			# $grand_children | stop-process -force
			# write-host "taskkill.exe /F /PID $($grand_children -join ' /PID ')"
			if ($grand_children) {
				# this will taskkill all ping.exe
				iex "taskkill.exe /T /F /PID $($grand_children -join ' /PID ')" > $null
			} 
            Write-Host  "Removing jobs..."
			Remove-Job $jobs -Force
            write-host -foregroundcolor white -backgroundcolor black "Discarded $discarded_count pings."
        }
    }
}

Out-PingStats @args
