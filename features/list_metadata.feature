Feature: List metadata

  Background:
    Given MailManager is initialized on "./mailman"

  Scenario: Getting the info URL
    Given I have a list named "foo"
    When I ask for its info_url
    Then I should get a URL

  Scenario: Getting the list address
    Given I have a list named "foo"
    When I ask for its address
    Then I should get an email address

  Scenario: Getting the request email
    Given I have a list named "foo"
    When I ask for its request_email
    Then I should get an email address

  Scenario: Setting & getting the list description
    Given I have a list named "foo"
    And I set its description to "foo list of fun"
    When I ask for its description
    Then I should get "foo list of fun"

  Scenario: Setting & getting the subject prefix
    Given I have a list named "foo"
    And I set its subject_prefix to "[Foo List] "
    When I ask for its subject_prefix
    Then I should get "[Foo List] "
