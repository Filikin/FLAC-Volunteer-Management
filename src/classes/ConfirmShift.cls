/*
Author: Eamon Kelly, Enclude
Purpose: Confirm a shift by a volunteer
Called from: ShowOneShift page
Tested in: Name of testing class
*/
public with sharing class ConfirmShift 
{
	public String ConfirmText {get; set;}
	Volunteer_Hours__c shift = null;
	// returns the correct URL for the CSS override file
    public string strURLtoCSSFile { 
        get { 
            if (strURLtoCSSFile == null) {
                list<Document> listDocs = [SELECT Name, Id From Document WHERE Name = 'VolunteersPersonalSiteCSS.css' LIMIT 1 ];
                if (listDocs.size() > 0) {
                    Document doc = listDocs[0];
                    string imageid = doc.id;
                    imageid = imageid.substring(0,15);
                    strURLToCSSFile = '/servlet/servlet.FileDownload?file=' + imageid;
                }
            }
            return strURLtoCSSFile;
        }  
        
        set;
    }
    
	public ConfirmShift (ApexPages.StandardController controller)
	{
		shift=(Volunteer_Hours__c)controller.getRecord();
		if (shift.Status__c != 'Second confirmation received') ConfirmText = 'Confirm';
		else ConfirmText = 'Thank You';
	}
	
	public pageReference Confirmed ()
	{
		shift.Status__c = 'Second confirmation received';
		update shift;
		return new pageReference ('https://v4s-flac.cs8.force.com/ShowOneShift?id=' + shift.id);
	}
}