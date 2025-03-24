#include <stdint.h>	// uint8_t
#include <string.h> // strlen, strcmp
#include <assert.h> // assert

#include <string>
#include <array>

extern "C"
{
	uint8_t reverse_lookup(const char value_to_find);
	size_t base64_decode(const char* encoded, const size_t input_len, char* output, const size_t output_size);
	size_t base64_encode(const char* input, const size_t input_len, char* output, const size_t output_size); 
};

void test_reverse_lookup()
{
	const char conversion_table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

	for (int i = 0; i < 64; i++)
	{
		assert(i == reverse_lookup(conversion_table[i]));
	}

	assert(reverse_lookup('*') == 255);
	assert(reverse_lookup(';') == 255);
	assert(reverse_lookup('?') == 255);
	assert(reverse_lookup('_') == 255);
	assert(reverse_lookup('{') == 255);
}

int main(void) 
{
	constexpr size_t MAX_INDEX = 3;

	test_reverse_lookup();

	std::array<std::string, MAX_INDEX> plain = {
		"Man",
		"Polyfon zwitschernd aßen Mäxchens Vögel Rüben, Joghurt und Quark", 
		"Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam"
	};

	std::array<std::string, MAX_INDEX> encoded = {
		"TWFu",
		"UG9seWZvbiB6d2l0c2NoZXJuZCBh32VuIE3keGNoZW5zIFb2Z2VsIFL8YmVuLCBKb2dodXJ0IHVuZCBRdWFyaw==",
		"TG9yZW0gaXBzdW0gZG9sb3Igc2l0IGFtZXQsIGNvbnNldGV0dXIgc2FkaXBzY2luZyBlbGl0ciwgc2VkIGRpYW0gbm9udW15IGVpcm1vZCB0ZW1wb3IgaW52aWR1bnQgdXQgbGFib3JlIGV0IGRvbG9yZSBtYWduYSBhbGlxdXlhbQ=="
	};

	for (int i = 0; i < MAX_INDEX; i++)
	{
		std::string result(200, 0x00);

		const size_t rc_enc = base64_encode(plain[i].c_str(), plain[i].size(), &(result[0]), result.size());
		result.resize(rc_enc);

		assert(encoded[i].compare(result) == 0);

		const size_t rc_dec = base64_decode(encoded[i].c_str(), encoded[i].size(), &(result[0]), result.size());
		result.resize(rc_dec);

		while (result.back() == 0x00)
		{
			result.pop_back();
		}
			

		assert(plain[i].compare(result) == 0);
	}
}
