# Rutcl 🇨🇱
Valida, formatea y genera **RUT chileno** en [V](https://vlang.io). Sin dependencias.

```v
import rutcl

fn main() {
	println(rutcl.is_valid('12.345.678-5')) // true
	println(rutcl.is_valid('12.345.678-4')) // false

	r := rutcl.parse('123456785')!
	println(r.format())            // 12.345.678-5
	println(r.format(dots: false)) // 12345678-5
	println(r.mask())              // **.***.678-5
}
```

## Instalación

```sh
v install --git https://github.com/trobukan/rutcl
```

## API

- `rut.is_valid(s)`: dice si el RUT es válido
- `rut.parse(s)!`: valida y devuelve un `Rut`
- `rut.format(s, dots: false)!`: valida y reescribe el texto
- `rut.calculate_dv(n)`: calcula el dígito verificador
- `rut.random()`: RUT válido para tests
- `r.mask()`: oculta el RUT en logs
- `r.is_company()`: `true` si es persona jurídica (≥ 50.000.000)

Acepta `12.345.678-5`, `12345678-5` y `123456785`, con `K` en mayúscula o minúscula.

## Desarrollo

```sh
v test .
```

