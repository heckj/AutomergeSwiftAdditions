import AutomergeSwiftAdditions
import Foundation

public struct AutomergeMicroBenchmarks {}

public struct GeoLocation: Hashable, Codable {
    var latitude: Double
    var longitude: Double
    var altitude: Double?
    var speed: Double?
    var heading: Double?

    init(latitude: Double, longitude: Double, altitude: Double? = nil, speed: Double? = nil, heading: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.speed = speed
        self.heading = heading
    }
}

public struct Note: Hashable, Codable {
    var timestamp: Date
    var description: String
    var location: GeoLocation
    var ratings: [Int]

    init(timestamp: Date, description: String, location: GeoLocation, ratings: [Int]) {
        self.timestamp = timestamp
        self.description = description
        self.location = location
        self.ratings = ratings
    }
}

public struct ExampleModel: Codable {
    var title: String
    var notes: [Note]

    init(title: String, notes: [Note]) {
        self.title = title
        self.notes = notes
    }
}
