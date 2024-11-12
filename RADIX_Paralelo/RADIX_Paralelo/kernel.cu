#include <iostream>
#include <vector>
#include <cmath>
#include <ctime>
#include <algorithm>
#include <cuda_runtime.h>

using namespace std;

__device__ int getDigit(int num, int digitPosition) {
    return (num / static_cast<int>(pow(10, digitPosition))) % 10;
}

__global__ void countingSortKernel(int* arr, int* output, int* count, int size, int digitPosition) {
    const int base = 10;
    int idx = threadIdx.x + blockIdx.x * blockDim.x;

    // Contagem dos dígitos
    if (idx < size) {
        int digit = getDigit(arr[idx], digitPosition);
        atomicAdd(&count[digit], 1); // Count each digit per thread
    }
    __syncthreads();

    // Realiza a contagem acumulada de forma segura
    if (idx == 0) {
        for (int i = 1; i < base; i++) {
            count[i] += count[i - 1]; // Accumulate counts
        }
    }
    __syncthreads();

    // Coloca os elementos na posição correta com base no dígito atual
    if (idx < size) {
        int digit = getDigit(arr[idx], digitPosition);
        int position = atomicAdd(&count[digit], -1) - 1; // Find position for the element
        output[position] = arr[idx]; // Place the element in the correct position
    }
}

void radixSort(vector<int>& arr) {
    int maxElement = *max_element(arr.begin(), arr.end());
    int maxDigits = log10(maxElement) + 1;

    int size = arr.size();
    int* d_arr, * d_output, * d_count;

    // Allocate memory on the device
    cudaMalloc(&d_arr, size * sizeof(int));
    cudaMalloc(&d_output, size * sizeof(int));
    cudaMalloc(&d_count, 10 * sizeof(int));

    cudaMemcpy(d_arr, arr.data(), size * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemset(d_count, 0, 10 * sizeof(int));

    int blockSize = 256; // Tamanho do bloco de threads
    int gridSize = (size + blockSize - 1) / blockSize;

    // Para cada dígito, realiza o countingSort paralelizado
    for (int i = 0; i < maxDigits; i++) {
        cudaMemset(d_count, 0, 10 * sizeof(int)); // Limpa o contador de dígitos antes de cada iteração
        countingSortKernel << <gridSize, blockSize >> > (d_arr, d_output, d_count, size, i);
        cudaMemcpy(arr.data(), d_output, size * sizeof(int), cudaMemcpyDeviceToHost); // Copia de volta os dados ordenados
    }

    cudaFree(d_arr);
    cudaFree(d_output);
    cudaFree(d_count);
}

int main() {
    srand(static_cast<unsigned int>(time(0)));

    vector<int> sizes = { 100, 1000, 10000, 100000, 1000000, 10000000 };

    for (int size : sizes) {
        vector<int> arr(size);
        for (int i = 0; i < size; i++) {
            arr[i] = rand() % 1000000;  // Números aleatórios entre 0 e 999999
        }

        clock_t start = clock();
        radixSort(arr);
        clock_t end = clock();

        double duration = double(end - start) / CLOCKS_PER_SEC;
        cout << "Array Size: " << size << ", Execution Time: " << duration << " s" << endl;
    }

    return 0;
}
