String jobName = 'Recurring Milestone Daily Job';
String cronExpression = '0 0 2 * * ?';

// Check whether this job is already registered.
List<CronTrigger> existingJobs = [
    SELECT Id
    FROM CronTrigger
    WHERE CronJobDetail.Name = :jobName
];

if (existingJobs.isEmpty()) {
    System.schedule(
        jobName,
        cronExpression,
        new RecurringMilestoneScheduler()
    );
    System.debug('Recurring milestone job registered.');
} else {
    System.debug('Recurring milestone job is already registered.');
}
