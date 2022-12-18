# Out-PingStats

A PowerShell program to ping a host and display plenty of text and pseudo graphical statistics about the short and long-term quality of the connection

## For the impatient

To just test your internet connection (pings google.com):

    powershell -exec bypass -c ". {iwr -useb https://raw.githubusercontent.com/ndemou/Out-PingStats/main/Out-PingStats.ps1}|iex"
    
To download and run with specific options for your case:
    
    powershell -exec bypass -c ". {cd $Env:USERPROFILE; iwr -useb https://raw.githubusercontent.com/ndemou/Out-PingStats/main/Out-PingStats.ps1 -OutFile Out-PingStats.ps1}"
    powershell -exec bypass -c "cd $Env:USERPROFILE; .\Out-PingStats.ps1 -PingsPerSec 2 www.somehost.com"
    
## How to use
    Out-PingStats   # by default it pings google.com at 5 pings per sec
    Out-PingStats www.somehost.com 

## Example output and how to make the most out of it 
![image](https://user-images.githubusercontent.com/4411400/208316162-c115a6c9-eca6-49d6-94d8-b90c9b6f2628.png)

The LAST RTTs graph at the top shows one bar for every ping.
It's just a bit better than looking at the text output of the ping command.
In the top, real time graph, Lost packets will appear as a bar of red stars: 

![image](https://user-images.githubusercontent.com/4411400/204651924-730d2144-0dbf-41b8-a825-8e53f8072165.png)

The RTT HISTOGRAM includes only the most recent few hundred pings.
You need some experience with it to get a feeling of what is normal and what is not.
Take a look at the examples below for a quick start.

All the graphs except the LAST RTTs and HISTOGRAM are slow updating. 
Every bar represents quality metrics that are updated once every some seconds. 
This is the *period*, it is 2mins by default and can be changed with `-AggregationSeconds`.
In the x-axis you get a tick every 10 periods (20mins).

We compute the minimum of all RTT times(`min`) and the 95th percentile(`p95`). 
So if p95 equals 50msec you know that 95% of pings had an RTT<=50msec.
Or only 5% of pings were replied in more than 50msec.
We use `p95` in order to have a measure of worst case RTT times excluding a few "outliers".

The RTT BASELINE graph displays the minimum RTT of all pings and the the RTT VARIANCE
displays the difference `p95-min`. 

LOSS% is exactly what you guess.

ONE-WAY JITTER is an aproximation of the one-way jittet. 
We just divide the two-way jitter by two assuming that any delays are symetrical.

## Regarding the terminal font

If your terminal font contains the unicode block characters (like "DejaVu sans mono" does)
then you can add the `-HighResFont $true` option to get preatier and more detailed graphs.

If you don't, you can download "DejaVu sans mono" install it by double clicking on the ttf file
and clicking install. You then need to configute your PowerShell terminal to use the new font.

If you don't force high or low resolution by using the `-HighResFont $true/$false` option 
the code will try to detect the font and decide whether to use the unicode block characters.
It will display this warning if it thinks it can not.
![image](https://user-images.githubusercontent.com/4411400/208317605-721dafc4-06fb-4dd1-86ae-5c264fe08a0d.png)

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
    -HighResFont $true   (read above Re: fonts)
