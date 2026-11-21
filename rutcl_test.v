module rutcl

const valid_ruts = [
	'12.345.678-5',
	'12345678-5',
	'123456785',
	' 12.345.678 - 5 ',
	'11.111.111-1',
	'10.000.000-8',
	'76.086.428-5',
	'24.965.387-K',
	'24.965.387-k',
	'6-K',
	'14-0',
	'1-9',
	'99.999.999-9',
	'012345678-5',
]

const invalid_ruts = [
	'',
	'-',
	'5',
	'12.345.678-4',
	'12.345.678-K',
	'abc',
	'hola 12.345.678-5',
	'12.345.678-5!',
	'1K.345.678-5',
	'0-0',
	'000-0',
	'100.000.000-9',
	'123456789012-3',
]

fn test_calculate_dv() {
	cases := {
		1:        `9`
		2:        `7`
		3:        `5`
		5:        `1`
		6:        `K`
		9:        `4`
		14:       `0`
		100:      `7`
		1000:     `6`
		1234:     `3`
		999999:   `K`
		1000000:  `9`
		1234567:  `4`
		12345678: `5`
		24965387: `K`
		50000000: `7`
		76123456: `0`
	}
	for number, dv in cases {
		assert calculate_dv(number) == u8(dv), 'dv incorrecto para ${number}'
	}
}

fn test_clean() {
	assert clean('12.345.678-5') == '123456785'
	assert clean('12.345.678-k') == '12345678K'
	assert clean(' 1 2 ') == '12'
	assert clean('') == ''
	assert clean('abc') == ''
}

fn test_is_valid_accepts() {
	for s in valid_ruts {
		assert is_valid(s), 'debería ser válido: "${s}"'
	}
}

fn test_is_valid_rejects() {
	for s in invalid_ruts {
		assert !is_valid(s), 'debería ser inválido: "${s}"'
	}
}

fn test_parse_values() {
	r := parse('12.345.678-5') or { panic(err) }
	assert r.number == 12345678
	assert r.dv == u8(`5`)

	k := parse('24.965.387-k') or { panic(err) }
	assert k.number == 24965387
	assert k.dv == u8(`K`)
}

fn test_parse_error_format() {
	parse('hola') or {
		assert err is InvalidFormatError
		assert err.msg() == 'rut: formato inválido'
		return
	}
	assert false, 'parse debía fallar'
}

fn test_parse_error_dv() {
	parse('12.345.678-4') or {
		assert err is InvalidDvError
		assert err.msg() == 'rut: dígito verificador incorrecto'
		return
	}
	assert false, 'parse debía fallar'
}

fn test_format_options() {
	r := parse('12345678-5') or { panic(err) }
	assert r.format() == '12.345.678-5'
	assert r.format(dots: false) == '12345678-5'
	assert r.format(hyphen: false) == '12.345.6785'
	assert r.format(dots: false, hyphen: false) == '123456785'
}

fn test_format_short_numbers() {
	assert (parse('6-K') or { panic(err) }).format() == '6-K'
	assert (parse('14-0') or { panic(err) }).format() == '14-0'
	assert (parse('1234-3') or { panic(err) }).format() == '1.234-3'
	assert (parse('1000000-9') or { panic(err) }).format() == '1.000.000-9'
}

fn test_format_function() {
	assert format('123456785')! == '12.345.678-5'
	assert format('12.345.678-5', dots: false)! == '12345678-5'
	format('12.345.678-0') or {
		assert err is InvalidDvError
		return
	}
	assert false, 'format debía fallar'
}

fn test_str() {
	r := parse('12.345.678-5') or { panic(err) }
	assert r.str() == '12345678-5'
	assert '${r}' == '12345678-5'
}

fn test_mask() {
	r := parse('12.345.678-5') or { panic(err) }
	assert r.mask() == '**.***.678-5'
	short := parse('14-0') or { panic(err) }
	assert short.mask() == '14-0'
}

fn test_from_number() {
	r := from_number(12345678) or { panic(err) }
	assert r.dv == u8(`5`)
	assert r.format() == '12.345.678-5'
}

fn test_from_number_out_of_range() {
	from_number(0) or {
		assert err is InvalidFormatError
		return
	}
	assert false, 'debía fallar con 0'
}

fn test_from_number_too_big() {
	from_number(100_000_000) or {
		assert err is InvalidFormatError
		return
	}
	assert false, 'debía fallar sobre el máximo'
}

fn test_is_company() {
	assert !(parse('12.345.678-5') or { panic(err) }).is_company()
	assert (parse('76.086.428-5') or { panic(err) }).is_company()
	assert (from_number(50_000_000) or { panic(err) }).is_company()
	assert !(from_number(49_999_999) or { panic(err) }).is_company()
}

fn test_roundtrip_many_numbers() {
	for n in 1 .. 20_000 {
		r := from_number(n) or { panic(err) }
		again := parse(r.format()) or { panic('no parseó ${r.format()}') }
		assert again == r
		assert is_valid(r.str())
	}
}

fn test_any_wrong_dv_is_rejected() {
	for n in [1, 99, 12345678, 24965387, 76086428] {
		right := calculate_dv(n)
		for d in '0123456789K' {
			s := '${n}-${u8(d).ascii_str()}'
			assert is_valid(s) == (u8(d) == right), 'falló con ${s}'
		}
	}
}

fn test_random() {
	for _ in 0 .. 1000 {
		p := random()
		assert is_valid(p.format())
		assert !p.is_company()

		c := random_company()
		assert is_valid(c.format())
		assert c.is_company()
	}
}
