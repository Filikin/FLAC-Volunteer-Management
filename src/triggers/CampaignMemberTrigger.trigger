trigger CampaignMemberTrigger on CampaignMember (after update, before insert, after insert) 
{
	TriggerDispatcher.MainEntry ('CampaignMember', trigger.isBefore, trigger.isDelete, trigger.isAfter, trigger.isInsert, trigger.isUpdate, trigger.isExecuting,
		trigger.new, trigger.newMap, trigger.old, trigger.oldMap);
}