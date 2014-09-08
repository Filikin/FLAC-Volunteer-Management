trigger LeadTrigger on Lead (before insert, before update) 
{
	TriggerDispatcher.MainEntry ('Lead', trigger.isBefore, trigger.isDelete, trigger.isAfter, trigger.isInsert, trigger.isUpdate, trigger.isExecuting,
		trigger.new, trigger.newMap, trigger.old, trigger.oldMap);
}