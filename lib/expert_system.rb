module ExpertSystem
  class Estimator
    ACCEPTANCE_CRITERIA_SETS = [
        FuzzySet.trapezoid([-2, -2, -2, 0]),
        FuzzySet.trapezoid([-0.5, 0, 0, 0.5]),
        FuzzySet.trapezoid([0, 2, 2, 2])
    ]

    ACCEPTANCE_CRITERIA_DYNAMICS_SETS = [
        FuzzySet.trapezoid([-4, -4, -4, 0]),
        FuzzySet.trapezoid([-1, 0, 0, 1]),
        FuzzySet.trapezoid([0, 4, 4, 4])
    ]

    ON_TIME_DELIVERY_SETS = [
        FuzzySet.trapezoid([0, 0, 0.5, 0.7]),
        FuzzySet.trapezoid([0.5, 0.7, 0.7, 0.9]),
        FuzzySet.trapezoid([0.5, 0.9, 1, 1])
    ]

    VELOCITY_DYNAMICS_SETS = [
        FuzzySet.trapezoid([0, 0, 0, 1]),
        FuzzySet.trapezoid([0.9, 1, 1, 1.1]),
        FuzzySet.trapezoid([0.8, 0.9, 1, 1])
    ]

    RESULT_SET = [
        FuzzySet.trapezoid([0, 0, 50, 60]),
        FuzzySet.trapezoid([50, 70, 70, 90]),
        FuzzySet.trapezoid([80, 90, 100, 100])
    ]

    def initialize(sprint)
      @sprint = sprint
    end

    def inference
      rules = []

      3.times do |a|
        3.times do |b|
          3.times do |c|
            3.times do |d|
              result = ((a + b + c + d) / 4).round
              rules << FuzzyRule.new([ACCEPTANCE_CRITERIA_SETS[a], ACCEPTANCE_CRITERIA_DYNAMICS_SETS[b], VELOCITY_DYNAMICS_SETS[c], ON_TIME_DELIVERY_SETS[d]], RESULT_SET[result])
            end
          end
        end
      end

      ms = MamdaniImplication.new(rules)
      ms.evaluate([acceptance_rate, acceptance_rate_dynamics, velocity_dynamics, on_time_delivery], {:t_norm => :min, :implication => :larsen, :defuzzification => :CoG})
    end

    def single_inference(sets, value)
      rules = []
      rules << FuzzyRule.new([sets[0]], RESULT_SET[0])
      rules << FuzzyRule.new([sets[1]], RESULT_SET[1])
      rules << FuzzyRule.new([sets[2]], RESULT_SET[2])

      ms = MamdaniImplication.new(rules)
      ms.evaluate([value], {:t_norm => :min, :implication => :larsen, :defuzzification => :CoG})
    end

    def acceptance_rate_inference(member = nil)
      single_inference(ACCEPTANCE_CRITERIA_SETS, acceptance_rate)
    end

    def acceptance_rate_dynamics_inference
      single_inference(ACCEPTANCE_CRITERIA_DYNAMICS_SETS, acceptance_rate_dynamics)
    end

    def on_time_delivery_inference
      single_inference(ON_TIME_DELIVERY_SETS, on_time_delivery)
    end

    def velocity_dynamics_inference
      single_inference(VELOCITY_DYNAMICS_SETS, velocity_dynamics)
    end

    def filter_stories(sprint, member = nil)
      issues = []
      sprint.fixed_issues.each do |issue|
        issues << issue if issue.closed? && (member === nil || issue.assigned_to_id == member.user.id)
      end
      issues
    end

    def velocity_dynamics
      if @sprint.prev.nil?
        1
      else
        old = velocity(@sprint.prev, true)
        new = velocity(@sprint, true)
        new / old
      end
    end

    def acceptance_rate_dynamics
      if @sprint.prev.nil?
        0
      else
        old = acceptance_rate(@sprint.prev)
        new = acceptance_rate(@sprint)
        new - old
      end
    end

    def acceptance_rate(sprint = nil)
      sprint = @sprint if sprint === nil
      acceptance_rate_internal(filter_stories(sprint))
    end

    def on_time_delivery
      velocity(@sprint, true) / velocity(@sprint)
    end

    def acceptance_rate_internal(issues)
      return 0 if issues.count == 0

      sum = 0
      issues.each do |issue|
        weight = issue.story_points.is_a?(Integer) ? issue.story_points : 1
        sum += issue.acceptance_rate * weight if issue.acceptance_rate.is_a? Integer
      end
      sum.to_f / issues.count
    end

    def velocity(sprint, fact = false)
      sum = 0
      sprint.fixed_issues.each do |issue|
        sum += issue.story_points if (! fact || issue.closed?)
      end
      sum
    end
  end
end