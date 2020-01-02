# PGP keys map

[pgpverify-maven-plugin](https://github.com/s4u/pgpverify-maven-plugin) provides a mechanism for verifying (un)signed maven artifacts using a map of PGP public keys. This is a public repository of PGP public key fingerprints as discovered in the public Maven repository.

## Trust by consensus (reproducibility)

The _keysmap_ repository is constructed in such a way that multiple builds produce the byte-exact same `pgp-keys.map` file.

__Trust by consensus__: builds from multiple independent locations do indeed produce the exact same `pgp-keys.map` file. As part of certifying the content, one needs only to provide his signature (as a sign of approval) of a local build. Once sufficient signatures are committed, an automated CI build performs the same operations and should be able to validate `pgp-keys.map` with all given signatures.

Properties:
- `artifacts.txt`: source list of artifacts to include in the keysmap.
- `artifact-metadata`: source of (downloaded) metadata. Persisting this data locally ensures that there is a stable set of input data, ensuring reproducibility.
- `artifact-signatures`: signatures of all artifact versions, downloaded from the Maven repository.  
  It is assumed that signatures do not disappear over time, hence will not affect reproducibility.
- `keyring`: the local PGP keystore in which downloaded public keys are stored.  
  It is assumed that public keys do not disappear over time, hence will not affect reproducibility.

## Usage

Validate keysmap by constructing a `pgp-keys.map` then validating using all signatures in `signatures`.

```
git clone https://github.com/cobratbq/pgp-keys.git
git submodule init
git submodule update
make validate
```

Validation will fail in case of insufficient signatures.

## Design

Plan for PGP keys map maintenance/validation: trust based on consensus of independent parties generating and signing the byte-exact `pgp-keys.map`.

```
                                         /- pgp-public-keys-cache --\
artifact-list --> artifact-metadata-cache --> artifact-signatures --> pgp-keys.map --> validate
```

## TODO

- Makefile needs to take into account deleted entries in `artifacts.txt` and if so, remove metadata files no longer present.
- Makefile needs to take into account deleted metadata when generating/refreshing `artifact-signatures`.
- Investigate if we can intelligently skip (re)downloading PGP public keys on every run.
- `artifact-metadata/checksum` based on `artifacts.txt` is not correct, because on-line metadata changes over time independent of this artifact list.
- `artifact-signatures/checksum` to be based on all artifact metadata?
- Canonicalize `pgp-keys.map`:
  - _Assumption_: groupID may be shared by multiple independent developers (`org.apache.maven.plugins`, `org.codehaus.mojo`) therefore we cannot blindly group multiple signatures under one groupID.
  - _Reduction_: version range for all artifacts with subsequent version that use the same fingerprint.
  - _Reduction_: artifactID-wildcard if (all versions of) all artifacts of a single group use the same fingerprint.  
  _This may hold for wild-carded version specifier, or version-range specifier, or specific version, as long as this holds for all artifacts._
  - Add final entries in list for undefined version of artifact with fingerprint used in most recent version to facilitate future versions.
- Add ability to verify downloaded signatures against the actual artifacts.
