import Foundation

enum HeritageCategory: String, CaseIterable, Codable {
    case cultural = "Cultural"
    case natural = "Natural"
    case mixed = "Mixed"
}

struct HeritageSite: Identifiable, Codable, Equatable {
    
    let id: UUID
    
    let name: String
    let location: String
    let images: [String]
    let category: HeritageCategory
    
    let history: String
    let keyFeatures: [String]
    let unescoReason: String
    
    let entryFee: Double
    let recommendedHours: Int
    
    let latitude: Double
    let longitude: Double
    
    init(
        id: UUID = UUID(),  
        name: String,
        location: String,
        images: [String],
        category: HeritageCategory,
        history: String,
        keyFeatures: [String],
        unescoReason: String,
        entryFee: Double,
        recommendedHours: Int,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.images = images
        self.category = category
        self.history = history
        self.keyFeatures = keyFeatures
        self.unescoReason = unescoReason
        self.entryFee = entryFee
        self.recommendedHours = recommendedHours
        self.latitude = latitude
        self.longitude = longitude
    }
}
