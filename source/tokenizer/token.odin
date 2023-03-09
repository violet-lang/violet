package tokenizer

TokenKind :: enum {
  Invalid,
  EOF,

  Iden,
  StrLiteral,
  
  KeywordFunc,
}

Token :: struct {
  line: int,
  column: int,
  kind: TokenKind,
  value: string,
}