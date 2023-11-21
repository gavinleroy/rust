// compile-flags: -Ztrack-trait-obligations
// run-pass

// Just making sure this flag is accepted and doesn't crash the compiler
use traits::IntoString;

fn does_impl_into_string<T: IntoString>(_: T) {}

fn main() {
    let v = vec![(0, 1), (2, 3)];

    does_impl_into_string(v);
}

mod traits {
    pub trait IntoString {
        fn to_string(&self) -> String;
    }

    impl IntoString for (i32, i32) {
        fn to_string(&self) -> String {
            format!("({}, {})", self.0, self.1)
        }
    }

    impl<T: IntoString> IntoString for Vec<T> {
        fn to_string(&self) -> String {
            let s = self.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(", ");
            format!("[{s}]")
        }
    }
}
