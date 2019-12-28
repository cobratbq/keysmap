# PGP keys map

## Usage

`make validate` to verify pgp-keys.map with committed signatures.

## Design

Plan for PGP keys map maintenance/validation: trust based on consensus of independent parties generating and signing the byte-exact `pgp-keys.map`.

```
                                         /- pgp-public-keys-cache --\
artifact-list --> artifact-metadata-cache --> artifact-signatures --> pgp-keys.map --> validate
```

