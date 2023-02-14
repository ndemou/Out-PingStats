<#
    v0.19.5

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
TODO: In Histogram show the actual values instead of min... and ...MAX
TODO: Print clock time every 10 or 20 vertical bars
      i.e. '22:26 instead of just ` (yes ' is better than `)
TODO: Maybe when multiple scripts run simultaneously sync Y-max for all graphs
TODO: Option to read input from saved file
TODO: Hide histogram if console height is not enough
TODO: In a perfect world this script could be discovering good pingable hosts
      as it is running instead of the hardcoded list.
      (I already have the helper_find_pingable_com_host function to use)
TODO: While we collect enough data points to have a decent histogram
      we do present the histogram. After that point we change visualization:
      Now every block that used to show the histogram has a color that
      represents how likely it was for the actual histogram to reach this
      block.
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

<# Re: targets for pinging & DNS querying
   ===========================================
   THE BASIC FACTS
   ---------------
   The hosts of one line are queried/pinged in order ONE AFTER THE OTHER
   Every line is queried/pinged IN PARALLEL WITH EVERY OTHER LINE

   ADVICE
   ------
   It's best to have AT LEAST 4 hosts in each line so that if you ping
   every 1/2sec you are pinging each host at a slow pace of 1 ping per 2 seconds

   Don't add a DNS server to both lists even if it responds to pings
   They seem to throtle their packets per second

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
$DNS_TARGET_LIST = @(`
    @('1.0.0.1'        , '1.1.1.1'        , '8.8.8.8'        , '8.8.4.4',        '208.67.222.222' , '208.67.220.220' , '4.2.2.2'        , '4.2.2.1'),
    @('9.9.9.9'        , '149.112.112.112', '8.26.56.26'     , '8.20.247.20'    ,'185.225.168.168', '185.228.169.168', '76.76.19.19'    , '76.223.122.150' ),
    @('176.103.130.130', '176.103.130.131', '64.6.64.6'      , '64.6.65.6'      ,'216.87.84.211',   '23.90.4.6',       '77.88.8.8',       '77.88.8.1'      ),
    @(  '209.244.0.3',   '209.244.0.4',     '216.146.35.35',   '216.146.36.36'  ,'216.146.35.35',   '216.146.36.36',   '91.239.100.100',  '89.233.43.71'   ),
    @('156.154.70.5',    '156.157.71.5',    '81.218.119.11',   '209.88.198.133' ,'195.46.39.39',    '195.46.39.40',    '74.82.42.42',     '84.200.69.80'   )
)



$PING_TARGET_LIST = @(`
    @('2.19.51.63','170.49.49.66','52.85.158.24','104.18.1.128','104.18.86.87','104.18.174.72','104.16.135.38','104.18.29.192'),
    @('76.223.65.111','104.22.7.73','92.123.88.8','13.248.196.236','104.18.18.10','1.1.1.1','104.26.2.96','13.248.160.137'),
    @('75.2.93.210','13.248.216.40','3.33.176.117','52.85.158.64','104.18.27.236','104.18.202.79','172.67.71.222','52.85.158.106'),
    @('76.76.21.21','217.114.94.2','52.85.158.88','62.169.226.23','104.22.70.236','104.107.154.205','104.107.153.13','104.17.208.47'),
    @('15.197.142.173','104.17.85.88','104.26.0.179','184.168.131.241','104.16.122.96','104.17.135.55','84.254.12.27','104.22.71.131'),
    @('52.85.158.120','52.85.158.34','104.107.154.112','3.33.139.32','104.26.4.172','104.107.155.109','13.248.192.179','141.193.213.10'),
    @('52.85.158.97','172.67.70.62','172.66.41.43','52.85.158.98','141.193.213.11','162.159.129.11','52.85.158.117','52.85.158.41'),
    @('104.22.9.75','104.18.11.141','75.2.60.5','104.122.212.115','160.153.0.112','13.248.243.5','162.159.135.42','52.85.158.61'),
    @('52.85.158.54','172.67.73.230','13.248.172.93','104.22.77.82','52.85.158.25','141.193.213.21','23.227.38.74','162.159.130.84'),
    @('76.223.105.230','172.66.40.67','76.223.34.124','199.59.243.222','104.18.72.237','104.18.13.126','13.248.187.189','13.248.162.114'),
    @('104.18.99.229','104.18.216.68','104.18.36.69','52.85.158.11','104.26.2.177','172.67.73.224','104.18.149.59','192.200.160.248'),
    @('104.26.14.147','104.18.7.54','99.83.136.155','52.85.158.83','165.215.204.68','199.60.103.74','3.33.152.147','151.101.194.159'),
    @('151.101.130.132','104.107.153.29','52.85.158.95','216.239.34.21','151.101.195.10','34.102.136.180','216.239.32.21','151.101.1.195'),
    @('104.18.34.213','152.199.21.98','104.20.82.247','75.2.70.75','23.185.0.1','52.85.158.8','34.117.83.221','75.2.52.182'),
    @('192.124.249.109','151.101.193.135','23.185.0.4','104.107.144.95','104.19.191.28','151.101.194.49','52.85.158.77','151.101.2.159'),
    @('52.85.158.5','104.20.172.41','130.211.7.63','141.193.213.20','104.26.2.95','3.33.228.28','104.18.3.176','151.101.131.10'),
    @('172.66.43.190','199.60.103.30','104.18.33.19','192.124.249.27','216.239.38.21','23.227.38.65','75.2.40.207','192.124.249.17'),
    @('99.83.190.102','192.0.78.25','172.67.71.24','216.239.36.21','13.107.237.45','52.85.158.17','104.22.40.88','104.26.13.247'),
    @('2.21.69.138','199.16.172.42','13.107.246.40','151.101.65.124','75.2.26.18','75.2.64.137','192.0.66.2','52.85.158.31'),
    @('199.60.103.52','192.124.249.105','172.67.129.46','192.124.249.127','185.53.178.52','208.91.204.251','204.74.99.103','185.53.178.50'),
    @('170.33.13.246','185.53.178.54','185.53.177.31','172.67.129.156','194.97.137.224','192.0.66.184','84.242.9.12','146.75.122.114'),
    @('172.67.208.201','192.0.78.228','185.60.251.251','104.21.72.127','104.21.17.225','91.250.65.34','172.67.214.35','172.67.195.18'),
    @('104.21.18.72','85.10.214.235','173.212.244.233','91.195.240.135','172.67.201.226','82.98.81.5','104.21.75.192','217.160.0.59'),
    @('104.21.7.143','212.86.203.242','91.195.241.232','104.21.34.17','104.21.57.136','136.243.235.86','104.64.166.238','64.190.63.111'),
    @('104.21.85.239','104.21.15.26','104.21.14.123','104.21.55.196','194.77.47.146','85.187.142.74','185.53.177.52','193.53.247.79')
)
<#
  Pingable hosts: https://www.dotcom-monitor.com/blog/technical-tools/network-location-ip-addresses/

  BAD DNS servers
  ---------------
  '84.200.70.40','91.239.100.100', '89.233.43.71'

  ALL ??.COM HOSTS THAT RESPOND TO PING (?=some letter)
  -----------------------------------------------------

    # in groups of 10
    'aa.com','ad.com','ae.com','af.com','ai.com','aj.com','ak.com','am.com','ao.com','ap.com',
    'aq.com','as.com','au.com','av.com','bb.com','bc.com','be.com','bf.com','bg.com','bi.com',
    'bk.com','bl.com','bo.com','bq.com','bv.com','bw.com','bx.com','bz.com','cb.com','cd.com',
    'ce.com','cg.com','ci.com','cj.com','ck.com','cl.com','cm.com','co.com','cs.com','cu.com',
    'cv.com','cw.com','dc.com','dh.com','dl.com','dn.com','dr.com','ds.com','dt.com','dv.com',
    'dw.com','dx.com','dz.com','ea.com','eb.com','ed.com','ef.com','ei.com','ej.com','ek.com',
    'el.com','er.com','es.com','ev.com','ew.com','ey.com','ez.com','fa.com','fb.com','fc.com',
    'fd.com','fe.com','fj.com','fn.com','fp.com','fs.com','ft.com','ga.com','gd.com','ge.com',
    'gf.com','gg.com','gl.com','go.com','gq.com','gr.com','gs.com','gu.com','gv.com','gw.com',
    'gx.com','gz.com','ha.com','hb.com','hc.com','he.com','hf.com','hi.com','hm.com','hq.com',
    'hr.com','ht.com','hv.com','ib.com','id.com','ie.com','ii.com','il.com','in.com','ip.com',
    'iq.com','ir.com','is.com','it.com','iv.com','jb.com','jd.com','jk.com','jl.com','jm.com',
    'jn.com','jp.com','js.com','jw.com','jy.com','ka.com','kc.com','kd.com','ke.com','kh.com',
    'kj.com','kk.com','kn.com','ks.com','ku.com','kw.com','ky.com','la.com','ld.com','le.com',
    'li.com','lj.com','lk.com','ln.com','lo.com','lp.com','lr.com','lu.com','lx.com','ly.com',
    'ma.com','md.com','mg.com','mj.com','mn.com','mp.com','ms.com','mt.com','mu.com','mx.com',
    'my.com','mz.com','na.com','nd.com','ne.com','nl.com','nn.com','no.com','np.com','nt.com',
    'nw.com','oa.com','oc.com','oe.com','oj.com','ok.com','ol.com','om.com','on.com','oo.com',
    'op.com','or.com','ov.com','oy.com','oz.com','pd.com','pi.com','pn.com','pp.com','pq.com',
    'pt.com','pu.com','pv.com','py.com','qa.com','qb.com','qd.com','qf.com','qh.com','qj.com',
    'qk.com','qm.com','qn.com','qo.com','qp.com','qq.com','qw.com','qy.com','qz.com','ra.com',
    'rc.com','rh.com','ri.com','rj.com','rk.com','rl.com','ro.com','rv.com','ry.com','rz.com',
    'sc.com','sh.com','si.com','sk.com','sl.com','sm.com','sn.com','so.com','sq.com','ss.com',
    'sy.com','td.com','tf.com','th.com','tk.com','tn.com','to.com','tp.com','tr.com','ts.com',
    'tt.com','tu.com','tw.com','tx.com','uc.com','ud.com','ui.com','uj.com','um.com','un.com',
    'up.com','uq.com','ut.com','ux.com','vb.com','vh.com','vi.com','vk.com','vl.com','vn.com',
    'vp.com','vq.com','vs.com','vu.com','vv.com','vw.com','vx.com','vy.com','vz.com','wg.com',
    'wk.com','wl.com','wm.com','wo.com','wp.com','wq.com','ws.com','wt.com','wv.com','ww.com',
    'wz.com','xa.com','xb.com','xd.com','xe.com','xf.com','xh.com','xi.com','xk.com','xl.com',
    'xm.com','xp.com','xq.com','xr.com','xs.com','xv.com','xx.com','xy.com','yc.com','yd.com',
    'ye.com','yf.com','yg.com','yo.com','yw.com','yy.com','zb.com','zf.com','zg.com','zj.com',
    'zl.com','zn.com','zo.com','zv.com','zw.com','zy.com',

    # In groups of 4
    'aa.com','ad.com','ae.com','af.com',
    'ai.com','aj.com','ak.com','am.com',
    'ao.com','ap.com','aq.com','as.com',
    'au.com','av.com','bb.com','bc.com',
    'be.com','bf.com','bg.com','bi.com',
    'bk.com','bl.com','bo.com','bq.com',
    'bv.com','bw.com','bx.com','bz.com',
    'cb.com','cd.com','ce.com','cg.com',
    'cs.com','ct.com','cu.com','cv.com',
    'cw.com','dc.com','dh.com','dl.com',
    'dn.com','dq.com','dr.com','ds.com',
    'dt.com','dv.com','dw.com','dx.com',
    'dz.com','ea.com','eb.com','ed.com',
    'ef.com','ei.com','ej.com','ek.com',
    'el.com','er.com','es.com','ev.com',
    'ew.com','ey.com','ez.com','fa.com',
    'fb.com','fc.com','fd.com','fe.com',
    'fj.com','fn.com','fp.com','fs.com',
    'ft.com','ga.com','gd.com','ge.com',
    'gf.com','gg.com','gl.com','go.com',
    'gq.com','gs.com','gu.com','gv.com',
    'gw.com','gz.com','ha.com','hb.com',
    'hc.com','he.com','hi.com','hl.com',
    'hm.com','hq.com','hr.com','ht.com',
    'hv.com','ib.com','id.com','ih.com',
    'ii.com','il.com','in.com','ip.com',
    'iq.com','ir.com','is.com','it.com',
    'iv.com','jb.com','jd.com','jk.com',
    'jl.com','jn.com','jp.com','js.com',
    'jw.com','jy.com','ka.com','kc.com',
    'kd.com','ke.com','kh.com','kk.com',
    'kn.com','ks.com','ku.com','kw.com',
    'la.com','ld.com','le.com','li.com',
    'lj.com','lk.com','ln.com','lo.com',
    'lp.com','lr.com','lt.com','lu.com',
    'lx.com','ly.com','lz.com','ma.com',
    'md.com','mg.com','mj.com','mn.com',
    'mp.com','ms.com','mt.com','mu.com',
    'my.com','mz.com','na.com','nd.com',
    'ne.com','nn.com','no.com','np.com',
    'nt.com','nw.com','oa.com','oc.com',
    'oe.com','oj.com','ok.com','ol.com',
    'om.com','on.com','oo.com','op.com',
    'or.com','ov.com','oy.com','oz.com',
    'pd.com','pi.com','pn.com','pp.com',
    'pq.com','pt.com','pv.com','px.com',
    'py.com','qa.com','qb.com','qd.com',
    'qf.com','qh.com','qj.com','qk.com',
    'qm.com','qn.com','qo.com','qp.com',
    'qq.com','qw.com','qx.com','qz.com',
    'ra.com','rc.com','rh.com','ri.com',
    'rj.com','rk.com','rl.com','rn.com',
    'ro.com','rv.com','rx.com','ry.com',
    'rz.com','sc.com','sh.com','si.com',
    'sk.com','sl.com','sm.com','sn.com',
    'so.com','sq.com','sy.com','td.com',
    'tf.com','th.com','tk.com','tn.com',
    'to.com','tp.com','tr.com','ts.com',
    'tt.com','tu.com','tw.com','tx.com',
    'ua.com','uc.com','ud.com','ui.com',
    'uj.com','um.com','un.com','up.com',
    'uq.com','ut.com','ux.com','uz.com',
    'vb.com','vh.com','vi.com','vl.com',
    'vn.com','vp.com','vq.com','vs.com',
    'vu.com','vv.com','vw.com','vx.com',
    'vy.com','vz.com','wg.com','wk.com',
    'wl.com','wm.com','wn.com','wo.com',
    'wp.com','wq.com','ws.com','wv.com',
    'ww.com','wy.com','wz.com','xa.com',
    'xb.com','xd.com','xe.com','xf.com',
    'xh.com','xk.com','xm.com','xp.com',
    'xq.com','xr.com','xs.com','xv.com',
    'xx.com','xy.com','yb.com','yc.com',
    'yd.com','ye.com','yf.com','yg.com',
    'yo.com','yw.com','yy.com','zb.com',
    'ze.com','zf.com','zg.com','zi.com',
    'zj.com','zl.com','zn.com','zo.com',
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

$CodeOfDnsQuery = @'
Function Start-DNSQuery {
    # Allows custom interval with msec accuracy.
    # Will try hard to send 1000/$Interval pings per second
    # by adjusting the delay between two consequtive pings.
    # NOTE that in case of failure, it returns 999
    Param(
        [string]$target="1.0.0.1",
        [int]$Interval = 1000,
        [int]$TimeOut = 0
    )

    if ($TimeOut -eq 0) {$TimeOut = $Interval*0.9}
    $ping_count = 0
    $ts_first_ping = (Get-Date)
    while ($True) {
        $sent_at = (Get-Date)
        # $sent_at.ticks / 10000 milliseconds counter

        try {
            $status = 'Failed'
            $output=(Resolve-DnsName google.com -type A -Server $target -DnsOnly -NoHostsFile -QuickTimeout)
            if ($output.TTL -is [uint32]) {$status = 'Success'}
            $debug = ''
        } catch {
            $status = $Error[0].Exception.GetType().FullName
            $debug = $status
        }

        $ts_end = (Get-Date)
        $ping_count += 1
        if ($status -eq 'Success') {
            $RTT = [math]::max(1, [int](($ts_end.ticks - $sent_at.ticks)/10000))
        } else {
            $RTT = 9999
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
            Status = $status; `
            ts_start = [int](($sent_at.ticks - $ts_first_ping.ticks)/10000); `
            ts_end = [int](($ts_end.ticks - $ts_first_ping.ticks)/10000); `
            RTT2 = [math]::round((($ts_end.ticks - $sent_at.ticks)/10000),1); `
            RTT = $RTT; `
            ping_count = $ping_count; `
            target = $target; `
            group_id = $target; `
            debug = $debug
        }
        if ($sleep_ms -gt 0) {start-sleep -Milliseconds $sleep_ms}

    }
}
'@

$CodeOfMultiDnsQueries = @'
Function Start-MultiDnsQueries {
    # Will try hard to send pings at exact times
    # every second +0msec for 1 ping/sec
    # or every sec +0msec and +500msec for 2 pings/sec
    # NOTE that in case of failure, it does not return 0 but
    # the elapsed time
    Param(
        [array]$target_list= @('8.8.8.8', '208.67.222.222', `
            '1.1.1.1', '4.2.2.2', '4.2.2.1', '8.8.4.4', `
            '208.67.220.220', '1.0.0.1'),
        [int]$TimeOut = 0,
        [switch]$TwicePerSec = $False
    )

    function get_median($series){
        # see function notes on main code
        $sorted = [array]($series  | ?{$_ -ne 9999} | sort-object)
        if ($sorted) {
            [int]$sorted[[int]($sorted.count/2)]
        } else {
            9999
        }
    }
    function get_baseline($Baseline, $RTT_list){
        # see function notes on main code
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

    # create a hash table to hold the last N RTTs of each host
    # in order to compute the average of mins which will allow us
    # to "normalize" the different groups close to a common baseline
    $max_values_to_keep = 40
    $last_RTTs = @{}
    $failures = @{}
    $Median_of_last_RTTs = @{}
    $Baseline = $null
    $target_list | %{
        $last_RTTs[$_] = New-Object System.Collections.Queue
        $last_RTTs[$_].enqueue(9999)
        $Median_of_last_RTTs[$_] = 99
        $failures[$_] = 0
    }

    if ($TwicePerSec) {$PerSec=2} else {$PerSec=1}
    $Interval = 1000 / $PerSec
    if ($TimeOut -eq 0) {$TimeOut = $Interval*0.9}
    $ping_count = 0
    $target_counter = 0
    $cur_msec = (Get-Date).millisecond
    if ($cur_msec -gt 0) {
        start-sleep -Milliseconds (1000-$cur_msec+8) # align at 0msec
        # without +8 sometimes the sleep is 1-5 msec less than needed
        # and we sent at 995-999msec
    }

    while ($True) {
        $debug_msg = ''
        if ($target_list.length -eq 1) {
            $target = $target_list[0]
        } else {
            # cycle over available targets
            $target = $target_list[$target_counter % $target_list.length]
            # if a target has 3 consequtive failures it has 9/70 chance of been skiped
            # if it has 9 consequtive failures (or more) it has 69/70 chance
            # NOTE: strangely -maximum 92 gives values that are at most 91
            while ($failures[$target]*10 -ge (get-random -minimum 21 -maximum 92)) {
                $target_counter += 1
                $debug_msg += "$($target) skiped "
                $target = $target_list[$target_counter % $target_list.length]
            }
        }

        $sent_at = (Get-Date)
        # $sent_at.ticks / 10000 milliseconds counter

        try {
            $status = 'Failed'
            write-verbose "Trying $target"
            $output=(Resolve-DnsName google.com -type A -Server $target -DnsOnly -NoHostsFile -QuickTimeout  -erroraction 'silentlycontinue')
            if ($output.TTL -is [uint32]) {$status = 'Success'}
            $debug = ''
            $ts_end = (Get-Date)
            if ($status -eq 'Success') {
                $Real_RTT = [int](($ts_end.ticks - $sent_at.ticks)/10000)
                if (($ts_end.ticks - $sent_at.ticks) -eq 0) {
                    # not sure why but I often get 0 ticks diff!
                    # in that case I ignore it and /normalize/ the value to the most recent min
                    $Real_RTT = $Median_of_last_RTTs[$target]
                } elseif ($Real_RTT -gt $Interval) {
                    # RTT is so big that we can as well consider it a failure
                    # (If we don't we create a mess in the main loop where
                    # some late responses are interleaved between good responses)
                    # (Resolve-DnsName does offer a -TimeOut option,
                    # QuickTimeout seems to allow about 7-8sec timeout which is huge
                    # for our purpose)
                    $Real_RTT  = 9999
                    $status = 'Failed'
                }
            } else {
                $Real_RTT = 9999
            }
        } catch {
            $status = $Error[0].Exception.GetType().FullName
            $debug = $status
            $ts_end = (Get-Date)
            $Real_RTT = 9999
        }

        $ping_count += 1
        if ($status -ne 'Success') {
            # failed ping

            $failures[$target] = [math]::min(9, $failures[$target]+1) # don't go over 9
            $debug_msg += "$($target): $($failures[$target]) con.fail. "
        } else {
            # succesful ping
            if (($last_RTTs[$target].count -eq 1) -and ($last_RTTs[$target].Peek() -eq 0)) {
                $foo = $last_RTTs[$target].dequeue() # get rid of the initial dummy value
            }
            $failures[$target] = [math]::max(0, $failures[$target]-1)
            $last_RTTs[$target].enqueue($Real_RTT)
            if ($last_RTTs[$target].count -gt $max_values_to_keep) {$foo = $last_RTTs[$target].dequeue()}
            $Median_of_last_RTTs[$target] = get_median $last_RTTs[$target]
            $Baseline = (get_baseline $Baseline $Median_of_last_RTTs.values)
        }

        if ($ping_count -le 10) {
            $effective_RTT = $Real_RTT
        } else {
            if ($Real_RTT -eq 9999) {
                $effective_RTT = 9999
            } else {
                $effective_RTT = [math]::max($Baseline, $Real_RTT + ($Baseline - $Median_of_last_RTTs[$target]))
            }
        }
        # return this:
        [PSCustomObject]@{`
            sent_at = $sent_at; `
            Status = $status.tostring(); `
            target = $target; `
            ping_count = $ping_count; `
            RTT = $effective_RTT; `
            dt = $Real_RTT - $effective_RTT; `
            real_RTT = $Real_RTT; `
            Median_of_last_RTTs = $Median_of_last_RTTs[$target]; `
            Baseline = $Baseline; `
            group_id = $target_list[0] + $target_list[1]; `
            debug = $debug_msg
        }
        # sleep until msec =0 (or 500 for $PerSec=2)
        $cur_msec = (Get-Date).millisecond
        if ($cur_msec -gt 500) {
            $sleep_msec = (1000-$cur_msec)
        } else {
            if ($PerSec -eq 2) {
                $sleep_msec = (500-$cur_msec)
            } else {
                $sleep_msec = (1000-$cur_msec)
            }
        }
        write-verbose "cur_msec=$cur_msec`t`tsleeping for $sleep_msec"
        start-sleep -Milliseconds ($sleep_msec+8)
        # see above for +8

        $target_counter += 1
    }
}
'@

$CodeOfMultiPings = @'
Function Start-MultiPings {
    # Will try hard to send pings at exact times
    # every second +0msec for 1 ping/sec
    # or every sec +0msec and +500msec for 2 pings/sec
    # NOTE that in case of failure, it does not return 0 but
    # the elapsed time
    Param(
        [array]$target_list= @('8.8.8.8', '208.67.222.222', `
            '1.1.1.1', '4.2.2.2', '4.2.2.1', '8.8.4.4', `
            '208.67.220.220', '1.0.0.1'),
        [int]$TimeOut = 0,
        [switch]$TwicePerSec = $False
    )

    function get_median($series){
        # see function notes on main code
        $sorted = [array]($series  | ?{$_ -ne 9999} | sort-object)
        if ($sorted) {
            [int]$sorted[[int]($sorted.count/2)]
        } else {
            9999
        }
    }
    function get_baseline($Baseline, $RTT_list){
        # see function notes on main code
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

    # create a hash table to hold the last N RTTs of each host
    # in order to compute the average of mins which will allow us
    # to "normalize" the different groups close to a common baseline
    $max_values_to_keep = 40
    $last_RTTs = @{}
    $failures = @{}
    $Median_of_last_RTTs = @{}
    $Baseline = $null
    $target_list | %{
        $last_RTTs[$_] = New-Object System.Collections.Queue
        $last_RTTs[$_].enqueue(9999)
        $Median_of_last_RTTs[$_] = 9999
        $failures[$_] = 0
    }

    if ($TwicePerSec) {$PerSec=2} else {$PerSec=1}
    $Interval = 1000 / $PerSec
    if ($TimeOut -eq 0) {$TimeOut = $Interval*0.9}
    $ping_count = 0
    $target_counter = 0
    $cur_msec = (Get-Date).millisecond
    if ($cur_msec -gt 0) {
        start-sleep -Milliseconds (1000-$cur_msec+8) # align at 0msec
    }

    while ($True) {
        $debug_msg = ''
        if ($target_list.length -eq 1) {
            $target = $target_list[0]
        } else {
            # cycle over available targets
            $target = $target_list[$target_counter % $target_list.length]
            # if a target has 3 consequtive failures it has 9/70 chance of been skiped
            # if it has 9 consequtive failures (or more) it has 69/70 chance
            # NOTE: strangely -maximum 92 gives values that are at most 91
            while ($failures[$target]*10 -ge (get-random -minimum 21 -maximum 92)) {
                $target_counter += 1
                $debug_msg += "$($target) skiped "
                $target = $target_list[$target_counter % $target_list.length]
            }
        }
        $sent_at = (Get-Date)
        $Ping = [System.Net.NetworkInformation.Ping]::New()
        try {
            $ret = $Ping.Send($target, $TimeOut)
        } catch {
            $ret =[PSCustomObject]@{`
                Status = $Error[0].Exception.GetType().FullName; `
                RTT = 9999; `
                group_id = $target_list[0] + $target_list[1]; `
                target = $target `
            }
        }

        $ts_end = (Get-Date)
        $ping_count += 1
        if ($ret.Status -ne 'Success') {
            # failed ping
            $real_RTT = 9999
            $failures[$target] = [math]::min(9, $failures[$target]+1) # don't go over 9
            $debug_msg += "$($target): $($failures[$target]) con.fail. "
        } else {
            # succesful ping
            $real_RTT = $ret.RoundtripTime
            if (($last_RTTs[$target].count -eq 1) -and ($last_RTTs[$target].Peek() -eq 0)) {
                $foo = $last_RTTs[$target].dequeue() # get rid of the initial dummy value
            }
            $failures[$target] = [math]::max(0, $failures[$target]-1)
            $last_RTTs[$target].enqueue($real_RTT)
            if ($last_RTTs[$target].count -gt $max_values_to_keep) {$foo = $last_RTTs[$target].dequeue()}
            $Median_of_last_RTTs[$target] = get_median $last_RTTs[$target]
            $Baseline = (get_baseline $Baseline $Median_of_last_RTTs.values)
        }

        if ($real_RTT -eq 9999) {
            $effective_RTT = 9999
        } else {
            $effective_RTT = [math]::max($Baseline, $real_RTT + ($Baseline - $Median_of_last_RTTs[$target]))
        }

        # return this:
        [PSCustomObject]@{`
            sent_at = $sent_at; `
            Status = $ret.Status.tostring(); `
            target = $target; `
            ping_count = $ping_count; `
            RTT = $effective_RTT; `
            dt = $Real_RTT - $effective_RTT; `
            real_RTT = $real_RTT; `
            Median_of_last_RTTs = $Median_of_last_RTTs[$target]; `
            Baseline = $Baseline; `
            group_id = $target_list[0] + $target_list[1]; `
            debug = $debug_msg
        }
        # sleep until msec =0 (or 500 for $PerSec=2)
        $cur_msec = (Get-Date).millisecond
        if ($cur_msec -gt 500) {
            start-sleep -Milliseconds (1000-$cur_msec+8)
        } else {
            if ($PerSec -eq 2) {
                start-sleep -Milliseconds (500-$cur_msec+8)
            } else {
                start-sleep -Milliseconds (1000-$cur_msec+8)
            }
        }

        $target_counter += 1
    }
}
'@

$CodeOfSpecialPing = @'
Function Start-SpecialPing {
    # Allows custom interval with msec accuracy.
    # Will try hard to send 1000/$Interval pings per second
    # by adjusting the delay between two consequtive pings.
    # NOTE that in case of failure, it does not return 0 but
    # the elapsed time
    Param(
        [string]$target="",
        [int]$TimeOut = 0,
        [int]$Interval = 500
    )

    if ($TimeOut -eq 0) {$TimeOut = $Interval*0.9}
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
function get_median($series){
    # returns the integer part of the median of $series after ignoring any 9999 elements
    # It returns 9999 if series is empty (or contains only 9999 elements)
    # NOTE technicaly it is not exactly the median because if $series has even 
    # number of elements I'm just returning the value of the element just before
    # the midle of the list
    $sorted = [array]($series  | ?{$_ -ne 9999} | sort-object)
    if ($sorted) {
        [int]$sorted[[int]($sorted.count/2)]
    } else {
        9999 # $series is empty or contains only 9999
    }
}
function get_baseline($Baseline, $RTT_list){
    # Calculates a "Baseline" given a series of RTTs and the current 
    # Baseline. The baseline must _slowly_ follow the minimum of all the values 
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

        if ($i -eq 0) {$from_str="min"; $cumul_str=" Cumul"} else {$from_str="{0,3}" -f $from; $cumul_str=" {0,3}% " -f $perc_cumul}
        if ($i -eq ($HistBucketsCount - 1)) {$to_str="MAX"} else {$to_str="{0,3}" -f $to}
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
    render_bar_graph $values $title "<stats><H_grid>" 9999 `
        $y_min $y_max $RTTMIN_BAR_GRAPH_THEME

    # display $Variance_values
    #------------------------------
    $values = @($Variance_values | select -last $MaxItems)
    $stats = (stats_of_series $values)
    $y_min = (std_num_le $stats.min)
    if ($y_min -lt 10) {$y_min = 0}
    $y_max = (y_axis_max $stats.min $stats.max $y_min 10)
    if ($y_max -eq $y_min) {$y_max = (std_num_ge $y_max + 1)}
    $title = "RTT VARIANCE(p95-min), $AggPeriodDescr, min=<min>, max=<max>, last=<last> (ms)"
    render_bar_graph $values $title "<stats><H_grid>" 9999 `
        $y_min $y_max

    # display the lost% bar graph
    #------------------------------
    $stats = (stats_of_series $Loss_values)
    $y_min = 0
    $y_max = (y_axis_max $stats.min $stats.max 0 4)
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
function render_all($last_input, $PingsPerSec, $ShowCountOfResponders) {
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
    render_bar_graph $graph_values "$title"  "<stats><H_grid>" 9999 $y_min $y_max

    if ($ShowCountOfResponders) {
        # display the RespondersCnt bar graph
        $graph_values =  @($RespondersCnt_values | select -last $script:EffBarsThatFit)
        #echo ([string][char]9472*75)
        $title = "LAST Count of responders,  min=<min>, max=<max>, last=<last>"
        # decide Y axis limits
        $stats = (stats_of_series ($graph_values | ?{$_ -ne 9999}))
        ($time_graph_abs_min, $p5, $p95, $time_graph_abs_max) = ($stats.min, $stats.p5, $stats.p95, $stats.max)
        $y_max = (y_axis_max $stats.min $stats.max 0 9)
        render_bar_graph $graph_values "$title"  "<stats><H_grid>" 9999 0 30  $JITTER_BAR_GRAPH_THEME
    }

    # display the histogram
    if ($RTT_values.count) {
        #echo ([string][char]9472*75)
        echo "    ${COL_TITLE}RTT HISTOGRAM, last $HistSamples samples, p95=${COL_H1}${p95}${COL_TITLE}ms$COL_RST"
        render_histogram @($RTT_values | select -last $HistSamples)
        $p95 = [int](stats_of_series $RTT_values).p95
        echo ""
    }

    if ($Variance_values.count) {
        render_slow_updating_graphs
        if (Test-Path variable:script:SCREEN_DUMP_FILE) {
            $filename = ($script:SCREEN_DUMP_FILE -replace ($env:TEMP -replace '\\','\\'), '$env:TEMP')
            echo "$COL_IMP_LOW     (Saving to $filename)"
        }
        $error = $null # empty $error which collects errors from pings and DNS queries
        [gc]::Collect() # force garbage collection
    }

    if ($DebugMode) {
        #echo "AggPeriodSeconds=$script:AggPeriodSeconds"
        #echo "Variance_values=$Variance_values"
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
    $ToSave_values = @()
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
        $RespondersCnt_values = New-Object System.Collections.Queue
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
        $bumpy_start_cleanup_done = $false
    }
    process {
        $Items  | %{
            # echo "Item: $($_.GetType().Name) $($_.status) $($_.RTT) $($_.status) $($_.bucket_ok_pings)"
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
            $RespondersCnt_values.enqueue($_.bucket_ok_pings)
            # ignore the first few pings (the sometimes bumpy start)
            if (($RTT_values.count -eq 61) -and !$bumpy_start_cleanup_done) {
                $bumpy_start_cleanup_done = $true
                $RTT_values.clear()
                $RTT_values.enqueue($ms)
                $all_pings_cnt = 1
                $all_lost_cnt  += [math]::min($all_lost_cnt,1)

                $RespondersCnt_values.clear()
                $RespondersCnt_values.enqueue($_.bucket_ok_pings)
            }

            # keep $ms to a list of values that we will right to the ops....pingrec file
            if ($ms -eq 9999) {$ToSave_values += @(-1)} else {$ToSave_values += @($ms)}

            # keep at most $script:EffBarsThatFit measurements in RTT_values
            while ($RTT_values.count -gt $max_values_to_keep) {
                $foo = $RTT_values.dequeue()
                $foo = $RespondersCnt_values.dequeue()
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
            $AggPeriodStart = (get-date) # FIXME must subtract as many seconds as we are already after the AggregationSeconds
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
                if ($DebugData) {
                    "Baseline_values = $($stats.min) Variance_values=$($stats.p95 - $stats.min) from these data: $last_hist_secs_values_no_lost" >> "$($env:TEMP)\ops.$ts.data"
                }

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
            while ($Variance_values.count -gt ($script:EffBarsThatFit+100)) {
                $foo = $Variance_values.dequeue()
                $foo = $Baseline_values.dequeue()
                $foo = $Jitter_values.dequeue()
                $foo = $Loss_values.dequeue()
            }

            append_to_pingtimes $ToSave_values $script:PINGREC_FILE

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
            $total_threads = ($DNS_TARGET_LIST.count + $PING_TARGET_LIST.count)
            $DNS_TARGET_LIST | %{
                $group_id = $_[0] + $_[1]
                $last_RTTs[$group_id] = New-Object System.Collections.Queue
                $last_RTTs[$group_id].enqueue(99)
                $Median_of_last_RTTs[$group_id] = 0

                $jobs += @((
                    Start-ThreadJob -ThrottleLimit $total_threads -ArgumentList $PingsPerSec, $_, $CodeOfMultiDnsQueries -ScriptBlock {
                        $PingsPerSec = $args[0]
                        $target_list = $args[1]
                        $CodeOfMultiDnsQueries = $args[2]
                        . Invoke-Expression $CodeOfMultiDnsQueries
                        $TwicePerSec = $false; if ($PingsPerSec -eq 2) {$TwicePerSec = $true}
                        Start-MultiDnsQueries -target_list $target_list
                    }
                ))
            }
            $PING_TARGET_LIST | %{
                $group_id = $_[0] + $_[1]
                $last_RTTs[$group_id] = New-Object System.Collections.Queue
                $last_RTTs[$group_id].enqueue(99)
                $Median_of_last_RTTs[$group_id] = 0

                $jobs +=  @((
                    Start-ThreadJob -ThrottleLimit $total_threads -ArgumentList $PingsPerSec, $_, $CodeOfMultiPings -ScriptBlock {
                            $PingsPerSec = $args[0]
                            $target = $args[1]
                            $CodeOfMultiPings = $args[2]
                            . Invoke-Expression $CodeOfMultiPings
                            $TwicePerSec = $false; if ($PingsPerSec -eq 2) {$TwicePerSec = $true}
                            Start-MultiPings -target $target
                    }
                ))
            }
        } else {
<#
            # DNS query of specific target
            # (Instead of the default ping specific target mode)
            #----------------------------------
            $jobs += @((
                start-job -ArgumentList $PingsPerSec, $target, $CodeOfDnsQuery -ScriptBlock {
                        $PingsPerSec = $args[0]
                        $target = $args[1]
                        $CodeOfDnsQuery = $args[2]
                        . Invoke-Expression $CodeOfDnsQuery
                        Start-DNSQuery
                            -Interval (1000/$PingsPerSec)
                            -Target $target
                    }
            ))
#>
            $group_id = $target
            $last_RTTs[$group_id] = New-Object System.Collections.Queue
            $last_RTTs[$group_id].enqueue(99)
            $Median_of_last_RTTs[$group_id] = 0

            $jobs += @((
                start-ThreadJob -ArgumentList $PingsPerSec, $target, $CodeOfSpecialPing -ScriptBlock {
                    $PingsPerSec = $args[0]
                    $target = $args[1]
                    $CodeOfSpecialPing = $args[2]
                    . Invoke-Expression $CodeOfSpecialPing
                    Start-SpecialPing  -Target $target -Interval (1000/$PingsPerSec) -TimeOut ((1000/$PingsPerSec)*0.9)
                }
            ))
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
                        if (($job | get-job).HasMoreData) {$data += [array]($job | receive-job)}
                    }

                    # $data
                    if ($data) {
                        # data contain these properties:
                        #     sent_at <-get-date
                        #     Status
                        #     RTT
                        if ($parallel_testing) {
                            # ?{$_} ignores some $null data -- don't know why they are there
                            $data_sorted = ($data | ?{$_} |  sort-object -property sent_at)
                            if ($DebugData) {
                                $data_sorted | ft >> "$($env:TEMP)\ops.$ts.data"
                            }
                            if ($debugmode) {
                                write-verbose "<---data_sorted---"
                                $data_sorted | %{write-verbose $_}
                                write-verbose "--->"
                            }
                            write-verbose "<---bucket---"
                            write-verbose " "

                            $data_sorted | %{
                                if ($_.status -eq 'Success' -and $last_success_at -lt $_.sent_at) {
                                    # if later I receive packets with sent_at before this
                                    # timestamp I will discard them (it is obviously a timeout
                                    # that came delayed by one or more seconds
                                    $last_success_at = $_.sent_at
                                }
                                if ($_.sent_at -lt $last_success_at) {
                                    # ignore this packet
                                    write-verbose ":::Ignoring late packet at sent_at=$($_.sent_at)"
                                } else {

                                    #----------------------------------------------------------
                                    # "Normalize" the RTT reported by each group in order to bring
                                    # them close to a _common_ minimum
                                    if (($last_RTTs[$_.group_id].count -eq 1) -and ($last_RTTs[$_.group_id].Peek() -eq 0)) {
                                        $foo = $last_RTTs[$_.group_id].dequeue() # get rid of the initial dummy value
                                    }
                                    $last_RTTs[$_.group_id].enqueue($_.RTT)
                                    if ($last_RTTs[$_.group_id].count -gt $max_values_to_keep) {$foo = $last_RTTs[$_.group_id].dequeue()}
                                    $Median_of_last_RTTs[$_.group_id] = get_median $last_RTTs[$_.group_id]
                                    $Baseline = (get_baseline $Baseline $Median_of_last_RTTs.values)
                                    if ($_.RTT -ne 9999) {
                                        $_.RTT = [math]::max($Baseline, $_.RTT + ($Baseline - $Median_of_last_RTTs[$_.group_id]))
                                    }
                                    #----------------------------------------------------------

                                    # process packet
                                    $msec_dif = [math]::abs(($_.sent_at - $bucket_time).TotalMilliseconds)
                                    write-verbose ("$_" -replace 'PSComputerName.*')
                                    write-verbose "msec_dif:  $msec_dif, bucket_time=$bucket_time, sent_at=$($_.sent_at)"
                                    if ($msec_dif -lt 300) {
                                        # this ping is very close to the previous -- add it to existing bucket
                                        $bucket += $_
                                    } else {
                                        # this ping is far from the previous -- process the currect bucket
                                        if ($bucket) {
                                            if (($bucket).Status -contains 'Success') {
                                                $bucket_status = 'Success'
                                            } else {
                                                $bucket_status = $bucket[0].Status # status from the 1st item in the bucket
                                            }
                                            $ok_pings = [array]($bucket | ?{$_.Status -eq 'Success'})
                                            if ($ok_pings) {$ok_pings = $ok_pings.length} else {$ok_pings=0}
                                            $ping_count += 1

                                            $RTT = (($bucket).RTT | measure -Minimum).minimum

                                            $output = [PSCustomObject]@{`
                                                sent_at = (($bucket).sent_at | measure -Minimum).minimum; `
                                                Status = $bucket_status; `
                                                RTT = $RTT; `
                                                ping_count = $ping_count; `
                                                bucket_pings = $bucket.length; `
                                                bucket_ok_pings = $ok_pings; `
                                                Baseline = $Baseline; `
                                                destination = ($bucket.target) -join ";"; `
                                                debug = ($bucket.debug) -join ""
                                            }
                                            $ping_count += 1
                                            $bucket_time = $_.sent_at
                                            write-verbose ":::Starting new bucket, Init bucket_time=$bucket_time"
                                            $bucket = @()
                                            write-verbose ""
                                            write-verbose "<==============output=============="
                                            echo $output
                                            write-verbose "=======>"
                                            if ($DebugData) {
                                                $output | ft >> "$($env:TEMP)\ops.$ts.data"
                                            }

                                        } else {
                                            write-verbose ":::The bucket is EMPTY"
                                        }
                                        $bucket = [array]$_ # this ping is the 1st in a new bucket
                                        $bucket_time = $_.sent_at
                                        write-verbose ":::Starting new bucket, Init bucket_time=$bucket_time"
                                    }
                                }
                            }
                            $data = @()
                        } else {
                            # non-parallel single host mode of operation ($parallel_testing=$false)
                            $data_sorted = ($data | ?{$_} | sort-object -property sent_at)
                            $data = @()
                            $data_sorted | %{
                                $ok_pings = 0
                                if ($_.status -eq 'Success') {$ok_pings = 1}
                                $output = [PSCustomObject]@{`
                                    sent_at = $_.sent_at; `
                                    Status = $_.status; `
                                    RTT = $_.RTT; `
                                    ping_count = $_.ping_count; `
                                    bucket_pings = 1; `
                                    bucket_ok_pings = $ok_pings; `
                                    Baseline = $Baseline; `
                                    destination = $_.target; `
                                    debug = ""
                                }
                                echo $output
                            }
                        }
                    }
                }
            }
        } `
         | Format-PingTimes `
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
            Write-Host  "Removing jobs..."
            foreach ($job in $jobs) {Remove-Job $job -Force}
            write-host -foregroundcolor white -backgroundcolor black "Discarded $discarded_count pings."
        }
    }
}

function helper_find_pingable_com_host() {
    # discovers pingable IPs and prints a list of them with RTTs in the lower first quartile
    # it prints the IPs with lower RTTs first

    [char[]]' abcdefghijklmnopqrstuvwxyz' | %{
        $c1=$_
        [char[]]'abcdefghijklmnopqrstuvwxyz' | %{
            $c2=$_
            [char[]]'abcdefghijklmnopqrstuvwxyz' | %{
                $c3=$_
                $h="$c1$c2$c3.com".trim()
                Start-ThreadJob -ThrottleLimit 100 -ArgumentList $h -ScriptBlock {
                    ping -n 1 $args[0]
                }
            }
        }
    }

    $RTTs = @{}
    $low_RTT_IPs = @{}

    sleep 5
    while (($RTTs.count -lt (120*8)) -and (get-job  -State 'completed')) {
        sleep 10
        get-job  -State 'completed' | %{
            $out=(Receive-Job -id $_.id)
            if (!($out -like 'Ping statistics for 127.*') -and ($out -like '*Received = 1*') -and ($out -like '*Minimum*')) {
                $ip = ($out | sls 'Pinging').line -replace '^.*\[' -replace '].*'
                $RTT = [int](($out | sls Minimum).line -replace '^.*= ' -replace 'ms')
                $RTTs[$ip] = $RTT
                #echo $ip
            }
            remove-job -id $_.id
        }
        # 25% percentile of RTTs
        $RTT_p25 = ($RTTs.Values | sort | select -First ([int]($RTTs.count/4)) | select -last 1)

        $low_RTT_IPs = ($RTTs.keys | ? {$RTTs[$_] -lt $avg_RTT})
        echo "Found $($RTTs.keys.count) IPs, 1/4 of them have RTT <= $RTT_p25 ms"
    }

    get-job | Remove-Job -force

    $line=''; $cnt=0;
    $RTTs.keys | ? {$RTTs[$_] -le $RTT_p25} | %{
        [PSCustomObject]@{ ip = $_; RTT = $RTTs[$_] }
    } | sort -Property RTT | %{
        $ip = $_.ip
        $line +=  "'$ip',"
        $cnt+=1
        if ($cnt % 8 -eq 0) {
            $line = "@($line)" -replace ',\)','),'
            echo "$line"
            $line=''
        }
    }
}

if (!(Get-Module ThreadJob -list)) {
    echo "Please install ThreadJob module by issuing this command with admin priviledges:`nInstall-Module -Name ThreadJob"
} else {
    # $args_json = (($args | ConvertTo-Json ) -replace '\r\n',' ')
    Out-PingStats @args
}
