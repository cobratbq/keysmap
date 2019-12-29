package main

import (
	"fmt"
	"os"

	"golang.org/x/crypto/openpgp/armor"
	"golang.org/x/crypto/openpgp/packet"
)

func main() {
	block, err := armor.Decode(os.Stdin)
	expectSuccess(err)
	pkt, err := packet.NewReader(block.Body).Next()
	expectSuccess(err)
	switch sig := pkt.(type) {
	case *packet.Signature:
		os.Stdout.WriteString(fmt.Sprintf("%0x\n", *sig.IssuerKeyId))
	case *packet.SignatureV3:
		os.Stdout.WriteString(fmt.Sprintf("%0x\n", sig.IssuerKeyId))
	default:
		panic(fmt.Sprintf("Unsupported type: %#v", sig))
	}
}

func expectSuccess(err error) {
	if err != nil {
		panic(err.Error())
	}
}
