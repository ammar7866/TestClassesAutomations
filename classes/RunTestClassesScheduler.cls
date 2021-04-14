global class RunTestClassesScheduler implements Schedulable{
	public static String baseUrl = URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v49.0/tooling/';
	global void execute(SchedulableContext ctx){
		String toolingAPIMethodName = 'runTestsAsynchronous';
		String body;
		for (TestClassAutomation__c customSettingRecord : TestClassAutomation__c.getAll().values()){
			List<String> testClassesNames = new List<String>();
			if (customSettingRecord.Test_Classes__c != null){
				testClassesNames.addAll(customSettingRecord.Test_Classes__c.split(','));
			}
			List<String> recipientsList;
			if (String.isNotBlank(customSettingRecord.Recipients__c)){
				recipientsList = customSettingRecord.Recipients__c.split(',');
			} else{
				recipientsList = new List<String>{UserInfo.getUserEmail()};
			}
			body = UtilityMethods.createBody(testClassesNames);
			UtilityMethods.createRequest(baseUrl, toolingAPIMethodName, body, customSettingRecord.Mode__c, recipientsList);
		}
	}
}