package tokenizer

TokenKind :: enum {
  Invalid,
  EOF,

  Iden,
  StrLiteral,
  
  KeywordFunc,
}

Token :: struct {
  kind: TokenKind,
  value: string,
}