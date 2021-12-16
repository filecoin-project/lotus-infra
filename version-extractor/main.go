package main

import "github.com/filecoin-project/lotus/build"
import "fmt"

func main() {
	fmt.Printf("%s\n", build.BuildVersion)
}
