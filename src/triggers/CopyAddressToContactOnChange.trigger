trigger CopyAddressToContactOnChange on Account (after update) 
{
	list<contact> co=new list<contact>();
	for(account a:trigger.new)
	{
		if (!a.Name.contains ('Individual'))
		{
			for(contact con:[select id,MailingCity,MailingState,MailingCountry,MailingPostalCode,MailingStreet from contact where accountid=:a.id and npe01__Primary_Address_Type__c = 'Work'])
			{
				con.MailingCity=a.BillingCity;
				con.MailingState=a.BillingState;
				con.MailingCountry=a.BillingCountry;
				con.MailingPostalCode=a.BillingPostalCode;
				con.MailingStreet=a.BillingStreet;
				co.add(con);
			}
			update co;
		}
	}
}