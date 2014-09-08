<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Reminder_of_PILA_Referral_action</fullName>
        <ccEmails>mairead.healy@flac.ie</ccEmails>
        <description>Reminder of PILA Referral action</description>
        <protected>false</protected>
        <recipients>
            <recipient>eithne.lynch@flac.ie</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>FLAC_Staff_Email_Template/PILA_Referral_Reminder</template>
    </alerts>
    <rules>
        <fullName>Reminder of next action</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Campaign.IsActive</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <criteriaItems>
            <field>Campaign.Next_action_to_be_completed_by__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Email PILA user if next action date is past</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
        <workflowTimeTriggers>
            <actions>
                <name>Reminder_of_PILA_Referral_action</name>
                <type>Alert</type>
            </actions>
            <offsetFromField>Campaign.Next_action_to_be_completed_by__c</offsetFromField>
            <timeLength>1</timeLength>
            <workflowTimeTriggerUnit>Days</workflowTimeTriggerUnit>
        </workflowTimeTriggers>
    </rules>
</Workflow>
