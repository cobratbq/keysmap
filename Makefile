ORIGINAL_GNUPGHOME=$(GNUPGHOME)
SHA256SUM=tools/sha256sum

.PHONY: validate
validate: GNUPGHOME := $(ORIGINAL_GNUPGHOME)
validate: pgp-keys.map
	@mkdir -p signatures
	@test $$(find signatures -name '*.asc' | wc -l) -ge 2 || (echo "ERROR: at least 2 signatures are required."; exit 1)
	find signatures -type f -exec gpg --verify "{}" pgp-keys.map \;

pgp-keys.map: GNUPGHOME := keyring
pgp-keys.map: tools artifact-signatures keyring/pubring.kbx
	(find artifact-signatures -maxdepth 1 -type f -name '*.asc' -empty -exec sh -c 'echo $$(basename "{}" .asc) =' \; ; \
		find artifact-signatures -maxdepth 1 -type f -name '*.asc' ! -empty \
		-exec sh -c 'tools/extract-keyid < "{}" | xargs gpg -a --export | tools/extract-fingerprint | xargs echo "$$(basename "{}" .asc) ="' \; \
		) | tee pgp-keys-raw.txt | tools/canonicalize-keysmap > pgp-keys.map

keyring/pubring.kbx: GNUPGHOME := keyring
keyring/pubring.kbx: tools artifact-signatures
	umask 0077 && mkdir -p keyring
	find artifact-signatures -type f -name '*.asc' -exec sh -c 'tools/extract-keyid < "{}"' \; | sort | uniq | \
		while read key; do gpg -k "$$key" > /dev/null 2>&1 || echo "$$key"; done | xargs gpg --recv-keys; echo -n

.PHONY: artifact-signatures
artifact-signatures: tools artifact-metadata
	mkdir -p artifact-signatures
	$(SHA256SUM) -b artifact-metadata/* | $(SHA256SUM) --quiet -c artifact-signatures/checksum || (\
		find artifact-metadata -type f -name '*.xml' -exec sh -c 'tools/download-signatures -d artifact-signatures < "{}"' \; && \
		$(SHA256SUM) -b artifact-metadata/* | $(SHA256SUM) -b - > artifact-signatures/checksum)

.PHONY: artifact-metadata
artifact-metadata: tools artifacts.txt
	mkdir -p artifact-metadata
	$(SHA256SUM) --quiet -c artifact-metadata/checksum || (\
		tools/download-metadata -d artifact-metadata < artifacts.txt && \
		$(SHA256SUM) -b artifacts.txt > artifact-metadata/checksum)

.PHONY: tools
tools:
	$(MAKE) -C tools all

.PHONY: clean
clean:
	rm -rf artifact-signatures pgp-keys.map

# For 'distclean' we also remove existing signatures. It is assumed that updated
# metadata will produce an updated pgp-keys.map anyways.
.PHONY: distclean
distclean: clean
	rm -rf artifact-metadata signatures keyring
	$(MAKE) -C tools clean

