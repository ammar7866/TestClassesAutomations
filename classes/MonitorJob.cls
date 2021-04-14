global class MonitorJob implements Schedulable{
	global String jobName;
	global String testClassJobId;
	global String mode;
	global List<String> recipientsList;
	global MonitorJob(String jobName, String testClassJobId, String mode, List<String> recipientsList){
		this.jobName = jobName;
		this.testClassJobId = testClassJobId;
		this.mode = mode;
		this.recipientsList = recipientsList;
	}

	global void execute(SchedulableContext ctx){

		Map<String, String> classNameVsStatus = new Map<String, String>();
		List<AsyncApexJob> testClassJob = [SELECT Id, Status
		                                   FROM AsyncApexJob
		                                   WHERE ID = :testClassJobId];
		if (!testClassJob.isEmpty()){
            if (testClassJob[0].Status == 'Completed'){

				for (ApexTestQueueItem atqi : [Select Id, ApexClassId, ApexClass.Name, ExtendedStatus, ParentJobId, Status
				                               From ApexTestQueueItem
				                               Where ParentJobId = :testClassJobId]){
					if (mode == 'Always'){
						if (atqi.Status == 'Completed'){
							List<String> extendedStatusString = UtilityMethods.decodeExtendedStatus(atqi.ExtendedStatus);
							if (Integer.valueOf(extendedStatusString[0]) == Integer.valueOf(extendedStatusString[1])){
								classNameVsStatus.put(atqi.ApexClass.Name, 'Passed');
							} else{
								classNameVsStatus.put(atqi.ApexClass.Name, 'Failed');
							}
						} else{
							classNameVsStatus.put(atqi.ApexClass.Name, atqi.Status);
						}
					} else if (mode == 'Failure'){
						List<String> extendedStatusString = UtilityMethods.decodeExtendedStatus(atqi.ExtendedStatus);
						if (Integer.valueOf(extendedStatusString[0]) != Integer.valueOf(extendedStatusString[1])){
							classNameVsStatus.put(atqi.ApexClass.Name, String.valueOf(Integer.valueOf(extendedStatusString[1])-Integer.valueOf(extendedStatusString[0])));
						}
					}
				}
				String emailBody = '';
				if (!classNameVsStatus.isEmpty()){
					for (String className : classNameVsStatus.keySet()){
						if (mode != 'Failure'){
							emailBody += '' + className + '-' + classNameVsStatus.get(className)+'\n';
						} else{
							emailBody += '' + className + '-' + classNameVsStatus.get(className)+' methods failed.\n';
						}
					}
				} else{
					emailBody = 'All test passed!';
				}

				UtilityMethods.sendEmail(recipientsList, emailBody);
			} else{
                UtilityMethods.schedulePulseCheck(testClassJobId, mode, recipientsList);
			}

			UtilityMethods.abortJobs(new List<String>{jobName});

		}
	}
}