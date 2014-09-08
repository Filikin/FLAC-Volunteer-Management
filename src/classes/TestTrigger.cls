/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TestTrigger 
{
    static testMethod void CopyAddressToContactOnChangeTest() 
    {
		Account acct1 = new Account(name='Org account', BillingStreet='some street');
        insert acct1;
            
        Contact volunteer = new Contact(AccountId=acct1.Id,lastname='person',firstname='apex',npe01__Primary_Address_Type__c='Work');
        insert volunteer;
		
		acct1.BillingStreet = 'some other street';
		Test.startTest();
		update acct1;
		Test.stopTest();
		
		volunteer = [Select Id, MailingStreet from Contact where id = :volunteer.id];
		System.assertEquals (volunteer.MailingStreet, 'some other street');
    }
    
    static testMethod void CopyAddressToContactOnChangeTest2() 
    {
    	// should fail as 
		Account acct1 = new Account(name='Individual', BillingStreet='some street');
        insert acct1;
            
        Contact volunteer = new Contact(AccountId=acct1.Id,lastname='person',firstname='apex',npe01__Primary_Address_Type__c='Work');
        insert volunteer;
		
		acct1.BillingStreet = 'some other street';
		Test.startTest();
		update acct1;
		Test.stopTest();
		
		volunteer = [Select Id, MailingStreet from Contact where id = :volunteer.id];
		System.assertEquals (volunteer.MailingStreet, null);
    }
    
    static testMethod void CopyAddressToContactOnChangeTest3() 
    {
    	// should fail as 
		Account acct1 = new Account(name='Individual', BillingStreet='some street');
        insert acct1;
            
        Contact volunteer = new Contact(AccountId=acct1.Id,lastname='person',firstname='apex',npe01__Primary_Address_Type__c='Home', MailingStreet='Home street');
        insert volunteer;
		
		acct1.BillingStreet = 'some other street';
		Test.startTest();
		update acct1;
		Test.stopTest();
		
		volunteer = [Select Id, MailingStreet from Contact where id = :volunteer.id];
		System.assertEquals (volunteer.MailingStreet, 'Home street');
    }

    static testMethod void ConvertLeadToContactTest()
    {
    	Lead[] leadsbefore = [select ID, Name from Lead];

    	Lead testLead = new Lead (FirstName = 'Test', LastName = 'Testing123', Company = 'TestAccount', EMail = 'test@test123.com');
    	insert testLead;
    	
    	Lead[] leadsafter = [select ID, Name from Lead];
    	System.Assert (leadsafter.size() > leadsbefore.size());
    	
    	Contact createdContact = [select FirstName, Email, AccountID from Contact where email=:testLead.Email limit 1];
    	Account createdAccount = [select ID, Name, Main_email_address__c from Account where Name = :testLead.Company limit 1];
    	System.AssertEquals (createdContact.FirstName, testLead.FirstName);
    	System.AssertEquals (createdAccount.Main_email_address__c, testLead.Email);
    	System.AssertEquals (createdContact.AccountId, createdAccount.Id);
    	
	   	Lead testLead2 = new Lead (FirstName = 'Test', LastName = 'Testing124', Company = 'TestAccount', EMail = 'test@test124.com');
    	insert testLead2;
      	Contact createdContact2 = [select FirstName, Email, AccountID from Contact where email=:testLead2.Email limit 1];
  	
     	System.AssertEquals (createdContact2.FirstName, testLead2.FirstName);
    	System.AssertEquals (createdContact2.AccountId, createdAccount.Id);
    }
    
    static testMethod void ConvertLeadToExistingContactTest()
    {
    	Lead[] leadsbefore = [select ID, Name from Lead];

    	Lead testLead = new Lead (FirstName = 'Test', LastName = 'Testing123', Company = 'TestAccount', EMail = 'test@test123.com');
    	insert testLead;
    	
    	Lead[] leadsafter = [select ID, Name from Lead];
    	System.Assert (leadsafter.size() > leadsbefore.size());
    	
    	Contact createdContact = [select FirstName, Email, AccountID, Receives_PILA_Bulletin__c from Contact where email=:testLead.Email limit 1];
    	system.assert (createdContact.Receives_PILA_Bulletin__c);
    	createdContact.Receives_PILA_Bulletin__c = false;
    	update createdContact;
    	
	   	Lead testLead2 = new Lead (FirstName = 'Test', LastName = 'Testing124', Company = 'TestAccount', EMail = 'test@test123.com');
    	insert testLead2;
      	Contact createdContact2 = [select ID, Receives_PILA_Bulletin__c from Contact where ID = :createdContact.id];
  	
    	system.assert (createdContact2.Receives_PILA_Bulletin__c);
    }
    
}