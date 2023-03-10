package tokenizer

import "../file"
import "core:os"
import "core:fmt"
import "core:slice"
import "core:unicode"
import "core:unicode/utf8"

Tokenizer :: struct {
  file: ^file.File,
  current_index: int,
  current_line: int,
  current_column: int,
}

err :: proc(self: ^Tokenizer, msg: string)  {
  fmt.printf("%s:%i:%i \x1b[31mERROR:\x1b[0m %s\n", self.file.path, self.current_line, self.current_column, msg)
  os.exit(-1)
}

new :: proc(file: ^file.File) -> Tokenizer {
	return Tokenizer { file = file, current_index = 0, current_column = 1, current_line = 1, }
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
// Returns 0 if there are no runes left in the file.
next_rune :: proc(self: ^Tokenizer) -> rune {
	if self.current_index >= slice.length(self.file.contents) {
		return 0
	}

  rune := utf8.rune_at(cast(string)self.file.contents, self.current_index)
	self.current_index += utf8.rune_size(rune)
  self.current_column += 1
  if rune == '\n' {
    self.current_line += 1
    self.current_column = 1
  }

	return rune
}

fall_back :: proc(self: ^Tokenizer, current: rune) -> rune {
  self.current_column -= 1
  self.current_index -= utf8.rune_size(current)
  
  return utf8.rune_at(cast(string)self.file.contents, self.current_index)
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
    case "end": return TokenKind.KeywordEnd
    case "export": return TokenKind.KeywordExport
    case "func": return TokenKind.KeywordFunc
    case "import": return TokenKind.KeywordImport
    case "using": return TokenKind.KeywordUsing
  }

  return TokenKind.Iden
}

lex_iden :: proc(self: ^Tokenizer) -> Token {
	start_index := self.current_index

	// assume that the first character is a valid identifier start
	// if !is_iden_start(peek_rune(self)) {
	// 	return ---,
	// }

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
	}
}

lex_string :: proc(self: ^Tokenizer) -> Token {
  start_index := self.current_index

	next_rune(self) // skips the opening quote

  for {
		rune := peek_rune(self)
		
		if rune == 0 || rune == '\n' {
      err(self, "String literal isn't terminated")			
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
	}
}

lex_char :: proc(self: ^Tokenizer) -> Token {
  start_index := self.current_index

	next_rune(self) // skips the opening quote

  count := 0
  for {
		rune := peek_rune(self)
		
		if rune == 0 || rune == '\n' {
      err(self, "Character literal isn't terminated")
		}

    if rune == '\\' {
			next_rune(self) // skip the backslash
    } 
		
		// if the character was an escape, this skips the character after the backslash as well
		next_rune(self)

    if rune == '\'' {
      break
    }

    count += 1
	}

  if count == 0 {
    err(self, "Character literal is empty")
  }

  if count > 1 {
    err(self, "Character contains more than one character")
  }

	return Token {
		kind = TokenKind.CharLiteral,
		value = cast(string)self.file.contents[start_index:self.current_index],
	}
}

lex_single_line_comment :: proc(self: ^Tokenizer) {
  for {
    rune := peek_rune(self)

    if rune == '\n' || rune == 0 {
      break
    }

    next_rune(self)
  }
}

lex_multi_line_comment :: proc(self: ^Tokenizer) {
  for {
    rune := peek_rune(self)

    if rune == '*' {
      rune = next_rune(self)

      if rune == '/' {
        break
      }
    } else if rune == 0 {
      break
    }

    next_rune(self)
  }
}

lex_symbol :: proc(self: ^Tokenizer) -> Token {
  start_index := self.current_index
  kind := TokenKind.Invalid

  rune := next_rune(self)
  switch(rune) {
    case '(': kind = TokenKind.OpenParen; break
    case ')': kind = TokenKind.CloseParen; break
    case '[': kind = TokenKind.OpenBracket; break
    case ']': kind = TokenKind.CloseBracket; break
    case '{': kind = TokenKind.OpenBrace; break
    case '}': kind = TokenKind.CloseBrace; break
    case ':': kind = TokenKind.Colon; break
    case ';': kind = TokenKind.SemiColon; break
    case ',': kind = TokenKind.Comma; break
    case '.': kind = TokenKind.Period; break
    case '@': kind = TokenKind.At; break
    case '?': kind = TokenKind.Question; break
    case '<':
      kind = TokenKind.OpLessThan
      op_rune := next_rune(self)
      switch (op_rune) {
        // <=
        case '=': kind = TokenKind.OpLessEqual; break
        // <<
        case '<': kind = TokenKind.OpBinaryShiftLeft; break
        case: fall_back(self, op_rune)
      }
      break
    case '>':
      kind = TokenKind.OpGreaterThan
      op_rune := next_rune(self)
      switch (op_rune) {
        // >=
        case '=': kind = TokenKind.OpGreaterEqual; break
        // >>
        case '>': kind = TokenKind.OpBinaryShiftRight; break
        case 0: break
        case: fall_back(self, op_rune)
      }
      break
    case '+':
      kind = TokenKind.OpPlus
      op_rune := next_rune(self)
      switch (op_rune) {
        // +=
        case '=': kind = TokenKind.OpPlusEqual; break
        // ++
        case '+': kind = TokenKind.OpIncrement; break
        case 0: break
        case: fall_back(self, op_rune)
      }
      break
    case '-':
      kind = TokenKind.OpMinus
      op_rune := next_rune(self)
      switch (op_rune) {
        // -=
        case '=': kind = TokenKind.OpMinusEqual; break
        // --
        case '-': kind = TokenKind.OpDecrement; break
        case 0: break
        case: fall_back(self, op_rune)
      }
      break
    case '*':
      kind = TokenKind.OpMultiply
      op_rune := next_rune(self)
      switch (op_rune) {
        // *=
        case '=': kind = TokenKind.OpMultiplyEqual; break
        case 0: break
        case: fall_back(self, op_rune)
      }
      break
    case '/':
      kind = TokenKind.OpDivide
      op_rune := next_rune(self)
      switch (op_rune) {
        // /=
        case '=': kind = TokenKind.OpDivideEqual; break
        // single line comment
        case '/': kind = TokenKind.Comment; lex_single_line_comment(self); break;
        // multi line comment
        case '*': kind = TokenKind.Comment; lex_multi_line_comment(self); break;
        case 0: break
        case: fall_back(self, op_rune)
      }
      break
    case '%':
      kind = TokenKind.OpModulo
      op_rune := next_rune(self)
      switch (op_rune) {
        // /=
        case '=': kind = TokenKind.OpModuloEqual; break
        case 0: break
        case: fall_back(self, op_rune)
      }
      break
    case '=':
      kind = TokenKind.OpAssign
      op_rune := next_rune(self)
      switch (op_rune) {
        // ==
        case '=': kind = TokenKind.OpEqual; break
        case 0: break
        case: fall_back(self, op_rune)
      }
      break
    case '!':
      kind = TokenKind.OpNot
      op_rune := next_rune(self)
      switch (op_rune) {
        // !=
        case '=': kind = TokenKind.OpNotEqual; break
        case 0: break
        case: fall_back(self, op_rune)
      }
      break
    case '&':
      kind = TokenKind.OpBinaryAnd
      op_rune := next_rune(self)
      switch (op_rune) {
        // &&
        case '&': kind = TokenKind.OpAnd; break
        case 0: break
        case: fall_back(self, op_rune)
      }
      break
    case '|':
      kind = TokenKind.OpBinaryOr
      op_rune := next_rune(self)
      switch (op_rune) {
        // ||
        case '|': kind = TokenKind.OpOr; break
        case 0: break
        case: fall_back(self, op_rune)
      }
      break
    case '^': kind = TokenKind.OpBinaryXOr; break
    case '~': kind = TokenKind.OpBinaryComplement; break
  }
  
  return Token {
		kind = kind,
		value = cast(string)self.file.contents[start_index:self.current_index],
	}
}

lex_hexadecimal :: proc(self: ^Tokenizer) {
  next_rune(self) // skips the 'x'

  count := 0
  for {
    rune := peek_rune(self)

    // check if the next digit is hexadecimal
    switch (rune) {
      case 'a': case 'b': case 'c': case 'd': case 'e': case 'f':
      case 'A': case 'B': case 'C': case 'D': case 'E': case 'F':
        count += 1
        break
      case:
        if !unicode.is_digit(rune) {
          if count == 0 {
            err(self, "Invalid token")
          }
          return
        }
    }

    next_rune(self)
  }
}

lex_exponent :: proc(self: ^Tokenizer) {
  next_rune(self) // skips the 'e'

  rune := peek_rune(self)

  // check whether the exponent is positive or negative
  if rune == '+' || rune == '-' {
    next_rune(self)

    count := 0
    for {
      rune = peek_rune(self)

      if !unicode.is_digit(rune) {
        if count == 0 {
          err(self, "Invalid token")
        }
        return
      }
      
      count += 1
      next_rune(self)
    }
  } else {
    err(self, "Invalid token")
  }
}

lex_floating :: proc(self: ^Tokenizer) {
  next_rune(self) // skips the '.'
  count := 0
  for {
    rune := peek_rune(self)

    count += 1

    if rune == 'e' || rune == 'E' {
      lex_exponent(self)
      return
    }

    if !unicode.is_digit(rune) {
      count -= 1
      if count == 0 {
        err(self, "Invalid token")
      }
      return
    }

    next_rune(self)
  }  
}

lex_number :: proc(self: ^Tokenizer) -> Token {
  start_index := self.current_index
  kind := TokenKind.IntegerLiteral

  for {
    rune := peek_rune(self)

    if rune == 'x' {
      lex_hexadecimal(self)
      break
    }
    
    if rune == '.' {
      kind = TokenKind.FloatingLiteral
      lex_floating(self)
      break
    }

    if !unicode.is_digit(rune) {
      break
    }

    next_rune(self)
  }

  return Token {
		kind = kind,
		value = cast(string)self.file.contents[start_index:self.current_index],
	}
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
		return ---, false
	}

  token: Token
  first_line := self.current_line
  first_column := self.current_column

  if is_iden_start(first_rune) {
		token = lex_iden(self)
  } else if first_rune == '"' {
		token = lex_string(self)
  } else if first_rune == '\'' {
		token = lex_char(self)
  } else if unicode.is_punct(first_rune) || unicode.is_symbol(first_rune) {
    token = lex_symbol(self)
  } else if unicode.is_digit(first_rune) {
    token = lex_number(self)
  } else {
		return ---, false
	}
	
	token.line = first_line
	token.column = first_column
	return token, true
}