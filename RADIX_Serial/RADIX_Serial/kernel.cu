#include <iostream>
#include <vector>
#include <cmath>
#include <ctime>
#include <algorithm>  // Para std::max_element

using namespace std;

int getDigit(int num, int digitPosition) {
    return (num / static_cast<int>(pow(10, digitPosition))) % 10;
}

void countingSort(vector<int>& arr, int digitPosition) {
    const int base = 10;
    vector<int> count(base, 0);
    vector<int> output(arr.size());

    for (int i = 0; i < arr.size(); i++) {
        int digit = getDigit(arr[i], digitPosition);
        count[digit]++;
    }

    for (int i = 1; i < base; i++) {
        count[i] += count[i - 1];
    }

    for (int i = arr.size() - 1; i >= 0; i--) {
        int digit = getDigit(arr[i], digitPosition);
        output[count[digit] - 1] = arr[i];
        count[digit]--;
    }

    for (int i = 0; i < arr.size(); i++) {
        arr[i] = output[i];
    }
}

void radixSort(vector<int>& arr) {
    int maxElement = *max_element(arr.begin(), arr.end());
    int maxDigits = log10(maxElement) + 1;

    for (int i = 0; i < maxDigits; i++) {
        countingSort(arr, i);
    }
}

int main() {
    // Inicializando a semente para números aleatórios com o tempo atual
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