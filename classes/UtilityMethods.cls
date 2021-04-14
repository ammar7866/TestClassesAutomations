public with sharing class UtilityMethods{
	public static String createBody(List<String> testClassesNames){

		String returnValue;
		if (!testClassesNames.isEmpty()){
			returnValue = '{"tests":[';
			for (Integer i = 0; i < testClassesNames.size(); i++){
				GenerateClassNamesArray arrObject = new GenerateClassNamesArray();
				arrObject.className = testClassesNames[i];
				returnValue += JSON.serialize(arrObject);

				if (testClassesNames.size() > 1 && testClassesNames.size() != (i + 1)){
					returnValue += ',';
				}
			}
			returnValue += ']}';
		} else{
			returnValue = '{"testLevel": "RunLocalTests"}';
		}
		return returnValue;
	}

	@future(callout = true)
	public static void createRequest(String baseUrl, String toolingMethodName, String body, String mode ,List<String> recipientsList){
		HTTPRequest req = new HTTPRequest();
		req.setEndpoint(baseUrl + toolingMethodName);
		req.setMethod('POST');
		// OAuth header
		req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
		req.setHeader('Content-Type', 'application/json');
		req.setHeader('Content-Length', '0');
		req.setBody(body);
		Http h = new Http();
		HttpResponse res = h.send(req);
		// Response to a create should be 201
		if (res.getStatusCode() != 201){
            schedulePulseCheck(res.getBody().remove('"'), mode, recipientsList);
		}
	}

	public static String getFormattedDateTimeString(DateTime dateTimeVar, Boolean showSeconds, Boolean showTimeZone){

		String dateFormatString = (showSeconds) ? 'MM/dd/yyyy hh:mm:ss aaa' : 'MM/dd/yyyy hh:mm aaa';
		String timeZoneAbbreviation = UserInfo.getTimeZone().getDisplayName();
		timeZoneAbbreviation = timeZoneAbbreviation.replaceAll('\\B.|\\P{L}', '').toUpperCase();
		String timeZoneString = UserInfo.getTimeZone().toString();
		String dateTimeString = dateTimeVar.format(dateFormatString, timeZoneString);
		dateTimeString += (showTimeZone) ? ' ' + timeZoneAbbreviation : '';
		return dateTimeString;
	}

	public static String getCronString(Integer secondsUntilJobStart){

		DateTime currentDateTime = System.now();
		DateTime dateTimeForNextJob = currentDateTime.addSeconds(secondsUntilJobStart);
		Integer seconds = dateTimeForNextJob.second();
		Integer minutes = dateTimeForNextJob.minute();
		Integer hours = dateTimeForNextJob.hour();
		Integer dayOfMonth = dateTimeForNextJob.day();
		Integer month = dateTimeForNextJob.month();
		Integer year = dateTimeForNextJob.year();
		String cronString = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ?' + ' ' + year;
		return cronString;
	}

	public static void schedulePulseCheck(String testJobId, String mode, List<String> recipientsList){
		String jobName = 'Pulse Check for Test Class Monitor Job';
        System.debug('Inside of pulse check');
		jobName += ' @ ' + getFormattedDateTimeString(DateTime.now(), true, true);
		MonitorJob monitorJobInstance = new MonitorJob(jobName, testJobId, mode, recipientsList);
		String cronString = getCronString(Integer.valueOf(Label.IntervalBetweenPulseCheckInSeconds));
        if(!Test.isRunningTest())
            System.schedule(jobName, cronString, monitorJobInstance);
    }

	public static List<String> decodeExtendedStatus(String extendedStatusString){
		extendedStatusString = extendedStatusString.remove('(');
		extendedStatusString = extendedStatusString.remove(')');
		List<String> finalArr = extendedStatusString.split('/');
		return finalArr;
	}

    public static void sendEmail(List<String> recipientsList, String body){
		List<String> sendTo = new List<String>();
        sendTo.addAll(recipientsList);
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setSubject('Test Class Result');
		mail.setTargetObjectId(UserInfo.getUserId());
		mail.setToAddresses(sendTo);
		mail.setSaveAsActivity(false);
		mail.setPlainTextBody(body);
		Messaging.sendEmail(new Messaging.Email[]{mail});
	}

    @future
    public static void abortJobs(List<String> jobNames){
        for(CronTrigger jobInstance : [SELECT Id,CronJobDetail.Name FROM CronTrigger WHERE  CronJobDetail.Name IN :jobNames]){
            System.abortJob(jobInstance.Id);
        }
    }
	public class GenerateClassNamesArray{
		public String className;

	}
}