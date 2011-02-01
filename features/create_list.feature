Feature: Creating a new list
  As a developer using MailManager
  In order to create new mailing lists
  I want MailManager to offer this feature

  Background:
    Given MailManager is initialized on "./mailman"

  Scenario: Creating a new list
    Given no lists exist
    When I create a new list "foo"
    Then I should have a list named "foo"

  Scenario: Creating a list with the same name as an existing list
    Given no lists exist
    When I create a new list "foo"
    Then it should raise MailManager::ListNameConflictError when I create a new list "foo"
    And I should have 1 list
