#!/bin/bash

echo "compile test"
nvcc set_gpu.cu -o set_gpu

echo "run test"
./set_gpu
