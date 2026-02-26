import Foundation

// Central itinerary calculation engine.
// Pure business logic — no UI layer dependencies.
enum TripPlannerEngine {

    // Travel and planning assumptions used throughout the engine.
    static let travelSpeedKmph: Double = 55.0
    static let maxActiveHoursPerDay: Double = 13.0
    static let bufferHoursPerDay: Double = 2.0
    static let netUsableHoursPerDay: Double = maxActiveHoursPerDay - bufferHoursPerDay
    static let overnightThresholdKm: Double = 180.0

    // Entry point for generating a full TripPlan.
    static func plan(input: TripInput) -> TripPlan {

        let oneWayHours    = input.distanceKm / travelSpeedKmph
        let bufferedTravel = oneWayHours * 2 * 1.15
        let totalActiveHrs = bufferedTravel + input.recommendedVisitHours

        let isSameDay = totalActiveHrs <= netUsableHoursPerDay
                     && input.distanceKm <= overnightThresholdKm

        let nightsRequired: Int
        let totalDays: Int

        if isSameDay {
            nightsRequired = 0
            totalDays = 1
        } else {
            totalDays = max(2, Int(ceil(totalActiveHrs / netUsableHoursPerDay)))
            nightsRequired = totalDays - 1
        }

        let costs = calculateCosts(
            input: input,
            totalDays: totalDays,
            nightsRequired: nightsRequired
        )

        let days = buildSchedule(
            input: input,
            oneWayHours: oneWayHours,
            totalDays: totalDays,
            isSameDay: isSameDay
        )

        return TripPlan(
            siteName: input.siteName,
            distanceKm: input.distanceKm,
            groupSize: input.groupSize,
            style: input.style,
            oneWayTravelTimeHours: oneWayHours,
            recommendedVisitHours: input.recommendedVisitHours,
            totalActiveHours: totalActiveHrs,
            isSameDayTrip: isSameDay,
            nightsRequired: nightsRequired,
            days: days,
            cost: costs
        )
    }


    // Calculates total and per-person cost breakdown.
    private static func calculateCosts(
        input: TripInput,
        totalDays: Int,
        nightsRequired: Int
    ) -> CostBreakdown {

        let style  = input.style
        let group  = Double(input.groupSize)
        let distRT = input.distanceKm * 2 * 1.15

        let entryFeeTotal    = input.baseEntryFeePerPerson * style.entryFeeMultiplier * group
        let travelCostTotal  = style.travelCostPerKmPerPerson * distRT * group
        let foodCostTotal    = style.foodCostPerPersonPerDay * Double(totalDays) * group
        let shelterCostTotal = style.shelterCostPerPersonPerNight * Double(nightsRequired) * group

        let raw      = entryFeeTotal + travelCostTotal + foodCostTotal + shelterCostTotal
        let rounded  = roundToNearestUnit(raw)
        let perPerson = roundToNearestUnit(rounded / Double(max(input.groupSize, 1)))

        return CostBreakdown(
            entryFeeTotal: entryFeeTotal,
            travelCostTotal: travelCostTotal,
            foodCostTotal: foodCostTotal,
            shelterCostTotal: shelterCostTotal,
            rawGrandTotal: raw,
            roundedGrandTotal: rounded,
            perPersonRounded: perPerson,
            travelCostPerKmPerPerson: style.travelCostPerKmPerPerson,
            foodCostPerPersonPerDay: style.foodCostPerPersonPerDay,
            shelterCostPerPersonPerNight: style.shelterCostPerPersonPerNight,
            entryFeeMultiplierUsed: style.entryFeeMultiplier
        )
    }


    // Rounds to a realistic Indian spending bracket.
    static func roundToNearestUnit(_ value: Double) -> Double {
        let unit: Double = value < 5000 ? 500 : 1000
        return (value / unit).rounded() * unit
    }


    // Builds structured day-wise plan.
    private static func buildSchedule(
        input: TripInput,
        oneWayHours: Double,
        totalDays: Int,
        isSameDay: Bool
    ) -> [DayPlan] {

        if isSameDay {
            return [buildSameDayPlan(
                departure: input.departureTime,
                oneWayHours: oneWayHours,
                visitHours: input.recommendedVisitHours,
                siteName: input.siteName
            )]
        }

        return buildMultiDayPlan(
            departure: input.departureTime,
            oneWayHours: oneWayHours,
            visitHours: input.recommendedVisitHours,
            siteName: input.siteName,
            totalDays: totalDays
        )
    }


    // Generates itinerary for same-day trip.
    private static func buildSameDayPlan(
        departure: TripTime,
        oneWayHours: Double,
        visitHours: Double,
        siteName: String
    ) -> DayPlan {

        let bufferedOneWay = oneWayHours * 1.15
        var cursor = departure
        var events: [ScheduleEvent] = []

        events.append(ScheduleEvent(time: cursor, icon: "figure.walk",
            title: "Depart home"))

        cursor = cursor.adding(hours: bufferedOneWay)
        events.append(ScheduleEvent(time: cursor, icon: "mappin.and.ellipse",
            title: "Arrive at \(siteName)"))

        cursor = cursor.adding(hours: 0.5)
        events.append(ScheduleEvent(time: cursor, icon: "cup.and.saucer.fill",
            title: "Rest & freshen up", durationHours: 0.5))

        cursor = cursor.adding(hours: 0.5)
        events.append(ScheduleEvent(time: cursor, icon: "building.columns.fill",
            title: "Explore \(siteName)", durationHours: visitHours))

        let lunchTime = cursor.adding(hours: max(1.0, visitHours / 2))
        events.append(ScheduleEvent(time: lunchTime, icon: "fork.knife",
            title: "Lunch break", durationHours: 0.75))

        cursor = cursor.adding(hours: visitHours + 0.75)
        events.append(ScheduleEvent(time: cursor, icon: "car.fill",
            title: "Depart for home", durationHours: bufferedOneWay))

        cursor = cursor.adding(hours: bufferedOneWay)
        events.append(ScheduleEvent(time: cursor, icon: "house.fill",
            title: "Arrive home"))

        let sorted = events.sorted {
            ($0.time.hour * 60 + $0.time.minute)
            < ($1.time.hour * 60 + $1.time.minute)
        }

        return DayPlan(
            dayNumber: 1,
            label: "Day 1 — Same-day trip",
            events: sorted,
            requiresOvernightStay: false,
            hoursActive: bufferedOneWay * 2 + visitHours + 1.75
        )
    }


    // Generates itinerary for multi-day trip.
    private static func buildMultiDayPlan(
        departure: TripTime,
        oneWayHours: Double,
        visitHours: Double,
        siteName: String,
        totalDays: Int
    ) -> [DayPlan] {

        var plans: [DayPlan] = []
        let bufferedOneWay  = oneWayHours * 1.15
        let explorePerDay   = netUsableHoursPerDay - 2.0

        var cursor = departure
        var day1Events: [ScheduleEvent] = []

        day1Events.append(ScheduleEvent(time: cursor, icon: "figure.walk",
            title: "Depart home"))

        cursor = cursor.adding(hours: bufferedOneWay)
        day1Events.append(ScheduleEvent(time: cursor, icon: "mappin.and.ellipse",
            title: "Arrive at \(siteName)"))

        cursor = cursor.adding(hours: 0.5)
        day1Events.append(ScheduleEvent(time: cursor, icon: "cup.and.saucer.fill",
            title: "Check in & freshen up", durationHours: 0.5))

        let day1Budget  = netUsableHoursPerDay - bufferedOneWay - 1.0
        let day1Explore = max(0, min(visitHours, day1Budget))

        if day1Explore > 0 {
            cursor = cursor.adding(hours: 0.5)
            day1Events.append(ScheduleEvent(time: cursor, icon: "building.columns.fill",
                title: "Begin exploring \(siteName)", durationHours: day1Explore))
            cursor = cursor.adding(hours: day1Explore)
        }

        day1Events.append(ScheduleEvent(time: cursor, icon: "fork.knife",
            title: "Dinner", durationHours: 0.75))

        plans.append(DayPlan(
            dayNumber: 1,
            label: "Day 1 — Travel to \(siteName)",
            events: day1Events,
            requiresOvernightStay: true,
            hoursActive: bufferedOneWay + 1.0 + day1Explore + 0.75
        ))

        var remainingVisit = visitHours - day1Explore

        for dayNum in 2...(max(2, totalDays - 1)) {

            var c = TripTime(hour: 7, minute: 0)
            var events: [ScheduleEvent] = []

            events.append(ScheduleEvent(time: c, icon: "sun.and.horizon.fill",
                title: "Breakfast", durationHours: 0.5))

            c = c.adding(hours: 0.5)

            if remainingVisit > 0 {

                let todayExplore = min(remainingVisit, explorePerDay)

                events.append(ScheduleEvent(time: c, icon: "building.columns.fill",
                    title: "Explore \(siteName)", durationHours: todayExplore))

                c = c.adding(hours: todayExplore)

                remainingVisit -= todayExplore

            } else {

                events.append(ScheduleEvent(time: c, icon: "figure.walk",
                    title: "Explore nearby area or rest", durationHours: 3))

                c = c.adding(hours: 3)
            }

            plans.append(DayPlan(
                dayNumber: dayNum,
                label: "Day \(dayNum)",
                events: events,
                requiresOvernightStay: true,
                hoursActive: netUsableHoursPerDay
            ))
        }

        return plans
    }


    static func formatHours(_ hours: Double) -> String {
        guard hours > 0 else { return "0 min" }
        if hours < 1 { return "\(Int((hours * 60).rounded())) min" }
        let h = Int(hours)
        let m = Int(((hours - Double(h)) * 60).rounded())
        return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
    }


    static func formatRupees(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        let formatted = formatter.string(from: NSNumber(value: Int(amount))) ?? "\(Int(amount))"
        return "₹\(formatted)"
    }
}
