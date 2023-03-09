package main

import "core:fmt"
import "core:os"
import "core:strings"

import "file"
import "tokenizer"

// Enable UTF-8 on Windows
enable_utf8 :: proc() {
	when ODIN_OS == .Windows {
		@(default_calling_convention = "std")
		foreign {
			@(link_name="SetConsoleOutputCP") set_console_output_cp :: proc(i32) ---
		}

		set_console_output_cp(65001) // enable utf-8 on windows
	}
}

main :: proc() {
	enable_utf8()

	f, errno := file.read("test.vi")

	if errno == 0 {
		defer file.close(&f)
		lexer := tokenizer.new(&f)

		token, is_valid := tokenizer.next_token(&lexer)

		for is_valid != false {
			fmt.printf("test.vi:%i:%i: %s: %s\n", token.line, token.column, token.kind, token.value)
			token, is_valid = tokenizer.next_token(&lexer)
		}
	}
}