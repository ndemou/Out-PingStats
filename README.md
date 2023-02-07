## What is it?

Out-PingStats displays nice, detailed and easy to understand graphs 
that help you assess the short and long-term quality of your 
uplink to the internet (or your connection to a specific host) 
with a quick glance at the screen. Oh! and all that without 
leaving your PowerShell terminal 🙂

![image](https://user-images.githubusercontent.com/4411400/208316162-c115a6c9-eca6-49d6-94d8-b90c9b6f2628.png)

## Why would you want to use it? 

#### You want to evaluate the quality of a connection for minutes or hours 

Out-PingStats can easily and **nicely** display a few hours worth of data in one screen.

#### You want to evaluate the uplink quality of a large network

In such cases one will typically `ping google.com`
but some times google.com will throttle incoming packets and 
this will appear as packet loss in your pings. 
Out-PingStats is immune to this problem.
<details>
  <summary>More info</summary>
  
  Out-PingStats pings 
  more than a dozen different hosts in parallel and implements a smart
  algorithm to combine the different response times in one meaningful value.
  If you see packet loss or the RTT jumping up then you know it's 
  because of a real problem in your uplink and not because google.com
  or whatever is throttling your pings.

  This is not a minor issue: 
  I have, in many cases, seen packet loss of 3% to 5% 
  and some times even more.
  My assumption is that in a LAN with many devices
  there's greater chance that enough of them will happen to "hammer"
  the host you ping.
</details>

#### You love your PowerShell but prefer graphs over a long list of numbers

Sorry robots, this is for humans :-)

### TLDR How to try it out

#### Step 1. Install depedencies 

    # Run this from an admin PowerShell
    Install-Module -Name ThreadJob 
    
#### Step 2. Try it out

   1. Quick'n'dirty test of your internet connection:

           powershell -exec bypass -c ". {iwr -useb https://raw.githubusercontent.com/ndemou/Out-PingStats/main/Out-PingStats.ps1}|iex"
    
   2. Quick'n'dirty test of the connection to a specific host in your LAN:
    
           powershell -exec bypass -c ". {cd '$Env:USERPROFILE'; iwr -useb https://raw.githubusercontent.com/ndemou/Out-PingStats/main/Out-PingStats.ps1 -OutFile Out-PingStats.ps1}"
           powershell -exec bypass -c "cd '$Env:USERPROFILE'; .\Out-PingStats.ps1 -PingsPerSec 4 $(read-host 'Enter IP to ping')"

Your graphs will be nice but probably not "high quality". Read below about selecting a font that will display perfect graphs.

### How to use

    # To test Internet quality 
    Out-PingStats   
    
    # To test network connection to 10.1.1.1 by pinging at 4 pings per second:
    Out-PingStats -PingsPerSec 4 10.1.1.1 

If you want to evaluate your connection to a specific host (e.g. when you want to test your ethernet/WIFI quality) you specify the host with `-Target` and maybe also set a higher ping rate (with `-PingsPerSec`). In this case Out-PingStats will obviously only ping the host you specified.

### Understanding the graphs

The **LAST RTTs** graph at the top shows one bar for every ping/DNS query.
It's a bit better than looking at the text output of the ping command.
Timeouts/lost packets will appear as a bar of red stars: 

![image](https://user-images.githubusercontent.com/4411400/204651924-730d2144-0dbf-41b8-a825-8e53f8072165.png)

The **RTT HISTOGRAM** includes the most recent few hundred pings.
If you don't know what a histogram is take a look at [wikipedia](https://en.wikipedia.org/wiki/Histogram), it's a very interesting way of representing a group of measurements.
In any case you will need some experience with this graph to get a feeling of what is *normal* and what is not but I think it worths the small effort.
Take a look at the examples below for a quick start.

#### Slow updating graphs

All graphs except LAST RTTs and HISTOGRAM are **slow updating graphs**. 
Each bar in them represents some **indicator of network quality** that is computed 
for a fixed *period* of several seconds. 
The *period* is by default 2 minutes but can be changed with `-AggregationSeconds`.
In the x-axis you get a tick every 10 periods (so 20 mins by default).

> **For all these graphs the lower the better**

**RTT BASELINE** displays the minimum RTT and **RTT VARIANCE** 
displays the difference `almost_max - min` for the period. 
`Almost_max` is in fact is the 95th percentile (`p95`) of RTTs. 
In simple words, none of the pings had an `RTT < BASELINE`, for 95% of them we had `BASELINE < RTT <
BASELINE + VARIANCE` and for 5% of them we had `RTT > BASELINE + VARIANCE`. 

We use the 95th percentile instead of the maximum as a better indicator of bad RTT times that
we have to deal with **most** of the time. 
This proves to be very handy because spurious high RTTs are very common and may appear all over the place.
E.g. you may have 199 pings below 20msec and one at 500msec or 900msec. 
This outlier would completely ruin your plot and provides almost no information on the quality of the line.

**LOSS%** is exactly what you guess, and **ONE-WAY JITTER** is an aproximation of the one-way jitter 
(we just divide the two-way jitter by 2, assuming that any delays are symetrical). 
The jitter graph will not show jitter over 30msec because that's the limit for VoIP that doesn't suck :-)

### Regarding the terminal font

If your terminal font contains unicode block characters (like these: ▁▂▃▄▅▆▇█)
then you can add the `-HighResFont $true` option to get
 preatier and more detailed graphs. 
Paste the above characters to your terminal to check.
"Courier" and "Consolas" do not include them, "DejaVu sans mono" does.

If you don't force high or low resolution by using the `-HighResFont $true/$false` option 
the code will *try* to detect the font and decide whether to use the unicode block characters.
It will display this warning if it thinks it can not.
![image](https://user-images.githubusercontent.com/4411400/208317605-721dafc4-06fb-4dd1-86ae-5c264fe08a0d.png)

If you are seeing low-resolution graphs, you can download the free and very nice "DejaVu sans mono" font,
install it by double-clicking on the ttf file and clicking install, 
and then configure your PowerShell terminal to use it.

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
(e.g. `A` for 31msec, `B` for 32msec, etc)

### Histogram examples

#### Histogram of a not so good wifi connection

![image](https://user-images.githubusercontent.com/4411400/204652000-c71b4ccd-2cda-4458-a846-f122332446b0.png)

#### Histogram of a good wifi connection

![image](https://user-images.githubusercontent.com/4411400/204652036-79f1b56c-1866-4508-b6af-0e8beddc1e5a.png)

## Parameters
    -PingsPerSec

Pings per second to perform.
In the default mode of operation (if you don't specify a hostn with `-target`) you can only select 1 (the default) or 2.

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
To that end it will run a lot of DNS query and ping jobs in parallel. Each job queries a different DNS server or pings a different host every second.
It has 4 sets of hosts to switch between so that each host will see a ping/query every 4 seconds (or 2 seconds if you specify `-PingsPerSec 2`). 
This way we minimize the chances of our pings getting throttled. 
If at least two replies are received at a specific second we consider it a success and we **only** take the minimum RTT into acount. 
We also use a smart algorithm to "normalize" the RTTs of different servers so that we don't see jitter due to the differences between the RTTs of the different servers. 

#### About the algorithm for RTT Normalization 

When we are reading RTTs from one and then another host with different average times 
it will appear as though there is jitter. To minimize this effect we use
this method:

  1) We keep the last 10 or 20 successfull RTTs from each host.
  2) Calculate the min of all these RTTs.
  3) Calculate the *average of all minimums*.
  4) Adjust the real RTT values by moving them towards the 
*average of all minimums* by as many msec as their min is away from
the average min. 

Example: 

Say that during the last 10 pings the min RTT of 3 hosts are like this:

                <----Last 10 RTTs----------->  Min Avg Avg-Min
      - host1 : 40 42 50 45 41 40 42 50 45 41 : 40 50   10
      - host2 : 63 63 60 66 62 61 63 61 66 62 : 60 50  -10
      - host3 : 51 51 50 54 50 52 51 53 54 50 : 50 50    0

(The value "Avg" above is the average of the three minimums -- 50 = (40+50+60)/3)

Assuming that the minimums where the same before, then the Effective 
RTTs will be calculated like this:

     - host1 : 50 52 60 55 51 50 52 60 55 51 
     - host2 : 53 53 50 56 52 51 53 51 56 52 
     - host3 : 51 51 50 54 50 52 51 53 54 50 
       
Note that since we adjust the real RTTs by an amount that depends 
on a *slow* changing average (the average of the minimum of the last *N* RTTs) 
their variability is only slightly affected by the tiny amount of fluctuation 
that the average is experiencing.
Note also that MultiPings is reporting to main code just one RTT value
from the 3 hosts (the min RTT). Then the main code calculates the jitter 
based on this artificial/agregate RTT value. I _think_ that this 
is better than taking the jitter for every host. Especially for MultiDnsQueries
code I have seen that every few seconds I get a sporadic slow reply from every DNS
server. This will register as two strong jitter measurements but it's more
plausible that this slow reply is due to the DNS application rather than due 
to the network (DNS is not as simple as ping). By keeping just the min(RTT) of all
parallel DNS queries we mostly suppress such sporadic spikes. 

## Note for non European users

There's a list of IPs that are Europe centric in the code. Not all of them but many. 
You may wish to change them to match your continent.
