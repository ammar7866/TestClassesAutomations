@isTest(SeeAllData=true)
public class RunTestClassesScheduler_Test{
	public static testmethod void test1(){
		TestClassAutomation__c customSettingRecord = new TestClassAutomation__c();
		customSettingRecord.Name = 'BatchFirst';
		customSettingRecord.Mode__c = 'Always';
		customSettingRecord.Recipients__c = 'test@gmail.com';
		customSettingRecord.Recipients__c = 'test@gmail.com';
		customSettingRecord.Test_Classes__c = 'AnimalLocatorTest';
		insert customSettingRecord;

		Test.startTest();
        Test.setMock(HttpcalloutMock.class, new MockTest());
		RunTestClassesScheduler testClassesRun = new RunTestClassesScheduler();
		// Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
		String sch = '0 0 23 * * ?';
        String jobID = System.schedule('Test Classes Run Job', sch, testClassesRun);
        List<AsyncApexJob> jobInfo = [SELECT Id,Status,NumberOfErrors FROM AsyncApexJob where Status = 'Completed' AND JobType = 'TestRequest' limit 1];
        System.debug(jobInfo);

        MonitorJob monitorJobInstance = new MonitorJob('jobName', jobInfo[0].Id, 'Always', new List<String>{'test@test.com'});
        String jobID2 = System.schedule('Monitor Job', sch, monitorJobInstance);

        MonitorJob monitorJobInstance2 = new MonitorJob('jobName 2', jobInfo[0].Id, 'Failure', new List<String>{'test@test.com'});
        String jobID3 = System.schedule('Monitor Job 2', sch, monitorJobInstance2);
        
		Test.stopTest();
	}
}