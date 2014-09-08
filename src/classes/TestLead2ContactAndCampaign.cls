@isTest
private class TestLead2ContactAndCampaign 
{
	static Lead CreateLead ()
	{
		ID PILAConferenceID = [select ID from RecordType where sObjectType='Lead' and DeveloperName='PILA_Conference'].id;
		
    	Lead testLead = new Lead (FirstName = 'Test', LastName = 'Testing123', Company = 'TestAccount', EMail = 'test@test123.com', 
    		Accessibility_or_other_special_needs__c ='Loads', Add_to_FLAC_main_mailing_list__c=true, Breakout_Session_first_preference__c='Event 1', 
    		Breakout_Session_second_preference__c ='Event 2', Member_of_the_legal_profession__c='No', Special_dietary_requirements__c='Yes', I_would_like_to_receive_PILA_Bulletin__c=false,
    		Status='Open - not converted', RecordTypeID=PILAConferenceID);
    	testLead.Website = 'www.enclude.ie';
    	insert testLead;
    	return testLead;
	}
	
	static testMethod void ConvertLeadToContactTest()
    {
    	Lead[] leadsbefore = [select ID, Name from Lead];

		Lead testLead = CreateLead ();
		    	
    	Lead[] leadsafter = [select ID, Name from Lead];
    	System.Assert (leadsafter.size() > leadsbefore.size());
    	
    	Contact createdContact = [select FirstName, Email, AccountID from Contact where email=:testLead.Email limit 1];
    	System.AssertEquals (createdContact.FirstName, testLead.FirstName);
//    	System.AssertEquals (createdContact.Any_special_needs_we_should_know_about__c, 'Loads'); -- not in fieldset in production
//    	System.AssertEquals (createdContact.Have_you_attended_any_T_A_I_event__c, 'Yes'); -- not in fieldset in production
    	
	   	Lead testLead2 = new Lead (FirstName = 'Test', LastName = 'Testing124', Company = 'TestAccount', EMail = 'test@test124.com', leadsource='Online Registration 2012', Status='Open - not converted');
    	insert testLead2;
      	Contact createdContact2 = [select FirstName, Email from Contact where email=:testLead2.Email limit 1];
  	
     	System.AssertEquals (createdContact2.FirstName, testLead2.FirstName);
    }
    
	static testMethod void ConvertLeadToContactTestWithContactPresent()
    {
    	Contact currentContact = new Contact (FirstName = 'Test', LastName = 'Testing123', EMail = 'test@test123.com');
    	insert currentContact;
    	
    	Lead[] leadsbefore = [select ID, Name from Lead];

		Lead testLead = CreateLead ();
    	
    	Lead[] leadsafter = [select ID, Name from Lead];
    	System.Assert (leadsafter.size() > leadsbefore.size());
    	
    	Contact createdContact = [select FirstName, Email, AccountID from Contact where email=:testLead.Email limit 1];
    	System.AssertEquals (createdContact.FirstName, testLead.FirstName);
    	System.AssertEquals (currentContact.id, createdContact.id);
    	
	   	Lead testLead2 = new Lead (FirstName = 'Test', LastName = 'Testing124', Company = 'TestAccount', EMail = 'test@test124.com', leadsource='Online Registration 2012', Status='Open - not converted');
    	insert testLead2;
      	Contact createdContact2 = [select FirstName, Email from Contact where email=:testLead2.Email limit 1];
  	
     	System.AssertEquals (createdContact2.FirstName, testLead2.FirstName);
    }

    static testMethod void ContactToCampaignTest()
    {
 		Lead testLead = CreateLead ();
    	
     	Contact createdContact = [select FirstName, Email, AccountID from Contact where email=:testLead.Email limit 1];
    	System.AssertEquals (createdContact.FirstName, testLead.FirstName);
 
    	Campaign camp = new Campaign (Name='Test');
    	insert camp;
    	CampaignMember cm = new CampaignMember (CampaignID=camp.id, LeadId=testLead.id);
    	insert cm;
    	
    	cm = [select ID, LeadID, ContactID from CampaignMember where id = :cm.id];
    	System.AssertEquals (null, cm.LeadId);
    	System.AssertEquals (createdContact.id, cm.ContactId);
    }
    
    static testMethod void UpdateCampaignMemberTest()
    {
 		Lead testLead = CreateLead ();
    	
     	Contact createdContact = [select ID, FirstName, LastName, Email, AccountID from Contact where email=:testLead.Email limit 1];
     	Contact newContact = createdContact.clone(false,true);
		delete createdContact;
		 
    	Campaign camp = new Campaign (Name='Test');
    	insert camp;
    	CampaignMember cm = new CampaignMember (CampaignID=camp.id, LeadId=testLead.id);
    	insert cm;
    	
		insert newContact;
		
    	cm.Status = 'Responded';
		update cm;    	
    }
    
    static testMethod void UpdateLeadTest()
    {
     	Campaign camp = new Campaign (Name='Test');
    	insert camp;
 		Lead testLead = CreateLead ();
    	CampaignMember cm = new CampaignMember (CampaignID=camp.id, LeadId=testLead.id);
    	insert cm;

		testLead.Email = 'test@test123.com';
		update testLead;
		    	
		cm.Status = 'Responded';
		update cm;
		
     	Contact createdContact = [select ID, FirstName, LastName, Email, AccountID from Contact where email=:testLead.Email limit 1];
	   	System.AssertEquals (createdContact.FirstName, testLead.FirstName);
		
		List <CampaignMember> cmList = [select ID from CampaignMember where ContactID=:createdContact.ID limit 1];
		system.assertEquals (1, cmList.size());

		List <CampaignMember> cmListLead = [select ID from CampaignMember where LeadID=:testLead.ID limit 1];
		system.assertEquals (0, cmListLead.size());
    	
    }
}