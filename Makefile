export GNUPGHOME=keyring

.PHONY: validate
validate: pgp-keys.map
	@mkdir -p signatures
	@test $$(ls signatures | wc -l) -ge 2 || (echo "ERROR: at least 2 valid signatures are required."; exit 1)
	find signatures -type f -exec gpg --verify "{}" pgp-keys.map \;

pgp-keys.map: artifact-signatures keyring/pubring.kbx tools
	(find artifact-signatures -maxdepth 1 -type f -iname '*.asc' -empty -exec sh -c 'echo $$(basename "{}" .asc) =' \; ; \
		find artifact-signatures -maxdepth 1 -type f -iname '*.asc' ! -empty \
		-exec sh -c 'tools/extract-keyid < "{}" | xargs gpg -a --export | tools/extract-fingerprint | xargs echo "$$(basename "{}" .asc) ="' \; \
		) | sort > pgp-keys.map

keyring/pubring.kbx: artifact-signatures tools
	umask 0077 && mkdir -p keyring
	find artifact-signatures -type f -iname '*.asc' -exec sh -c 'tools/extract-keyid < "{}"' \; | sort | uniq | xargs gpg --recv-keys
	touch keyring/pubring.kbx

.PHONY: artifact-signatures
artifact-signatures: artifact-metadata tools
	mkdir -p artifact-signatures
	sha256sum --quiet -c artifact-signatures/checksum || (\
		find artifact-metadata -type f -iname '*.xml' -exec sh -c 'tools/download-signatures -d artifact-signatures < "{}"' \; && \
		sha256sum -b artifact-metadata/checksum > artifact-signatures/checksum)

.PHONY: artifact-metadata
artifact-metadata: artifacts.txt tools
	mkdir -p artifact-metadata
	sha256sum --quiet -c artifact-metadata/checksum || (\
		tools/download-metadata -d artifact-metadata < artifacts.txt && \
		sha256sum -b artifacts.txt > artifact-metadata/checksum)

.PHONY: tools
tools:
	$(MAKE) -C tools

.PHONY: clean
clean:
	rm -rf download-metadata download-signatures artifact-signatures extract-fingerprint extract-keyid pgp-keys.map

.PHONY: distclean
distclean: clean
	# For distclean we also remove existing signatures, as we assume updated
	# metadata will produce an invalid (updated) pgp-keys.map anyways.
	rm -rf artifact-metadata signatures keyring

