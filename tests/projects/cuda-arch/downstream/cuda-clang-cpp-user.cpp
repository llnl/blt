#include <iostream>

#include "cuda-clang-cpp.cuh"

int main() {
    // The call below will print out the architecture the upstream project was compiled with, which we
    // can verify is different from the architecture used by this project.
    std::cout << "Hello from downstream project.  Getting cuda arch from upstream: " << std::endl;
    run_kernel();

    return 0;
}
