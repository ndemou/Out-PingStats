# Out-PingStats

A PowerShell program to evaluate LAN or Internet quality. It displays plenty of text and pseudo graphical statistics about the short and long-term quality of your connection. By default it performs DNS queries to many free DNS servers and aggregates the response times (RTT) in a smart way. This is useful to test your Internet quality. If you want to test your ethernet/WIFI network quality you can specify a host that responds to pings. it will present the same quality metrics but this time for the ping RTTs.

## For the impatient

To just test your internet connection (pings google.com):

    powershell -exec bypass -c ". {iwr -useb https://raw.githubusercontent.com/ndemou/Out-PingStats/main/Out-PingStats.ps1}|iex"
    
To download and run with specific options for your case:
    
    powershell -exec bypass -c ". {cd '$Env:USERPROFILE'; iwr -useb https://raw.githubusercontent.com/ndemou/Out-PingStats/main/Out-PingStats.ps1 -OutFile Out-PingStats.ps1}"
    powershell -exec bypass -c "cd '$Env:USERPROFILE'; .\Out-PingStats.ps1 -PingsPerSec 4 10.1.1.1"

## How to use
    Out-PingStats   # To test Internet quality 
    Out-PingStats -PingsPerSec 4 10.1.1.1 # To test WIFI/ethernet connection quality to host 10.1.1.1

## Example output 
![image](https://user-images.githubusercontent.com/4411400/208316162-c115a6c9-eca6-49d6-94d8-b90c9b6f2628.png)

## Understanding the graphs

The **LAST RTTs** graph at the top shows one bar for every ping/DNS query.
It's a bit better than looking at the text output of the ping command.
Timeouts/lost packets will appear as a bar of red stars: 

![image](https://user-images.githubusercontent.com/4411400/204651924-730d2144-0dbf-41b8-a825-8e53f8072165.png)

The **RTT HISTOGRAM** includes the most recent few hundred pings.
If you don't know what a histogram is [wikipedia is your friend](https://en.wikipedia.org/wiki/Histogram).
You will need some experience with it to get a feeling of what is normal and what is not.
Take a look at the examples below for a quick start.

### Slow updating graphs

All graphs except LAST RTTs and HISTOGRAM are **slow updating graphs**. 
Each bar in them represents some **indicator of network quality** that is computed 
for a fixed *period* of several seconds. 
The *period* is 2mins by default and can be changed with `-AggregationSeconds`.
In the x-axis you also get a tick every 10 periods (=20mins by default).

> **For all these indicators the lower the better**

**RTT BASELINE** displays the minimum RTT and **RTT VARIANCE** 
displays the difference `p95 - min` for the period. 
In simple words, almost all of your pings had an RTT between *BASELINE*
and *BASELINE plus VARIANCE*. Read below for a more accurate 
description of p95.

**LOSS%** is exactly what you guess, and **ONE-WAY JITTER** is an aproximation of the one-way jittet. 
We just divide the two-way jitter by two assuming that any delays are symetrical.

#### Regarding p95

`p95` is the 95th percentile of RTTs. 
For the many of us without a statistics degree, if `p95` equals 50msec then 95% 
of pings had an RTT<=50msec. 
Put another way only 5% of pings had RTTs worse than 50msec.
We use the 95th percentile as a good aproximation of bad RTT times that
we have to deal with **most** of the time. In other words we consider 
these 5% of values that were worse than the `p95` as "outliers" that 
we can safely ignore. This is usualy a good idea because
it's common to have spourious extreme RTT times.

## Regarding the terminal font

If your terminal font contains unicode block characters (▁▂▃▄▅▆▇█)
then you can add the `-HighResFont $true` option to get
 preatier and more detailed graphs.
"Courier" and "Consolas" do not include them, "DejaVu sans mono" does.

If you don't force high or low resolution by using the `-HighResFont $true/$false` option 
the code will *try* to detect the font and decide whether to use the unicode block characters.
It will display this warning if it thinks it can not.
![image](https://user-images.githubusercontent.com/4411400/208317605-721dafc4-06fb-4dd1-86ae-5c264fe08a0d.png)

If you are seeing low-resolution graphs, you can download the free and very nice "DejaVu sans mono" fonts,
install them (by double clicking on the ttf file and clicking install) 
and then configute your PowerShell terminal to use it.

## Example: Histogram of a not so good wifi connection

![image](https://user-images.githubusercontent.com/4411400/204652000-c71b4ccd-2cda-4458-a846-f122332446b0.png)

## Example: Histogram of a good wifi connection

![image](https://user-images.githubusercontent.com/4411400/204652036-79f1b56c-1866-4508-b6af-0e8beddc1e5a.png)

# Parameters
    -PingsPerSec

Pings per second to perform.

In DNS query mode (the default if you don't specify a host) you can only select 1 (the default) or 2.

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

# Other details

## Parallel pings/smart aggreagation

When checking internet quality this script tries hard to be resilient to problems that are specific to a specific DNS server. To that end it will run more than 5 DNS query jobs in parallel. Each job queries 4 different hosts one after the other every second. If at least one reply is received we consider it a success. If more than one replies comes through we take into acount only the minimum RTT. Also we use a smart algorithm to "normalize" the RTTs of various servers so that we don't see jitter due to the differences between the RTTs of the different servers. 

## Saved statistics

The script records every ping response to a text file named like:
`google.com.2022-12-16_19.01.21.pingtimes.
First line is 

    pingrec-v1,2022-05-12,5 pings/sec,google.com

Then we have one line per minute starting with the timestamp `hhmm:`
Finaly one char per ping follows. The char is `[char](ttl+32)`
(e.g. "A" for 33msec, "B" for 34msec...)
