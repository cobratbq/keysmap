# Base variables.
KEYSERVER=keyserver.ubuntu.com
KEYRING=./keyring.kbx
SHA256SUM=tools/sha256sum
MAKEFLAGS += --no-builtin-rules

# Composite variables.
# Note: these variables should not be modified, unless the process fundamentally changes.
GNUPG_LOCAL=gpg --no-options --no-default-keyring --keyring $(KEYRING) --keyserver $(KEYSERVER)

.SUFFIXES:

.PHONY: validate
validate: pgp-keys.map
	@mkdir -p signatures
	@test $$(find signatures -name '*.asc' | wc -l) -ge 2 || (echo "ERROR: at least 2 signatures are required."; exit 1)
	find signatures -type f -exec gpg --verify "{}" pgp-keys.map \;

pgp-keys.map: tools/canonicalize-keysmap pgp-keys-generated.txt pgp-keys-manual.txt
	cat pgp-keys-manual.txt pgp-keys-generated.txt | tools/canonicalize-keysmap > pgp-keys.map

pgp-keys-generated.txt: tools/extract-keyid tools/extract-fingerprint artifact-signatures/checksum $(KEYRING)
	(find artifact-signatures -maxdepth 1 -type f -name '*.asc' -empty -exec sh -c 'echo $$(basename "{}" .asc) =' \; ; \
		find artifact-signatures -maxdepth 1 -type f -name '*.asc' ! -empty \
		-exec sh -c 'tools/extract-keyid < "{}" | xargs $(GNUPG_LOCAL) -a --export | tools/extract-fingerprint | xargs echo "$$(basename "{}" .asc) ="' \; \
		) > pgp-keys-generated.txt

$(KEYRING): tools/extract-keyid artifact-signatures/checksum
	find artifact-signatures -type f -name '*.asc' -exec sh -c 'tools/extract-keyid < "{}"' \; | sort | uniq | \
		while read key; do $(GNUPG_LOCAL) -k "$$key" > /dev/null 2>&1 || echo "$$key"; done | xargs $(GNUPG_LOCAL) --recv-keys; echo -n
	touch $(KEYRING)

artifact-signatures/checksum: tools/download-signatures artifact-metadata/checksum
	$(SHA256SUM) -b artifact-metadata/* | $(SHA256SUM) --quiet -c artifact-signatures/checksum || (\
		find artifact-metadata -type f -name '*.xml' -exec sh -c 'tools/download-signatures -d artifact-signatures < "{}"' \; && \
		$(SHA256SUM) -b artifact-metadata/* | $(SHA256SUM) -b - > artifact-signatures/checksum)

artifact-metadata/checksum: tools/download-metadata artifacts.txt
	$(SHA256SUM) --quiet -c artifact-metadata/checksum || (\
		tools/download-metadata -d artifact-metadata < artifacts.txt && \
		$(SHA256SUM) -b artifacts.txt > artifact-metadata/checksum)

tools/sha256sum tools/download-metadata tools/download-signatures tools/extract-keyid tools/extract-fingerprint tools/canonicalize-keysmap:
	$(MAKE) -C tools all

# For 'distclean' we also remove existing signatures. It is assumed that updated
# metadata will produce an updated pgp-keys.map anyways.
.PHONY: distclean
distclean: clean
	rm -rf artifact-metadata/checksum artifact-signatures/checksum signatures $(KEYRING){,~}
	$(MAKE) -C tools clean

.PHONY: clean
clean:
	rm -rf pgp-keys.map pgp-keys-generated.txt

