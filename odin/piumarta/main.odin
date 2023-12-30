package main

import "core:fmt"
import "core:mem"
import "core:strings"

Object :: struct {
	_vt: ^VTable,
}

VTable :: struct {
  using object: Object,
	entries: map[^Object]^Object,
	parent: ^VTable,
}

Symbol :: struct {
	using object: Object,
	value: string,
}


vtable_allocate :: proc(self: ^VTable, $T: typeid) -> ^T {
	ptr, _ := mem.alloc(size_of(T), align_of(T))
	object := cast(^T)ptr
	object._vt = self
	return object
}

vtable_delegated :: proc(self: ^VTable) -> ^VTable {
	child := vtable_allocate(self, VTable)
	child._vt = self._vt if self != nil else nil
	child.parent = self
	return child
}

vtable_add_method :: proc (self: ^VTable, key: ^Object, value: ^Object) {
	self.entries[key] = value
}

vtable_lookup :: proc (self: ^VTable, key: ^Object) -> ^Object {
	return self.entries[key]
}

symbol_new :: proc(value: string) -> ^Symbol {
	symbol := new(Symbol)
	symbol.value = value
	return symbol
}

symbol_intern :: proc(self: ^Object, value: string) -> ^Object {
	for key, _ in SymbolList.entries {
		symbol := cast(^Symbol)key
		if strings.compare(value, symbol.value) == 0 {
			return symbol
		}
	}

	symbol := symbol_new(value)
	vtable_add_method(SymbolList, symbol, nil)
	return symbol
}

bind :: proc(receiver: ^Object, message: ^Object) -> ^Object {
	if message == s_lookup && receiver == vtable_vt {
		return vtable_lookup(receiver._vt, message)
	}

	return send(receiver._vt, s_lookup, message)
}

send :: proc(receiver: ^Object, message: ^Object, args: ..^Object) -> ^Object {
	method := cast(rawptr)bind(receiver, message)

	if method == nil {
		panic("method == nil")
	}

	// hack to convert a variadic call to one with a fixed number of arguments
	switch len(args) {
	case 1:
		fn := cast(proc(^Object, ^Object) -> ^Object)method
		return fn(receiver, args[0])

	case:
		panic("unimplemented")
	}
}

vtable_vt : ^VTable = nil
SymbolList : ^VTable = nil
s_lookup : ^Object = nil

main :: proc() {
  vtable_vt = vtable_delegated(nil)
	vtable_vt._vt = vtable_vt

	object_vt := vtable_delegated(nil)
	object_vt._vt = vtable_vt
	vtable_vt.parent = object_vt

	symbol_vt := vtable_delegated(object_vt)
	SymbolList = vtable_delegated(nil)

	s_lookup = symbol_intern(nil, "lookup")
	vtable_add_method(vtable_vt, s_lookup, cast(^Object)cast(rawptr)vtable_lookup)

	s_add_method := symbol_intern(nil, "addMethod")
	vtable_add_method(vtable_vt, s_add_method, cast(^Object)cast(rawptr)vtable_add_method)

	out := send(vtable_vt, s_lookup, s_add_method)
	fmt.println(out == cast(^Object)cast(rawptr)vtable_add_method)
}
