module rutcl

import rand
import strings

const max_digits = 8

const company_threshold = 50_000_000

pub struct InvalidFormatError {
	Error
}

pub fn (e InvalidFormatError) msg() string {
	return 'rut: formato inválido'
}

pub struct InvalidDvError {
	Error
}

pub fn (e InvalidDvError) msg() string {
	return 'rut: dígito verificador incorrecto'
}

pub struct Rut {
pub:
	number int
	dv     u8
}

@[params]
pub struct FormatOptions {
pub:
	dots   bool = true
	hyphen bool = true
}

pub fn clean(input string) string {
	mut sb := strings.new_builder(input.len)
	for c in input {
		if c.is_digit() {
			sb.write_u8(c)
		} else if c == `k` || c == `K` {
			sb.write_string('K')
		}
	}
	return sb.str()
}

pub fn calculate_dv(number int) u8 {
	mut n := number
	mut sum := 0
	mut factor := 2
	for n > 0 {
		sum += (n % 10) * factor
		n /= 10
		factor = if factor == 7 { 2 } else { factor + 1 }
	}
	r := 11 - sum % 11
	if r == 11 {
		return u8(`0`)
	}
	if r == 10 {
		return u8(`K`)
	}
	return u8(`0`) + u8(r)
}

pub fn parse(input string) !Rut {
	for c in input {
		if !(c.is_digit() || c == `k` || c == `K` || c == `.` || c == `-` || c == ` `) {
			return InvalidFormatError{}
		}
	}
	cleaned := clean(input)
	if cleaned.len < 2 {
		return InvalidFormatError{}
	}
	dv := cleaned[cleaned.len - 1]
	body := cleaned[..cleaned.len - 1].trim_left('0')
	if body.len == 0 || body.len > max_digits || body.contains('K') {
		return InvalidFormatError{}
	}
	number := body.int()
	if dv != calculate_dv(number) {
		return InvalidDvError{}
	}
	return Rut{
		number: number
		dv:     dv
	}
}

pub fn is_valid(input string) bool {
	r := parse(input) or { return false }
	return r.number > 0
}

pub fn from_number(number int) !Rut {
	if number < 1 || number > 99_999_999 {
		return InvalidFormatError{}
	}
	return Rut{
		number: number
		dv:     calculate_dv(number)
	}
}

pub fn format(input string, opts FormatOptions) !string {
	r := parse(input)!
	return r.format(opts)
}

pub fn random() Rut {
	return random_between(1_000_000, company_threshold)
}

pub fn random_company() Rut {
	return random_between(company_threshold, 100_000_000)
}

fn random_between(min int, max int) Rut {
	n := rand.int_in_range(min, max) or { min }
	return Rut{
		number: n
		dv:     calculate_dv(n)
	}
}

pub fn (r Rut) str() string {
	return '${r.number}-${r.dv.ascii_str()}'
}

pub fn (r Rut) format(opts FormatOptions) string {
	mut body := r.number.str()
	if opts.dots {
		body = add_dots(body)
	}
	sep := if opts.hyphen { '-' } else { '' }
	return '${body}${sep}${r.dv.ascii_str()}'
}

pub fn (r Rut) mask() string {
	s := r.number.str()
	mut sb := strings.new_builder(s.len)
	for i, c in s {
		if s.len - i <= 3 {
			sb.write_u8(c)
		} else {
			sb.write_string('*')
		}
	}
	return '${add_dots(sb.str())}-${r.dv.ascii_str()}'
}

pub fn (r Rut) is_company() bool {
	return r.number >= company_threshold
}

fn add_dots(s string) string {
	mut sb := strings.new_builder(s.len + 3)
	for i, c in s {
		if i > 0 && (s.len - i) % 3 == 0 {
			sb.write_string('.')
		}
		sb.write_u8(c)
	}
	return sb.str()
}
