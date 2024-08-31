package main

import (
	"flag"
	"fmt"

	"google.golang.org/protobuf/compiler/protogen"
	"google.golang.org/protobuf/types/pluginpb"
)

var showVersion = flag.Bool("version", false, "print the version and exit")

func main() {
	flag.Parse()
	if *showVersion {
		fmt.Printf("protoc-gen-go-errors %v\n", release)
		return
	}

	//// load test file
	//tempFile, err := os.OpenFile("./test/test.data", os.O_RDONLY, 0766)
	//if err != nil {
	//	fmt.Println("load test file failed:", err)
	//	return
	//}
	//defer func() { _ = tempFile.Close() }()
	//
	////replace test file as stdin
	//os.Stdin = tempFile

	var flags flag.FlagSet
	protogen.Options{
		ParamFunc: flags.Set,
	}.Run(func(gen *protogen.Plugin) error {
		gen.SupportedFeatures = uint64(pluginpb.CodeGeneratorResponse_FEATURE_PROTO3_OPTIONAL)
		for _, f := range gen.Files {
			if !f.Generate {
				continue
			}
			generateFile(gen, f)
		}
		return nil
	})
}
