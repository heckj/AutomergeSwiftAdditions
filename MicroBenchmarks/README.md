# Automerge Swift Additions Micro Benchmarks

Example:

    swift package benchmark --target CodableBenchmarks

Creating the `initial` baseline:

    swift package --allow-writing-to-package-directory benchmark baseline update initial

Comparing a current run against the stored baseline `initial`:

    swift package benchmark baseline compare initial
    swift package benchmark baseline compare coderbaseline
    swift package benchmark baseline check coderbaseline


