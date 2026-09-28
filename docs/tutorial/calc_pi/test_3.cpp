///////////////////////////////////////////////////////////////////////////////
//
// file: test_3.cpp
// 
// Simple example that calculates pi via simple integration.
//
// Adapted from:
// https://www.mcs.anl.gov/research/projects/mpi/usingmpi/examples-usingmpi/simplempi/cpi_c.html
///////////////////////////////////////////////////////////////////////////////

#include <gtest/gtest.h>
#include <cuda_runtime_api.h>

#include <iostream>

#include "calc_pi.hpp"
#include "calc_pi_cuda.hpp"

const double PI_REF = 3.141592653589793238462643;

bool require_cuda_device()
{
    int device_count = 0;
    const cudaError_t result = cudaGetDeviceCount(&device_count);

    if (result == cudaErrorNoDevice ||
        (result == cudaSuccess && device_count == 0))
    {
        std::cerr << "ERROR: test_3 requires at least one CUDA-capable device, "
                     "but no CUDA devices were found. Run this test in a GPU "
                     "allocation and verify that "
                     "CUDA_VISIBLE_DEVICES exposes a device."
                  << std::endl;
        return false;
    }

    if (result != cudaSuccess)
    {
        std::cerr << "ERROR: test_3 requires an accessible CUDA device, but "
                     "cudaGetDeviceCount failed: "
                  << cudaGetErrorString(result)
                  << ". Verify the GPU allocation, CUDA driver, and "
                     "CUDA_VISIBLE_DEVICES."
                  << std::endl;
        return false;
    }

    return true;
}

// test serial lib
TEST(calc_pi_cuda, serial_example)
{
    ASSERT_NEAR(calc_pi(1000),PI_REF,1e-6);
}


// test cuda lib
TEST(calc_pi_cuda, cuda_example)
{
    ASSERT_NEAR(calc_pi_cuda(1000),PI_REF,1e-6);
}

// compare serial and cuda
TEST(calc_pi_cuda, compare_serial_cuda)
{
    ASSERT_NEAR(calc_pi(1000),calc_pi_cuda(1000),1e-12);
}

int main(int argc, char** argv)
{
    if (!require_cuda_device())
    {
        return 1;
    }

    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
