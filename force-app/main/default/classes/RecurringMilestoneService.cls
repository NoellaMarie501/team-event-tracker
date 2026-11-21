public with sharing class RecurringMilestoneService {
  //recurring milestone generator
  public static void generateUpcomingMilestones() {
    //use today's date as our target date for recurring milestone creation
    //then use a 30-day lookahead window for upcoming milestones
    //this can be parameterized in future as needed
    Date today = Date.today();
    Date windowEnd = today.addDays(30);

    // get all active employees that qualify for recurring milestone creation i.e having a birthday or annivesary date
    List<Employee__c> employees = [
      SELECT
        Id,
        First_Name__c,
        Last_Name__c,
        Date_of_Birth__c,
        Employment_Start_Date__c
      FROM Employee__c
      WHERE
        Active__c = TRUE
        AND (Date_of_Birth__c != NULL
        OR Employment_Start_Date__c != NULL)
    ];

    //list of final recurring milesestones to create both for birthdays and anniversaries
    List<Milestone__c> potentialMilestones = new List<Milestone__c>();

    for (Employee__c employee : employees) {
      // Check birthday
      if (employee.Date_of_Birth__c != null) {
        Milestone__c birthday = prepareRecurringMilestone(
          employee,
          employee.Date_of_Birth__c,
          'Birthday',
          today,
          windowEnd
        );

        if (birthday != null) {
          potentialMilestones.add(birthday);
        }
      }

      // Check work anniversary
      if (employee.Employment_Start_Date__c != null) {
        Milestone__c anniversary = prepareRecurringMilestone(
          employee,
          employee.Employment_Start_Date__c,
          'Work Anniversary',
          today,
          windowEnd
        );

        if (anniversary != null) {
          potentialMilestones.add(anniversary);
        }
      }
    }

    //employee IDs for recurring milestones
    Set<Id> employeeIds = new Set<Id>();
    for (Milestone__c milestone : potentialMilestones) {
      employeeIds.add(milestone.Employee__c);
    }

    // Retrieve existing recurring milestones for these employees to check for duplicates
    List<Milestone__c> existingMilestones = [
      SELECT Employee__c, Milestone_Category__c, Occurrence_Year__c
      FROM Milestone__c
      WHERE
        Employee__c IN :employeeIds
        AND Milestone_Type__c = 'Recurring'
        AND Milestone_Category__c IN ('Birthday', 'Work Anniversary')
    ];

    // Build composite keys for existing milestones
    Set<String> existingMilestoneKeys = new Set<String>();

    for (Milestone__c milestone : existingMilestones) {
      String key =
        String.valueOf(milestone.Employee__c) +
        '|' +
        milestone.Milestone_Category__c +
        '|' +
        String.valueOf(milestone.Occurrence_Year__c.intValue());

      existingMilestoneKeys.add(key);
    }

    // Keep only potential milestones that don't already exist
    List<Milestone__c> milestonesToInsert = new List<Milestone__c>();

    for (Milestone__c potential : potentialMilestones) {
      String key =
        String.valueOf(potential.Employee__c) +
        '|' +
        potential.Milestone_Category__c +
        '|' +
        String.valueOf(potential.Milestone_Date__c.year());

      if (!existingMilestoneKeys.contains(key)) {
        milestonesToInsert.add(potential);
      }
    }

    // Insert new milestones
    if (!milestonesToInsert.isEmpty()) {
      insert milestonesToInsert;
    }
  }

  private static Milestone__c prepareRecurringMilestone(
    Employee__c employee,
    Date sourceDate,
    String category,
    Date today,
    Date windowEnd
  ) {
    // Calculate the next occurrence
    Date occasionDate = getAnnualDate(sourceDate, today.year());

    //check if occasion passed if yes check for next year as it can still be within the window.
    //For example, if today is Dec 29 and the birthday is Jan 2, we want to catch that upcoming event.
    if (occasionDate <= today) {
      occasionDate = getAnnualDate(sourceDate, today.year() + 1);
    }

    // check and Return nothing if the occasion is outside the look-ahead window
    if (occasionDate > windowEnd) {
      return null;
    }

    Milestone__c milestone = new Milestone__c();

    milestone.Name =
      employee.First_Name__c +
      ' ' +
      employee.Last_Name__c +
      ' - ' +
      category +
      ' ' +
      occasionDate.year();

    milestone.Milestone_Type__c = 'Recurring';
    milestone.Milestone_Category__c = category;
    milestone.Milestone_Date__c = occasionDate;
    milestone.Employee__c = employee.Id;

    return milestone;
  }

  //gets the original date for a recurring milestone ex: (March 15 1995), adjusted for leap years and return the milestone date for current year(2027)
  private static Date getAnnualDate(Date sourceDate, Integer year) {
    Integer month = sourceDate.month();
    Integer day = sourceDate.day();

    // Handle February 29 in non-leap years
    if (month == 2 && day == 29 && !Date.isLeapYear(year)) {
      day = 28;
    }

    return Date.newInstance(year, month, day);
  }
}
