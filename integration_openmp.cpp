#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <omp.h>

double f(double x) {
    return sin(x);
}
double RectangleMethodOMP(double a, double b, int N) {
    double h = (b - a) / N;
    double sum = 0.0;
    int i;

    #pragma omp parallel for default(none) \
        shared(a, h, N) private(i) \
        reduction(+:sum) schedule(static)
    for (i = 0; i < N; i++) {
        double x = a + (i + 0.5) * h;
        sum += f(x);
    }
    return sum * h;
}

double TrapezoidMethodOMP(double a, double b, int N) {
    double h = (b - a) / N;
    double sum = (f(a) + f(b)) / 2.0;
    int i;

    #pragma omp parallel for default(none) \
        shared(a, h, N) private(i) \
        reduction(+:sum) schedule(static)
    for (i = 1; i < N; i++) {
        double x = a + i * h;
        sum += f(x);
    }
    return sum * h;
}

double SimpsonMethodOMP(double a, double b, int N) {
    double h = (b - a) / N;
    double sum = f(a) + f(b);
    int i;

    #pragma omp parallel for default(none) \
        shared(a, h, N) private(i) \
        reduction(+:sum) schedule(static)
    for (i = 1; i < N; i++) {
        double x = a + i * h;
        if (i % 2 == 0)
            sum += 2.0 * f(x);
        else
            sum += 4.0 * f(x);
    }
    return sum * h / 3.0;
}

double RectangleSerial(double a, double b, int N) {
    double h = (b - a) / N;
    double sum = 0.0;
    for (int i = 0; i < N; i++) {
        double x = a + (i + 0.5) * h;
        sum += f(x);
    }
    return sum * h;
}

double TrapezoidSerial(double a, double b, int N) {
    double h = (b - a) / N;
    double sum = (f(a) + f(b)) / 2.0;
    for (int i = 1; i < N; i++) {
        double x = a + i * h;
        sum += f(x);
    }
    return sum * h;
}

double SimpsonSerial(double a, double b, int N) {
    double h = (b - a) / N;
    double sum = f(a) + f(b);
    for (int i = 1; i < N; i++) {
        double x = a + i * h;
        if (i % 2 == 0)
            sum += 2.0 * f(x);
        else
            sum += 4.0 * f(x);
    }
    return sum * h / 3.0;
}

void TestResult(double ParallelResult, double SerialResult, const char* methodName) {
    double diff = fabs(ParallelResult - SerialResult);
    double tolerance = fabs(SerialResult) * 1e-9;
    if (tolerance < 1e-9) tolerance = 1e-9;
    if (diff < tolerance) {
        printf("[%s] Parallel and serial results are identical.\n", methodName);
    } else {
        printf("[%s] Results differ! Serial=%.15f, Parallel=%.15f\n",
               methodName, SerialResult, ParallelResult);
    }
}

int main(int argc, char* argv[]) {
    double a = 0.0;
    double b = M_PI;
    int N = 100000000;

    if (argc > 1) {
        N = atoi(argv[1]);
    }

    int NumThreads = omp_get_max_threads();
    if (argc > 2) {
        NumThreads = atoi(argv[2]);
        omp_set_num_threads(NumThreads);
    }

    printf("Parallel numerical integration program (OpenMP)\n");
    printf("Max threads available: %d\n", NumThreads);
    printf("Function: f(x) = sin(x), Interval: [0, pi]\n");
    printf("Number of subintervals N = %d\n", N);
    printf("Exact value: 2.0\n\n");

    double Start, Finish, Duration;
    double Result;

    // Rectangle method
    Start = omp_get_wtime();
    Result = RectangleMethodOMP(a, b, N);
    Finish = omp_get_wtime();
    Duration = Finish - Start;
    printf("Rectangle method:  %.15f\n", Result);
    printf("Error:             %.2e\n", fabs(Result - 2.0));
    printf("Time:              %f sec\n", Duration);
    TestResult(Result, RectangleSerial(a, b, N), "Rectangle");
    printf("\n");

    // Trapezoid method
    Start = omp_get_wtime();
    Result = TrapezoidMethodOMP(a, b, N);
    Finish = omp_get_wtime();
    Duration = Finish - Start;
    printf("Trapezoid method:  %.15f\n", Result);
    printf("Error:             %.2e\n", fabs(Result - 2.0));
    printf("Time:              %f sec\n", Duration);
    TestResult(Result, TrapezoidSerial(a, b, N), "Trapezoid");
    printf("\n");

    // Simpson method
    Start = omp_get_wtime();
    Result = SimpsonMethodOMP(a, b, N);
    Finish = omp_get_wtime();
    Duration = Finish - Start;
    printf("Simpson method:    %.15f\n", Result);
    printf("Error:             %.2e\n", fabs(Result - 2.0));
    printf("Time:              %f sec\n", Duration);
    TestResult(Result, SimpsonSerial(a, b, N), "Simpson");

    return 0;
}