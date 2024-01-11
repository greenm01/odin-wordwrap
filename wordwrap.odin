package wordwrap

import "core:bytes"
import "core:io"
import "core:strings"

NBSP :: 0xA0

// ported from https://github.com/mitchellh/go-wordwrap
// WrapString wraps the given string within lim width in characters.
// Wrapping is currently naive and only happens at white-space. A future
// version of the library will implement smarter wrapping. This means that
// pathological cases can dramatically reach past the limit, such as a very
// long word.
wrap_string :: proc(s: string, lim: uint) -> string {
	
	buf := new(bytes.Buffer)
	word_buf  := new(bytes.Buffer)
	space_buf := new(bytes.Buffer)
		
	defer bytes.buffer_destroy(buf)
	defer bytes.buffer_destroy(word_buf)
	defer bytes.buffer_destroy(space_buf)

	current: uint
	word_buf_len, space_buf_len: uint

	for char in s {
		if char == '\n' {
			if bytes.buffer_length(word_buf) == 0 {
				if current+space_buf_len > lim {
					current = 0
				} else {
					current += space_buf_len
					b := bytes.buffer_to_bytes(space_buf)
					bytes.buffer_write(buf, b)
				}
				bytes.buffer_reset(space_buf)
				space_buf_len = 0
			} else {
				current += space_buf_len + word_buf_len
				b := bytes.buffer_to_bytes(space_buf)
				bytes.buffer_write(buf, b)
				bytes.buffer_reset(space_buf)
				space_buf_len = 0
				b = bytes.buffer_to_bytes(word_buf)
				bytes.buffer_write(buf, b)
				bytes.buffer_reset(word_buf)
				word_buf_len = 0
			}
			bytes.buffer_write_rune(buf, char)
			current = 0
		} else if strings.is_space(char) && char != NBSP {
			if bytes.buffer_length(space_buf) == 0 || bytes.buffer_length(word_buf) > 0 {
				current += space_buf_len + word_buf_len
				b := bytes.buffer_to_bytes(space_buf)
				bytes.buffer_write(buf, b)
				bytes.buffer_reset(space_buf)
				space_buf_len = 0
				b = bytes.buffer_to_bytes(word_buf)
				bytes.buffer_write(buf, b)
				bytes.buffer_reset(word_buf)
				word_buf_len = 0
			}
			bytes.buffer_write_rune(space_buf, char)
			space_buf_len += 1
		} else {
			bytes.buffer_write_rune(word_buf, char)
			word_buf_len += 1

			if current+word_buf_len+space_buf_len > lim && word_buf_len < lim {
				bytes.buffer_write_rune(buf, '\n')
				current = 0
				bytes.buffer_reset(space_buf)
				space_buf_len = 0
			}
		}
	}

	if bytes.buffer_length(word_buf) == 0 {
		if current+space_buf_len <= lim {
			b := bytes.buffer_to_bytes(space_buf)
			bytes.buffer_write(buf, b) 
		}
	} else {
		b := bytes.buffer_to_bytes(space_buf)
		bytes.buffer_write(buf, b)
		b = bytes.buffer_to_bytes(word_buf)
		bytes.buffer_write(buf, b)
	}

	return strings.clone(bytes.buffer_to_string(buf))
}
