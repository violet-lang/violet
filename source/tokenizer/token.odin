package tokenizer

TokenKind :: enum {
  Invalid,
  Comment,

  Iden,
  StrLiteral,
  CharLiteral,
  IntegerLiteral,
  FloatingLiteral,
  
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

  KeywordEnd,
  KeywordExport,
  KeywordFunc,
  KeywordImport,
  KeywordUsing,
}

Token :: struct {
  line: int,
  column: int,
  kind: TokenKind,
  value: string,
}