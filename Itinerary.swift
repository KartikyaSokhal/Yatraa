
import Foundation

struct ItineraryCalculator {

    
    static let travelSpeedKmph: Double    = 60.0
    static let workingHoursPerDay: Double = 8.0

    
    struct Input {
        let distanceKm: Double
        let recommendedHours: Double
        let entryFeePerPerson: Double
        let travelCostPerKm: Double
        let foodCostPerPersonPerDay: Double
        let groupSize: Int
    }

    
    struct Result {
        let oneWayTravelTimeHours: Double
        let returnTravelTimeHours: Double
        let totalTravelTimeHours: Double
        let siteVisitHours: Double
        let totalHoursRequired: Double
        let daysRequired: Int
        let costBreakdown: CostBreakdown
        let dailySchedule: [DaySchedule]
    }

    struct CostBreakdown {
        let entryFeeTotal: Double
        let travelCostTotal: Double
        let foodCostTotal: Double
        let grandTotal: Double
        let perPersonTotal: Double
        let travelCostPerKmUsed: Double
        let foodCostPerDayUsed: Double

        var formattedGrandTotal: String { "₹\(Int(grandTotal))" }
        var formattedPerPerson: String   { "₹\(Int(perPersonTotal))" }
    }

    struct DaySchedule {
        let dayNumber: Int
        let activities: [String]
        let hoursAllocated: Double
    }

    
    static func calculate(_ input: Input) -> Result {
        let oneWayHours      = input.distanceKm / travelSpeedKmph
        let returnHours      = oneWayHours
        let totalTravelHours = oneWayHours + returnHours
        let totalHours       = totalTravelHours + input.recommendedHours

        let daysRequired = Int(ceil(totalHours / workingHoursPerDay))

        let travelCostPerPerson = (input.distanceKm * 2) * input.travelCostPerKm
        let entryFeeTotal   = input.entryFeePerPerson * Double(input.groupSize)
        let travelCostTotal = travelCostPerPerson * Double(input.groupSize)
        let foodCostTotal   = input.foodCostPerPersonPerDay * Double(input.groupSize) * Double(daysRequired)
        let grandTotal      = entryFeeTotal + travelCostTotal + foodCostTotal
        let perPersonTotal  = grandTotal / Double(max(input.groupSize, 1))

        let costBreakdown = CostBreakdown(
            entryFeeTotal: entryFeeTotal,
            travelCostTotal: travelCostTotal,
            foodCostTotal: foodCostTotal,
            grandTotal: grandTotal,
            perPersonTotal: perPersonTotal,
            travelCostPerKmUsed: input.travelCostPerKm,
            foodCostPerDayUsed: input.foodCostPerPersonPerDay
        )

        let schedule = buildSchedule(
            daysRequired: daysRequired,
            oneWayHours: oneWayHours,
            siteHours: input.recommendedHours
        )

        return Result(
            oneWayTravelTimeHours: oneWayHours,
            returnTravelTimeHours: returnHours,
            totalTravelTimeHours: totalTravelHours,
            siteVisitHours: input.recommendedHours,
            totalHoursRequired: totalHours,
            daysRequired: daysRequired,
            costBreakdown: costBreakdown,
            dailySchedule: schedule
        )
    }

   
    private static func buildSchedule(
        daysRequired: Int,
        oneWayHours: Double,
        siteHours: Double
    ) -> [DaySchedule] {

        var schedule: [DaySchedule] = []

        if daysRequired == 1 {
            let activities = [
                "Depart from your location (\(formatHours(oneWayHours)) travel)",
                "Arrive and explore site (\(formatHours(siteHours)))",
                "Return journey (\(formatHours(oneWayHours)) travel)"
            ]
            schedule.append(DaySchedule(dayNumber: 1, activities: activities, hoursAllocated: oneWayHours * 2 + siteHours))
        } else {
            let day1SiteHours = max(0, min(siteHours, workingHoursPerDay - oneWayHours))
            var day1Activities = ["Depart from your location (\(formatHours(oneWayHours)) travel)"]
            if day1SiteHours > 0 {
                day1Activities.append("Begin site exploration (\(formatHours(day1SiteHours)))")
            }
            schedule.append(DaySchedule(dayNumber: 1, activities: day1Activities, hoursAllocated: workingHoursPerDay))

            var remainingSiteHours = siteHours - day1SiteHours
            var dayNumber = 2
            while remainingSiteHours > workingHoursPerDay && dayNumber < daysRequired {
                schedule.append(DaySchedule(
                    dayNumber: dayNumber,
                    activities: ["Continue site exploration (\(formatHours(workingHoursPerDay)))"],
                    hoursAllocated: workingHoursPerDay
                ))
                remainingSiteHours -= workingHoursPerDay
                dayNumber += 1
            }

            var lastDayActivities: [String] = []
            if remainingSiteHours > 0 {
                lastDayActivities.append("Complete site exploration (\(formatHours(remainingSiteHours)))")
            }
            lastDayActivities.append("Return journey (\(formatHours(oneWayHours)) travel)")
            schedule.append(DaySchedule(
                dayNumber: daysRequired,
                activities: lastDayActivities,
                hoursAllocated: remainingSiteHours + oneWayHours
            ))
        }

        return schedule
    }

    
    static func formatHours(_ hours: Double) -> String {
        if hours < 1 {
            return "\(Int(hours * 60)) min"
        } else if hours == floor(hours) {
            return "\(Int(hours)) hr"
        } else {
            let h = Int(hours)
            let m = Int((hours - Double(h)) * 60)
            return m > 0 ? "\(h) hr \(m) min" : "\(h) hr"
        }
    }
}
