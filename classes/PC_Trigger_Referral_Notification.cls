/*********************************************************************************************************
Trigger Name    : PC_Trigger_Referral_Notification
Description     : Trigger handler class on Pharmacy Referral object to send a notification email to physician and patient
Created By      : Deloitte
Created Date    : Oct 4, 2017
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                       Date                   Description
--------------------------------------------------------------------------------------------------------------
Prachi Nandgaonkar              Oct 4, 2017            [PC-1755] Initial Version
Tejas Patel                     Oct 7, 2017            [PC-1755] Updated sendNotification() to send eLetter
Xiukai Ning                     Feb 28, 2019           PC-3775 - Code review. FLS is NOT needed in Triggers, as they always run in System Mode.
                                                       Trigger delegate class (handler) that has with Sharing keyword however, will apply user sharing.
                                                       We are removing all FLS and With Sharing keywords in the handlers.
Vijay Kashikar                  07-Marc-2019           [PC-4556] Changed reference from PC_Program_Service_Permission__c.PC_Program__c to PC_Program_Service_Permission__c.PC_ProgramCase__c
Satheesh Kumar                  Nov 16, 2021           [PC-8213] Excluded FLS Check and added inherited sharing
****************************************************************************************************************/
public inherited sharing class PC_Trigger_Referral_Notification extends PC_TriggerHandler {
    
    public static TriggerState triggerState = new TriggerState();
    
    override public TriggerState getState(){
        return triggerState;
    }
    
    override public void afterInsert() {
        sendNotification((List<PC_Pharmacy_Referral__c>) newList);
    }
    
    /*********************************************************************************
	Method Name    : sendNotification
	Author         : Prachi Nandgaonkar
	Description    : This method sends eLetter for referral service to physician and patient
	Return Type    : void
	Parameter      : List of incoming Pharmacy Referral records - Trigger.new
	*********************************************************************************/
    private void sendNotification(List<PC_Pharmacy_Referral__c> referrals) {
        //Initialize lists to hold intermediate results
        List<String> fields 	= new List<String>();
        LIST<ID> programId 		= new LIST<ID>();
        LIST<ID> engProgramId 	= new LIST<ID>();
        LIST<ID> serviceId 		= new LIST<ID>();
        LIST<ID> eLetterId 		= new LIST<ID>();
        Map<ID, ID> service_eLetterId = new Map<ID, ID>();
        
        //Variable to capture permissions from HCP and patient
        Boolean hcpPermission 	= true;
        Boolean patientPermission = true;
        Map<ID, permissionWrapper> permission = new Map<ID, permissionWrapper>();
        
        try{
            //Fetch program case Id
            for (PC_Pharmacy_Referral__c r : referrals){
                programId.add(r.PC_Program__c);
            }

            //Fetch Engagement Program Service for given Engagement Program
            LIST<PC_Engagement_Program_Service__c> prgService = [SELECT PC_Active__c, PC_Service__c, PC_Notification_Template__c 
                                                                 FROM PC_Engagement_Program_Service__c 
                                                                 WHERE PC_Engagement_Program__c in (SELECT PC_Engagement_Program__c FROM Case WHERE ID in :programId)
                                                                 and PC_Active__c = true];
            
            for (PC_Engagement_Program_Service__c s : prgService){
                serviceId.add(s.PC_Service__c);
                eLetterId.add(s.PC_Notification_Template__c);
                service_eLetterId.put(s.PC_Service__c,s.PC_Notification_Template__c);
            }
            
            //Fetch service and permissions for referral notification by email
            LIST<PC_Service__c> service = [SELECT PC_HCP_Permission_Required__c, PC_Patient_Permission_Required__c 
                                           FROM PC_Service__c 
                                           WHERE ID in :serviceId and PC_Service_Function__c =: PC_Constants.SERVICE_FUNCTION 
                                           and PC_Service_Communication_Channel__c =: PC_Constants.SERVICE_COMMUNICATION_CHANNEL];
            
            //Query PC_Program_Service_Permission__c to check if permission is granted for referral notification by email
            LIST<PC_Program_Service_Permission__c> servicePermission = [SELECT PC_Service__c, PC_HCP_Response__c, PC_Patient_Response__c, PC_ProgramCase__c
                                                                        FROM PC_Program_Service_Permission__c 
                                                                        WHERE PC_Service__c in :serviceId and PC_ProgramCase__c in :programId and PC_Active__c = true];
            
            //If service requires permissions, verify service has been granted permissions for HCP and patient
            for(PC_Service__c s : service){
                if(s.PC_HCP_Permission_Required__c == true){
                    for(PC_Program_Service_Permission__c ps : servicePermission){
                        if(ps.PC_Service__c == s.Id && ps.PC_HCP_Response__c != PC_Constants.PERMISSION_HCP_RESPONSE){
                            hcpPermission = false;
                        }
                    }  
                }
                
                if(s.PC_Patient_Permission_Required__c == true){
                    for(PC_Program_Service_Permission__c ps : servicePermission){
                        if(ps.PC_Service__c == s.Id && ps.PC_Patient_Response__c != PC_Constants.PERMISSION_PATIENT_RESPONSE){
                            patientPermission = false;
                        }
                    }  
                }
                permissionWrapper tempPermission = new permissionWrapper();
                tempPermission.hcpPermission = hcpPermission;
                tempPermission.patientPermission = patientPermission;
                permission.put(s.ID, tempPermission);
            }

            for (PC_Pharmacy_Referral__c r : referrals){
                for(PC_Program_Service_Permission__c ps : servicePermission){
                    if(ps.PC_ProgramCase__c == r.PC_Program__c){
                        ID eId = service_eLetterId.get(ps.PC_Service__c);
                        permissionWrapper currentPermission = permission.get(ps.PC_Service__c);
                        List<PC_eLetter_Recipient> recepients = new List<PC_eLetter_Recipient> ();
                        PC_eLetter__c eLetter = PC_eLetterService.getELetter(eId);
                        recepients = PC_eLetterService.getParticipants(ps.PC_ProgramCase__c, eLetter);

                        for (PC_eLetter_Recipient rec : recepients) {
                            if((rec.recipientRecordType == PC_Constants.PHYSICIAN_RECORD_TYPE && currentPermission.hcpPermission == false) ||
                                    (rec.recipientRecordType == PC_Constants.PATIENT_RECORD_TYPE && currentPermission.patientPermission == false)){
                                rec.sendToMe = false;
                                rec.sendFax = false;
                                rec.sendEmail = false;
                            } else {
                                rec.sendToMe = false;
                                rec.sendFax = false;
                                rec.sendEmail = true;
                            }
                        }

                        String tempRecipient = JSON.serialize(recepients);
                        String returnMsg = PC_eLetterAuraController.sendOutboundDocuments(tempRecipient , eId, ps.PC_ProgramCase__c);
                        system.debug('**returnMsg : ' + returnMsg);
                    }
                }
            }

            /*
            for (ID pId : programId){
                for (ID eId : eLetterId){ 
                    String temEId = (String) eId;
                    ID permissionServiceId = service_eLetterId.get(eId);
                    permissionWrapper currentPermission = permission.get(permissionServiceId);
                    List<PC_eLetter_Recipient> recepients = new List<PC_eLetter_Recipient> ();
                    PC_eLetter__c eLetter = PC_eLetterService.getELetter(temEId);
                    recepients = PC_eLetterService.getParticipants(pId, eLetter);
                    
                    for (PC_eLetter_Recipient rec : recepients) {
                        if((rec.recipientRecordType == PC_Constants.PHYSICIAN_RECORD_TYPE && currentPermission.hcpPermission == false) || 
                           (rec.recipientRecordType == PC_Constants.PATIENT_RECORD_TYPE && currentPermission.patientPermission == false)){
                               rec.sendToMe = false;
                               rec.sendFax = false;
                               rec.sendEmail = false;
                           } else {
                               rec.sendToMe = false;
                               rec.sendFax = false;
                               rec.sendEmail = true;
                           }
                    }
                    
                    String tempRecipient = JSON.serialize(recepients);
                    String returnMsg = PC_eLetterAuraController.sendOutboundDocuments(tempRecipient , temEId, pId);
                    system.debug('**returnMsg : ' + returnMsg);
                }
            }
            */
        } catch(Exception ex) {
            PC_Utility.logAndThrowException(ex);
        }
    }
    /* Wrapper for Permission */ 
    public class permissionWrapper{
        @AuraEnabled public Boolean hcpPermission { get; set; }
        @AuraEnabled public Boolean patientPermission { get; set; }
        
        public permissionWrapper() {
        }
    }
}