package tokenizer

TokenKind :: enum {
  Invalid,

  Iden,
  StrLiteral,
  
  OpenParen,
  CloseParen,
  OpenBracket,
  CloseBracket,
  OpenBrace,
  CloseBrace,
  Colon,
  SemiColon,
  Comma,
  Period,
  At,
  Question,

  OpLessThan, // <
  OpLessEqual, // <=
  OpBinaryShiftLeft, // <<
  OpGreaterThan, // >
  OpGreaterEqual, // >=
  OpBinaryShiftRight, // >>
  OpPlus, // +
  OpPlusEqual, // +=
  OpIncrement, // ++
  OpMinus, // -
  OpMinusEqual, // -=
  OpDecrement, // --
  OpMultiply, // *
  OpMultiplyEqual, // *=
  OpDivide, // /
  OpDivideEqual, // /=
  OpModulo, // %
  OpModuloEqual, // %=
  OpAssign, // =
  OpEqual, // ==
  OpNot, // !
  OpNotEqual, // !=
  OpBinaryAnd, // &
  OpAnd, // &&
  OpBinaryOr, // |
  OpOr, // ||
  OpBinaryXOr, // ^
  OpBinaryComplement, // ~

  KeywordFunc,
}

Token :: struct {
  line: int,
  column: int,
  kind: TokenKind,
  value: string,
}