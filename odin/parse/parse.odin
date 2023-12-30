package main

import "core:fmt"
import "core:io"
import "core:strings"
import "core:unicode/utf8"

Parser :: struct {
	reader: strings.Reader,
	last_read_length: i64,
	failed: bool,
	error: string
}

ParserError :: union { string, io.Error }

Number :: int
Operator :: rune
Token :: union { Number, Operator }

make_parser :: proc(input: string) -> ^Parser {
  p := new(Parser)
	strings.reader_init(&p.reader, input)
	return p
}

Chars :: distinct bit_set['\x00'..<utf8.RUNE_SELF; u128]

is_whitespace :: proc(c: rune) -> bool {
	return c == ' '
}

peek :: proc(parser: ^Parser) -> (rune, ParserError) {
	parser.last_read_length = 0

	for {
		c, size, err := strings.reader_read_rune(&parser.reader)
		if err != nil {
			return 0, err
		}

		parser.last_read_length += cast(i64)size

		if !is_whitespace(c) {
			// unread the peeked bytes
			strings.reader_seek(&parser.reader, -parser.last_read_length, .Current)
			return c, nil
		}
	}
}

advance :: proc(parser: ^Parser) {
	if parser.last_read_length > 0 {
		strings.reader_seek(&parser.reader, parser.last_read_length, .Current)
		parser.last_read_length = 0
	} else {
		panic("cannot advance")
	}
}

digit :: proc(parser: ^Parser) -> (n: int, err: ParserError) {
	c := peek(parser) or_return
	if c >= '0' && c <= '9' {
		advance(parser)
		return cast(int)(c - '0'), nil
	}

	return 0, "expected digit between 0 and 9"
}

one_or_more :: proc($T: typeid, fn: proc(^Parser) -> (T, ParserError), parser: ^Parser) -> ([]T, ParserError) {
	acc := make([dynamic]T)
	for {
		if result, err := fn(parser); err == nil {
			append(&acc, result)
		} else {
			break
		}
	}

	if len(acc) > 0 {
		return acc[:], nil
	}

	return nil, "expected one or more"
}


seq :: proc($T: typeid, parser: ^Parser, fns: ..proc(^Parser) -> (T, ParserError)) -> ([]T, ParserError) {
	acc := make([dynamic]T)

	for fn in fns {
		result, err := fn(parser)
		if err != nil {
			return nil, err
		}
		append(&acc, result)
	}

	return acc[:], nil
}

number :: proc(parser: ^Parser) -> (token: Token, err: ParserError) {
	digits := one_or_more(int, digit, parser) or_return

	num : Number = 0
	for d in digits {
		num *= 10
		num += d
	}

	return num, nil
}

operator :: proc(parser: ^Parser) -> (t: Token, err: ParserError) {
	operators :: Chars{'+', '-', '*', '/'}
	c := peek(parser) or_return
	if c in operators {
		advance(parser)
		return c, nil
	}

	return nil, "expected operator"
}

run_calc :: proc(a: Number, op: Operator, b: Number) -> int {
	switch op {
	case '+':
		return a+b
	case '-':
		return a-b
	case '*':
		return a*b
	case '/':
		return a/b
	}

	panic("impossible!")
}

calc :: proc(input: string) {
	parser := make_parser(input)

	if tokens, err := seq(Token, parser, number, operator, number); err == nil {
		a := tokens[0].(Number)
		op := tokens[1].(Operator)
		b := tokens[2].(Number)
		result := run_calc(a, op, b)
		fmt.printf("%d %c %d = %d\n", a, op, b, result)
	} else {
		fmt.println(err)
	}
}

main :: proc() {
	input := "2 + 3"
	calc(input)
}
