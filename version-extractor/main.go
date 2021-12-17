package main

import (
	"fmt"

	"github.com/filecoin-project/lotus/build"
)

func main() {
	fmt.Printf("%s", build.BuildVersion)
}
