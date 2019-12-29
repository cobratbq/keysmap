export GNUPGHOME=keyring

.PHONY: validate
validate: pgp-keys.map signatures
	@test $$(ls signatures | wc -l) -ge 2 || (echo "ERROR: requires at least 2 valid signatures."; exit 1)
	ls signatures | while read sigfile; do gpg --verify "signatures/$$sigfile" pgp-keys.map; done

signatures:
	mkdir -p signatures

pgp-keys.map: artifact-signatures keyring/pubring.kbx extract-keyid extract-fingerprint
	ls artifact-signatures | (while read sig; do (./extract-keyid < "artifact-signatures/$$sig") | xargs gpg -a --export | ./extract-fingerprint | xargs echo "$$(basename $$sig .asc) ="; done) > pgp-keys.map

extract-fingerprint: tools/extract-fingerprint/*
	go build -o extract-fingerprint ./tools/extract-fingerprint

keyring/pubring.kbx: artifact-signatures extract-keyid
	umask 0077 && mkdir -p keyring
	ls artifact-signatures | (while read sig; do ./extract-keyid < "artifact-signatures/$$sig"; done) | sort | uniq | xargs gpg --recv-keys
	touch keyring/pubring.kbx

extract-keyid: tools/extract-keyid/*
	go build -o extract-keyid ./tools/extract-keyid

artifact-signatures: artifact-metadata download-signatures
	mkdir -p artifact-signatures
	ls artifact-metadata | while read artifact; do ./download-signatures -d artifact-signatures < "artifact-metadata/$$artifact"; done
	touch artifact-signatures

artifact-metadata: artifacts.txt download-metadata
	mkdir -p artifact-metadata
	./download-metadata -d artifact-metadata < artifacts.txt
	touch artifact-metadata

download-signatures: tools/download-signatures/*
	go build -o download-signatures ./tools/download-signatures

download-metadata: tools/download-metadata/*
	go build -o download-metadata ./tools/download-metadata

.PHONY: clean
clean:
	rm -f pgp-keys.map

.PHONY: distclean
distclean: clean
	# For distclean we also remove existing signatures, as we assume updated
	# metadata will produce an invalid (updated) pgp-keys.map anyways.
	rm -rf artifact-signatures artifact-metadata signatures download-metadata download-signatures keyring extract-fingerprint extract-keyid

