# Out-PingStats

A PowerShell program to evaluate the quality of your connection to the Internet (default behaviour) or to a specific host. 
Out-PingStats displays nice & detailed terminal graphs that help you assess the short and long-term quality of your connection. 

![image](https://user-images.githubusercontent.com/4411400/208316162-c115a6c9-eca6-49d6-94d8-b90c9b6f2628.png)

This program is good if:

 * You want to glance at the screen and have a clear idea of what happens (instead of having to interpret streams of numbers from ping)
 * You want to evaluate the quality of a connection for more than a few dozen seconds.
 * You want to evaluate the Internet quality of a busy network with many devices.

When evaluating for minutes or hours, Out-PingStats will aggregate measurements without losing important details so that it can easily display a few hours of data in one screen.

When evaluating the Internet quality of a busy network you will typically ping some well known host like google.com, 1.1.1.1 etc. 
However some times you may see sporadic packet loss on an otherwise perfectly working line. 
I guess that all these hosts have to throttle incoming packets. Thus when many devices behind the same public IP are hitting them hard with DNS queries or pings they will drop some packets. 
I have seen 3%, 5% and some times even more packet loss to well known hosts when at the same time I had zero loss to the ISP gateway and Internet servers that I own.
Out-PingStats is immune to such problems because it queries/pings more than a dozen different hosts in parallel and smartly aggregates the response times.

## For the impatient

### Step 1. Install depedencies 

    Install-Module -Name ThreadJob # Run from an elevated PowerShell
    
### Step 2. Try it out

   1. Quick'n'dirty test of your internet connection:

           powershell -exec bypass -c ". {iwr -useb https://raw.githubusercontent.com/ndemou/Out-PingStats/main/Out-PingStats.ps1}|iex"
    
   2. Quick'n'dirty test of the connection to a specific host in your LAN:
    
           powershell -exec bypass -c ". {cd '$Env:USERPROFILE'; iwr -useb https://raw.githubusercontent.com/ndemou/Out-PingStats/main/Out-PingStats.ps1 -OutFile Out-PingStats.ps1}"
           powershell -exec bypass -c "cd '$Env:USERPROFILE'; .\Out-PingStats.ps1 -PingsPerSec 4 $(read-host 'Enter IP to ping')"

## How to use

    # To test Internet quality 
    Out-PingStats   
    
    # To test network connection to 10.1.1.1 by pinging at 4 pings per second:
    Out-PingStats -PingsPerSec 4 10.1.1.1 

If you want to evaluate your connection to a specific host (e.g. when you want to test your ethernet/WIFI quality) you specify the host with `-Target` and maybe also set a higher ping rate (with `-PingsPerSec`). In this case Out-PingStats will obviously only ping the host you specified.

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
In simple words, none of the pings had an RTT less than *BASELINE*, and 95% of them had an RTT between *BASELINE*
and *BASELINE plus VARIANCE*. Read below for a more detailed
description of p95.

**LOSS%** is exactly what you guess, and **ONE-WAY JITTER** is an aproximation of the one-way jitter 
(we just divide the two-way jitter by 2, assuming that any delays are symetrical). 
The jitter graph will not show jitter over 30msec because that's the limit for VoIP that doesn't suck :-)

#### Regarding p95

`p95` is the 95th percentile of RTTs. 
For the many of us without a statistics degree, if `p95` equals 50msec then 95% 
of pings had an RTT<=50msec. 
Put another way only 5% of pings had RTTs worse than 50msec.
We use the 95th percentile as a good aproximation of bad RTT times that
we have to deal with **most** of the time. In other words we consider 
these 5% of values that were larger than the `p95` as "outliers" that 
we can safely ignore. 

## Regarding the terminal font

If your terminal font contains unicode block characters (like these: ▁▂▃▄▅▆▇█)
then you can add the `-HighResFont $true` option to get
 preatier and more detailed graphs. 
Paste the above characters to your terminal to check.
"Courier" and "Consolas" do not include them, "DejaVu sans mono" does.

If you don't force high or low resolution by using the `-HighResFont $true/$false` option 
the code will *try* to detect the font and decide whether to use the unicode block characters.
It will display this warning if it thinks it can not.
![image](https://user-images.githubusercontent.com/4411400/208317605-721dafc4-06fb-4dd1-86ae-5c264fe08a0d.png)

If you are seeing low-resolution graphs, you can download the free and very nice "DejaVu sans mono" fonts,
install them (by double clicking on the ttf file and clicking install) 
and then configute your PowerShell terminal to use it.

## Histogram examples

### Histogram of a not so good wifi connection

![image](https://user-images.githubusercontent.com/4411400/204652000-c71b4ccd-2cda-4458-a846-f122332446b0.png)

### Histogram of a good wifi connection

![image](https://user-images.githubusercontent.com/4411400/204652036-79f1b56c-1866-4508-b6af-0e8beddc1e5a.png)

# Parameters
    -PingsPerSec

Pings per second to perform.
In the default mode of operation (if you don't specify a host) you can only select 1 (the default) or 2.

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

## Parallel pings/smart aggregation

When checking internet quality this script tries hard to be resilient to problems of specific hosts. 
To that end it will run a lot of DNS query and ping jobs in parallel. Each job queries a different DNS server or pings a different host every second.
It has 4 sets of hosts to switch between so that each host will see a ping/query every 4 seconds (or 2 seconds of you specify `-PingsPerSec 2`). 
This way, it will not overload any one of them and thus it will not be throttled by anyone. 
If at least two replies are received at a specific second we consider it a success and we **only** take the minimum RTT into acount. 
We also use a smart algorithm to "normalize" the RTTs of different servers so that we don't see jitter due to the differences between the RTTs of the different servers. 

### About the algorithm for RTT Normalization 

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

## Saved statistics

The script records every ping response to a text file named like:
`google.com.2022-12-16_19.01.21.pingtimes.
First line is 

     pingrec-v1,2022-05-12,5 pings/sec,google.com

Then we have one line per minute starting with the timestamp `hhmm:`
Finaly one char per ping follows. The char is `[char](ttl+32)`
(e.g. "A" for 33msec, "B" for 34msec...)

## Note for non European users

There's a list of IPs that are Europe centric in the code. Not all of them but many. 
You may wish to change them to match your continent.
