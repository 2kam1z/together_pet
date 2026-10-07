import Testing
import Foundation
@testable import Together_pet

struct TogetherPetTests {
    
    @Test
    func streakIncreasesAtMoscowMidnight() throws {
        let formatter = ISO8601DateFormatter()
        
        let lastCompletion = try #require(
            formatter.date(from: "2026-10-06T23:59:00+03:00")
        )
        
        let nextDay = try #require(
                formatter.date(from: "2026-10-07T00:01:00+03:00")
        )
        
        let pet = SharedPet(
            name: "Пикси",
            emoji: "🐣",
            energy: 0,
            experience: 0
        )
        
        let pair = SharedPair(
            memberIDs: ["test-user"],
            pet: pet,
            streak: 4,
            lastGoalCompletedAt: lastCompletion
        )
        
        let result = pair.streakAfterCompletion(
            on: nextDay,
            calendar: GoalCalendar.moscow
        )
        
        #expect(result == 5)
    }
    
    @Test
    func streakDoesNotIncreaseOnSameMoscowDay() throws {
        let formatter = ISO8601DateFormatter()
        
        let lastCompletion = try #require(
            formatter.date(from: "2026-10-06T20:30:00Z")
        )
        
        let nextCompletion = try #require(
            formatter.date(from: "2026-10-06T23:59:00+03:00")
        )
        
        let pet = SharedPet(
            name: "Пикси",
            emoji: "🐣",
            energy: 0,
            experience: 0
        )
        
        let pair = SharedPair(
            memberIDs: ["test-user"],
            pet: pet,
            streak: 4,
            lastGoalCompletedAt: lastCompletion
        )
        
        let result = pair.streakAfterCompletion(
            on: nextCompletion,
            calendar: GoalCalendar.moscow
        )
        
        #expect(result == 4)
        
    }
    
    @Test
    func streakRestartAfterMissedDay() throws {
        let formatter = ISO8601DateFormatter()
        
        let lastCompletion = try #require(
            formatter.date(from: "2026-10-06T12:00:00+03:00")
        )
        
        let nextCompletion = try #require(
            formatter.date(from: "2026-10-08T12:00:00+03:00")
        )
        
        let pet = SharedPet(
            name: "Пикси",
            emoji: "🐣",
            energy: 0,
            experience: 0
        )
        
        let pair = SharedPair(
            memberIDs: ["test-user"],
            pet: pet,
            streak: 4,
            lastGoalCompletedAt: lastCompletion
        )
        
        let result = pair.streakAfterCompletion(
            on: nextCompletion,
            calendar: GoalCalendar.moscow
        )
        
        #expect(result == 1)
    }
    
    @Test
    func firstCompletionStartsStreak() throws {
        let formatter = ISO8601DateFormatter()
        
        let nextCompletion = try #require(
            formatter.date(from: "2026-10-08T12:00:00+03:00")
        )
        
        let pet = SharedPet(
            name: "Пикси",
            emoji: "🐣",
            energy: 0,
            experience: 0
        )
        
        let pair = SharedPair(
            memberIDs: ["test-user"],
            pet: pet,
        )
        
        let result = pair.streakAfterCompletion(
            on: nextCompletion,
            calendar: GoalCalendar.moscow
        )
        
        #expect(result == 1)
    }
    
    @Test
    func visibleStreakExpiresAfterMissedDay() throws {
        let formatter = ISO8601DateFormatter()
        
        let sameDay = try #require(
            formatter.date(from: "2026-10-06T18:00:00+03:00")
        )
        
        let nextDay = try #require(
            formatter.date(from: "2026-10-07T18:00:00+03:00")
        )
        
        let afterMissedDay = try #require(
            formatter.date(from: "2026-10-08T00:00:00+03:00")
        )
        
        let pet = SharedPet(
            name: "Пикси",
            emoji: "🐣",
            energy: 0,
            experience: 0
        )
        
        let pair = SharedPair(
            memberIDs: ["test-user"],
            pet: pet,
            streak: 4,
            lastGoalCompletedAt: sameDay
        )
        
        #expect(
            pair.visibleStreak(
                on: sameDay,
                calendar: GoalCalendar.moscow
            ) == 4
        )
        
        #expect(
            pair.visibleStreak(
                on: nextDay,
                calendar: GoalCalendar.moscow
            ) == 4
        )
        
        #expect(
            pair.visibleStreak(
                on: afterMissedDay,
                calendar: GoalCalendar.moscow
            ) == 0
        )
    }

}
