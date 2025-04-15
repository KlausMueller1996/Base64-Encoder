#include <stdint.h>	// uint8_t
#include <string.h> // strlen, strcmp
#include <assert.h> // assert

#include <string>
#include <array>

#include "base64_encoder.h"


int main(void) 
{
	constexpr size_t MAX_INDEX = 9;

	std::array<std::string, MAX_INDEX> plain = {
		"Pol",
		"AAA",
		"Polyfon zwitschernd aßen Mäxchens Vögel Rüben, Joghurt und Quark",
		"Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam",
		"light work.",
		"light work",
		"light wor",
		"light wo",
		"light w"
	};

	std::array<std::string, MAX_INDEX> encoded = {
		"UG9s",
		"QUFB",
		"UG9seWZvbiB6d2l0c2NoZXJuZCBh32VuIE3keGNoZW5zIFb2Z2VsIFL8YmVuLCBKb2dodXJ0IHVuZCBRdWFyaw==",
		"TG9yZW0gaXBzdW0gZG9sb3Igc2l0IGFtZXQsIGNvbnNldGV0dXIgc2FkaXBzY2luZyBlbGl0ciwgc2VkIGRpYW0gbm9udW15IGVpcm1vZCB0ZW1wb3IgaW52aWR1bnQgdXQgbGFib3JlIGV0IGRvbG9yZSBtYWduYSBhbGlxdXlhbQ==",
		"bGlnaHQgd29yay4=",
		"bGlnaHQgd29yaw==",
		"bGlnaHQgd29y",
		"bGlnaHQgd28=",
		"bGlnaHQgdw=="
	};

	for (int i = 0; i < MAX_INDEX; i++)
	{
		std::string result(200, 0x00);

		const auto rc_enc = base64_encode(plain[i].data(), static_cast<unsigned long>(plain[i].size()), (char*) result.data(), static_cast<unsigned long>(result.size()));
		assert(rc_enc > 0);
		result.resize(rc_enc);

		assert(encoded[i].compare(result)==0);
	}

	for (int i = 0; i < MAX_INDEX; i++)
	{
		std::string result(200, 0x00);

		const auto rc_dec = base64_decode(encoded[i].data(), static_cast<unsigned long>(encoded[i].size()), (char*) result.data(), static_cast<unsigned long>(result.size()));
		assert(rc_dec > 0);
		result.resize(rc_dec);

		const int cmp = plain[i].compare(result);
		assert(plain[i].compare(result) == 0);
	}

	{
		std::string encoded = "TWFu";
		std::string plain(4, 0x00);

		assert(0 == base64_decode(NULL, static_cast<unsigned long>(encoded.size()), (char*) plain.data(), static_cast<unsigned long>(plain.size())));
		assert(0 == base64_decode(encoded.data(), NULL, (char*) plain.data(), static_cast<unsigned long>(plain.size())));
		assert(0 == base64_decode(encoded.data(), static_cast<unsigned long>(encoded.size()), NULL, static_cast<unsigned long>(plain.size())));
		assert(0 == base64_decode(encoded.data(), static_cast<unsigned long>(encoded.size()), (char*) plain.data(), NULL));

		assert(3 == base64_decode(encoded.data(), static_cast<unsigned long>(encoded.size()), (char*) plain.data(), static_cast<unsigned long>(plain.size())));
		
		plain.assign(3, 0x00);
		assert(0 == base64_decode(encoded.data(), static_cast<unsigned long>(encoded.size()), (char*) plain.data(), static_cast<unsigned long>(plain.size())));

		plain.assign(2, 0x00);
		assert(0 == base64_decode(encoded.data(), static_cast<unsigned long>(encoded.size()), (char*) plain.data(), static_cast<unsigned long>(plain.size())));

		plain.assign(1, 0x00);
		assert(0 == base64_decode(encoded.data(), static_cast<unsigned long>(encoded.size()), (char*) plain.data(), static_cast<unsigned long>(plain.size())));
	}
}