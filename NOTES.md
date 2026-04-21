# General notes about pinging

## WHY DO I ONLY PING ALL ACES, ALL EIGHTS

Hosts like all aces and all eights had 0.8% packet loss in my tests, 
so pinging just the 4 well known IPs 1.1.1.1, 1.1.1.2, 8.8.8.8, 8.8.4.4 is more than enough to avoid false negatives
>99.999% of the time 

## BEACON PING

I use a beacon ping to 127.0.0.1 to run at the same rate as the main pings
Main loop uses replies from localhost as a reference "sampling clock".
This is usefull because ping.exe timeout(1.5sec) is larger than the ping period (every 1sec)
there can be silence periods where I will simple get no data back from 
parallel Multi Pings. During these silent periods localhost will respond
and main-loop will be able to detect timeouts
It will also be handy when we run on a laptop that goes to sleep.
where localhost will also stop responding 


## About ping.exe -w 1000 

-w 1000 is supposed to set the timeout to 1000msec but Windows seem to have some bugs there.
If you ping.exe -w N a non responding host you get timeouts every N+1000msec
Either Windows code waits 1000msec before sending the next packet after a timeout,
or they incorectly set the timeout to 2000msec
So the ICMP echo request packet must have been transmited between N to N+1000 msecs before and

Also pinging a host that replies in 300msec with -w 100 results in ping.exe happily reporting ping replies:

PS C:\Users\user> ping -t -w 100 diamc.kr | %{echo "$((get-date -UFormat %s)) $_"}
1696105305,53652
1696105305,53752 Pinging diamc.kr [211.177.94.215] with 32 bytes of data:
1696105305,76649 Request timed out.
1696105307,07725 Reply from 211.177.94.215: bytes=32 time=307ms TTL=46
1696105308,08322 Reply from 211.177.94.215: bytes=32 time=306ms TTL=46
1696105309,0846 Reply from 211.177.94.215: bytes=32 time=307ms TTL=46
1696105310,08837 Reply from 211.177.94.215: bytes=32 time=306ms TTL=46
1696105311,09126 Reply from 211.177.94.215: bytes=32 time=307ms TTL=46
1696105312,12153 Reply from 211.177.94.215: bytes=32 time=306ms TTL=46
1696105313,10928 Reply from 211.177.94.215: bytes=32 time=305ms TTL=46
1696105314,11527 Reply from 211.177.94.215: bytes=32 time=306ms TTL=46

## Regarding targets for pinging 

### THE BASIC FACTS

The hosts of one line are queried/pinged in order ONE AFTER THE OTHER
Every line is queried/pinged IN PARALLEL WITH EVERY OTHER LINE

### ADVICE

It's best to have AT LEAST 4 hosts in each line so that if you ping
every 1/2sec you are pinging each host at a slow pace of 1 ping per 2 seconds

### MORE DETAILS

Although you may be tempted to think that all hosts of one column are
pinged in parallel that will only be true if all hosts respond without
timing out. As soon as one host times out the order is messed up.
So after a while the only thing you can be sure of is that
some host of some line is pinged in parallel with a random
host of another line, and some random host of another line
and so on...
