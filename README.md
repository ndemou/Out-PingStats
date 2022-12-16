# Out-PingStats

A PowerShell program to ping a host and display plenty of text and pseudo graphical statistics about the short and long-term quality of the connection

## For the impatient

To just test your internet connection (pings google.com):

    powershell -exec bypass -c ". {iwr -useb https://raw.githubusercontent.com/ndemou/Out-PingStats/main/Out-PingStats.ps1}|iex"
    
To download and run with specific options for your case:
    
    powershell -exec bypass -c ". {iwr -useb https://raw.githubusercontent.com/ndemou/Out-PingStats/main/Out-PingStats.ps1 -OutFile c:\temp\Out-PingStats.ps1}"
    Out-PingStats -PingsPerSec 2 www.somehost.com
    
## How to use
    Out-PingStats   # by default it pings google.com at 5 pings per sec
    Out-PingStats www.somehost.com 

## Example output and how to make the most out of it 
![image](https://user-images.githubusercontent.com/4411400/204651704-cc6d6e56-81a7-43aa-b82e-6adec8f1a26e.png)

(If you read the output of the program carefully most of what I am explaining below is redundant)

The top graph shows one bar for every ping.
So this is good for a realtime assessment of network quality.

The second graph is a Histogram of the most recent few hundred pings.
You need some experience with it to get a feeling of what is normal and what is not.
Take a look at the examples below for a quick start.

The bottom three graphs give long term view of the network quality. 
Every bar represents a measurement for a 2 minutes period. 
For every 10 periods (20mins) you also see a tick on the x-axis.

The third graph plots the 95th percentile of the RTT of all pings in that period.
I have chosen the 95th percentile because it is more sensitive to shorter periods of bad ping times. 
So if you see 50msec you know that almost all pings had an RTT less than 50msec.

The 4th graph plots the packet loss in that period.

The 5th graph plots an approximation of the 95th percentile of one way jitter in that period.
Specifically we measure the two way jitter and we assume that it is evenly split.


In the above screenshot we see:
   1.   Basic statistics about the whole time
   1.   The value at this point exceeded the graph max (70ms in this example)
   1.   You can see a period of not so good ping times
   1.   During a period of 2' you had a small packet loss
   1.   The packet loss was 0.333% as you can see in the graph statistics 

In the top, real time graph, Lost packets will appear as a bar of red stars: 

![image](https://user-images.githubusercontent.com/4411400/204651924-730d2144-0dbf-41b8-a825-8e53f8072165.png)

In this example, in the the real time graph, we see 114 pings with p5=18msec and p95=61msec. p5 and p95 stand for 5th and 95th percentile. So 5% of the 114 pings were <=18msec and 95% were <=61msec.

## Important: You need a monospace font containing the unicode block characters.

I think that Windows 11/Powershell 7, have proper fonts by default. 
In windows 10 you must download DejaVu sans mono 
(or other fonts that contain unicode block characters), 
install them (double click and click install on the downloaded ttf file), 
and finaly configute your PowerShell terminal to use the new font.

## Example: Histogram of some not so good wifi connection

![image](https://user-images.githubusercontent.com/4411400/204652000-c71b4ccd-2cda-4458-a846-f122332446b0.png)

## Example: Histogram of a good wifi connection

![image](https://user-images.githubusercontent.com/4411400/204652036-79f1b56c-1866-4508-b6af-0e8beddc1e5a.png)

# Parameters
    -PingsPerSec

Pings per second to perform.
Note that if you set this **too** high (e.g much more than 10) there are 2 gotchas:

A) Code that renders the screen is rather slow and ping replies will pile up
  (when you stop the program, take a note of "Discarded N pings" message.
  If N is more than two times your PingsPerSec you've hit this gotcha)

B) The destination host may drop some of your ICMP echo requests(pings)

    -Title "My pings"   (by default the host you ping)
    -GraphMax 50 -GraphMin 5    (by default they adjust automatically)
    -AggregationSeconds 120    (the default)
    -BucketsCount 10    (the default)
    -UpdateScreenEvery 1    (the default)
    -HistSamples 100    (the default)
    -BarGraphSamples 20    (by default fills screen width) 
