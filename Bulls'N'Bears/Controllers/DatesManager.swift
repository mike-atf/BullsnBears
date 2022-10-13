//
//  DatesManager.swift
//  Alogea
//
//  Created by aDav on 28/03/2022.
//  Copyright © 2022 AppToolFactory. All rights reserved.
//

import Foundation

let year: TimeInterval = 365*24*3600
let quarter: TimeInterval = year/4
let month: TimeInterval = year/12
let week: TimeInterval = 7*24*3600
let day: TimeInterval = 24*3600

class DatesManager {
    
    /// returns [first day of month 00:00, last day of month 23:59:59]
    class func monthDates(ofDate: Date) -> [Date] {
        
        let components: Set<Calendar.Component> = [.year, .month, .weekday, .day, .hour, .minute]

        var dateComponents = Calendar.current.dateComponents(components, from: ofDate)
        dateComponents.second = 0
        dateComponents.minute = 0
        dateComponents.hour = 0
        dateComponents.day = 1
        
        let firstDayDate = Calendar.current.date(from: dateComponents) ?? Date()

        dateComponents.second = 59
        dateComponents.minute = 59
        dateComponents.hour = 23
        dateComponents.month! += 1
        dateComponents.day! = 1

        let lastDayDate = (Calendar.current.date(from: dateComponents) ?? Date()).addingTimeInterval(-24*3600)
        
        return [firstDayDate, lastDayDate]

    }
    
    class func firstDayOfThisMonth(date:Date) -> Date {
        let components: Set<Calendar.Component> = [.year, .month, .weekday, .day, .hour, .minute]

        var dateComponents = Calendar.current.dateComponents(components, from: date)
        dateComponents.second = 0
        dateComponents.minute = 0
        dateComponents.hour = 0
        dateComponents.day = 1
        
        return Calendar.current.date(from: dateComponents)!

    }
    
    class func endOflastDayOfThisMonth(date:Date) -> Date {
        let components: Set<Calendar.Component> = [.year, .month, .weekday, .day, .hour, .minute]

        var dateComponents = Calendar.current.dateComponents(components, from: date)
        dateComponents.second = 0
        dateComponents.minute = 0
        dateComponents.hour = 0
        dateComponents.month! += 1
        dateComponents.day = 1
        
        return Calendar.current.date(from: dateComponents)!.addingTimeInterval(-1)

    }

    
    class func timeIntervalOfThisMonth(date:Date) -> TimeInterval {
        let components: Set<Calendar.Component> = [.year, .month, .weekday, .day, .hour, .minute]

        var dateComponents = Calendar.current.dateComponents(components, from: date)
        dateComponents.second = 0
        dateComponents.minute = 0
        dateComponents.hour = 0
        dateComponents.day = 1
        
        let firstDayDate = Calendar.current.date(from: dateComponents)!

        dateComponents = Calendar.current.dateComponents(components, from: date)
        dateComponents.second = 0
        dateComponents.minute = 0
        dateComponents.hour = 0
        dateComponents.day = 1
        dateComponents.month! += 1
        let nextFirstDayDate = Calendar.current.date(from: dateComponents)!

        return nextFirstDayDate.timeIntervalSince(firstDayDate)

    }

    
    class func firstDayOfPreviousMonth(date:Date) -> Date {
        let components: Set<Calendar.Component> = [.year, .month, .weekday, .day, .hour, .minute]

        var dateComponents = Calendar.current.dateComponents(components, from: date)
        dateComponents.second = 0
        dateComponents.minute = 0
        dateComponents.hour = 0
        dateComponents.month! -= 1
        dateComponents.day = 1
        
        return Calendar.current.date(from: dateComponents)!

    }

    
    /// returns [first day of month 00:00, last day of month 23:59:59]
    class func previousMonthDates(ofDate: Date) -> [Date] {
        
        let components: Set<Calendar.Component> = [.year, .month, .weekday, .day, .hour, .minute]

        var dateComponents = Calendar.current.dateComponents(components, from: ofDate)
        dateComponents.second = 0
        dateComponents.minute = 0
        dateComponents.hour = 0
        dateComponents.day = 1
        dateComponents.month! -= 1
        
        let firstDayDate = Calendar.current.date(from: dateComponents) ?? Date()

        dateComponents.second = 59
        dateComponents.minute = 59
        dateComponents.hour = 23
        dateComponents.month! += 1
        dateComponents.day! = 1

        let lastDayDate = (Calendar.current.date(from: dateComponents) ?? Date().addingTimeInterval(-24*3600))
        
        return [firstDayDate, lastDayDate]

    }

    
    class func endOflastWeekDay(ofDate: Date) -> Date {
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let today = calendar.startOfDay(for: Date().addingTimeInterval(7*24*3600))
        let dayOfWeek = calendar.component(.weekday, from: today) - calendar.firstWeekday
        let weekdays = calendar.range(of: .weekday, in: .weekOfYear, for: today)!
        let days = (weekdays.lowerBound ..< weekdays.upperBound)
            .compactMap { calendar.date(byAdding: .day, value: $0 - dayOfWeek, to: today) }

        
        return days.first!.addingTimeInterval(-1)

    }
    
    /// returns the Monday or equivalent or the week of the date provided
    class func beginningOfFirstWeekDay(ofDate: Date) -> Date {
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let today = calendar.startOfDay(for: Date())
        let dayOfWeek = calendar.component(.weekday, from: today) - calendar.firstWeekday
        let weekdays = calendar.range(of: .weekday, in: .weekOfYear, for: today)!
        let days = (weekdays.lowerBound ..< weekdays.upperBound)
            .compactMap { calendar.date(byAdding: .day, value: $0 - dayOfWeek, to: today) }

        
        return days.first!

    }
    
    class func beginningOfYear(of date: Date) -> Date {
        
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]

        var dateComponents = Calendar.current.dateComponents(components, from: date)
        dateComponents.second = 0
        dateComponents.minute = 0
        dateComponents.hour = 0
        dateComponents.month = 1
        dateComponents.day = 1
        
        return Calendar.current.date(from: dateComponents)!
    }
    
    class func beginningOfQuarter(of date: Date) -> Date {
        
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]

        var dateComponents = Calendar.current.dateComponents(components, from: date)
        dateComponents.second = 0
        dateComponents.minute = 0
        dateComponents.hour = 0
        if dateComponents.month! < 4 {
            dateComponents.month = 1
        } else if dateComponents.month! < 7 {
            dateComponents.month = 4
        } else if dateComponents.month! < 10 {
            dateComponents.month = 7
        } else {
            dateComponents.month = 10
        }
                    
        dateComponents.day = 1
        
        return Calendar.current.date(from: dateComponents)!
    }
    
    class func endOfQuarter(of date: Date) -> Date {
        
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]

        var dateComponents = Calendar.current.dateComponents(components, from: date)
        dateComponents.second = 0
        dateComponents.minute = 0
        dateComponents.hour = 0
        
        if dateComponents.month! < 4 {
            dateComponents.month = 3
            dateComponents.day = 31
        } else if dateComponents.month! < 7 {
            dateComponents.month = 6
            dateComponents.day = 30
        } else if dateComponents.month! < 10 {
            dateComponents.month = 9
            dateComponents.day = 30
        } else {
            dateComponents.month = 12
            dateComponents.day = 31
        }
        
        return Calendar.current.date(from: dateComponents)!
    }


    
    class func endOfYear(of date: Date) -> Date {
        
        let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]

        var dateComponents = Calendar.current.dateComponents(components, from: date)
        dateComponents.second = 59
        dateComponents.minute = 59
        dateComponents.hour = 23
        dateComponents.month = 12
        dateComponents.day = 31
        
        return Calendar.current.date(from: dateComponents)!
    }


    
    class func beginningOfDay(of date: Date) -> Date {
        
        return Calendar.current.startOfDay(for: date)
    }
    
    class func beginningOfNextDay(of date: Date) -> Date {
        
        return Calendar.current.startOfDay(for: date).addingTimeInterval(24*3600)
    }

    
    class func endOfDay(of date: Date) -> Date {

        return Calendar.current.startOfDay(for: date).addingTimeInterval(23*3600+59*60+59)
    }


}
