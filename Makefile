export GNUPGHOME=keyring

.PHONY: validate
validate: pgp-keys.map signatures
	ls signatures | while read sigfile; do gpg --verify "signatures/$$sigfile" pgp-keys.map; done

signatures:
	mkdir -p signatures

pgp-keys.map: artifact-signatures keyring
	touch pgp-keys.map

.PHONY: keyring
keyring: keyring/pubring.kbx
	touch keyring

keyring/pubring.kbx: artifact-signatures 
	umask 0077 && mkdir -p keyring
	ls artifact-signatures | (while read sig; do go run ./tools/extract-keyid//main.go < "artifact-signatures/$$sig"; done) | sort | uniq | xargs gpg --recv-keys

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
	rm -rf artifact-signatures artifact-metadata signatures download-metadata download-signatures keyring

