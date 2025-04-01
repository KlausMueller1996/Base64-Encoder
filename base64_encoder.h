#pragma once

extern "C"
{
	int base64_decode(const char* encoded, const size_t input_len, char* output, const size_t output_size);
	int base64_encode(const char* input, char* output);
}