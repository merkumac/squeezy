//
//  CompressionPlannerTests.swift
//  Squeezy
//
//  Created by kort on 25/10/2026.
//

import Testing
@testable import Squeezy

struct CompressionPlannerTests {
    @Test func plansStayWithinTargetBudget() {
        let plans = CompressionPlanner().makePlans(duration: 7200, hasAudio: true, sourceBytes: 2_000_000_000)
        
        #expect(plans.count == 3)
        
        for plan in plans {
            #expect(plan.estimatedBytes <= plan.targetBytes)
            #expect(plan.videoBitrate >= 0)
        }
    }
    
    @Test func longerVideoGetsLowerBitrate() {
        let planner = CompressionPlanner()
        
        let short = planner.makePlans(duration: 3600, hasAudio: true, sourceBytes: 2_000_000_000)
        let long = planner.makePlans(duration: 7200, hasAudio: true, sourceBytes: 2_000_000_000)
        
        #expect(short[1].videoBitrate > long[1].videoBitrate)
    }
    
    @Test func audioBudgetIsZeroWhenMissing() {
        let plans = CompressionPlanner().makePlans(duration: 3600, hasAudio: false, sourceBytes: 2_000_000_000)
        
        #expect(plans.allSatisfy {
            $0.audioBitrate == 0
        })
    }
    
    @Test func invalidDurationProducesNoPlans() {
        let planner = CompressionPlanner()
        
        #expect(planner.makePlans(duration: 0, hasAudio: true, sourceBytes: 1_000_000).isEmpty)
        #expect(planner.makePlans(duration: -.infinity, hasAudio: true, sourceBytes: 1_000_000).isEmpty)
        #expect(planner.makePlans(duration: .nan, hasAudio: true, sourceBytes: 1_000_000).isEmpty)
        #expect(planner.makePlans(duration: 30, hasAudio: true, sourceBytes: 0).isEmpty)
        #expect(planner.makePlans(duration: 30, hasAudio: true, sourceBytes: -1).isEmpty)
    }
    
    @Test func shortVideosDoesNotExpand() {
        let plans = CompressionPlanner().makePlans(duration: 30, hasAudio: true, sourceBytes: 2_500_000)
        
        #expect(plans.count == 3)
        
        for plan in plans {
            #expect(plan.targetBytes <= 2_250_000)
            #expect(plan.estimatedBytes < 2_500_000)
            #expect(plan.videoBitrate < 1_000_000)
        }
    }
}
