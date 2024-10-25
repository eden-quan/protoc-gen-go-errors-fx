var {{ .ErrorEnumName }}MessageMap = map[int32]string {
    {{- range .Errors }}
    {{ .BizCode}}: "{{.DefaultReason }}",
    {{- end }}
}

var {{ .ErrorEnumName }}HttpCodeMap = map[int32]int {
    {{- range .Errors }}
    {{ .BizCode}}: {{ .HTTPCode }},
    {{- end }}
}

func (e {{ .ErrorEnumName }}) stackTrace(skipFrame int) string {
	pc := make([]uintptr, 32)
	n := runtime.Callers(skipFrame, pc)
	pc = pc[:n]
	frames := runtime.CallersFrames(pc)
	msg := make([]string, 0, n)
	for {
		frame, more := frames.Next()
		funcName := frame.Function
		line := frame.Line
		file := frame.File
		msg = append(msg, fmt.Sprintf("\t%s:%d\n\t%s", file, line, funcName))
		if !more {
			break
		}
	}

	return strings.Join(msg, "\n")
}


func (e {{ .ErrorEnumName }}) toError(skipFrame int, msgFormat string, args ...interface{}) *errors.Error {
	err := errors.New({{ .ErrorEnumName }}HttpCodeMap[int32(e.Number())], e.String(), fmt.Sprintf(msgFormat, args...))
	innerErr := errors.New(int(err.Code), err.Reason, err.Message).WithMetadata(map[string]string{
		"BizCode":        strconv.Itoa(int(e.Number())),
		"DefaultMessage": {{ .ErrorEnumName }}MessageMap[int32(e.Number())],
		"__Stack":        e.stackTrace(skipFrame),
		"__MetaKey":      "__",
	})
	return err.WithCause(innerErr)
}


func (e {{ .ErrorEnumName }}) ToError(msgFormat string, args ...interface{}) *errors.Error {
	return e.toError(4, msgFormat, args...)
}

// FromErrorf generate error from err with extra info, if err is nil, mean's everything is fine, return nil
func (e {{ .ErrorEnumName }}) FromErrorf(err error, format string, args ...interface{}) *errors.Error {
	if err == nil {
		return nil
	}

	te := e.toError(4, format, args...)
    return te.WithCause(te.Unwrap().(*errors.Error).WithCause(err))
}

// FromError generate error from err with extra info, if err is nil, mean's everything is fine, return nil
func (e {{ .ErrorEnumName }}) FromError(err error) *errors.Error {
	if err == nil {
		return nil
	}

	te := e.toError(4, "")
    return te.WithCause(te.Unwrap().(*errors.Error).WithCause(err))
}

// FromOrToError generate error from err with extra info, if err is nil, generate new error
func (e {{ .ErrorEnumName }}) FromOrToError(err error) *errors.Error {
	if err == nil {
		return e.toError(4, "")
	}

	te := e.toError(4, "")
    return te.WithCause(te.Unwrap().(*errors.Error).WithCause(err))
}


func (e {{ .ErrorEnumName }}) DefaultMessage() string {
    return {{ .ErrorEnumName }}MessageMap[int32(e.Number())]
}

func (e {{ .ErrorEnumName }}) HttpCode() int {
    return {{ .ErrorEnumName }}HttpCodeMap[int32(e.Number())]
}


{{ range .Errors }}

{{ if .HasComment }}{{ .Comment }}{{ end -}}
func Is{{.CamelValue}}(err error) bool {
	if err == nil {
		return false
	}
	e := errors.FromError(err)
	return e.Reason == {{ .Name }}_{{ .Value }}.String() && e.Code == {{ .HTTPCode }}
}

{{ if .HasComment }}{{ .Comment }}{{ end -}}
func Error{{ .CamelValue }}(format string, args ...interface{}) *errors.Error {
     return {{ .Name }}_{{ .Value }}.toError(4, format, args...)
}

{{- end }}
