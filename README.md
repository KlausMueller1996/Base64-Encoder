# Base 64 encoding

## how to build

You need to have Microsoft MASM and C++ Compiler installed.
If you have Visual Studio on your machine open a "x64 native Tools Command Prompt" and enter the following to commands

```
ml64 /c base64_encode.asm base64_decode.asm 
cl main.cpp base64_decode.obj base64_encode.obj
```

## how to  call

function signatures are:
```
void base64_decode(const char* encoded, const size_t input_len, char* output, const size_t output_size);
void base64_encode(const char* input, const size_t input_len, char* output, const size_t output_size); 
```

sample code is provided in main.c

## implementation details
The algorithm is described in detail at [Wikipedia](https://en.wikipedia.org/wiki/Base64). This implementation uses conversion table from [RFC 4648 §4](https://datatracker.ietf.org/doc/html/rfc4648#section-4). 

## remarks
This is my first study of written Assembly code fox x64 architecture. Feel free to comment and give fedback.
This code is testes on Windows 10 and 11, not sure if this also works on Linux?

## TODO

- [ ] ensure that no more than output_size bytes are written
- [ ] ensure that output ends with a 0x00