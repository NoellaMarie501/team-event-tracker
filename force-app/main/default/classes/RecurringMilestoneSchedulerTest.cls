@IsTest
private class RecurringMilestoneSchedulerTest {
  // Test create and register scheduler job
  @IsTest
  static void schedulesRecurringMilestoneJob() {
    // Arrange
    String cronExpression = '0 0 2 * * ?';

    // Act
    Test.startTest();

    String jobId = System.schedule(
      'Recurring Milestone Daily Job Test',
      cronExpression,
      new RecurringMilestoneScheduler()
    );

    Test.stopTest();

    // Assert
    System.assertNotEquals(
      null,
      jobId,
      'The recurring milestone scheduled job should be registered.'
    );

    CronTrigger scheduledJob = [
      SELECT Id, CronExpression, State
      FROM CronTrigger
      WHERE Id = :jobId
    ];

    System.assertEquals(cronExpression, scheduledJob.CronExpression);
  }

  // Test generate milestone when the scheduled job runs (simulate scheduled context)
  @IsTest
  static void shouldGenerateBirthdayMilestone_WhenScheduledJobRuns() {
    // Given
    Date targetBirthday = Date.today().addDays(10);
    Employee__c employee = new Employee__c(
      First_Name__c = 'Scheduled',
      Last_Name__c = 'User',
      Date_of_Birth__c = Date.newInstance(
        1990,
        targetBirthday.month(),
        targetBirthday.day()
      ),
      Active__c = true
    );
    insert employee;

    // When
    Test.startTest();
    System.schedule(
      'Recurring Milestone Execution Test',
      '0 0 2 * * ?',
      new RecurringMilestoneScheduler()
    );
    Test.stopTest();

    // Then
    List<Milestone__c> milestones = [
      SELECT Milestone_Category__c, Milestone_Date__c
      FROM Milestone__c
      WHERE Employee__c = :employee.Id
    ];

    Assert.areEqual(
      1,
      milestones.size(),
      'The scheduled job should generate exactly one milestone for the employee.'
    );
    Assert.areEqual(
      'Birthday',
      milestones[0].Milestone_Category__c,
      'The generated milestone should be a birthday.'
    );
    Assert.areEqual(
      targetBirthday,
      milestones[0].Milestone_Date__c,
      'The birthday milestone should fall on the upcoming birthday.'
    );
  }
}
