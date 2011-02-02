Feature: Deleting a list
  As a developer using MailManager
  In order to delete lists
  I want MailManager to offer this feature

  Background:
    Given MailManager is initialized on "./mailman"

  Scenario: Deleting a list
    Given I have a list named "foo"
    When I delete list "foo"
    Then I should have 0 lists

  Scenario: Deleting a list that doesn't exist
    Given no lists exist
    Then it should raise MailManager::ListNotFoundError when I delete list "foo"
