# Out-PingStats

A PowerShell program to ping a host and display plenty of statistics about the short and long-term quality of the connection

## How to use
    Out-PingStats   # by default it pings google.com
    Out-PingStats www.somehost.com 

## Example output and how to make the most out of it 
![image](https://user-images.githubusercontent.com/4411400/204651704-cc6d6e56-81a7-43aa-b82e-6adec8f1a26e.png)

In the above screenshot we see:
   1.   Basic statistics about the whole time
   1.   The value at this point exceeded the graph max (70ms in this example)
   1.   You can see a period of not so good ping times\
   1.   During a period of 2' you had a small packet loss
   1.   The packet loss was 0.333% as you can see in the graph statistics 

In the top, real time graph, Lost packets will appear as a bar of red stars: ![image](https://user-images.githubusercontent.com/4411400/204651924-730d2144-0dbf-41b8-a825-8e53f8072165.png)

In this example, in the the real time graph, we see 114 pings with p5=18msec and p95=61msec. p5 and p95 stand for 5th and 95th percentile. So 5% of the 114 pings were <=18msec and 95% were <=61msec.

## Important: You need a monospace font containing the unicode block characters.

I think that Windows 11/Powershell 7, have proper fonts by default. In windows 10 you must download DejaVu sans mono or other fonts that contain unicode block characters, double click and click install on the downloaded ttf file, and finaly configute your PowerShell terminal to use them instead of consolas.

## Example: Not so good wifi connection

![image](https://user-images.githubusercontent.com/4411400/204652000-c71b4ccd-2cda-4458-a846-f122332446b0.png)

## Example: A good wifi connection

![image](https://user-images.githubusercontent.com/4411400/204652036-79f1b56c-1866-4508-b6af-0e8beddc1e5a.png)

# Parameters
    -PingsPerSec
       Pings per second to perform.
Note that if you set this too high there are 2 gotchas:

A) Code that renders the screen is rather slow and ping replies will pile up
  (when you stop the program, take a note of "Discarded N pings" message.
  If N is more than two times your PingsPerSec you've hit this gotcha)

B) The destination host may drop some of your ICMP echo requests(pings)

    -Title (by default the host you ping)
    -GraphMax 50 -GraphMin 5 (by default they adjust automatically)
    -AggregationSeconds 120 (the default)
    -BucketsCount 10 (the default)
    -UpdateScreenEvery 1 (the default)
    -HistSamples 100 (the default)
    -BarGraphSamples 20 (by default fills screen width) 
