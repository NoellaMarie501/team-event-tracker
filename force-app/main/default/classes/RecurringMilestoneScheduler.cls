public with sharing class RecurringMilestoneScheduler implements Schedulable {
  public void execute(SchedulableContext context) {
    RecurringMilestoneService.generateUpcomingMilestones();
  }
}
