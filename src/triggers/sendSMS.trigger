trigger sendSMS on Contact (before update) 
{
    List <SMS__c> Messages = new List<SMS__c>();
    for (Contact oneContact : trigger.new)
    {
        if (oneContact.Send_SMS_TXT__c <> null && oneContact.MobilePhone <> null)
        {
            if (oneContact.Send_SMS_TXT__c.Length() > 0 && oneContact.MobilePhone.Length() > 0)
            {
                SMS__c oneMessage = new SMS__c (To_Contact__c = oneContact.ID, Outgoing_Message__c = oneContact.Send_SMS_TXT__c, Message_Sent__c = TRUE);
                Messages.Add (oneMessage);
                
//                OutgoingEmailManager outgoingemail = new OutgoingEmailManager();
//                outgoingemail.SendSMSEmail (oneContact.ID);
                oneContact.Last_SMS_TXT__c = oneContact.Send_SMS_TXT__c;
                oneContact.Send_SMS_TXT__c = '';
            }
        }
    }
    if (Messages.size() > 0)
    {
        insert Messages;
    }
}