
import SwiftUI

struct PlannerView: View {

    let site: HeritageSite

    @EnvironmentObject private var baseLocationManager: BaseLocationManager
    @Environment(\.dismiss) private var dismiss

    @State private var groupSize: Int = 1
    @State private var travelStyle: TravelStyle = .balanced
    @State private var departureHour: Int = 6
    @State private var expandedDay: Int? = 1
    @State private var showAllDays: Bool = false

    private var distanceKm: Double {
        baseLocationManager.distanceKm(to: site)
    }

    private var tripPlan: TripPlan? {
        guard distanceKm > 0 else { return nil }
        let input = TripInput(
            distanceKm: distanceKm,
            recommendedVisitHours: Double(site.recommendedHours),
            baseEntryFeePerPerson: site.entryFee,
            siteName: site.name,
            groupSize: groupSize,
            style: travelStyle,
            departureTime: TripTime(hour: departureHour, minute: 0)
        )
        return TripPlannerEngine.plan(input: input)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                siteHeader
                inputControls
                if let plan = tripPlan {
                    tripTypeBanner(plan)
                    timeSummaryCard(plan)
                    costCard(plan)
                    scheduleSection(plan)
                } else {
                    locationMissingCard
                }
                Spacer(minLength: 60)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Color(red: 0.96, green: 0.94, blue: 0.91).ignoresSafeArea())
        .navigationTitle("Plan My Visit")
        .navigationBarTitleDisplayMode(.inline)
    }

  

    private var siteHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(site.name)
                .font(.title2).fontWeight(.bold)

            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill").foregroundColor(.orange)
                if distanceKm > 0 {
                    Text("\(TripPlannerEngine.formatHours(distanceKm / TripPlannerEngine.travelSpeedKmph)) from \(baseLocationManager.baseCityName)")
                        .font(.subheadline).foregroundColor(.secondary)
                    Text("·").foregroundColor(.secondary)
                    Text(String(format: "%.0f km", distanceKm))
                        .font(.subheadline).foregroundColor(.secondary)
                } else {
                    Text("Location unavailable").font(.subheadline).foregroundColor(.secondary)
                }
            }

            HStack(spacing: 12) {
                infoChip(icon: "clock", text: "\(site.recommendedHours) hr visit")
                infoChip(icon: "ticket", text: "₹\(Int(site.entryFee))/person")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.orange)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

  
    private var inputControls: some View {
        VStack(spacing: 16) {

            // Group size
            HStack {
                Label("Group Size", systemImage: "person.2.fill")
                    .font(.subheadline).fontWeight(.medium)
                Spacer()
                Stepper(
                    "\(groupSize) \(groupSize == 1 ? "person" : "people")",
                    value: $groupSize, in: 1...30
                ).fixedSize()
            }

            Divider()

            
            VStack(alignment: .leading, spacing: 10) {
                Label("Travel Style", systemImage: "car.fill")
                    .font(.subheadline).fontWeight(.medium)

                HStack(spacing: 8) {
                    ForEach(TravelStyle.allCases) { style in
                        styleButton(style)
                    }
                }

                HStack {
                    rateChip(icon: "car",        label: "Travel", value: "₹\(Int(travelStyle.travelCostPerKmPerPerson))/km")
                    Spacer()
                    rateChip(icon: "fork.knife", label: "Food",   value: "₹\(Int(travelStyle.foodCostPerPersonPerDay))/day")
                    Spacer()
                    rateChip(icon: "bed.double", label: "Stay",   value: "₹\(Int(travelStyle.shelterCostPerPersonPerNight))/night")
                }
                .animation(.easeInOut(duration: 0.2), value: travelStyle.rawValue)
            }

            Divider()

          
            HStack {
                Label("Depart at", systemImage: "clock.arrow.circlepath")
                    .font(.subheadline).fontWeight(.medium)
                Spacer()
                Picker("Depart", selection: $departureHour) {
                    ForEach([4, 5, 6, 7, 8, 9], id: \.self) { h in
                        Text(String(format: "%02d:00", h)).tag(h)
                    }
                }
                .pickerStyle(.menu)
                .tint(.orange)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private func styleButton(_ style: TravelStyle) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { travelStyle = style }
        } label: {
            VStack(spacing: 4) {
                Text(style.emoji).font(.title2)
                Text(style.displayName).font(.caption2).fontWeight(.semibold)
                Text(style.tagline)
                    .font(.system(size: 9))
                    .foregroundColor(travelStyle == style ? .white.opacity(0.8) : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(travelStyle == style ? Color.orange : Color(.systemGray5))
            .foregroundColor(travelStyle == style ? .white : .primary)
            .cornerRadius(12)
        }
    }

    private func rateChip(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.caption2).foregroundColor(.orange)
            Text(label).font(.system(size: 9)).foregroundColor(.secondary)
            Text(value).font(.caption2).fontWeight(.semibold)
        }
    }

   

    private func tripTypeBanner(_ plan: TripPlan) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(plan.isSameDayTrip ? Color.orange.opacity(0.12) : Color.indigo.opacity(0.10))
                    .frame(width: 44, height: 44)
                Image(systemName: plan.isSameDayTrip ? "sun.max.fill" : "moon.stars.fill")
                    .font(.title3)
                    .foregroundColor(plan.isSameDayTrip ? .orange : .indigo)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(plan.tripTypeLabel)
                    .font(.subheadline).fontWeight(.bold)
                Text(plan.isSameDayTrip
                     ? "You can be home the same day."
                     : "\(plan.nightsRequired) overnight stay\(plan.nightsRequired == 1 ? "" : "s") required.")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(plan.isSameDayTrip ? Color.orange.opacity(0.06) : Color.indigo.opacity(0.06))
        .cornerRadius(14)
    }

    

    private func timeSummaryCard(_ plan: TripPlan) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.orange)
                Text("Trip Overview")
                    .font(.headline)
            }
            .padding(.bottom, 12)

            Divider()

            VStack(spacing: 0) {
                timeRow("arrow.left.arrow.right", "Distance",
                        String(format: "%.0f km one-way", plan.distanceKm))
                timeRow("car.fill", "Travel time",
                        TripPlannerEngine.formatHours(plan.oneWayTravelTimeHours) + " each way")
                timeRow("building.columns.fill", "Site visit",
                        TripPlannerEngine.formatHours(plan.recommendedVisitHours))
                timeRow("hourglass", "Total active time",
                        TripPlannerEngine.formatHours(plan.totalActiveHours))
                timeRow("moon.fill",
                        plan.isSameDayTrip ? "Overnight stay" : "Nights away",
                        plan.isSameDayTrip ? "Not required" : "\(plan.nightsRequired) night\(plan.nightsRequired == 1 ? "" : "s")",
                        highlight: !plan.isSameDayTrip,
                        isLast: true)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }



    private func costCard(_ plan: TripPlan) -> some View {
        let c = plan.cost
        return VStack(alignment: .leading, spacing: 0) {

            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "indianrupeesign.circle.fill").foregroundColor(.orange)
                    Text("Estimated Cost").font(.headline)
                }
                Spacer()
                styleBadge(plan.style)
            }
            .padding(.bottom, 12)

            Divider()

            VStack(spacing: 0) {
                costRow(
                    icon: "ticket",
                    title: "Entry fee\(c.entryFeeMultiplierUsed > 1 ? " + guide" : "")",
                    subtitle: "\(plan.groupSize) person\(plan.groupSize > 1 ? "s" : "")",
                    value: TripPlannerEngine.formatRupees(c.entryFeeTotal)
                )
                costRow(
                    icon: "car.fill",
                    title: "Travel",
                    subtitle: "₹\(Int(c.travelCostPerKmPerPerson))/km · \(String(format: "%.0f", plan.distanceKm * 2)) km RT",
                    value: TripPlannerEngine.formatRupees(c.travelCostTotal)
                )
                costRow(
                    icon: "fork.knife",
                    title: "Food",
                    subtitle: "₹\(Int(c.foodCostPerPersonPerDay))/day · \(plan.totalDays) day\(plan.totalDays > 1 ? "s" : "")",
                    value: TripPlannerEngine.formatRupees(c.foodCostTotal)
                )
                if c.shelterCostTotal > 0 {
                    costRow(
                        icon: "bed.double.fill",
                        title: "Stay",
                        subtitle: "₹\(Int(c.shelterCostPerPersonPerNight))/night · \(plan.nightsRequired) night\(plan.nightsRequired > 1 ? "s" : "")",
                        value: TripPlannerEngine.formatRupees(c.shelterCostTotal),
                        isLast: true
                    )
                }
            }
            .padding(.top, 4)

            // Total block
            VStack(spacing: 10) {
                Divider()

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Grand Total")
                            .font(.subheadline).fontWeight(.bold)
                        Text("Rounded to nearest ₹\(c.rawGrandTotal < 5000 ? "500" : "1,000")")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(c.formattedGrandTotal)
                        .font(.title2).fontWeight(.bold).foregroundColor(.orange)
                }

                if plan.groupSize > 1 {
                    HStack {
                        Text("Per person")
                            .font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Text(c.formattedPerPerson)
                            .font(.subheadline).fontWeight(.semibold).foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                costCallout(plan: plan)
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private func costRow(icon: String, title: String, subtitle: String, value: String, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.10))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline).fontWeight(.medium)
                    Text(subtitle)
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Text(value)
                    .font(.subheadline).fontWeight(.semibold)
            }
            .padding(.vertical, 10)

            if !isLast {
                Divider().padding(.leading, 44)
            }
        }
    }

    @ViewBuilder
    private func costCallout(plan: TripPlan) -> some View {
        switch plan.style {
        case .budget:
            if let saving = savingsVsBalanced() {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill").foregroundColor(.green).font(.caption)
                    Text("Saves \(TripPlannerEngine.formatRupees(saving)) vs Balanced")
                        .font(.caption).foregroundColor(.green).fontWeight(.medium)
                }
                .padding(10).background(Color.green.opacity(0.08)).cornerRadius(10)
            }
        case .balanced:
            EmptyView()
        case .premium:
            HStack(spacing: 6) {
                Image(systemName: "star.fill").foregroundColor(.orange).font(.caption)
                Text("Private transport · guided entry · quality dining & stays")
                    .font(.caption).foregroundColor(.secondary)
            }
            .padding(10).background(Color.orange.opacity(0.07)).cornerRadius(10)
        }
    }

    private func savingsVsBalanced() -> Double? {
        guard distanceKm > 0 else { return nil }
        let input = TripInput(
            distanceKm: distanceKm,
            recommendedVisitHours: Double(site.recommendedHours),
            baseEntryFeePerPerson: site.entryFee,
            siteName: site.name,
            groupSize: groupSize,
            style: .balanced,
            departureTime: TripTime(hour: departureHour, minute: 0)
        )
        let balancedPlan = TripPlannerEngine.plan(input: input)
        let saving = balancedPlan.cost.roundedGrandTotal - (tripPlan?.cost.roundedGrandTotal ?? 0)
        return saving > 0 ? saving : nil
    }



    private func scheduleSection(_ plan: TripPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.checkmark")
                        .foregroundColor(.orange)
                    Text("Day-by-Day Schedule")
                        .font(.headline)
                }
                Spacer()
                if plan.days.count > 1 {
                    Button(showAllDays ? "Collapse" : "Show All") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showAllDays.toggle()
                        }
                    }
                    .font(.subheadline).fontWeight(.medium).foregroundColor(.orange)
                }
            }

            let visibleDays = showAllDays ? plan.days : Array(plan.days.prefix(1))
            ForEach(visibleDays) { day in
                dayCard(day)
            }
        }
    }

    private func dayCard(_ day: DayPlan) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    expandedDay = expandedDay == day.dayNumber ? nil : day.dayNumber
                }
            } label: {
                HStack(spacing: 12) {
                    // Day number badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange)
                            .frame(width: 36, height: 36)
                        Text("\(day.dayNumber)")
                            .font(.subheadline).fontWeight(.bold)
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(day.label)
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.primary)
                        if day.requiresOvernightStay {
                            HStack(spacing: 4) {
                                Image(systemName: "bed.double.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.indigo)
                                Text("Overnight stay")
                                    .font(.caption2)
                                    .foregroundColor(.indigo)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: expandedDay == day.dayNumber ? "chevron.up" : "chevron.down")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            
            if expandedDay == day.dayNumber {
                VStack(alignment: .leading, spacing: 0) {
                    Divider().padding(.horizontal, 14)

                    ForEach(Array(day.events.enumerated()), id: \.element.id) { index, event in
                        eventRow(event, isLast: index == day.events.count - 1)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private func eventRow(_ event: ScheduleEvent, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {

            
            VStack(spacing: 0) {
                
                ZStack {
                    Circle()
                        .fill(isLast ? Color.orange : Color.orange.opacity(0.12))
                        .frame(width: 28, height: 28)
                    Image(systemName: event.icon)
                        .font(.system(size: 11))
                        .foregroundColor(isLast ? .white : .orange)
                }
               
                if !isLast {
                    Rectangle()
                        .fill(Color.orange.opacity(0.20))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.top, 2)
                }
            }
            .frame(width: 28)
            .padding(.leading, 14)

          
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(event.time.displayString)
                        .font(.caption).fontWeight(.bold)
                        .foregroundColor(.orange)
                        .monospacedDigit()
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color.orange.opacity(0.10))
                        .cornerRadius(6)

                    Text(event.title)
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundColor(.primary)
                }

                if event.durationHours > 0 {
                    Text("≈ \(TripPlannerEngine.formatHours(event.durationHours))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 2)
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 14)
            .padding(.vertical, 12)

            Spacer()
        }
    }

    

    private var locationMissingCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "location.slash.fill")
                .foregroundColor(.orange).font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text("Location Unavailable")
                    .font(.subheadline).fontWeight(.semibold)
                Text("Go back and set your planning base location.")
                    .font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(14)
    }

    

    private func timeRow(_ icon: String, _ title: String, _ value: String, highlight: Bool = false, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.10))
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                Text(title)
                    .font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .fontWeight(highlight ? .bold : .medium)
                    .foregroundColor(highlight ? .orange : .primary)
            }
            .padding(.vertical, 9)

            if !isLast {
                Divider().padding(.leading, 42)
            }
        }
    }

    private func styleBadge(_ style: TravelStyle) -> some View {
        Text(style.emoji + " " + style.displayName)
            .font(.caption).fontWeight(.semibold)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Color.orange.opacity(0.12))
            .foregroundColor(.orange)
            .cornerRadius(8)
    }
}
