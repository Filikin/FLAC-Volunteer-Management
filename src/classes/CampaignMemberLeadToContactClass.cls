/*
Author: Eamon Kelly, Enclude
Purpose: Convert campaign member from a lead to a contact
Called from: TriggerDispatcher
Tested in: 
*/
public with sharing class CampaignMemberLeadToContactClass implements TriggerDispatcher.ITriggerEntry
{
	public void MainEntry (String TriggerObject, Boolean isBefore, Boolean isDelete, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isExecuting,
		List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap)
	{
		if (isInsert)
		{
			system.debug ('Inserting CampaignMember');
			if (isBefore) CampaignLeadBeingInserted (newList, false);
		}
		else if (isUpdate)
		{
			system.debug ('Updating CampaignMember');
			CampaignLeadBeingInserted (newList, true);
			TidyUpCampaignMembers ();
		}
	}

	public void TidyUpCampaignMembers ()
	{
		// if there are still leads linked to campaigns where the contact now has a campaign member, remove the link
		List<CampaignMember> cmsToDelete = [select id from CampaignMember where LeadId != null and Attendance__c = 'Delete'];	
		if (cmsToDelete.size() > 0) delete cmsToDelete;
	}
	
	public void CampaignLeadBeingInserted (List<CampaignMember> cms, Boolean updating)
	{
 		Set<ID>LeadIDs = new Set<ID>();
	
		for (CampaignMember oneMember: cms)
		{
			if (oneMember.LeadId != null) LeadIDs.add(oneMember.LeadId);	
		}
		Map<ID,Lead>Leads = new Map<ID,Lead>([select ID, EMail, LastName, Accessibility_or_other_special_needs__c, Breakout_Session_first_preference__c,
			Breakout_Session_second_preference__c, Special_dietary_requirements__c from Lead where ID in :LeadIDs]);
	
		List<CampaignMember> campaignMembersToDelete = new List<CampaignMember>();
		List<CampaignMember> campaignMembersToAdd = new List<CampaignMember>();
		List<CampaignMember> campaignMembersToUpdate = new List<CampaignMember>();
	
		for (CampaignMember oneMember: cms)
		{
			if (oneMember.LeadId != null)
			{
				try
				{
					Lead oneLead = Leads.get(oneMember.LeadID);
					system.debug ('Lead Email is: ' + oneLead.eMail + ' Lastname is: ' + oneLead.LastName);
					Contact oneContact = [select ID from Contact where EMail=:oneLead.Email and LastName=:oneLead.LastName limit 1];
					// is this contact already registered?
					try
					{
						system.debug ('Checking existing');
						CampaignMember existingMember = [select ID, LeadID, ContactID, Registration__c, Accessibility_or_other_special_needs__c, Breakout_Session_first_preference__c,
							Breakout_Session_Second_preference__c, Special_dietary_requirements__c from CampaignMember where ContactID = :oneContact.id and CampaignID=:oneMember.CampaignId];
						system.debug ('Found existing');
						SetCampaignContactFields (existingMember, oneLead, oneContact, true);
						campaignMembersToUpdate.add(existingMember);
						if (oneMember.id != null) campaignMembersToDelete.add(new CampaignMember(id=oneMember.id));
						else oneMember.Attendance__c = 'Delete';
					}
					catch (Exception e)
					{
						system.debug ('Not found existing' + e.getMessage());
						if (updating)
						{
							CampaignMember newMember = oneMember.clone(false,true);
							SetCampaignContactFields (newMember, oneLead, oneContact, false);
							campaignMembersToAdd.add(newMember);
							campaignMembersToDelete.add(new CampaignMember(id=oneMember.id));
						}
						else
						{
							SetCampaignContactFields (oneMember, oneLead, oneContact, false);
						}
					}
				}
				catch (Exception e)
				{
					system.debug ('Error in CampaignLeadBeingInserted' + e.getMessage());
				}
			}
		}
		if (campaignMembersToDelete.size() > 0) delete campaignMembersToDelete;
		if (campaignMembersToAdd.size() > 0) insert campaignMembersToAdd;
 		if (campaignMembersToUpdate.size() > 0) update campaignMembersToUpdate;
   }
    
    void SetCampaignContactFields (CampaignMember memb, Lead webLead, Contact attendee, Boolean existingCampaignMember)
    {
 		if (!existingCampaignMember) 
 		{
 			memb.ContactId = attendee.ID;
			memb.LeadId = null;
 		}
   		memb.Registration__c = 'Registered';
   		memb.Accessibility_or_other_special_needs__c = webLead.Accessibility_or_other_special_needs__c;
   		memb.Breakout_Session_first_preference__c = webLead.Breakout_Session_first_preference__c;
   		memb.Breakout_Session_Second_preference__c = webLead.Breakout_Session_second_preference__c;
   		memb.Special_dietary_requirements__c = webLead.Special_dietary_requirements__c;
   		
    }
}