
.PHONY: validate
validate: pgp-keys.map signatures
	ls signatures | while read sigfile; do gpg --verify "signatures/$$sigfile" pgp-keys.map; done

signatures:
	mkdir -p signatures

pgp-keys.map: artifact-signatures
	touch -r artifact-signatures pgp-keys.map

artifact-signatures: artifact-metadata
	mkdir -p artifact-signatures
	touch -r artifact-metadata artifact-signatures

artifact-metadata: artifacts.txt
	mkdir -p artifact-metadata
	touch -r artifacts.txt artifact-metadata

.PHONY: clean
clean:
	rm -f pgp-keys.map

.PHONY: distclean
distclean: clean
	# For distclean we also remove existing signatures, as we assume updated
	# metadata will produce an invalid (updated) pgp-keys.map anyways.
	rm -rf artifact-signatures artifact-metadata signatures

