PROJECT ?= $(HOME)/Desktop/Oud_SmartShop/smartshoplist_v140

.PHONY: publish serve url

publish:
	git add -A
	git commit -m "publish" || true
	git push origin main

serve:
	python3 -m http.server 8080 --directory build/web & echo $$! > /tmp/web_8080.pid
	open -a "Safari" "http://127.0.0.1:8080/?ts=$$(date +%s)" || true
	open -a "Google Chrome" "http://127.0.0.1:8080/?ts=$$(date +%s)" || true

url:
	@remote=$$(git remote get-url origin); python3 - "$$remote" <<'PY'
import sys,urllib.parse
u=sys.argv[1].strip()
if u.startswith("git@"):
    owner,repo=u.split(":",1)[1].split("/",1)
else:
    p=urllib.parse.urlparse(u); owner,repo=p.path.lstrip("/").split("/",1)
if repo.endswith(".git"): repo=repo[:-4]
url=f"https://{owner}.github.io/" if repo==f"{owner}.github.io" else f"https://{owner}.github.io/{repo}/"
print(url)
PY
