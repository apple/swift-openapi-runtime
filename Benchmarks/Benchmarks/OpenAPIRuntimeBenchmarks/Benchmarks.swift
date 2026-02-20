//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2024 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import Benchmark
import OpenAPIRuntime

let benchmarks: @Sendable () -> Void = {
    let defaultMetrics: [BenchmarkMetric] = [.mallocCountTotal, .cpuTotal]

    Benchmark(
        "ISO8601DateTranscoder.encode(_:)",
        configuration: Benchmark.Configuration(
            metrics: defaultMetrics,
            scalingFactor: .kilo,
            maxDuration: .seconds(10_000_000),
            maxIterations: 5
        )
    ) { benchmark in
        let transcoder = ISO8601DateTranscoder()
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations { blackHole(try transcoder.encode(.distantFuture)) }
    }

    Benchmark(
        "ISO8601DateFormatter.string(from:)",
        configuration: Benchmark.Configuration(
            metrics: defaultMetrics,
            scalingFactor: .kilo,
            maxDuration: .seconds(10_000_000),
            maxIterations: 5
        )
    ) { benchmark in
        let formatter = ISO8601DateFormatter()
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations { blackHole(formatter.string(from: .distantFuture)) }
    }

    Benchmark(
        "Date.ISO8601Format(_:)",
        configuration: Benchmark.Configuration(
            metrics: defaultMetrics,
            scalingFactor: .kilo,
            maxDuration: .seconds(10_000_000),
            maxIterations: 5
        )
    ) { benchmark in
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations { blackHole(Date.distantFuture.ISO8601Format()) }
    }
}
