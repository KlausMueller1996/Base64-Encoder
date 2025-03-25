option casemap:none

.const
	
	; decoding_table using  
	;	ascii(+) as starting value 
	;	containg all chars in ascii order up to Z
	;	chars not used in encoding table have a value of 0FFh 
	; table has 50h entries

							; '+' has index 3E in encoding table 
	decoding_table			byte	 3Eh 
							; ',-;' are not in encoding table
							byte	0FFh, 0FFh, 0FFh
							; 'index of /' in encoding table
							byte	 3Fh				
							; index of '0-9' in encoding table
							byte	 34h, 035h, 036h, 037h, 038h, 039h, 3Ah, 3Bh, 3Ch, 3Dh	
							; ':;<=>?@' are not in encoding table. 
							; Padding char '=' is treated as invalid char as we do not need to continue decoding after a '=' in input stream
							byte	0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh
							; 'index of ''A'-'Z' in encoding table
							byte	 00h, 01h, 02h, 03h, 04h, 05h, 06h, 07h, 08h, 09h, 0Ah, 0Bh, 0Ch, 0Dh, 0Eh, 0Fh, 10h, 11h, 12h, 13h, 14h, 15h, 16h, 17h, 18h, 19h
							; '[\]^_`' are not in encoding table
							byte	0FFh, 0FFh, 0FFh, 0FFh, 0FFh, 0FFh 
							; index of 'a'-'z' in encoding table
							byte	 1Ah, 1Bh, 1Ch, 1Dh, 1Eh, 1Fh, 20h, 21h, 22h, 23h, 24h, 25h, 26h, 27h, 28h, 29h, 2Ah, 2Bh, 2Ch, 2Dh, 2Eh, 2Fh, 30h, 31h, 32h, 33h

.code

public reverse_lookup
public base64_decode

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 
	; arguments:
	;   rcx: char to be converted
	;
	; register usage:
	;   rbx: base pointer to conversion table
	;   
	; returns: 
	;	index of given char in base 64 encoding table
	;	0FFh in case of padding char '=' or non mappable character
	;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	reverse_lookup PROC

		push	rbx					; save rbx

		mov		rax, 0FFh			; initial return value

		sub		cl, '+'				; '+' is the lowest value char in the base 64 encoded table; chars below
		jc		unknown_character	; if carry is set, al was less then '+'

		cmp		cl, 4Fh				; we have 50 chars in the lookup_table, make sure we stay within this range
		ja		unknown_character

		; load char into rax and base adress of conversion table to rbx register
		mov		al, cl				
		lea		rbx, decoding_table
		xlat
	
unknown_character:

		pop		rbx
		ret

	reverse_lookup ENDP

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; 
	; arguments:
	;   rcx: pointer to input structure - there should be 4 bytes available
	;   rdx: input_len: Anzahl der zu konvertierenden Zeichen 
	;        muss ein vielfaches der Zahl 4 sein
	;   r8:  pointer to output structure
	;   r9:  number of elements in output buffer
	;
	; register usage:
	;	rax: calculations
	;	rcx: passing params to reverse_lookup
	;	rdx: temporary storage of tuple[0] and tuple[2]
	;   rsi: pointer to input structure
	;   rdi: pointer to output structure
	;   r12: input_ctr
	;   r13: input_len
	;   r14: output_ctr
	;   
	; returns: 
	;	size of return string including trailing zero 
	; 
	; algorithm:
	;	void base64_decode(const char* input, const int input_len, uint8_t* output, const int output_len) {
	;	  int out_ctr = 0;
	;	  int in_ctr = 0;
	;	
 	;	  while (in_ctr < input_len) {
	;		char tuple[4] = { 0 };
	;	
	;		tuple[0] = reverse_lookup(input[in_ctr++]);
	;		tuple[1] = reverse_lookup(input[in_ctr++]);
	;		tuple[2] = reverse_lookup(input[in_ctr++]);
	;		tuple[3] = reverse_lookup(input[in_ctr++]);
	;	
	;		if ( tuple[0] == -1)
	;			break;
	;		if ( tuple[1] == -1)
	;			break;
	;
	;		output[out_ctr++] = (uint8_t)(tuple[0] << 2) + (uint8_t)(tuple[1] >> 4);
	;
	;		if ( tuple[2] == -1)
	;			break;
	;
	;		output[out_ctr++] = (uint8_t)(tuple[1] << 4) + (uint8_t)(tuple[2] >> 2);
	;
	;		if ( tuple[3] == -1)
	;			break;
	;
	;		output[out_ctr++] = (uint8_t)(tuple[2] << 6) + (uint8_t)(tuple[3]);
	;	  }
	;	  output[out_ctr] = 0x00;
	;     return out_ctr;
	;  }
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	base64_decode PROC

		push	rsi
		push	rdi
		push	r12
		push	r13
		push	r14

		mov		rsi, rcx
		mov		rdi, r8
		mov		r12, 0
		mov		r13, rdx
		mov		r14, 0

input_loop:

		mov		edx, dword ptr[rsi+r12]		; load 4 input bytes into edx [input+3] [input+2] [input+1] [input]

				;	tuple[0] = reverse_lookup(input[in_ctr++]);
		mov		cl, dl
		call	reverse_lookup

				;	if ( tuple[0] == -1) return;
		cmp		al, 0FFh
		jz		add_zero_and_leave

		mov		dl, al						; store conversion result in edx register, overwriting the input value
											; ebx = [input+3] [input+2] [input+1] [tuple_0]

				;	tuple[1] = reverse_lookup(input[in_ctr++]);
		mov		cl, dh
		call	reverse_lookup

				;	if ( tuple[1] == -1) return;
		cmp		al, 0FFh
		jz		add_zero_and_leave			; al = tuple[1]

		mov		dh, al						; store conversion result in edx register, overwriting the input value
											; edx = [input+3] [input+2] [tuple_1] [tuple_0]

		mov		cl, dl						; al = tuple[1] ; cl = tuple[0]

				;	output[out_ctr++] = (uint8_t)(tuple[0] << 2) + (uint8_t)(tuple[1] >> 4);
		shl		cl, 2
		shr		al, 4
		add		al, cl
		mov		byte ptr [rdi + r14], al
		inc		r14

		shr		edx, 8						; edx = [00000000] [input+3] [input+2] [tuple_1]

		mov		cl, dh				
		call	reverse_lookup

				; if (tuple[2] == -1) break
		cmp		al, 0FFh
		jz		add_zero_and_leave			; al = [tuple_2]

		mov		dh, al						; edx = [00000000] [input+3] [tuple_2] [tuple_1]

				;	output[out_ctr++] = (uint8_t)(tuple[1] << 4) + (uint8_t)(tuple[2] >> 2);
											
		shl		dl, 4
		shr		al, 2
		add		al, dl
		mov		byte ptr [rdi + r14], al
		inc		r14

		shr		edx, 8						; edx = [00000000] [00000000] [input+3] [tuple_2] 

				;	al = tuple[3] = reverse_lookup(input[in_ctr++]);
		mov		cl, dh 				
		call	reverse_lookup

				; if (tuple[3] == -1) break
		cmp		al, 0FFh
		jz		add_zero_and_leave			; al = tuple[3]

				;	output[out_ctr++] = (uint8_t)(tuple[2] << 6) + (uint8_t)(tuple[3]);
		shl		dl, 6
		add		al, dl
		mov		byte ptr [rdi + r14], al
		inc		r14

		add		r12, 4
		cmp		r12, r13		
		jb		input_loop

add_zero_and_leave:

				;	  output[out_ctr] = 0x00
		mov		byte ptr [rdi + r14], 0

				;     return out_ctr;
		mov		rax, r14

		pop		r14
		pop		r13
		pop		r12
		pop		rdi
		pop		rsi

		ret

	base64_decode ENDP

END