<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Send_Email_from_SMS_Object</fullName>
        <ccEmails>smsenclude@enclude.ie</ccEmails>
        <description>Send Email from SMS Object</description>
        <protected>false</protected>
        <senderType>CurrentUser</senderType>
        <template>ENCLUDE/SMS_Email</template>
    </alerts>
    <rules>
        <fullName>Send Email from SMS</fullName>
        <actions>
            <name>Send_Email_from_SMS_Object</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>SMS__c.Outgoing_Message__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>When the object is created, send an SMS</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
