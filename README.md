## What is it?

Out-PingStats is a PowerShell script that displays detailed and easy-to-understand graphs to help you assess the short- and long-term quality of your internet uplink or connection to a specific host. You can use it without leaving your terminal.

## Example
![image](https://github.com/ndemou/Out-PingStats/assets/4411400/893ffc8e-80e3-4361-848e-f31ef6c36327)

Wondering how close to ethernet performance your Wi-Fi can give? Run Out-PingStats, spend plenty of minutes with both and enjoy the results:

![image](https://user-images.githubusercontent.com/4411400/226208489-cbed48f5-181f-4579-90b0-5d50e768720a.png)

On the left terminal we are pinging our gateway. Initially via ethernet and then via Wi-Fi. 

At the same time on the right terminal we've let Out-PingStats evaluate our uplink. 

Seeing the output it is obvious that your Wi-Fi isn't good for VoIP or gaming. 

## Why would you want to use it? 

#### You want a high certainty evaluation of your connection to the Internet 

To evaluate the uplink quality you may `ping google.com` or some other well known host. However, any specific host, even a robust one like google.com, may experience issues or may throttle your packets. Out-PingStats is immune to problems of specific hosts because it pings 4 well known hosts in parallel. If you see packet loss or bad response times, you can be pretty certain that it's because of a problem in either your infrastructure or your ISP.

#### You want to visually evaluate the quality of a connection for many minutes or hours 

Out-PingStats can nicely display several hours' worth of data in one screen, making it easy to assess the long term quality of a connection. It also saves its screen every 2 minutes in your `%TEMP%` folder so that you don't loose the results even if you accidentaly close its window. Check the saved screens with `ls $env:TEMP\ops*.screen` and view any of them with `cat ops.2023-05-14_15.34.46.screen`. Simple and helpful :-)

![image](https://github.com/ndemou/Out-PingStats/assets/4411400/08671c38-29ce-4fe3-afe7-56a3ccd2c2b5)

#### You love your shell, but also prefer graphs to long lists of numbers.

Well then, Out-PingStats is for you!

### TLDR How to try it out

#### Step 1. Download 

    cd $Env:USERPROFILE
    iwr -useb https://raw.githubusercontent.com/ndemou/Out-PingStats/main/Out-PingStats.ps1 -OutFile Out-PingStats.ps1

#### Step 2. Run

   1. Quick'n'dirty test of your internet connection:

           cd $Env:USERPROFILE
           powershell -exec bypass -c ".\Out-PingStats.ps1"
    
   3. Quick'n'dirty test of the connection to a specific host in your LAN:

           cd $Env:USERPROFILE
           powershell -exec bypass -c ".\Out-PingStats.ps1 10.1.1.1"

You will get good enough graphs without configuring anything but they
will probably not be the highest quality possible. 
Read below about selecting a font that will display the best graphs possible.

### How to use

    # To test Internet quality 
    Out-PingStats   
    
    # To test network connection to 10.1.1.1
    Out-PingStats 10.1.1.1 

    # To test network connection to 10.1.1.1 by pinging at 20 pings per second:
    Out-PingStats -PingsPerSec 20 10.1.1.1 

If you want to evaluate your connection to a specific host 
(e.g. when you want to test your ethernet/WIFI quality)
you specify the host with `-Target` and maybe also set 
a higher ping rate (with `-PingsPerSec`). 
In this case Out-PingStats will obviously only ping the host you specified.

### Understanding the graphs

The **LAST RTTs** graph at the top shows one bar for every ping/DNS query.
It's a bit better than looking at the raw output of `ping.exe`.
Timeouts/lost packets will appear as a bar of red stars: 

![image](https://user-images.githubusercontent.com/4411400/204651924-730d2144-0dbf-41b8-a825-8e53f8072165.png)

The **RTT HISTOGRAM** includes the most recent few hundred pings.
If you don't know what a histogram is take a look at [wikipedia](https://en.wikipedia.org/wiki/Histogram), 
it's a very interesting way of representing a group of measurements.
In any case you will need some experience with this graph to get a feeling 
of what is *normal* and what is not but I think it worths the time spent.
Take a look at the examples below for a quick start.

#### Slow updating graphs

All graphs below the HISTOGRAM are **slow updating graphs**. 
Each bar represents some **indicator of network quality** that is computed 
for a fixed *period* of several seconds. We get all the RTTs of that period
and we aggregate them to one value.
The *period* is by default 2 minutes but can be changed with `-AggregationSeconds`.
In the x-axis you get a tick every 10 periods (so 20 mins by default).

> **For all graphs the lower the better**

**RTT 95th PERCENTILE** `= AlmostMax(RTT)` for the period. Almost Max is the 95th percentile (`p95`) of RTTs. In simple words, during a period, 95% of RTTs were less or equal to this value. (See bellow for more info).

**LOSS%** is the percent of lost pings during the period.

**ONE-WAY JITTER** is half the two-way jitter. 
(we thus aproximate the one-way jitter by assuming that any delays are symetrical). 
The jitter graph will not show jitter over 30msec because that's the limit for VoIP that doesn't suck :-)

We use the 95th percentile instead of the maximum as a better indicator of bad RTT times that
we have to deal with **most** of the time. 
This is usualy (but not always) a good approximation of our feeling of a line. 
You may, for example, have 119 pings below 20msec and one at 820msec during a 2 minute period. 
If ploted, that 820msec outlier,  will skew the scale of your plot extremely while, at the same time provide 
little information on the quality of the line during that 2min period.
As a counter example gamers may care about the real max because even 1 or 2 cases of a really bad RTT 
at the wrong time may be quite noticable.

I confess, that **the selection of the 95th percentile is rather arbitrary and more 
a result of intuition & *taste* than of investigation or knowledge** on the subject.

### Regarding the terminal font

If your terminal font contains unicode block characters (like these: ▁▂▃▄▅▆▇█)
then you can add the `-HighResFont $true` option to get
 preatier and more detailed graphs. If you try the option and you get characters like these: ![image](https://user-images.githubusercontent.com/4411400/218545287-b2d6482d-50d6-47d2-a058-c67f5f07ff38.png)
then the font of your terminal is not containing unicode block characters.
Paste the above characters to your terminal to check.
"Courier" and "Consolas" do not include them, "DejaVu sans mono" does.

If you don't force high or low resolution by using the `-HighResFont $true/$false` option 
the code will *try* to detect the font and decide whether to use the unicode block characters.
It will display this warning if it thinks it can not.
![image](https://user-images.githubusercontent.com/4411400/208317605-721dafc4-06fb-4dd1-86ae-5c264fe08a0d.png)

If you are seeing low-resolution graphs the quick solution is this:
   1. [download the zip file for the free "DejaVu sans mono" font](https://dejavu-fonts.github.io/Download.html).
   1. Open the zip file.
   1. Double-click the file `DejaVuSansMono.ttf`  (inside the `ttf` folder).
   1. Click install.
   1. [Configure your PowerShell terminal](https://www.get-itsolutions.com/windows-terminal-change-font/) to use the newly installed font.
   1. Add the `-HighResFont $true` argument if you still don't get nice bars.

### Other features

#### Periodic screen dump to a file

Every time Out-PingStats updates the slow graphs, it dumps the screen to a file
named  `ops.<START-TIME>.screen` inside your %TEMP%
folder.  So if after closing the program you want to view its last output
you only have to `cat` this file.

#### Saved RTT measurements

Out-PingStats also records every RTT time measured to a text file named 
`ops.<START-TIME>.pingrec` in your %TEMP% folder. The file has one line per 
minute starting with the timestamp `hhmm:`. After the timestamp follows one
character per measurement. The character is `[char]($RTT+34)`
(e.g. `A` for 31msec, `B` for 32msec, etc). For lost pings you get an `!` instead.

## Parameters
    -PingsPerSec

Pings per second to perform.
In the default mode of operation (if you don't specify a host with `-target`) you can only select 1 (the default) or 2.

Note that if you set this **too** high (e.g much more than 10) there are 2 gotchas:

A) Code that renders the screen is rather slow and ping replies will pile up
  (when you stop the program, take a note of "Discarded N pings" message.
  If N is more than two times your PingsPerSec you've hit this gotcha)

B) The destination host will drop some of your ICMP echo requests(pings)

For Internet hosts don't go higher than 1. In a LAN 5 is fine.

    -Title "My pings"   (by default the host you ping)
    -GraphMax 50 -GraphMin 5    (by default they adjust automatically)
    -AggregationSeconds 120    (the default)
    -BucketsCount 10    (the default)
    -UpdateScreenEvery 1    (the default)
    -HistSamples 100    (the default)
    -BarGraphSamples 20    (by default fills screen width) 
    -HighResFont $true   (read above Re: fonts)

## Other details

### Parallel pings/smart aggregation

When checking internet quality this script tries hard to be resilient to problems of specific hosts. 
To that end it will run 4 ping jobs in parallel pinging 1.1.1.1, 1.1.2.2, 8.8.8.8, and 8.8.4.4.
If at least one reply is received at a specific second we 
consider it a success and we **only** take the minimum RTT into acount. 
We also use a smart algorithm to "normalize" the RTTs of different 
servers so that we don't see jitter due to the differences between 
the RTTs of the different servers. 

#### About the algorithm for RTT Normalization 

At times when we are reading the RTT from one and then from another host with different average times 
it will appear as though there is jitter. To minimize this effect we use
this method:

  1) Keep a record of the last N successfull RTTs from each host.
  2) Calculate the min of all these RTTs.
  3) Calculate a *baseline* value that follows the *minimum of all these minimums* **slowly** 
(we increment or decrement it by 1 or 2 msec per sample except if its difference to the real value grows too much in which case we make one big jump). 
  4) Adjust the real RTT values by moving them towards the 
*baseline* by as many msec as their min is away from
the average min. 

Note that since we adjust the real RTTs by an amount that depends 
on a *slow* changing value their variability/jitter is only slightly affected.
Note also that MultiPings is reporting to main code just one RTT value
from all hosts (the min RTT). Then the main code calculates the jitter 
based on this artificial/agregate RTT value. I _think_ that this 
is better than taking the jitter for every host. 

## Examples of Graphs

### Histogram of a not so good wifi connection

![image](https://github.com/ndemou/Out-PingStats/assets/4411400/9aa40240-1bca-4dc9-9ed1-3918ed791e9e)

### Histogram of a better wifi connection

![image](https://user-images.githubusercontent.com/4411400/204652036-79f1b56c-1866-4508-b6af-0e8beddc1e5a.png)

### Histogram of a very good wifi connection

![image](https://github.com/ndemou/Out-PingStats/assets/4411400/b81b872b-0981-4baa-93a3-22ceddec64e2)

### Long term behaviour of a 4G connection

![image](https://github.com/ndemou/Out-PingStats/assets/4411400/08671c38-29ce-4fe3-afe7-56a3ccd2c2b5)
