PROJECT ?= $(HOME)/Desktop/Oud_SmartShop/smartshoplist_v140
.PHONY: publish url
publish:
	@tools/fix_pages_and_redeploy.sh
url:
	@remote=$$(git remote get-url origin); python3 - "$$remote" <<'PY'
import sys,urllib.parse,subprocess,os
u=sys.argv[1].strip()
if u.startswith("git@"): o,r=u.split(":",1)[1].split("/",1)
else: p=urllib.parse.urlparse(u); o,r=p.path.lstrip("/").split("/",1)
if r.endswith(".git"): r=r[:-4]
root=f"https://{o}.github.io/" if r==f"{o}.github.io" else f"https://{o}.github.io/{r}/"
v=open("docs/version.txt").read().strip() if os.path.exists("docs/version.txt") else ""
print("root:", root); print("latest:", root+v+"/" if v else "(nog geen versie)")
PY
