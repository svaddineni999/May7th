public class PC_ChangeDocOwnerLightningController {
    @AuraEnabled
    public static PC_Document__c getDocDetails(Id docId) {
        PC_Document__c selectedDoc = new PC_Document__c();
        //FLS Check on PC_Document__c
        List<String> fields = new List<String>{'Name', 'RecordTypeId'};
        PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Document__c'), PC_Database.Operation.Reading, fields);
        
        selectedDoc = [SELECT Name, RecordType.DeveloperName FROM PC_Document__c WHERE ID =: docId];
        return selectedDoc;
    }
    
    @AuraEnabled
    public static LIST<ActionIconsWrapper> setupActionIcons(Id docId) {
        PC_Document__c selectedDoc = getDocDetails(docId);
       	LIST<PC_Document_Action_Setting__mdt> actionIconMetaData = [SELECT PC_Active__c, PC_Component__c, PC_Icon__c, PC_Document_Record_Type__c,
                                                                    PC_Label__c, PC_Ordinal__c FROM PC_Document_Action_Setting__mdt
                                                                  	WHERE PC_Active__c =: TRUE AND PC_Document_Record_Type__c =: selectedDoc.RecordType.DeveloperName
                                                                   	ORDER BY PC_Ordinal__c ];
        
        LIST<ActionIconsWrapper> actionIconsWrapper	= 	NEW LIST<ActionIconsWrapper>();
        
        FOR(PC_Document_Action_Setting__mdt a : actionIconMetaData){
            actionIconsWrapper.add(new ActionIconsWrapper(a));
        }
        System.debug('@@actionIconsWrapper :' + actionIconsWrapper);
        RETURN actionIconsWrapper;
    }
    
    /**
	* Wrapper for the action icons setup. Includes all information needed to initialize the
	* action icons.
	*/
    public class ActionIconsWrapper {
        @AuraEnabled public Boolean iconActive {get; set;}
        @AuraEnabled public String 	iconActionComponent {get; set;}
        @AuraEnabled public String 	iconDocRecordType {get; set;}
        @AuraEnabled public String 	iconImage {get; set;}
        @AuraEnabled public String 	iconLabel {get; set;}
        @AuraEnabled public Decimal iconOrdinal {get; set;}
        @AuraEnabled public Boolean iconVisibility {get; set;}
        
        public ActionIconsWrapper() {}
        
        public ActionIconsWrapper(PC_Document_Action_Setting__mdt a) {
        	iconActive 			= a.PC_Active__c;
            iconActionComponent = a.PC_Component__c;
            iconDocRecordType 	= a.PC_Document_Record_Type__c;
            iconImage 			= a.PC_Icon__c;
            iconLabel 			= a.PC_Label__c;  
            iconOrdinal 		= a.PC_Ordinal__c;
            iconVisibility 		= True;
        }
    }
    
}