@IsTest
private class RecurringMilestoneSchedulerTest {
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
}
