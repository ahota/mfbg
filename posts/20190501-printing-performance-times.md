Printing performance times in C++
=================================
2019-05-01

Getting performance times is fairly easy in C++11 and newer specifications. All
it takes is two calls to `high_resolution_clock::now()`, located in
the `chrono` header. An example would be:

```cpp
#include <chrono>
#include <iostream>

auto start = std::chrono::high_resolution_clock::now();
// do something here that takes time
auto end = std::chrono::high_resolution_clock::now();
```

Now that we have `start` and `end`, we just need to know - and ultimately
display - how much time was spent in between. The typical way I would do this
is:

```cpp
auto diff = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
std::cout << "Took " << diff.count() << " ms" << std::endl;
```

This is a bit more verbose than I would like (I also prefer to not clip
namespaces with `using namespace std::chrono` unless absolutely necessary). It
also has the limitation of only displaying milliseconds since that is what the
`duration` was cast to.

To make things easier I wrote a simple function, `print_time()` to print the
time in `HH:MM:SS.mmm` format given either a number of milliseconds or an
`std::chrono::duration` object (e.g. `end - start`). So now all you have to do
to print the times is:

```cpp
auto start = std::chrono::high_resolution_clock::now();
// do something here that takes time
auto end = std::chrono::high_resolution_clock::now();
print_time(end - start);
```

You can find it on GitHub [here]("https://github.com/ahota/print_time") along
with a basic test program. I'm now using this as a Git submodule in a couple
other projects and have nicely printed times.

###### Categories

* Programming
    * C++
