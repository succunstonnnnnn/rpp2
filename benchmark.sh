SEQ_SRC="integration_sequential.cpp"
OMP_SRC="integration_openmp.cpp"
SEQ_BIN="./integration_sequential"
OMP_BIN="./integration_openmp"
GCC="g++-15"
RUNS=3

N_VALUES=(10000 100000 1000000 10000000 100000000)
N_LABELS=("10^4" "10^5" "10^6" "10^7" "10^8")

for f in "$SEQ_SRC" "$OMP_SRC"; do
    if [ ! -f "$f" ]; then echo "ПОМИЛКА: не знайдено $f"; exit 1; fi
done

echo "Компіляція"
$GCC -O2 "$SEQ_SRC" -o "${SEQ_BIN#./}" && echo "  OK: $SEQ_BIN"
$GCC -O2 -fopenmp "$OMP_SRC" -o "${OMP_BIN#./}" && echo "  OK: $OMP_BIN"
echo ""

extract_time() {
    local output="$1" method="$2"
    echo "$output" | awk -v m="$method" '
        $0 ~ "^"m" method:" { found=1; next }
        found && /^Time:/ { print $2; exit }
    '
}

min_of() {
    echo "$@" | tr ' ' '\n' | awk 'BEGIN{m=""} {if(m==""||$1<m)m=$1} END{print m}'
}

RESULTS_DIR="benchmark_results"
mkdir -p "$RESULTS_DIR"

RECT_CSV="$RESULTS_DIR/rectangle.csv"
TRAP_CSV="$RESULTS_DIR/trapezoid.csv"
SIMP_CSV="$RESULTS_DIR/simpson.csv"

echo "N,Seq,t=2,t=4,t=8" > "$RECT_CSV"
echo "N,Seq,t=2,t=4,t=8" > "$TRAP_CSV"
echo "N,Seq,t=2,t=4,t=8" > "$SIMP_CSV"

echo "Бенчмарк (мінімум з $RUNS запусків)"
echo ""

bench_config() {
    local bin="$1" N="$2" t="$3"
    local r1 r2 r3 t1 t2 t3 s1 s2 s3 out
    for run in 1 2 3; do
        if [ -z "$t" ]; then out=$("$bin" "$N")
        else out=$("$bin" "$N" "$t"); fi
        case $run in
            1) r1=$(extract_time "$out" "Rectangle"); t1=$(extract_time "$out" "Trapezoid"); s1=$(extract_time "$out" "Simpson") ;;
            2) r2=$(extract_time "$out" "Rectangle"); t2=$(extract_time "$out" "Trapezoid"); s2=$(extract_time "$out" "Simpson") ;;
            3) r3=$(extract_time "$out" "Rectangle"); t3=$(extract_time "$out" "Trapezoid"); s3=$(extract_time "$out" "Simpson") ;;
        esac
    done
    BENCH_RECT=$(min_of $r1 $r2 $r3)
    BENCH_TRAP=$(min_of $t1 $t2 $t3)
    BENCH_SIMP=$(min_of $s1 $s2 $s3)
}

for idx in "${!N_VALUES[@]}"; do
    N="${N_VALUES[$idx]}"
    LABEL="${N_LABELS[$idx]}"
    echo "----- N = $LABEL ($N) -----"

    bench_config "$SEQ_BIN" "$N" ""
    seq_rect=$BENCH_RECT; seq_trap=$BENCH_TRAP; seq_simp=$BENCH_SIMP
    echo "  Послідовно:  rect=$seq_rect  trap=$seq_trap  simp=$seq_simp"

    bench_config "$OMP_BIN" "$N" 2
    omp2_rect=$BENCH_RECT; omp2_trap=$BENCH_TRAP; omp2_simp=$BENCH_SIMP
    echo "  OpenMP t=2:  rect=$omp2_rect  trap=$omp2_trap  simp=$omp2_simp"

    bench_config "$OMP_BIN" "$N" 4
    omp4_rect=$BENCH_RECT; omp4_trap=$BENCH_TRAP; omp4_simp=$BENCH_SIMP
    echo "  OpenMP t=4:  rect=$omp4_rect  trap=$omp4_trap  simp=$omp4_simp"

    bench_config "$OMP_BIN" "$N" 8
    omp8_rect=$BENCH_RECT; omp8_trap=$BENCH_TRAP; omp8_simp=$BENCH_SIMP
    echo "  OpenMP t=8:  rect=$omp8_rect  trap=$omp8_trap  simp=$omp8_simp"
    echo ""

    echo "$LABEL,$seq_rect,$omp2_rect,$omp4_rect,$omp8_rect" >> "$RECT_CSV"
    echo "$LABEL,$seq_trap,$omp2_trap,$omp4_trap,$omp8_trap" >> "$TRAP_CSV"
    echo "$LABEL,$seq_simp,$omp2_simp,$omp4_simp,$omp8_simp" >> "$SIMP_CSV"
done

echo "Результати"
echo ""
echo "Метод прямокутників:"
column -t -s, "$RECT_CSV"
echo ""
echo "Метод трапецій:"
column -t -s, "$TRAP_CSV"
echo ""
echo "Метод Сімпсона:"
column -t -s, "$SIMP_CSV"
