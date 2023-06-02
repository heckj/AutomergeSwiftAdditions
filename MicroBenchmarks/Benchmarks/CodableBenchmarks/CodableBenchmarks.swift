// Benchmark boilerplate generated by Benchmark

import Automerge
import AutomergeMicroBenchmarks
import AutomergeSwiftAdditions
import Benchmark
import Foundation

struct SimpleStruct: Codable {
    let name: String
    let duration: Double
    let flag: Bool
    let count: Int
}

let sample = SimpleStruct(name: "henry", duration: 3.14159, flag: true, count: 5)

let benchmarks = {
    Benchmark("SimpleEncode") { benchmark in
        for _ in benchmark.scaledIterations {
            let doc = Document()
            let automergeEncoder = AutomergeEncoder(doc: doc)
            
            try blackHole(automergeEncoder.encode(sample))
        }
    }

    Benchmark("LayeredEncode") { benchmark in
        let layeredSample = Samples.layered
        for _ in benchmark.scaledIterations {
            let doc = Document()
            let automergeEncoder = AutomergeEncoder(doc: doc)

            try blackHole(automergeEncoder.encode(layeredSample))
        }
    }
    
    Benchmark("SimpleEncodeDecodeRoundtrip") { benchmark in
        for _ in benchmark.scaledIterations {
            let doc = Document()
            let automergeEncoder = AutomergeEncoder(doc: doc)
            try automergeEncoder.encode(sample)
            let decoder = AutomergeDecoder(doc: doc)
            try blackHole(try decoder.decode(SimpleStruct.self))
        }
    }

    Benchmark("LayeredEncodeDecodeRoundtrip") { benchmark in
        let layeredSample = Samples.layered
        for _ in benchmark.scaledIterations {
            let doc = Document()
            let automergeEncoder = AutomergeEncoder(doc: doc)
            try automergeEncoder.encode(layeredSample)
            let decoder = AutomergeDecoder(doc: doc)
            try blackHole(try decoder.decode(ExampleModel.self))
        }
    }
}
