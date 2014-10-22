/*
Author: Eamon Kelly, Enclude
Purpose: Copy temp volunteer fields from lead convert into contact that are not accessible to the map lead fields page  
Called from: Trigger
Tested in: 
*/
trigger ContactTrigger on Contact (before insert) 
{
	TriggerDispatcher.MainEntry ('Contact', trigger.isBefore, trigger.isDelete, trigger.isAfter, trigger.isInsert, trigger.isUpdate, trigger.isExecuting,
		trigger.new, trigger.newMap, trigger.old, trigger.oldMap);
}