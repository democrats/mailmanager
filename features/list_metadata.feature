Feature: List metadata

  Background:
    Given MailManager is initialized on "./mailman"

  Scenario: Getting the info URL
    Given I have a list named "foo"
    When I ask for its info_url
    Then I should get a URL
