module Inference
  module Estimator
    class Evaluator


      bad = Fuzzyrb::FuzzySet.trapezoid([-2, -2, -2, -1])
      norm = FuzzySet.trapezoid([-1, 0, 0, 1])
      good = FuzzySet.trapezoid([1, 1, 1, 2])

      temp = [bad, norm, good]

      impl = new MamdaniImplication([FuzzyRule.new([bad], bad), FuzzyRule.new([norm], norm), FuzzyRule.new([norm], norm)])

      impl.evaluate(1.5, [:t_norm => :min, :implication => :mamdani])
    end
  end
end