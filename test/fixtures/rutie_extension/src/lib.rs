#[macro_use]
extern crate rutie;

use rutie::{Class, Object, RString, VM};

class!(RutieThermiteExample);

methods!(
    RutieThermiteExample,
    _rtself,
    fn pub_reverse(input: RString) -> RString {
        let ruby_string = input.map_err(VM::raise_ex).unwrap();

        RString::new_utf8(&ruby_string.to_string().chars().rev().collect::<String>())
    }
);

#[allow(non_snake_case)]
#[no_mangle]
pub extern "C" fn Init_rutie_thermite_example() {
    Class::new("RutieThermiteExample", None).define(|klass| {
        klass.def_self("reverse", pub_reverse);
    });
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_is_run_by_thermite_test() {
        assert_eq!("cba", "abc".chars().rev().collect::<String>());
    }
}
