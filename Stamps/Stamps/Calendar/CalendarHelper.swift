//
//  CalendarHelper.swift
//  Stamps
//
//  Created by Vladimir Svidersky on 2/8/20.
//  Copyright © 2020 Vladimir Svidersky. All rights reserved.
//

import Foundation

class CalenderHelper {

    // We will add configuration later where user can choose whether to have Mon...Sun weeks of Sun...Sat
    static var weekStartMonday = true
    
    // Singleton instance
    static let shared = CalenderHelper()

    private var months = [Month]()
    private var weeks = [Week]()
    private var repository = Storage.shared.repository
    
    private init() {
        // Initialize months
        var firstDate = repository.getFirstDiaryDate()?.beginningOfMonth
        let lastDate = repository.getLastDiaryDate()?.beginningOfMonth
        
        if firstDate == nil {
            let today = Date()
            months.append(Month(today.byAddingMonth(-1)))
            months.append(Month(today))
            months.append(Month(today.byAddingMonth(1)))
        }
        else {
            while firstDate! <= lastDate! {
                months.append(Month(firstDate!))
                firstDate = firstDate!.byAddingMonth(1)
            }
            months.append(Month(firstDate!))
        }
        
        // Initialize weeks
        var firstWeekDate = repository.getFirstDiaryDate()?.beginningOfWeek
        let lastWeekDate = repository.getLastDiaryDate()?.beginningOfWeek
        
        
        if firstWeekDate == nil {
            let today = Date()
            weeks.append(Week(today.byAddingWeek(-1)))
            weeks.append(Week(today))
            weeks.append(Week(today.byAddingWeek(1)))
        } else {
            weeks.append(Week(firstWeekDate!.byAddingWeek(-1)))
            while firstWeekDate! <= lastWeekDate! {
                weeks.append(Week(firstWeekDate!))
                firstWeekDate = firstWeekDate!.byAddingWeek(1)
            }
            weeks.append(Week(firstWeekDate!))
        }
    }
    
    func insertFirstMonth() {
        var year = months[0].year
        var month = months[0].month - 1
        
        if month == 0 {
            year -= 1
            month = 12
        }
        months.insert(Month(Date(year: year, month: month)), at: 0)
    }

    func insertLastMonth() {
        var year = months[0].year
        var month = months[0].month + 1
        
        if month == 13 {
            year += 1
            month = 1
        }
        months.append(Month(Date(year: year, month: month)))
    }

    var currentMonths: [Month] {
        return months
    }
    
    var currentWeeks: [Week] {
        return weeks
    }
    
    var numberOfMonths: Int {
        return months.count
    }
    
    func monthAt(_ index: Int) -> Month {
        return months[index]
    }
    
    // Converts index representation of the date into actual simple date structure
    // Handles cases where certain days in a week falls out of the current month and return nil for them
    // For example: if January 1 is Tuesday, calling it for January with week index == 0 and day index == 0 (Monday)
    // will return nil
    func dateFromIndex(month: Int, week: Int, day: Int) -> Date? {
        let dayNum = week * 7 + day - months[month].firstIndex + 1
        if dayNum > 0 && dayNum <= months[month].numberOfDays {
            return Date(year: months[month].year, month: months[month].month, day: dayNum)
        }
        return nil
    }
    
    // Converts date into section, row and day index representing
    // position for this date in the calendar representation
    func indexForDay(date: Date) -> (IndexPath, Int)? {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        // Month was not found in the calendar
        guard let section = months.firstIndex(where: { $0.year == comps.year && $0.month == comps.month }) else { return nil }

        let month = months[section]
        let row = ((comps.day! + month.firstIndex - 1) / 7)

        // TODO: CalendarHelper should not know about specifics of CalendarViewController.
        // now we add +1 to week index to accomodate the fact that CalendarViewController displays
        // month header on the first row in each section
        return (IndexPath(row: row+1, section: section), month.indexForDay(comps.day!))
    }
    
    func weekIndexForDay(date: Date) -> Int? {
        let target = Week(date)
        return weeks.firstIndex(where: { week in
            week.year == target.year && week.weekOfYear == target.weekOfYear
        })
    }
    
    func labelForDay(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMMM, d"
        
        return df.string(from: date)
    }

    // Returns date of the end of week (Sunday or Saturday) based on
    // CalendarHelper setting and selected month
    func endOfWeek(date: Date) -> Date {
        let month = Month(date)
        let dayIndex = month.indexForDay(Calendar.current.component(.day, from: date))
        return date.byAddingDays(6-dayIndex)
    }
    
    // Returns date of the end of the month
    func endOfMonth(date: Date) -> Date {
        let month = Month(date)
        return Date(year: month.year, month: month.month, day: month.numberOfDays)
    }
}

extension CalenderHelper {
    class Month {
        let month: Int
        let year: Int
        
        // Most of month will have 5 weeks, edge cases will be identified in recalculateWeeks() method
        var numberOfWeeks: Int = 5

        // Which day of the week 1st of the month fall into on the calendar view:
        // when Monday is first day if the week: 0 - Monday, 1 - Tuesday ... 6 - Sunday
        // when Sunday is first day if the week: 0 - Sunday, 1 - Monday ... 6 - Saturday
        var firstIndex: Int = 0

        // Number of days in a month, duh
        var numberOfDays = 31
        
        init(_ date: Date) {
            self.month = Calendar.current.component(.month, from: date)
            self.year = Calendar.current.component(.year, from: date)
            recalculateWeeks()
        }
        
        var label: String {
            let df = DateFormatter()
            df.dateFormat = "MMMM"
            return df.string(from: Date(year: year, month: month))
        }

        // Returns index specific month days fall into (used in AwardManager to detect week that day falls into)
        func indexForDay(_ day: Int) -> Int {
            return (day % 7 + firstIndex - 1) % 7
        }
        
        func labelsForDaysInWeek(_ weekIdx: Int) -> [String] {
            var res = [String]()
            let today = Date().databaseKey
            
            for i in 0...6 {
                let num = i + (weekIdx*7) - firstIndex + 1
                if num > 0 && num <= numberOfDays {
                    let date = Date(year: year, month: month, day: num)
                    if date.databaseKey != today {
                        res.append("\(num)")
                    }
                    else {
                        res.append("*\(num)")
                    }
                }
                else {
                    res.append("")
                }
            }
            return res
        }

        
        func recalculateWeeks() {
            let calendar = Calendar.current
            
            // Get 1st of the month
            let first = Date(year: year, month: month, day: 1)
            // Get weekday for the 1st of the month
            let firstWeekDay = Calendar.current.component(.weekday, from: first)

            // Calendar week day defined starting with Sunday as 1 - we need to transform it to our index,
            // so Monday can be first

            if weekStartMonday == true {
                firstIndex = firstWeekDay == 1 ? 6 : firstWeekDay - 2
            }
            else {
                firstIndex = firstWeekDay - 1
            }
            
            // Get how many days in month we have
            numberOfDays = calendar.range(of: .day, in: .month, for: first)!.count
            
            // Special case for February and 4 weeks
            if (firstIndex == 0 && numberOfDays == 28) {
                numberOfWeeks = 4;
            }
            else {
                // Do we have spill over for 6 weeks or not?
                if (firstIndex + (numberOfDays - 28) > 7) {
                    numberOfWeeks = 6;
                }
            }
        }
    }
    
    class Week {
        let year: Int
        let month: Int
        let weekOfYear: Int
        
        var lastDay: Date {
            return Date(
                year: year,
                month: month,
                weekOfYear: weekOfYear,
                weekDay: 7 + (CalenderHelper.weekStartMonday ? 1 : 0),
                calendar: calendar
            )
        }
        
        private let calendar: Calendar
        
        init(_ date: Date) {
            self.month = Calendar.current.component(.month, from: date)
            self.year = Calendar.current.component(.year, from: date)
            self.weekOfYear = Calendar.current.component(.weekOfYear, from: date)
            
            var calendar = Calendar.current
            calendar.firstWeekday = CalenderHelper.weekStartMonday ? 2 : 1
            self.calendar = calendar
        }
        
        var label: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            
            return [1, 7]
                .map({ $0 + (CalenderHelper.weekStartMonday ? 1 : 0) })
                .map({ Date(year: year, month: month, weekOfYear: weekOfYear, weekDay: $0, calendar: calendar) })
                .map({ formatter.string(from: $0) })
                .joined(separator: " - ")
        }
        
        func labelsForDaysInWeek() -> [String] {
            let formatter = DateFormatter()
            formatter.dateFormat = "d"
            let today = Date().databaseKey
            
            return (1...7)
                .map({
                    return Date(year: year, month: month, weekOfYear: weekOfYear, weekDay: $0)
                        .byAddingDays(CalenderHelper.weekStartMonday ? 1 : 0)
                })
                .map({
                    let formatted = formatter.string(from: $0)
                    
                    if $0.databaseKey == today {
                        return "*\(formatted)"
                    } else {
                        return formatted
                    }
                })
        }
        
        func date(forWeekday day: Int) -> Date? {
            return Date(year: year, month: month, weekOfYear: weekOfYear, weekDay: day + 1)
                .byAddingDays(CalenderHelper.weekStartMonday ? 1 : 0)
        }
    }
}
