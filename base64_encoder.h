#pragma once

extern "C"
{
	unsigned long base64_encode(const char* plain_input, const unsigned long input_len, char* encoded_output, const unsigned long output_size);
	unsigned long base64_decode(const char* encoded_input, const unsigned long input_len, char* plain_output, const unsigned long output_size);
}