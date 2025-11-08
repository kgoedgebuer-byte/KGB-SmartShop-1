SHELL := /bin/bash

.PHONY: publish publish-pwa

publish:
\t@bash tools/publish.sh

publish-pwa:
\t@bash tools/publish_pwa.sh
