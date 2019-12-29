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
	switch key := pkt.(type) {
	case *packet.PublicKey:
		os.Stdout.WriteString(fmt.Sprintf("0x%040x", key.Fingerprint))
	case *packet.PublicKeyV3:
		os.Stdout.WriteString(fmt.Sprintf("0x%040x", key.Fingerprint))
	default:
		panic(fmt.Sprintf("Unsupported type: %#v", key))
	}
}

func expectSuccess(err error) {
	if err != nil {
		panic(err.Error())
	}
}
