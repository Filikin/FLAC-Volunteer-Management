public with sharing class CloneCampaignClass 
{
	Campaign campaignToClone;
	public CampaignMember cm {get;set;}
	List<CampaignMemberStatus> cmStatus {get;set;} 
  	public String statusRequired{get;set;} 
	
    public CloneCampaignClass(ApexPages.StandardController controller) 
    {
        campaignToClone = [select id, CampaignMemberRecordTypeId, RecordTypeId, Name, NumberOfContacts from Campaign where ID = :controller.getRecord().id];
        
        cmStatus = [SELECT CampaignId, Id, Label, SortOrder, HasResponded, isDefault FROM CampaignMemberStatus where CampaignId = :campaignToClone.id];
        // use one of the campaign members as a template
        try
        {
       		cm = [select id, Attendance__c, Registration__c, Status from CampaignMember where CampaignID = :campaignToClone.id limit 1];
       		statusRequired = null;
       		cm.Attendance__c = null;
       		cm.Registration__c = null;
        }
        catch (Exception e)
       	{
       		ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Warning, 'No members to in this campaign');
			ApexPages.addMessage(myMsg);
       	}
    }
	
	public void copyCampaignMemberStatus (ID clonedCampaign)
	{
       	delete [SELECT Id FROM CampaignMemberStatus where CampaignId = :clonedCampaign and isDefault = false];
 /*
		CampaignMemberStatus defaultStatus = null;
		try 
		{
			defaultStatus = [SELECT Id, Label FROM CampaignMemberStatus where CampaignId = :clonedCampaign and isDefault = true limit 1];
		}
		catch (Exception e){}
*/	
		for (CampaignMemberStatus oneStatus: cmStatus)
 		{
 			CampaignMemberStatus newStatus = oneStatus.clone();
 			newStatus.CampaignId = clonedCampaign;
 			newStatus.SortOrder = oneStatus.SortOrder;
 			newStatus.HasResponded = oneStatus.HasResponded;
 			try
 			{
 				insert newStatus;
 			}
 			catch (Exception e)
 			{
 				system.debug ('Failed to add CampaignMemberStatus ' + e);
 /*				if (defaultStatus != null)
 				{
	 				defaultStatus.Label = oneStatus.Label;
 					update defaultStatus;
 				}
 */
 			}
 		}
	}
	
	public pageReference cloneCampaign ()
	{
     	Campaign clone = new Campaign (Name=campaignToClone.Name + ' Copy');
     	clone.IsActive = true;
     	clone.ParentId = campaignToClone.id;
     	if (campaignToClone.CampaignMemberRecordTypeId != null) clone.CampaignMemberRecordTypeId = campaignToClone.CampaignMemberRecordTypeId;
     	if (campaignToClone.RecordTypeId != null) clone.RecordTypeId = campaignToClone.RecordTypeId;

    	insert clone;
    	
    	copyCampaignMemberStatus (clone.Id);
    	
    	if (cm != null) cloneCampaignMembers (clone.Id);
    	
    	PageReference clonePage = new PageReference ('/' + clone.id);
		return clonePage;
	}
	
	public List<CampaignMember> getCampaignMembers ()
	{
		if (cm == null) return new List<CampaignMember>();
		system.debug ('Status ' + statusRequired);
		system.debug ('Attendance ' + cm.Attendance__c);
		system.debug ('Registration ' + cm.Registration__c);
		
		String soql = 'Select ID, ContactID from CampaignMember where CampaignID=\'' + campaignToClone.id + '\'';
		if (statusRequired != null || cm.Attendance__c != null || cm.Registration__c != null)
		{
			soql += ' and (';	
			if (statusRequired != null) soql += 'Status = \'' + statusRequired + '\'';
			if (cm.Attendance__c != null)
			{
				if (statusRequired != null) soql += ' or ';
				soql += 'Attendance__c = \'' + cm.Attendance__c + '\'';
			}
			if (cm.Registration__c != null)
			{
				if (statusRequired != null || cm.Attendance__c != null) soql += ' or ';
				soql += 'Registration__c = \'' + cm.Registration__c + '\'';
			}
		
			soql += ')';
		} 
		System.debug(soql);
		return (List<CampaignMember>)database.query(soql);
	}
	
	public Integer getNumberOfQualifyingMembers ()
	{
		List<CampaignMember> oldMembers = getCampaignMembers();
		return oldMembers.size();
	}
	
	public void cloneCampaignMembers (ID campaignID)
	{
		List<CampaignMember> oldMembers = getCampaignMembers();
		
		List<CampaignMember> newMembers = new List<CampaignMember>();
		for (CampaignMember oneMember: oldMembers)
			newMembers.add (new CampaignMember (CampaignID=campaignID, ContactID=oneMember.ContactID));
		if (newMembers.size()>0) insert newMembers;
	}
	
	public List<SelectOption> getCampaignStatusList() 
 	{
     	List<SelectOption> statusList = new List<SelectOption>();
		statusList.add(new SelectOption ('','--None--'));
 		for(CampaignMemberStatus oneStatus : cmStatus)
		{
 			statusList.add(new SelectOption (oneStatus.Label, oneStatus.Label));
		}
		
    	return statusList;
  	}
	
    public static testMethod void cloneCampaignTest ()
    {
    	Contact vol = new Contact (FirstName = 'Test', LastName='Therapist');
    	insert vol;
     	Campaign camp = new Campaign (Name='Test');
    	insert camp;
    	CampaignMember cm = new CampaignMember (CampaignID=camp.id, ContactId=vol.id);
    	cm.Attendance__c = 'Attended';
    	insert cm;

    	Contact vol2 = new Contact (FirstName = 'Test', LastName='Politician');
    	insert vol2;
    	CampaignMember cm2 = new CampaignMember (CampaignID=camp.id, ContactId=vol2.id);
    	cm2.Status = 'Responded';
    	insert cm2;

    	Contact vol3 = new Contact (FirstName = 'Test', LastName='Volunteer');
    	insert vol3;
    	CampaignMember cm3 = new CampaignMember (CampaignID=camp.id, ContactId=vol3.id);
    	cm3.Registration__c = 'Registered';
    	insert cm3;
    	
        ApexPages.StandardController CloneCampaignPage = new ApexPages.StandardController(camp);
        CloneCampaignClass cc = new CloneCampaignClass (CloneCampaignPage);
        
		cc.statusRequired = 'Responded';        
        cc.cloneCampaign();
        Campaign cloned = [select ID, Name, ParentId, NumberOfContacts from Campaign where Name like '% Copy' limit 1];
        system.assertEquals(camp.id, cloned.ParentId);
        
        system.assertEquals (1, cloned.NumberOfContacts);
        
        cc.getCampaignStatusList();
    }

    public static testMethod void cloneCampaignTest2 ()
    {
    	Contact vol = new Contact (FirstName = 'Test', LastName='Therapist');
    	insert vol;
     	Campaign camp = new Campaign (Name='Test');
    	insert camp;
    	CampaignMember cm = new CampaignMember (CampaignID=camp.id, ContactId=vol.id);
    	cm.Attendance__c = 'Attended';
    	insert cm;

    	Contact vol2 = new Contact (FirstName = 'Test', LastName='Politician');
    	insert vol2;
    	CampaignMember cm2 = new CampaignMember (CampaignID=camp.id, ContactId=vol2.id);
    	cm2.Status = 'Responded';
    	insert cm2;

    	Contact vol3 = new Contact (FirstName = 'Test', LastName='Volunteer');
    	insert vol3;
    	CampaignMember cm3 = new CampaignMember (CampaignID=camp.id, ContactId=vol3.id);
    	cm3.Registration__c = 'Registered';
    	insert cm3;
    	
        ApexPages.StandardController CloneCampaignPage = new ApexPages.StandardController(camp);
        CloneCampaignClass cc = new CloneCampaignClass (CloneCampaignPage);
        
		cc.statusRequired = 'Responded';  
		cc.cm.Attendance__c = 'Attended';      
        cc.cloneCampaign();
        Campaign cloned2 = [select ID, Name, ParentId, NumberOfContacts from Campaign where Name like '% Copy' limit 1];
        
        system.assertEquals (2, cloned2.NumberOfContacts);
    }
    
    public static testMethod void cloneCampaignTest3 ()
    {
    	Contact vol = new Contact (FirstName = 'Test', LastName='Therapist');
    	insert vol;
     	Campaign camp = new Campaign (Name='Test');
    	insert camp;
    	
    	CampaignMemberStatus defaultStatus = new CampaignMemberStatus (Label='Default', sortOrder=101, CampaignID=camp.id, IsDefault=true);
    	insert defaultStatus; 

    	CampaignMemberStatus newStatus = new CampaignMemberStatus (Label='Test', sortOrder=100, CampaignID=camp.id);
    	insert newStatus; 
    	
    	CampaignMember cm = new CampaignMember (CampaignID=camp.id, ContactId=vol.id);
    	cm.Attendance__c = 'Attended';
    	insert cm;

    	Contact vol2 = new Contact (FirstName = 'Test', LastName='Politician');
    	insert vol2;
    	CampaignMember cm2 = new CampaignMember (CampaignID=camp.id, ContactId=vol2.id);
    	cm2.Status = 'Responded';
    	insert cm2;

    	Contact vol3 = new Contact (FirstName = 'Test', LastName='Volunteer');
    	insert vol3;
    	CampaignMember cm3 = new CampaignMember (CampaignID=camp.id, ContactId=vol3.id);
    	cm3.Registration__c = 'Registered';
    	insert cm3;
    	
        ApexPages.StandardController CloneCampaignPage = new ApexPages.StandardController(camp);
        CloneCampaignClass cc = new CloneCampaignClass (CloneCampaignPage);
        
		cc.statusRequired = 'Responded';  
		cc.cm.Attendance__c = 'Attended'; 
		cc.cm.Registration__c = 'Registered';     
        cc.cloneCampaign();
        Campaign cloned3 = [select ID, Name, ParentId, NumberOfContacts from Campaign where Name like '% Copy' limit 1];
        
        system.assertEquals (3, cloned3.NumberOfContacts);
    }
}