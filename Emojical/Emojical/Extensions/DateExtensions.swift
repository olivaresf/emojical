//
//  DateExtensions.swift
//  Emojical
//
//  Created by Vladimir Svidersky on 1/18/20.
//  Copyright © 2020 Vladimir Svidersky. All rights reserved.
//

import Foundation

extension Date {
    
    // This date format is used to store date into database and sort records
    // YYYY-MM-DD with leading zeros for month and day
    var databaseKey: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: self)
    }
    
    var monthKey: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return String(df.string(from: self).prefix(7))
    }
    
    var databaseKeyWithTime: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm"
        return df.string(from: self)
    }

    // Convinience constructor when we have only date components
    init(year: Int, month: Int, day: Int = 1) {
        var comps = DateComponents.init()
        comps.month = month
        comps.year = year
        comps.day = day
        comps.hour = 22
        comps.minute = 0
        comps.second = 0
        
        self = Calendar.current.date(from: comps) ?? Date()
    }
    
    init(yyyyMmDd: String) {
        let comps = yyyyMmDd.split(separator: "-").map({ Int(String($0))! })
        if comps.count == 3 {
            self = Date(year: comps[0], month: comps[1], day: comps[2])
        } else {
            self = Date()
        }
    }
    
    /// Shifts date by number of days
    func byAddingDays(_ days: Int) -> Date {
        return self.advanced(by: TimeInterval(days * 24 * 60 * 60))
    }

    /// Shifts date by number of months
    func byAddingMonth(_ months: Int) -> Date {
        var comp = DateComponents()
        comp.month = months
        return Calendar.current.date(byAdding: comp, to: self)!
    }
    
    /// Shifts date by number of weeks
    func byAddingWeek(_ weeks: Int) -> Date {
        return self.byAddingDays(weeks * 7)
    }
    
    /// Property to recognize that date is today
    var isToday: Bool {
        return self.databaseKey == Date().databaseKey
    }
    
    /// Property to recognize whether day is a weekend (Saturday/Sunday) or not
    var isWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: self)
        return weekday == 1 || weekday == 7
    }
    
    /// Returns first date of the month for the date
    var firstOfMonth: Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: self)
        return Date(year: comps.year!, month: comps.month!)
    }

    /// Returns last day of the month for the date
    var lastOfMonth: Date {
        return firstOfMonth.byAddingMonth(1).byAddingDays(-1)
    }

    /// Returns last date of the week (Sunday or Saturday) based on CalendarHelper setting and selected month
    var lastOfWeek: Date {
        let month = CalendarHelper.Month(self)
        let dayIndex = month.indexForDay(Calendar.current.component(.day, from: self))
        return self.byAddingDays(6-dayIndex)
    }
}
