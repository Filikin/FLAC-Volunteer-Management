/*
Author: Eamon Kelly, Enclude
Purpose: Copy temp volunteer fields from lead convert into contact that are not accessible to the map lead fields page  
Called from: Trigger dispatcher
Tested in: 
*/
public with sharing class MapExtraLeadFieldsToContact implements TriggerDispatcher.ITriggerEntry
{
	public void MainEntry (String TriggerObject, Boolean isBefore, Boolean isDelete, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isExecuting,
		List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap)
	{
		if (isInsert)
		{
			ContactBeingInserted (newList);
		}
	}

	public void ContactBeingInserted (List<Contact> newVolunteers)
	{
		// Contact record type needs to change to volunteer
		ID volunteerRecordTypeID = [select ID from RecordType where sObjectType='Contact' and DeveloperName='FLAC_Volunteer' limit 1].id;
		for (Contact oneVolunteer : newVolunteers)
		{
			oneVolunteer.RecordTypeID = volunteerRecordTypeID;
			if (oneVolunteer.LeadSource == 'Volunteer')
			{
				oneVolunteer.HomePhone = oneVolunteer.Lead_Home_Phone__c;
				oneVolunteer.Main_FLAC_Mailing_List__c = true;
				oneVolunteer.Receives_FLAC_News__c = true;
				
				// by default, the work address comes in as the Mailing Address, but this is the primary address in the NPSP
				if (oneVolunteer.npe01__Primary_Address_Type__c.Contains ('Home'))
				{
					oneVolunteer.npe01__Primary_Address_Type__c = 'Home';
					oneVolunteer.npe01__Secondary_Address_Type__c = 'Work';
					oneVolunteer.OtherStreet = oneVolunteer.MailingStreet;
					oneVolunteer.OtherCity = oneVolunteer.MailingCity;
					oneVolunteer.OtherState = oneVolunteer.MailingState;
					oneVolunteer.MailingStreet = oneVolunteer.Lead_Home_Street__c;
					oneVolunteer.MailingCity = oneVolunteer.Lead_Home_Area_Town__c;
					oneVolunteer.MailingState = oneVolunteer.Lead_Home_City_County__c;
				}
				else
				{
					oneVolunteer.npe01__Secondary_Address_Type__c = 'Home';
					oneVolunteer.OtherStreet = oneVolunteer.Lead_Home_Street__c;
					oneVolunteer.OtherCity = oneVolunteer.Lead_Home_Area_Town__c;
					oneVolunteer.OtherState = oneVolunteer.Lead_Home_City_County__c;
					if (oneVolunteer.npe01__Primary_Address_Type__c.Contains ('email'))
					{
						oneVolunteer.Electronic_version_of_FLAC_News__c = true;
					}
					oneVolunteer.npe01__Primary_Address_Type__c = 'Work';
				}
			}
		}
	}

}