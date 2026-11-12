# Build release artifacts: make dist VERSION=1.0.0
VERSION ?= 1.2.0
NAME    := gpu-serving-tuner
OUT     := $(abspath ../../dist)

.PHONY: dist clean check

check:
	bash -n install.sh scripts/run-point.sh
	python3 -c "import ast; ast.parse(open('scripts/extract-metrics.py').read())"

dist: check
	mkdir -p $(OUT)
	rm -f $(OUT)/$(NAME)-$(VERSION).tar.gz $(OUT)/$(NAME)-$(VERSION).zip
	tar -czf $(OUT)/$(NAME)-$(VERSION).tar.gz -C .. --exclude='$(NAME)/.git' $(NAME)
	cd .. && zip -qr $(OUT)/$(NAME)-$(VERSION).zip $(NAME) -x '*/.DS_Store' '*/__pycache__/*' '*/.git/*'
	cd $(OUT) && shasum -a 256 $(NAME)-$(VERSION).tar.gz $(NAME)-$(VERSION).zip > SHA256SUMS.txt
	@echo "artifacts in $(OUT)"

clean:
	rm -f $(OUT)/$(NAME)-*.tar.gz $(OUT)/$(NAME)-*.zip $(OUT)/SHA256SUMS.txt
