Putting main() in a namespace
=============================
2019-05-23

Normally, I would simply place my `main()` in a file called, for example,
`main.cpp` or `<project_name>.cpp`, and that would serve as the "root" of the
project. Within this file, I would include as many headers as are necessary to
get the job done. This is generally what I see in other code as well, whether
`main()` is a huge function that does everything, or a simple two-line jumping
point for a GUI application.

But I recently found that this doesn't need to be the case. `main()` can be in
a namespace. It can be somewhere random in your code. It just has to _be
somewhere_ in your code. So why not hide it in a bird's nest of namespaces?

Well we can't do this for free.

Suppose we have a simple hello world application, but we hide `main()` inside a
namespace.

```cpp
namespace foo
{
    int main(int argc, char **argv)
    {
        std::cout << "Hello, world!" << std::endl;
        return 0;
    }
}
```

We can compile this successfully. On Linux, I can do `g++ -c test.cpp` and I
will get a valid `test.o` file output. However, this file cannot be linked into
an executable. If you try to run `g++ test.o -o test`, you will get an error to
the effect of `undefined reference to 'main'`.

This happens because C++ compilers mangle the names of symbols when compiling
the source code. This allows functions to have the same name in source within
different namespaces and scopes without resulting in a symbol collision[^1].

We can check that this is happening on Linux with the `nm` utility to look at
the symbols. Using the above code, running `nm test.o` results in:

```default
                 U __cxa_atexit
                 U __dso_handle
                 U _GLOBAL_OFFSET_TABLE_
0000000000000087 t _GLOBAL__sub_I__ZN3foo4mainEiPPc
000000000000003e t _Z41__static_initialization_and_destruction_0ii
0000000000000000 T _ZN3foo4mainEiPPc
                 U _ZNSolsEPFRSoS_E
                 U _ZNSt8ios_base4InitC1Ev
                 U _ZNSt8ios_base4InitD1Ev
                 U _ZSt4cout
                 U _ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_
0000000000000000 r _ZStL19piecewise_construct
0000000000000000 b _ZStL8__ioinit
                 U _ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc
```

As you can see, the names are quite mangled, but you can still make out in the
middle our `main` function, which compiled to the symbol `_ZN3foo4mainEiPPc`.
Note that it contains the `foo` namespace as part of the name[^2].

When we try to link our compiled symbols to an executable, the linker will look
for a symbol called `main`. Just `main`. And it has to actually be called that;
it can't just have the same function prototype. For example, we can foolishly
try to trick the compiler by creating a new function outside of our namespace
with the correct prototype:

```cpp
namespace foo
{
    int main(int argc, char **argv)
    {
        std::cout << "Hello, world!" << std::endl;
        return 0;
    }
}

int mane(int argc, char **argv)
{
    std::cout << "Neigh, world!" << std::endl;
    return 0;
}
```

This will compile, but it won't link. If we look at the symbols, we can see:

```default
                 U __cxa_atexit
                 U __dso_handle
                 U _GLOBAL_OFFSET_TABLE_
0000000000000099 t _GLOBAL__sub_I__ZN3foo4mainEiPPc
0000000000000050 t _Z41__static_initialization_and_destruction_0ii
000000000000003e T _Z4maneiPPc
0000000000000000 T _ZN3foo4mainEiPPc
                 U _ZNSolsEPFRSoS_E
                 U _ZNSt8ios_base4InitC1Ev
                 U _ZNSt8ios_base4InitD1Ev
                 U _ZSt4cout
                 U _ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_
0000000000000000 r _ZStL19piecewise_construct
0000000000000000 b _ZStL8__ioinit
                 U _ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc
```

Well, `_Z4maneiPPc` is arguably _less_ mangled than our `foo::main()`
function's symbol, but it's not what `ld` will be looking for.

But hold on a minute. If we made a globally scoped function with the correct
prototype and it was still mangled, how would it ever link? Because `main` is
treated specially. If we rename `mane` to `main` and inspect the symbols, we
can see we get the symbol we want:

```default
                 U __cxa_atexit
                 U __dso_handle
                 U _GLOBAL_OFFSET_TABLE_
0000000000000099 t _GLOBAL__sub_I__ZN3foo4mainEiPPc
000000000000003e T main
0000000000000050 t _Z41__static_initialization_and_destruction_0ii
0000000000000000 T _ZN3foo4mainEiPPc
                 U _ZNSolsEPFRSoS_E
                 U _ZNSt8ios_base4InitC1Ev
                 U _ZNSt8ios_base4InitD1Ev
                 U _ZSt4cout
                 U _ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_
0000000000000000 r _ZStL19piecewise_construct
0000000000000000 b _ZStL8__ioinit
                 U _ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc
```

There's our `main` symbol. This will link and run as expected. So how do we get
our `foo::main` to behave? We can use `extern` to accomplish this. If we
prepend the function with `extern "C"`, we tell the compiler to avoid mangling
the name of the symbol generated from this function. So the following code:

```cpp
namespace foo
{
    extern "C" int main(int argc, char **argv)
    {
        std::cout << "Hello, world!" << std::endl;
        return 0;
    }
}
```

generates the following symbols:

```default
                 U __cxa_atexit
                 U __dso_handle
                 U _GLOBAL_OFFSET_TABLE_
0000000000000087 t _GLOBAL__sub_I_main
0000000000000000 T main
000000000000003e t _Z41__static_initialization_and_destruction_0ii
                 U _ZNSolsEPFRSoS_E
                 U _ZNSt8ios_base4InitC1Ev
                 U _ZNSt8ios_base4InitD1Ev
                 U _ZSt4cout
                 U _ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_
0000000000000000 r _ZStL19piecewise_construct
0000000000000000 b _ZStL8__ioinit
                 U _ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc
```

Beautiful.

I have an overly verbose, yet contrived, example on GitHub [here](
https://gist.github.com/ahota/c8288979c6c0054a350f07e53418f298). I've hidden
`main` within a bird's nest of code.

So, why would you do this? I actually found this pattern in production code I
was working on. It's such a bizarre thing to do that I felt it must have a
legitimate purpose[^3].

My first thought was that it could be used as a shortcut to namespace
specification for types and variables. That is, if `main()` is within
`namespace foo`, and there exists an `int foo::bar`, then `main()` can refer to
it as simply `bar`. But you could just as easily write `main()` outside of the
namespace and use `using namespace foo` to achieve the same thing (though I
personally dislike clipping namespaces like this). This is an awful "shortcut"
for clipping the namespace.

Another idea I had, which is marginally more useful, is that this idiom can be
roughly equivalent to the Python `if __name__ == '__main__'`, where modules can
be run standalone or as a library.

Individual Python modules can be run with, for example, `python my_module.py`.
Within the interpreter, a built-in, module-scoped variable called `__name__` is
set to `'__main__'` to denote that this is the "entry point" to the running
process. If this same module was imported into another module via `import
my_module`, then `__name__` is set to the module's actual name. In this case,
it would be `'my_module'`.

We can somewhat replicate this with a bit of extra scaffolding in C++. If we
additionally add preprocessor macros around our namespaced `main()`, we can
prevent it from being compiled until we specifically want it:

```cpp
// foo.cpp
#include <iostream>

namespace foo
{
#ifndef I_GOT_A_MAIN
    extern "C" int main(int argc, char **argv)
    {
        std::cout << "foo::main()" << std::endl;
        return 0;
    }
#endif
}
```

If `I_GOT_A_MAIN` is already defined, then our namespaced main function will
not be compiled. We can define our "actual" `main()` function in another file
and include the above code.

```cpp
// bar.cpp
#define I_GOT_A_MAIN
#include <foo.cpp>

int main(int argc, char **argv)
{
    std::cout << "main()" << std::endl;
    return 0;
}
```

This can be compiled with `g++ bar.cpp -o test -I.` (I like to use angle
brackets in my `#include`s, hence the `-I`), and it would print out `main()`.
If you remove the `#define`, we will get a symbol collision from the linker
that `main` is defined twice. If we compile only `foo.cpp` with `g++ foo.cpp -o
foo_test`, we would get `foo::main()` printed.

Our `foo::main()` could be used as a unit test of some sort for everything
defined within the namespaces within that file. Shipping a unit test with every
source file sounds like a reasonable thing to do. We can simply compile
individual source files as our test platform instead of relying on third-party
utilities to do so, or totally rolling our own tests.

I have another overly complicated yet contrived example on GitHub
[here](https://github.com/ahota/beauty).

But maybe don't use this idiom in production code. It just feels dirty.

[^1]: C doesn't have this issue at all as it requires all functions to have
different prototypes, which directly translate to different symbols. See the
OpenGL C API for example.

[^2]: This may not always be the case. It just so happens that my compiler does
its naming this way.

[^3]: In hindsight, I no longer think it was purposefully written with a
special design in mind. It is just strangely written code.

###### Categories

* Programming
    * C++
