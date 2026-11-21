@IsTest
private class RecurringMilestoneServiceTest {
  // TC-002: Test Successful Milestone creation (birthday and work anniversary generated together)
  @IsTest
  static void generatesUpcomingBirthdayMilestone() {
    // Arrange: Create an active employee with both a birthday and a work anniversary in the window
    Date targetBirthday = Date.today().addDays(10);
    Date targetAnniv = Date.today().addDays(20);

    Employee__c employee = new Employee__c(
      First_Name__c = 'Marie',
      Last_Name__c = 'Kieng',
      Date_of_Birth__c = Date.newInstance(
        1992,
        targetBirthday.month(),
        targetBirthday.day()
      ),
      Employment_Start_Date__c = Date.newInstance(
        2016,
        targetAnniv.month(),
        targetAnniv.day()
      ),
      Active__c = true
    );

    insert employee;

    // Act: Run the recurring milestone generator
    Test.startTest();

    RecurringMilestoneService.generateUpcomingMilestones();

    Test.stopTest();

    // Assert: Verify the birthday milestone was created
    List<Milestone__c> createdBirthdayMilestones = [
      SELECT
        Name,
        Milestone_Type__c,
        Milestone_Category__c,
        Milestone_Date__c,
        Employee__c,
        Occurrence_Year__c
      FROM Milestone__c
      WHERE Employee__c = :employee.Id AND Milestone_Category__c = 'Birthday'
    ];

    Milestone__c createdBirthdayMilestone = createdBirthdayMilestones[0];

    System.assertEquals(
      1,
      createdBirthdayMilestones.size(),
      'One upcoming birthday milestone should be created.'
    );

    System.assertEquals(
      'Recurring',
      createdBirthdayMilestone.Milestone_Type__c
    );
    System.assertEquals(
      'Birthday',
      createdBirthdayMilestone.Milestone_Category__c
    );
    System.assertEquals(
      targetBirthday,
      createdBirthdayMilestone.Milestone_Date__c
    );
    System.assertEquals(employee.Id, createdBirthdayMilestone.Employee__c);
    System.assertEquals(
      targetBirthday.year(),
      createdBirthdayMilestone.Occurrence_Year__c
    );

    // Assert: Verify the work anniversary milestone was created in the same run
    List<Milestone__c> anniversaryMilestones = [
      SELECT
        Milestone_Type__c,
        Milestone_Category__c,
        Milestone_Date__c,
        Employee__c,
        Occurrence_Year__c
      FROM Milestone__c
      WHERE
        Employee__c = :employee.Id
        AND Milestone_Category__c = 'Work Anniversary'
    ];

    System.assertEquals(
      1,
      anniversaryMilestones.size(),
      'One upcoming work anniversary milestone should be created alongside the birthday.'
    );

    Milestone__c anniversaryMilestone = anniversaryMilestones[0];

    System.assertEquals('Recurring', anniversaryMilestone.Milestone_Type__c);
    System.assertEquals(targetAnniv, anniversaryMilestone.Milestone_Date__c);
    System.assertEquals(employee.Id, anniversaryMilestone.Employee__c);
    System.assertEquals(
      targetBirthday.year(),
      anniversaryMilestone.Occurrence_Year__c
    );

    // Assert: Exactly two milestones exist for the employee
    System.assertEquals(
      2,
      [SELECT COUNT() FROM Milestone__c WHERE Employee__c = :employee.Id],
      'Only the birthday and work anniversary milestones should be created.'
    );
  }

  // TC-007: Test milestone not created for inactive employees
  @IsTest
  static void doesNotGenerateMilestoneForInactiveEmployee() {
    // Arrange: Create an inactive employee with a birthday and work annivesary in the window
    Date targetBirthday = Date.today().addDays(5);
    Employee__c employee = new Employee__c(
      First_Name__c = 'Inactive',
      Last_Name__c = 'User',
      Date_of_Birth__c = Date.newInstance(
        1980,
        targetBirthday.month(),
        targetBirthday.day()
      ),
      Employment_Start_Date__c = Date.newInstance(2019, 1, 1),
      Active__c = false
    );
    insert employee;

    // Act
    Test.startTest();
    RecurringMilestoneService.generateUpcomingMilestones();
    Test.stopTest();

    //Assert
    List<Milestone__c> milestones = [
      SELECT Id
      FROM Milestone__c
      WHERE Employee__c = :employee.Id
    ];

    System.assertEquals(
      0,
      milestones.size(),
      'No milestones should be created for inactive employees.'
    );
  }

  // TC-003: No milestones when both dates are missing
  @IsTest
  static void shouldCreateNoMilestones_WhenBothDatesMissing() {
    // Given
    Employee__c employee = insertEmployee('NoDates', 'User', null, null);

    // When
    Test.startTest();
    RecurringMilestoneService.generateUpcomingMilestones();
    Test.stopTest();

    // Then
    Assert.areEqual(
      0,
      queryMilestones(employee.Id).size(),
      'No milestones should be created when birthday and employment start date are both missing.'
    );
  }

  // TC-004: Only birthday when employment start date is missing
  @IsTest
  static void shouldCreateOnlyBirthday_WhenOnlyBirthdayPresent() {
    // Given
    Date targetDate = Date.today().addDays(10);
    Employee__c employee = insertEmployee(
      'BirthdayOnly',
      'User',
      Date.newInstance(1990, targetDate.month(), targetDate.day()),
      null
    );

    // When
    Test.startTest();
    RecurringMilestoneService.generateUpcomingMilestones();
    Test.stopTest();

    // Then
    List<Milestone__c> milestones = queryMilestones(employee.Id);
    Assert.areEqual(
      1,
      milestones.size(),
      'Only one milestone should be created for an employee with just a birthday.'
    );
    Assert.areEqual(
      'Birthday',
      milestones[0].Milestone_Category__c,
      'The created milestone should be a birthday.'
    );
    Assert.areEqual(
      targetDate,
      milestones[0].Milestone_Date__c,
      'The birthday milestone should fall on the upcoming birthday.'
    );
  }

  // TC-005: Only work anniversary when birthday is missing
  @IsTest
  static void shouldCreateOnlyWorkAnniversary_WhenOnlyStartDatePresent() {
    // Given
    Date targetDate = Date.today().addDays(10);
    Employee__c employee = insertEmployee(
      'AnniversaryOnly',
      'User',
      null,
      Date.newInstance(2016, targetDate.month(), targetDate.day())
    );

    // When
    Test.startTest();
    RecurringMilestoneService.generateUpcomingMilestones();
    Test.stopTest();

    // Then
    List<Milestone__c> milestones = queryMilestones(employee.Id);
    Assert.areEqual(
      1,
      milestones.size(),
      'Only one milestone should be created for an employee with just an employment start date.'
    );
    Assert.areEqual(
      'Work Anniversary',
      milestones[0].Milestone_Category__c,
      'The created milestone should be a work anniversary.'
    );
    Assert.areEqual(
      targetDate,
      milestones[0].Milestone_Date__c,
      'The work anniversary milestone should fall on the upcoming anniversary.'
    );
  }

  // TC-006: Running the generator twice must not duplicate birthday milestones
  @IsTest
  static void shouldNotDuplicateBirthdayMilestone_WhenGeneratorRunsTwice() {
    // Given
    Date targetDate = Date.today().addDays(10);
    Employee__c employee = insertEmployee(
      'Duplicate',
      'User',
      Date.newInstance(1990, targetDate.month(), targetDate.day()),
      null
    );

    Test.startTest();
    RecurringMilestoneService.generateUpcomingMilestones();
    List<Milestone__c> afterFirstRun = queryMilestones(employee.Id);

    // When
    RecurringMilestoneService.generateUpcomingMilestones();
    Test.stopTest();

    // Then
    List<Milestone__c> afterSecondRun = queryMilestones(employee.Id);
    Assert.areEqual(
      1,
      afterFirstRun.size(),
      'The first run should create one birthday milestone.'
    );
    Assert.areEqual(
      1,
      afterSecondRun.size(),
      'The second run should not create a duplicate birthday milestone.'
    );
    Assert.areEqual(
      afterFirstRun[0].Id,
      afterSecondRun[0].Id,
      'The original birthday milestone should be the only one that remains.'
    );
    Assert.areEqual(
      targetDate.year(),
      afterSecondRun[0].Occurrence_Year__c.intValue(),
      'The birthday milestone should be for the target occurrence year.'
    );
  }

  // TC-011: Test Both dates fall beyond the 30-day look-ahead window
  @IsTest
  static void shouldCreateNoMilestones_WhenBothDatesBeyondWindow() {
    // Given
    Date outsideWindow = Date.today().addDays(45);
    Employee__c employee = insertEmployee(
      'BeyondWindow',
      'User',
      Date.newInstance(1990, outsideWindow.month(), outsideWindow.day()),
      Date.newInstance(2016, outsideWindow.month(), outsideWindow.day())
    );

    // When
    Test.startTest();
    RecurringMilestoneService.generateUpcomingMilestones();
    Test.stopTest();

    // Then
    Assert.areEqual(
      0,
      queryMilestones(employee.Id).size(),
      'No milestones should be created when both dates are beyond the 30-day window.'
    );
  }

  // TC-011 Test: Birthday is inside the window, work anniversary is beyond it
  @IsTest
  static void shouldCreateOnlyBirthday_WhenAnniversaryBeyondWindow() {
    // Given
    Date insideWindow = Date.today().addDays(10);
    Date outsideWindow = Date.today().addDays(45);
    Employee__c employee = insertEmployee(
      'MixedWindow',
      'User',
      Date.newInstance(1990, insideWindow.month(), insideWindow.day()),
      Date.newInstance(2016, outsideWindow.month(), outsideWindow.day())
    );

    // When
    Test.startTest();
    RecurringMilestoneService.generateUpcomingMilestones();
    Test.stopTest();

    // Then
    List<Milestone__c> milestones = queryMilestones(employee.Id);
    Assert.areEqual(
      1,
      milestones.size(),
      'Only the milestone inside the 30-day window should be created.'
    );
    Assert.areEqual(
      'Birthday',
      milestones[0].Milestone_Category__c,
      'The birthday inside the window should be created.'
    );
    Assert.areEqual(
      insideWindow,
      milestones[0].Milestone_Date__c,
      'The birthday milestone should fall on the upcoming birthday.'
    );
  }

  private static Employee__c insertEmployee(
    String firstName,
    String lastName,
    Date birthDate,
    Date startDate
  ) {
    Employee__c employee = new Employee__c(
      First_Name__c = firstName,
      Last_Name__c = lastName,
      Date_of_Birth__c = birthDate,
      Employment_Start_Date__c = startDate,
      Active__c = true
    );
    insert employee;
    return employee;
  }

  private static List<Milestone__c> queryMilestones(Id employeeId) {
    return [
      SELECT
        Id,
        Milestone_Type__c,
        Milestone_Category__c,
        Milestone_Date__c,
        Occurrence_Year__c
      FROM Milestone__c
      WHERE Employee__c = :employeeId
    ];
  }
}
