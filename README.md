# PGP keys map

[pgpverify-maven-plugin](https://github.com/s4u/pgpverify-maven-plugin) provides a mechanism for verifying (un)signed maven artifacts using a map of PGP public keys. This is a public repository of PGP public key fingerprints as discovered in the public Maven repository.

## Trust by consensus (reproducibility)

The _keysmap_ repository is constructed in such a way that multiple builds produce the byte-exact same `pgp-keys.map` file.

__Trust by consensus__: builds from multiple independent locations do indeed produce the exact same `pgp-keys.map` file. As part of certifying the content, one needs only to provide his signature (as a sign of approval) of a local build. Once sufficient signatures are committed, an automated CI build performs the same operations and should be able to validate `pgp-keys.map` with all given signatures.

__Mechanism__:

1. Check out `keysmap` repository locally, a specific branch if preparing for new release.
1. Run `make validate`. The validation itself may fail if insufficient signatures are available at present time.
1. Sign generated `pgp-keys.map`: `gpg -a --detach-sign -o "signatures/your-name.asc" pgp-keys.map`
1. Create PR containing `signatures/your-signature.asc`

__Properties__:

- `artifacts.txt`: source list of artifacts to include in the keysmap.
- `artifact-metadata`: source of (downloaded) metadata. Persisting this data locally ensures that there is a stable set of input data, ensuring reproducibility.
- `artifact-signatures`: signatures of all artifact versions, downloaded from the Maven repository.  
  It is assumed that signatures do not disappear over time, hence will not affect reproducibility.
- `keyring`: the local PGP keystore in which downloaded public keys are stored.  
  It is assumed that public keys do not disappear over time, hence will not affect reproducibility.

## Usage

Validate `pgp-keys.map` by generating the file and validating it using all signatures that can be found in `signatures`.

```
git submodule init
git submodule update
make validate
```

`make validate` may fail in case an insufficient number of signatures is found.

## Design

Plan for PGP keys map maintenance/validation: trust based on consensus of independent parties generating and signing the byte-exact `pgp-keys.map`.

```
                                         /- pgp-public-keys-cache --\
artifact-list --> artifact-metadata-cache --> artifact-signatures --> pgp-keys.map --> validate
```

## TODO

- Canonicalize `pgp-keys.map`:
  - _Assumption_: groupID may be shared by multiple independent developers (`org.apache.maven.plugins`, `org.codehaus.mojo`) therefore we cannot blindly group multiple signatures under one groupID.
  - _Reduction_: version range for all artifacts with subsequent version that use the same fingerprint.
  - _Reduction_: artifactID-wildcard if (all versions of) all artifacts of a single group use the same fingerprint.  
  _This may hold for wild-carded version specifier, or version-range specifier, or specific version, as long as this holds for all artifacts._
  - Add final entries in list for undefined version of artifact with fingerprint used in most recent version to facilitate future versions.
- Add ability to verify downloaded signatures against the actual artifacts.
- Currently assumes `jar`-type artifact. Check if this is an issue in cases with different packaging such as `war`, `ear`, etc.  
  _If needed to be discovered, download `pom` artifact first. Read _packaging type_ from the `pom` artifact, then download the appropriate signature file._
- Consider switching to downloading the tools (with `go install ...` or so) instead of building from submodule.
- Consider committing signatures as these should not change and there are *many* to download. Contributors could delete them and redownload them to verify that they correspond to the ones on the global maven repository.
