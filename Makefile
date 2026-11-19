# Build release artifacts: make dist VERSION=2.0.0
VERSION ?= 2.0.0
NAME := gpu-serving-tuner
OUT := $(abspath ../../dist)

.PHONY: dist clean check

check:
	@for file in install.sh scripts/*.sh; do bash -n "$$file"; done
	@python3 -c "import ast, pathlib; [ast.parse(p.read_text()) for p in pathlib.Path('scripts').glob('*.py')]"
	@python3 -c "import csv; list(csv.DictReader(open('examples/table-schema.example.csv', newline='')))"
	@! grep -RInE --exclude-dir=.git --exclude=Makefile '(BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY|AKIA[0-9A-Z]{16}|/data_ssd|/Users/[^<]|(10|192\.168)\.[0-9]+\.[0-9]+\.[0-9]+)' .

dist: check
	mkdir -p $(OUT)
	rm -f $(OUT)/$(NAME)-$(VERSION).tar.gz $(OUT)/$(NAME)-$(VERSION).zip
	tar -czf $(OUT)/$(NAME)-$(VERSION).tar.gz -C .. --exclude='$(NAME)/.git' $(NAME)
	cd .. && zip -qr $(OUT)/$(NAME)-$(VERSION).zip $(NAME) -x '*/.DS_Store' '*/__pycache__/*' '*/.git/*'
	cd $(OUT) && shasum -a 256 $(NAME)-$(VERSION).tar.gz $(NAME)-$(VERSION).zip > SHA256SUMS.txt
	@echo "artifacts in $(OUT)"

clean:
	rm -f $(OUT)/$(NAME)-*.tar.gz $(OUT)/$(NAME)-*.zip $(OUT)/SHA256SUMS.txt
