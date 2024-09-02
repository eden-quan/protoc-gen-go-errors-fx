# Summary

`protoc-gen-go-errors-fx` 参考 `protoc-gen-go-errors`，并在其中增加了新的 Feature, 主要包括

1. 自动生成的 Error 函数中会包含业务状态码，便于统一管理错误；
2. 自动生成的 Error 函数中包含注释信息，因此可以统一在代码中错误说明；
3. (TODO) 自动生成的错误中会包含堆栈信息，因此调用方无需在错误上继续封装堆栈信息;
4. (TODO) 错误信息支持全球化

# Example
通过 `protocol buffer` 定义以下枚举

```protobuf

import "errors/errors.proto";
import "google/protobuf/descriptor.proto";

enum ErrorsCode {
  option (errors.default_code) = 500;

  STATUS_OK = 0 [(errors.code) = 0];  // 
  ARGS_INVALID = 10010001 [(errors.code) = 500];   // 参数错误
}

```

我们可以得到如下生成的代码

```go
package errorv1

import (
	fmt "fmt"
	errors "github.com/go-kratos/kratos/v2/errors"
)

// 参数错误
func ErrorArgsInvalid(format string, args ...interface{}) *errors.Error {
	err := errors.New(500, ErrorsCode_ARGS_INVALID.String(), fmt.Sprintf(format, args...))
	return err.WithMetadata(map[string]string {
        "BizCode": "10010001",
        "DefaultReason": "参数错误",
    })
}

```