Feature: Chain Of Thought
  Decompose multi-step problems into intermediate steps

  Scenario: Multistep distance calculation
    Given I want to know a difficult distance calculation
    When I ask "How many full soccer fields would be needed to cover the distance between NYC and DC in a straight line?"
    Then I should be told something like "Approximately"
