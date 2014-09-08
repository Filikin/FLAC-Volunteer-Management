/*
Author: Eamon Kelly, Enclude
Purpose: Use fieldsets to map a lead to a contact and a campaign
Called from: TriggerDispatcher
Tested in: 
*/
public with sharing class WebToLeadToContactAndCampaignClass implements TriggerDispatcher.ITriggerEntry
{
	private	list <Contact> newContacts = new list<Contact>();
	private	list <Account> accountsToUpdate = new list<Account>();
	private set <ID> leadsToUpdateCampaign = new set <ID> ();
 	String actualFieldSetName;
	
	public void MainEntry (String TriggerObject, Boolean isBefore, Boolean isDelete, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isExecuting,
		List<SObject> newList, Map<Id, SObject> newMap, List<SObject> oldList, Map<Id, SObject> oldMap)
	{
		if (isInsert)
		{
			LeadBeingInserted (newList, false);
		}
		else if (isUpdate)
		{
			LeadBeingInserted (newList, true);
			if (leadsToUpdateCampaign.size() > 0) updateCampaignMembers ();
		}
	}

	public void updateCampaignMembers ()
	{
		list<CampaignMember> cms = [select ID, Registration__c from CampaignMember where LeadID in :leadsToUpdateCampaign];
		for (CampaignMember oneCM : cms)
		{
			oneCM.Registration__c = 'Registered';
		}	
		update cms;
	}
	
	public void LeadBeingInserted (List<Lead> newLeads, Boolean isUpdate)
	{
		// if an update, then also need to update the campaign
	    ID PILABulletinID = [select ID from RecordType where sObjectType='Lead' and DeveloperName='PILA_Bulletin'].id;
	    ID PILAConferenceID = [select ID from RecordType where sObjectType='Lead' and DeveloperName='PILA_Conference'].id;
    	For(Lead ld: newLeads)
	    {
	    	if ((ld.RecordTypeId == null || ld.RecordTypeId == PILABulletinID) && isValid(ld.Email))
	    	{
	    		PilaBulletinLead (ld);
	    	}
	    	else if (ld.RecordTypeId == PILAConferenceID)
	    	{
	    		PilaConferenceLead (ld, isUpdate);
	    	}
		    if (ld.Status.contains('Open'))
		    {
	    		ld.Conversion_Error__c = '';
	    		if (!isValid(ld.Email)) ld.Conversion_Error__c = 'Email address invalid ';
	    		if (!isValid(ld.LastName)) ld.Conversion_Error__c += ' Surname not valid';
	    		if (ld.RecordTypeId == PILAConferenceID && !isValid(actualFieldSetName)) ld.Conversion_Error__c += ' Field Set Name not valid: ' + actualFieldSetName;
 		   	}
 		   	else
 		   	{
 		   		ld.Conversion_Error__c = 'None';
 		   	}
	    }
		if (newContacts.size() > 0) upsert newContacts;
		if (accountsToUpdate.size() > 0) update accountsToUpdate;
	}
	
	public void PilaConferenceLead (Lead ld, Boolean isUpdate)
	{
		Boolean updateAccount = false;
	   	if (ld.leadsource == null) actualFieldSetName = 'PilaConference';
	   	else actualFieldSetName = ld.leadsource;
	    	
	   	if (isValid(ld.Email) && isValid(actualFieldSetName) && isValid(ld.LastName) && ld.Status.contains('Open'))
	   	{
	   		List<Schema.FieldSetMember> leadFields = null;
	   		List<Schema.FieldSetMember> contactFields = null;
	   		try
	   		{
		    	leadFields = getFields (actualFieldSetName.replace(' ','_'), true);
	   			contactFields = getFields (actualFieldSetName.replace(' ','_'), false);
	   		}
	   		catch (Exception e)
    		{
    			try
    			{
	    			actualFieldSetName = 'PilaConference';
 	 		    	leadFields = getFields (actualFieldSetName.replace(' ','_'), true);
	    			contactFields = getFields (actualFieldSetName.replace(' ','_'), false);
	   			}
	   			catch (Exception e2)
	   			{
	    			ld.Conversion_Error__c = 'Lead source not matching a fieldset and PilaConference fieldset not found ' + ld.leadsource;
    				return;
	   			}
    		}
				
			Account contactsAccount=getAccount (ld);
	
   			Contact currentContact = null;
   			Boolean newContact;
	 
    		List<Contact> possibleContacts = [select id  from Contact where LastName=:ld.LastName and (email = :ld.Email or npe01__HomeEmail__c = :ld.Email or npe01__WorkEmail__c = :ld.Email) limit 1];
    		if (possibleContacts.size() == 0)
    		{
	    		currentContact = new Contact (LastName = ld.LastName, Email = ld.Email, npe01__Preferred_Email__c='Work');
	    		newContact = true;
	    		if (contactsAccount != null) currentContact.AccountId = contactsAccount.id;
    		}
    		else
    		{
    			currentContact = possibleContacts[0];
    			newContact = false;
    		}
		    	
			try
	    	{
		    	for (Integer i=0; i<leadFields.size(); i++)
		    	{
	        		String fieldName = leadFields[i].getFieldPath();
		    		if (fieldName != 'Company')
		    		{
				    	Schema.DisplayType fieldType = leadFields[i].getType();
		    			system.debug ('Field is ' + fieldName + ' type is ' + fieldType);
		    			if (fieldType == DisplayType.Date && isValidDate((Date)(ld.get(fieldName))) && newContact)
		    			{
		    				system.debug ('Field is Date ' + fieldName);
		    				String contactFieldName = contactFields[i].getFieldPath().replace('ConvertedContact.','');
		    				currentContact.put(contactFieldName, (Date)(ld.get(fieldName)));
		    			}
				    	else if ((fieldType == DisplayType.Double || fieldType == DisplayType.Currency) && isValidDecimal((Decimal)(ld.get(fieldName))))
				    	{
		    				system.debug ('Field is Decimal ' + fieldName);
		    				if (contactFields[i].getFieldPath().contains('ConvertedContact.') && newContact)
		    				{
			    				String contactFieldName = contactFields[i].getFieldPath().replace('ConvertedContact.','');
			    				currentContact.put(contactFieldName, (Decimal)(ld.get(fieldName)));
		    				}
				    	}
					    else if (fieldType == DisplayType.Boolean)
					    {
			    			system.debug ('Field is Boolean ' + fieldName);
			    			Schema.DisplayType destFieldType = contactFields[i].getType();
			    			if (contactFields[i].getFieldPath().contains('ConvertedContact.') && newContact)
			    			{
				    			String contactFieldName = contactFields[i].getFieldPath().replace('ConvertedContact.','');
				    			if (destFieldType == DisplayType.Boolean) currentContact.put(contactFieldName, (Boolean)(ld.get(fieldName)));
				    			else currentContact.put(contactFieldName, (Boolean)(ld.get(fieldName))?1:0);
			    			}
			    			else if (contactFields[i].getFieldPath().contains('ConvertedAccount.') && contactsAccount != null)
			    			{
				    			String contactFieldName = contactFields[i].getFieldPath().replace('ConvertedAccount.','');
				    			if (destFieldType == DisplayType.Boolean) contactsAccount.put(contactFieldName, (Boolean)(ld.get(fieldName)));
				    			else contactsAccount.put(contactFieldName, (Boolean)(ld.get(fieldName))?1:0);
				    			updateAccount = true;
			    			}
				    	}
		    			else if (isValid((String)(ld.get(fieldName)))) 
		    			{
		    				system.debug ('Field is String ' + fieldName + ' path is ' + contactFields[i].getFieldPath());
		    				if (contactFields[i].getFieldPath().contains('ConvertedContact.') && newContact)
		    				{
			    				String contactFieldName = contactFields[i].getFieldPath().replace('ConvertedContact.','');
				    					
				    			if (contactFieldName.contains('Phone') && ((String)(ld.get(fieldName))).startsWith('08')) 
				    				currentContact.put('MobilePhone', (String)(ld.get(fieldName)));
				    			else currentContact.put(contactFieldName, (String)(ld.get(fieldName)));
		    				}
		    				else if (contactFields[i].getFieldPath().contains('ConvertedAccount.') && contactsAccount != null)
		    				{
			    				String contactFieldName = contactFields[i].getFieldPath().replace('ConvertedAccount.','');
			    				contactsAccount.put(contactFieldName, (String)(ld.get(fieldName)));
			    				updateAccount = true;
		    				}
		    			}
		    		}
	    		}
	    	}
		    catch (Exception e)
		    {
		    	system.debug ('Conversion error in PILA Conference Lead: ' + e.getMessage());
		    	return;
		    }
			    	
	    	newContacts.add (currentContact);
	    	if (updateAccount) accountsToUpdate.add(contactsAccount);
	    	if (isUpdate) leadsToUpdateCampaign.add (ld.id);
		    		
	    	ld.Status = 'Closed - Converted';
    	}
	}
    
	public static boolean isValid (String text)
	{
		if (text <> null && text <> '' && text <> '[not provided]') return true;
		else return false;
	}
	
	public static boolean isValidDate (Date text)
	{
		if (text <> null) return true;
		else return false;
	}
	
	public static boolean isValidDecimal (Decimal text)
	{
		if (text <> null) return true;
		else return false;
	}
	
	public List<Schema.FieldSetMember> getFields(String fieldSetName, Boolean bLeadFields) 
    {
    	System.Debug ('Fieldset name is' + fieldSetName);
    	Schema.FieldSet fs1 = Schema.SObjectType.Lead.fieldSets.getMap().get(fieldSetName);
    	if (fs1 == null) fs1 = Schema.SObjectType.Lead.fieldSets.getMap().get('PilaConference');
    	List<Schema.FieldSetMember> allFields = fs1.getFields();
     	List<Schema.FieldSetMember> returnFields = new List<Schema.FieldSetMember>();
    	
    	Integer start = bLeadFields ? 0:1;
    	for (Integer i=start; i<allFields.size(); i+=2)
    	{
			returnFields.add (allFields[i]);    		
    	}
    	return returnFields;
	}

	// Create a contact that receives the Pila Bulletin
	public void PilaBulletinLead (Lead ld)
	{
		Account contactsAccount= getAccount (ld);

    	try
    	{
    		Contact currentContact = [select id, Receives_PILA_Bulletin__c from Contact where email = :ld.Email limit 1];
    		currentContact.Receives_PILA_Bulletin__c = true;
    		newContacts.add (currentContact);
    	}
    	catch (Exception e)
    	{ // assume contact not found
    		ID GeneralContactRecordTypeId = [select id from RecordType where Name = 'General Contact' limit 1].id;
    		Contact c = new Contact (FirstName = ld.FirstName, LastName = ld.LastName, Email = ld.Email, RecordTypeID = GeneralContactRecordTypeId);
    		c.Is_General_public__c = ld.Is_General_public__c;
    		c.Is_NGO_staff__c = ld.Is_NGO_staff__c;
    		c.Member_of_the_legal_profession__c = ld.Member_of_the_legal_profession__c;
    		c.Receives_PILA_Bulletin__c = true;
    		c.Source__c = 'PILA bulletin signup';
    		if (contactsAccount <> null)
    		{
    			c.AccountID = contactsAccount.id;
    		}
    		newContacts.Add(c); 
    	}
   	}
	
	public Account getAccount (Lead ld)
	{
		Account contactsAccount = null;
		if (isValid(ld.Company))
		{
			try
			{
				contactsAccount = [select id from Account where Name = :ld.Company limit 1];
			}
			catch (Exception e) // exception thrown if no account found
			{ // assume account not found
   				contactsAccount = new Account (Name=ld.Company, Main_email_address__c=ld.Email);
   				insert contactsAccount;
   			} 
   		}
   		return contactsAccount;
	}
}