@isTest
private class TestVolunteerContact {

    static testMethod void TestContactAddedAsVolunteer() 
    {
        Contact vol = new Contact (LastName='Test', LeadSource = 'Volunteer', npe01__Primary_Address_Type__c = 'Home', MailingCity='Dublin');
        insert vol;
        vol = [select id, OtherCity from Contact where id = :vol.id];
        system.assertEquals ('Dublin', vol.OtherCity);
    }
}