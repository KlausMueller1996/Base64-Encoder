#include <stdint.h>	// uint8_t
#include <string.h> // strlen, strcmp
#include <assert.h> // assert

extern "C"
{
	uint8_t reverse_lookup(const char value_to_find);
	void base64_decode(const char* encoded, const size_t input_len, char* output, const size_t output_size);
	void base64_encode(const char* input, const size_t input_len, char* output, const size_t output_size); 
};


void test_reverse_lookup()
{
	const char conversion_table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	for (int i = 0; i < 64; i++)
	{
		assert(i == reverse_lookup(conversion_table[i]));
	}
}

int main(void) 
{
	test_reverse_lookup();

	const char* plain = "Polyfon zwitschernd aßen Mäxchens Vögel Rüben, Joghurt und Quark";
	const char* encoded = "UG9seWZvbiB6d2l0c2NoZXJuZCBh32VuIE3keGNoZW5zIFb2Z2VsIFL8YmVuLCBKb2dodXJ0IHVuZCBRdWFyaw==";
	char result[100]{ 0 };

	base64_encode(plain, ::strlen(plain), result, 100);
	assert(::strcmp(encoded, (char*)result) == 0);

 	base64_decode(encoded, ::strlen(encoded), result, 100);
 	assert(::strcmp(plain, (char *)result)==0);
}
