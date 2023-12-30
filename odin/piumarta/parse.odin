package main

import "core:fmt"
import "core:io"
import "core:strings"
import "core:unicode/utf8"

Parser :: struct {
	reader: strings.Reader,
	last_read_length: i64,
}

ParserError :: union { string, io.Error }

Char_Set :: distinct bit_set['\x00'..<utf8.RUNE_SELF; u128]
Upper_Alpha : Char_Set : {'A'}
Lower_Alpha : Char_Set : {'a'}
Digit : Char_Set : {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}

Number :: int
String :: struct { body: string }
UnaryMessage :: struct { name: string }

Token :: union { Number, String, UnaryMessage }


make_parser :: proc(input: string) -> ^Parser {
  p := new(Parser)
	strings.reader_init(&p.reader, input)
	return p
}


is_whitespace :: proc(c: rune) -> bool {
	return c == ' '
}

is_alpha :: proc(c: rune) -> bool {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

is_digit :: proc(c: rune) -> bool {
	return c >= '0' && c <= '9'
}

is_alpha_or_digit :: proc(c: rune) -> bool {
	return is_alpha(c) || is_digit(c)
}

peek :: proc(parser: ^Parser, skip_whitespace: bool = true) -> (rune, ParserError) {
	parser.last_read_length = 0

	for {
		c, size, err := strings.reader_read_rune(&parser.reader)
		if err != nil {
			return 0, err
		}

		parser.last_read_length += cast(i64)size

		if !skip_whitespace || !is_whitespace(c) {
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

char :: proc(p: ^Parser, expected: rune) -> (c: rune, err: ParserError) {
	c = peek(p) or_return
	if c == expected {
		advance(p)
		return c, nil
	}

	return c, fmt.tprintf("character '%v'", expected)
}

until_char :: proc(p: ^Parser, terminator: rune) -> (s: string, err: ParserError) {
	sb := strings.builder_make_none()

	for {
		c := peek(p, false) or_return
		if c != terminator {
			strings.write_rune(&sb, c)
			advance(p)
		} else {
			break
		}
	}

	return strings.to_string(sb), nil
}

string_literal :: proc(p: ^Parser) -> (t: Token, err: ParserError) {
	char(p, '"') or_return
	body := until_char(p, '"') or_return
	char(p, '"') or_return

	return String{ body }, err
}

one_of :: proc(p: ^Parser, cond: proc(rune) -> bool) -> (c: rune, err: ParserError) {
	c = peek(p) or_return
	if cond(c) {
		advance(p)
		return c, nil
	}

	return 0, "expected one_of"
}


identifier :: proc(p: ^Parser) -> (t: string, err: ParserError) {
	sb := strings.builder_make_none()
	start := one_of(p, is_alpha) or_return
	strings.write_rune(&sb, start)

	for {
		c, err := one_of(p, is_alpha_or_digit)
		if err != nil {
			break
		}
		strings.write_rune(&sb, c)
	}

  return strings.to_string(sb), nil
}

unary_message :: proc(p: ^Parser) -> (t: Token, err: ParserError) {
	name := identifier(p) or_return
	return UnaryMessage { name }, nil
}


parametric_message :: proc(p: ^Parser) -> (t: Token, err: ParserError) {
	return nil, "unimplemented"
}

message :: proc(p: ^Parser) -> (m: Token, err: ParserError) {
	m, err = parametric_message(p)
	if err != nil {
		m, err = unary_message(p)
		if err != nil {
			return nil, "expected message"
		}
	}

	return m, nil
}

main :: proc() {
	input := `"hello, " println`
	parser := make_parser(input)

	t, err := string_literal(parser)
	if err == nil {
		fmt.println(t)
	} else {
		fmt.printf("error: expected %v\n", err)
	}

	t, err = message(parser)
	if err == nil {
		fmt.println(t)
	} else {
		fmt.printf("error: expected %v\n", err)
	}
}
