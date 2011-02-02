Feature: List moderators administration

  Background:
    Given MailManager is initialized on "./mailman"
    Given I have a list named "foo"

  Scenario: Adding a moderator
    When I add a moderator "me@bar.com"
    Then I should have 1 moderator

  Scenario: Adding a moderator that already exists
    Given I add a moderator "me@bar.com"
    Then it should raise MailManager::ModeratorAlreadyExistsError when I add a moderator "me@bar.com"

  Scenario: Deleting a moderator
    Given I add a moderator "me@bar.com"
    When I delete a moderator "me@bar.com"
    Then I should have 0 moderators

  Scenario: Deleting a moderator that doesn't exist
    Given I add a moderator "other@bar.com"
    Then it should raise MailManager::ModeratorNotFoundError when I delete a moderator "me@bar.com"
