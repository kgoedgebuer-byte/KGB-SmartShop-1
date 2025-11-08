import os,re,time,sys
d=sys.argv[1]
p=os.path.join(d,"index.html")
s=open(p,"r",encoding="utf-8").read()
s=re.sub(r'(serviceWorkerVersion\s*:\s*)["\'][^"\']*["\']', r'\1null', s, flags=re.I)
s=re.sub(r'(const\s+serviceWorkerVersion\s*=\s*)["\'][^"\']*["\']\s*;', r'\1null;', s, flags=re.I)
ts=str(int(time.time()))
s=s.replace('src="flutter.js"', f'src="flutter.js?v={ts}"')
s=s.replace('src="flutter_bootstrap.js"', f'src="flutter_bootstrap.js?v={ts}"')
extra=("<script>(function(){try{if('serviceWorker'in navigator){navigator.serviceWorker.getRegistrations()"
       ".then(function(rs){rs.forEach(function(r){try{r.unregister()}catch(e){}})})}"
       "if(window.caches&&caches.keys){caches.keys().then(function(keys){keys.forEach(function(k){caches.delete(k)})})}"
       "}catch(e){}})();</script>")
s=re.sub(r"</body>", extra+"</body>", s, flags=re.I)
open(p,"w",encoding="utf-8").write(s)
for fn in ("flutter_service_worker.js","firebase-messaging-sw.js"):
    fp=os.path.join(d,fn)
    if os.path.exists(fp):
        try: os.remove(fp)
        except: pass
