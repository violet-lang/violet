package tokenizer

import "../file"
import "core:fmt"
import "core:slice"
import "core:unicode"
import "core:unicode/utf8"

Tokenizer :: struct {
  file: ^file.File,
  current_index: int,
}

new :: proc(file: ^file.File) -> Tokenizer {
	return Tokenizer { file = file, current_index = 0 }
}

// Returns the next rune without advancing the current index.
//
// Returns 0 if there is no runes left in the file.
peek_rune :: proc(self: ^Tokenizer) -> rune {
	if self.current_index >= slice.length(self.file.contents) {
		return 0
	}

	return utf8.rune_at(cast(string)self.file.contents, self.current_index)
}

// Returns the next rune and advances the current index.
//
// Returns 0 if there is no runes left in the file.
next_rune :: proc(self: ^Tokenizer) -> rune {
	if self.current_index >= slice.length(self.file.contents) {
		return 0
	}

  rune := utf8.rune_at(cast(string)self.file.contents, self.current_index)
	self.current_index += utf8.rune_size(rune)
	return rune
}

// Returns `true` if the character can start an identifier.
is_iden_start :: proc(c: rune) -> bool {
	return unicode.is_letter(c) || c == '_'
}

// Returns `true` if the character can continue an identifier.
is_iden_continue :: proc(c: rune) -> bool {
	return unicode.is_letter(c) || unicode.is_digit(c) || c == '_'
}

// Returns the appropriate TokenKind for the value, whether it is a keyword
// or identifier.
identifier_kind :: proc(value: string) -> TokenKind {
  switch (value) {
    case "func":
      return TokenKind.KeywordFunc
  }

  return TokenKind.Iden
}

lex_iden :: proc(self: ^Tokenizer) -> (Token, bool) {
	start_index := self.current_index

	if !is_iden_start(peek_rune(self)) {
		return ---, false
	}

	for {
		rune := peek_rune(self)
		
		if rune == 0 || !is_iden_continue(rune) {
			break
		}

		next_rune(self)
	}

  value := cast(string)self.file.contents[start_index:self.current_index]
	return Token {
		kind = identifier_kind(value),
		value = value,
	}, true
}

lex_string :: proc(self: ^Tokenizer) -> (Token, bool) {
  start_index := self.current_index

	next_rune(self) // skips the opening quote

  for {
		rune := peek_rune(self)
		
		if rune == 0 || rune == '\n' {
      // TODO: make error because end of string isn't found
			break
		}

    if rune == '\\' {
			next_rune(self) // skip the backslash
    } 
		
		// if the character was an escape, this skips the character after the backslash as well
		next_rune(self)

    if rune == '"' {
      break
    }
	}

	return Token {
		kind = TokenKind.StrLiteral,
		value = cast(string)self.file.contents[start_index:self.current_index],
	}, true
}

skip_white_space :: proc(self: ^Tokenizer) {
  for {
    if (unicode.is_white_space(peek_rune(self))) {
      next_rune(self)
    } else {
      return
    }
  }
}

next_token :: proc(self: ^Tokenizer) -> (Token, bool) {
  skip_white_space(self)

	first_rune := peek_rune(self)

	if first_rune == 0 {
		return Token { kind = TokenKind.EOF, value = "" }, false
	}

  if is_iden_start(first_rune) {
	  return lex_iden(self)
  }

  if first_rune == '"' {
    return lex_string(self)
  }

  return Token { kind = TokenKind.Invalid, value = "" }, false
}