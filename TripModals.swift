import Foundation

// Represents user's travel preference with realistic Indian pricing assumptions.
enum TravelStyle: String, CaseIterable, Identifiable, Codable, Sendable {

    case budget
    case balanced
    case premium

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .budget:   return "Budget"
        case .balanced: return "Balanced"
        case .premium:  return "Premium"
        }
    }

    var emoji: String {
        switch self {
        case .budget:   return "🎒"
        case .balanced: return "🚗"
        case .premium:  return "✈️"
        }
    }

    var tagline: String {
        switch self {
        case .budget:   return "Bus / auto"
        case .balanced: return "Cab / taxi"
        case .premium:  return "Private AC car"
        }
    }

    // Per person per km
    var travelCostPerKmPerPerson: Double {
        switch self {
        case .budget:   return 4.0
        case .balanced: return 10.0
        case .premium:  return 18.0
        }
    }

    // Per person per day
    var foodCostPerPersonPerDay: Double {
        switch self {
        case .budget:   return 350.0
        case .balanced: return 700.0
        case .premium:  return 1500.0
        }
    }

    // Per person per night
    var shelterCostPerPersonPerNight: Double {
        switch self {
        case .budget:   return 400.0
        case .balanced: return 1200.0
        case .premium:  return 3500.0
        }
    }

    // Premium includes guide / add-ons
    var entryFeeMultiplier: Double {
        switch self {
        case .budget, .balanced: return 1.0
        case .premium:           return 1.8
        }
    }
}


// Input required by TripPlannerEngine to generate a TripPlan.
struct TripInput: Sendable {

    let distanceKm: Double
    let recommendedVisitHours: Double
    let baseEntryFeePerPerson: Double
    let siteName: String
    let groupSize: Int
    let style: TravelStyle

    // Defaults to 6:00 AM departure.
    var departureTime: TripTime = TripTime(hour: 6, minute: 0)
}


// Lightweight time representation (24h clock) for itinerary scheduling.
struct TripTime: Sendable, Equatable {

    let hour: Int
    let minute: Int

    func adding(hours: Double) -> TripTime {
        let totalMinutes = Int(Double(hour * 60 + minute) + hours * 60)
        let h = (totalMinutes / 60) % 24
        let m = totalMinutes % 60
        return TripTime(hour: h, minute: m)
    }

    var displayString: String {
        String(format: "%02d:%02d", hour, minute)
    }
}


// Represents a timed activity within a day.
struct ScheduleEvent: Identifiable, Sendable {

    let id: UUID
    let time: TripTime
    let icon: String
    let title: String
    let durationHours: Double

    init(
        id: UUID = UUID(),
        time: TripTime,
        icon: String,
        title: String,
        durationHours: Double = 0
    ) {
        self.id = id
        self.time = time
        self.icon = icon
        self.title = title
        self.durationHours = durationHours
    }
}


// Contains structured schedule data for one day of the trip.
struct DayPlan: Identifiable, Sendable {

    let id: UUID
    let dayNumber: Int
    let label: String
    let events: [ScheduleEvent]
    let requiresOvernightStay: Bool
    let hoursActive: Double

    init(
        id: UUID = UUID(),
        dayNumber: Int,
        label: String,
        events: [ScheduleEvent],
        requiresOvernightStay: Bool,
        hoursActive: Double
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.label = label
        self.events = events
        self.requiresOvernightStay = requiresOvernightStay
        self.hoursActive = hoursActive
    }
}


// Itemised cost summary used by the UI for detailed breakdown display.
struct CostBreakdown: Sendable {

    let entryFeeTotal: Double
    let travelCostTotal: Double
    let foodCostTotal: Double
    let shelterCostTotal: Double

    let rawGrandTotal: Double
    let roundedGrandTotal: Double
    let perPersonRounded: Double

    let travelCostPerKmPerPerson: Double
    let foodCostPerPersonPerDay: Double
    let shelterCostPerPersonPerNight: Double
    let entryFeeMultiplierUsed: Double

    var formattedGrandTotal: String { "₹\(Int(roundedGrandTotal))" }
    var formattedPerPerson: String { "₹\(Int(perPersonRounded))" }
}


// Final output returned by TripPlannerEngine.
struct TripPlan: Sendable {

    let siteName: String
    let distanceKm: Double
    let groupSize: Int
    let style: TravelStyle

    let oneWayTravelTimeHours: Double
    let recommendedVisitHours: Double
    let totalActiveHours: Double

    let isSameDayTrip: Bool
    let nightsRequired: Int

    let days: [DayPlan]
    let cost: CostBreakdown

    var totalDays: Int { days.count }

    var tripTypeLabel: String {
        isSameDayTrip
        ? "Same-day trip"
        : "\(totalDays) day trip · \(nightsRequired) night\(nightsRequired == 1 ? "" : "s")"
    }
}
