export GNUPGHOME=keyring

.PHONY: validate
validate: pgp-keys.map
	@mkdir -p signatures
	@test $$(ls signatures | wc -l) -ge 2 || (echo "ERROR: at least 2 valid signatures are required."; exit 1)
	find signatures -type f -exec gpg --verify "{}" pgp-keys.map \;

pgp-keys.map: artifact-signatures keyring/pubring.kbx extract-keyid extract-fingerprint
	(find artifact-signatures -maxdepth 1 -type f -empty -exec sh -c 'echo $$(basename "{}" .asc) =' \; ; \
		find artifact-signatures -maxdepth 1 -type f ! -empty \
		-exec sh -c './extract-keyid < "{}" | xargs gpg -a --export | ./extract-fingerprint | xargs echo "$$(basename "{}" .asc) ="' \; \
		) | sort > pgp-keys.map

extract-fingerprint: tools/extract-fingerprint/*
	go build -o extract-fingerprint ./tools/extract-fingerprint

keyring/pubring.kbx: artifact-signatures extract-keyid
	umask 0077 && mkdir -p keyring
	find artifact-signatures -type f -exec sh -c './extract-keyid < "{}"' \; | sort | uniq | xargs gpg --recv-keys
	touch keyring/pubring.kbx

extract-keyid: tools/extract-keyid/*
	go build -o extract-keyid ./tools/extract-keyid

artifact-signatures: artifact-metadata download-signatures
	mkdir -p artifact-signatures
	find artifact-metadata -type f -iname '*.xml' -exec sh -c './download-signatures -d artifact-signatures < "{}"' \;
	touch artifact-signatures

artifact-metadata: artifact-metadata/completed
artifact-metadata/completed: artifacts.txt download-metadata
	mkdir -p artifact-metadata
	./download-metadata -d artifact-metadata < artifacts.txt
	touch artifact-metadata/completed

download-signatures: tools/download-signatures/*
	go build -o download-signatures ./tools/download-signatures

download-metadata: tools/download-metadata/*
	go build -o download-metadata ./tools/download-metadata

.PHONY: clean
clean:
	rm -rf artifact-signatures pgp-keys.map

.PHONY: distclean
distclean: clean
	# For distclean we also remove existing signatures, as we assume updated
	# metadata will produce an invalid (updated) pgp-keys.map anyways.
	rm -rf artifact-metadata signatures download-metadata download-signatures keyring extract-fingerprint extract-keyid

