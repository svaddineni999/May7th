/*********************************************************************************************************
Class Name      : PC_DataTable
Description     : Controller class for pc_RecordEditForm and pc_DataTable
Created By      : Tejas Patel
Created Date    : Jan 08, 2021
Modification Log:
--------------------------------------------------------------------------------------------------------------
Developer                   Date                   Description
--------------------------------------------------------------------------------------------------------------
Tejas Patel                 Jan 08,2021            Initial Version
Vijay Kashikar              21-Jan-21              [PC-7102] Added FLS Checks
Vijay Kashikar              21-Jan-21              [PC-7102] Added sharing clause
Tushar Arora                17-Mar-21              [PC-7540] Added Logic for program case value on edit on order screen.
************************************************************************************************************/

public with sharing class PC_DataTable {
    /**Called from pc_RecordEditForm LWC.
     *Returns the list of fields from the Order Object depending on the fieldset.
     *Returns the current value for the ShipTo2 picklist field.
     *Returns the Map of roles and Id's from the association object.
    * @param fsname
    * @param recordIdString
    * @return returns resultSetFields custom wrapper class.
    */

    @AuraEnabled(cacheable=true)
    public static resultSetFields getFields(String fsname, String recordIdString)
    {
        resultSetFields rsf = new resultSetFields();
        try{
            String errorMessage;
            String sObj;
            Id recordId;
            Boolean runShipToLogic = false;
            if(String.isBlank(recordIdString)){
                sObj = PC_Constants.getQualifiedAPIName('PC_Order__c');
            }else{
                recordId = (Id) Id.valueOf(recordIdString);
                sObj = recordId.getSobjectType().getDescribe().getName();
            }

            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sObj);
            Schema.DescribeSObjectResult describe = targetType.getDescribe();
            Map<String, Schema.FieldSet> fsMap = describe.fieldSets.getMap();
            Schema.FieldSet fs = fsMap.get(fsname);
            List<Schema.FieldSetMember> fieldSetProduct = fs.getFields();
            List<String> fieldsList = new List<String>();

            List<column> cList = new List<column>();
            for (Schema.FieldSetMember f : fieldSetProduct) {
                column c    = new column();
                c.label     = f.getLabel();
                c.fieldName = f.getFieldPath();
                c.type      = f.getType().name();
                c.isEditable = f.getSObjectField().getDescribe().isUpdateable();
                cList.add(c);
                if(f.getFieldPath() == PC_Constants.getQualifiedAPIName('PC_ShipTo__c')){
                    runShipToLogic = true;
                }
            }

            List<PC_OrderItem__c> oiList = new List<PC_OrderItem__c>();
            if(String.isNotBlank(recordIdString) && runShipToLogic){
                List<String> productFields = new List<String>();
                productFields.add(PC_Constants.getQualifiedAPIName('PC_PreferredShipmentRole__c'));
                PC_Database.assertAccess('Product2', PC_Database.Operation.Reading, productFields);

                //FLS not needed on Order item as the queries fields are not isPermissionable
                oiList = [Select ID, Name, PC_Product__r.PC_PreferredShipmentRole__c From PC_OrderItem__c Where PC_Order__c = :recordId];
            }
            Set<String> picklistValues = new Set<String>();
            Map<Integer,Set<String>> tempMap = new Map<Integer,Set<String>>();
            Set<String> errorOrderItems = new Set<String>();
            Integer counter = 1;
            for(PC_OrderItem__c oi : oiList){
                Set<String> temp = new Set<String>();
                if(String.isNotBlank(oi.PC_Product__r.PC_PreferredShipmentRole__c)){
                    temp.addAll(oi.PC_Product__r.PC_PreferredShipmentRole__c.split(';'));
                    tempMap.put(counter,temp);
                    counter = counter+1;
                    picklistValues.addAll(temp);
                }else{
                    errorOrderItems.add(oi.Name);
                }
            }

            if(errorOrderItems.size() > 0){
                errorMessage = Label.PC_ProductsNotConfiguredToShip + ' ' + String.join(new List<String>(errorOrderItems),'-');
                PC_Utility.throwAuraHandledException(errorMessage);
            }

            for(Integer i : tempMap.keySet()){
                picklistValues.retainAll(tempMap.get(i));
            }

            List <Map<String,String>> options = new List <Map<String,String>> ();
            Map<String,String> associationMap = new Map<String,String>();
            String existingShipToValue;
            String existingProgramCaseValue;
            
            if(runShipToLogic){
                if(picklistValues.size() > 0) {
                    Schema.DescribeFieldResult preferredShipTo = Product2.PC_PreferredShipmentRole__c.getDescribe();
                    List<Schema.PicklistEntry> allPicklistValue = preferredShipTo.getPicklistValues();


                    for (Schema.PicklistEntry s : allPicklistValue) {
                        Map < String, String > values = new Map < String, String >{
                                'label' => s.getLabel(),
                                'value' => s.getValue()
                        };
                        if (picklistValues.contains(values.get('value'))) {
                            options.add(values);
                        }
                    }
                } else {
                    errorMessage = Label.PC_ProductsNotHavingCommonShippingPreference;
                    PC_Utility.throwAuraHandledException(errorMessage);
                }
            }
            List<PC_Association__c> aList = new List<PC_Association__c>();
            PC_Order__c o = new PC_Order__c();
            String patientId;

            if(String.isNotBlank(recordIdString)){
                List<String> orderFields = new List<String>();
                orderFields.add(PC_Constants.getQualifiedAPIName('PC_ShipTo2__c'));
                orderFields.add(PC_Constants.getQualifiedAPIName('PC_ProgramCase__c'));
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Order__c'), PC_Database.Operation.Reading, orderFields);

                List<String> accountFields = new List<String>();
                accountFields.add('AccountId');
                PC_Database.assertAccess(PC_Constants.PC_ACCOUNT, PC_Database.Operation.Reading, accountFields);

                o = [Select Id, PC_ShipTo2__c, PC_ProgramCase__c, PC_ProgramCase__r.AccountId From PC_Order__c Where Id =: recordId];
                Id pId = o.PC_ProgramCase__c;
                patientId = o.PC_ProgramCase__r.AccountId;
                existingShipToValue = o.PC_ShipTo2__c;
                existingProgramCaseValue = o.PC_ProgramCase__c;

                List<String> associationFields = new List<String>();
                associationFields.add(PC_Constants.getQualifiedAPIName('PC_Associated_User__c'));
                associationFields.add(PC_Constants.getQualifiedAPIName('PC_Account__c'));
                associationFields.add(PC_Constants.getQualifiedAPIName('PC_Role__c'));
                PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Association__c'), PC_Database.Operation.Reading, associationFields);
                aList = [Select ID, PC_Associated_User__c, PC_Account__c, PC_Role__c from PC_Association__c where PC_Program__c =: pId];
            }

            if(String.isNotBlank(patientId)){
                associationMap.put('Patient',patientId);//Hard coded since API name
            }
            for(PC_Association__c a : aList){
                if(String.isNotBlank(a.PC_Role__c)){
                    if(String.isNotBlank(a.PC_Account__c)){
                        associationMap.put(a.PC_Role__c,a.PC_Account__c);
                    }
                    if(String.isNotBlank(a.PC_Associated_User__c)){
                        associationMap.put(a.PC_Role__c,a.PC_Associated_User__c);
                    }
                }
            }

            rsf.fieldList           = cList;
            rsf.shipToValues        = options;
            rsf.associationMap      = associationMap;
            rsf.existingShipToValue = existingShipToValue;
            rsf.existingProgramCaseValue = existingProgramCaseValue;
            rsf.errorMessage        = errorMessage;

        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return rsf;
    }

    /**Called from pc_DataTable LWC.
     * Used to insert/update Order Items
    * @param orderItemData
    * @return Returns the JSON string equivalent of the list of inserted/updated Order Items.
    */

    @AuraEnabled
    public static String saveOrderItems(String orderItemData)
    {
        List<PC_OrderItem__c> returnValue = new List<PC_OrderItem__c>();
        try{
            List<PC_OrderItem__c> insertOrderItems = (List<PC_OrderItem__c>) JSON.deserialize(orderItemData, List<PC_OrderItem__c>.class);
            returnValue = PC_Database.ups(insertOrderItems);
        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return JSON.serialize(returnValue);
    }

    /**Called from pc_DataTable LWC.
     * Used to initiatize the custom wrapper resultSet
    * @return Returns the custom wrapper resultSet.
    */

    @AuraEnabled(cacheable=true)
    public static resultSet resultSet()
    {
        resultSet r1 = new resultSet();
        return r1;
    }
    
    /**Called from pc_DataTable LWC.
     * Used to get relevant data or Order, Product and OrderItem.
    * @return Returns the custom wrapper resultSet.
    */
    @AuraEnabled(cacheable=true)
    public static resultSet getcolumns(String fsProduct, String fsOrderItem, String recordIdString, String programIdString, String prescriptionIdString, String showAllProduct)
    {
        resultSet r         = new resultSet();
        try{
            Id recordId;
            Id programId;
            Id prescriptionId;
            Boolean showAllProductCheck = Boolean.valueOf(showAllProduct);
            if(String.isNotBlank(recordIdString)){
                recordId = (Id) Id.valueOf(recordIdString);
            }
            if(String.isNotBlank(programIdString)){
                programId = (Id) Id.valueOf(programIdString);
            }
            if(String.isNotBlank(prescriptionIdString)){
                prescriptionId = (Id) Id.valueOf(prescriptionIdString);
            }
            //FieldSet from Product2
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get('Product2');
            Schema.DescribeSObjectResult describe = targetType.getDescribe();
            Map<String, Schema.FieldSet> fsMap = describe.fieldSets.getMap();
            Schema.FieldSet fs = fsMap.get(fsProduct);
            List<Schema.FieldSetMember> fieldSetProduct = fs.getFields();
            List<String> fsFieldsToQuery = new List<String>();
            List<String> fsFieldsToQuery1 = new List<String>();

            List<column> cListProduct = new List<column>();
            for (Schema.FieldSetMember f : fieldSetProduct) {
                column c    = new column();
                c.label     = f.getLabel();
                c.fieldName = f.getFieldPath();
                fsFieldsToQuery.add(f.getFieldPath());
                c.type      = f.getType().name();
                c.isEditable = f.getSObjectField().getDescribe().isUpdateable();
                cListProduct.add(c);
            }

            //FieldSet from Order Item
            targetType = Schema.getGlobalDescribe().get(PC_Constants.getQualifiedAPIName('PC_OrderItem__c'));
            describe = targetType.getDescribe();
            fsMap = describe.fieldSets.getMap();
            fs = fsMap.get(fsOrderItem);
            List<Schema.FieldSetMember> fieldSetOrderItem = fs.getFields();

            List<column> cListOrderItem = new List<column>();

            for (Schema.FieldSetMember f : fieldSetOrderItem) {
                column c    = new column();
                c.label     = f.getLabel();
                c.fieldName = f.getFieldPath();
                c.type      = f.getType().name().toUpperCase() == 'DATETIME' ? 'date' : f.getType().name().toUpperCase();
                c.isEditable = f.getSObjectField().getDescribe().isUpdateable();
                fsFieldsToQuery1.add(f.getFieldPath());
                cListOrderItem.add(c);
                if(c.fieldName == PC_Constants.getQualifiedAPIName('PC_Product__c')){
                    column c1       = new column();
                    c1.label        = f.getLabel();
                    c1.fieldName    = PC_Constants.getQualifiedAPIName('PC_Product__r')+'.Name';
                    c1.type         = 'String';
                    fsFieldsToQuery1.add(c1.fieldName);
                    cListOrderItem.add(c1);
                }
            }

            List<String> caseFields = new List<String>();
            caseFields.add(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'));
            PC_Database.assertAccess(PC_Constants.PC_CASE, PC_Database.Operation.Reading, caseFields);

            List<String> prescriptionFields = new List<String>();
            prescriptionFields.add(PC_Constants.getQualifiedAPIName('PC_Product__c'));
            PC_Database.assertAccess(PC_Constants.getQualifiedAPIName('PC_Prescription__c'), PC_Database.Operation.Reading, prescriptionFields);

            List<PC_Order__c> ord = [SELECT PC_Prescription__r.PC_Product__c, PC_ProgramCase__r.PC_Engagement_Program__c
                                    FROM PC_Order__c WHERE id = :recordId];

            List<Case> prgcase = new List<Case>();
            if(programId != null){
                //FLS done above
                prgcase = [SELECT PC_Engagement_Program__c FROM Case WHERE id = :programId];
            }

            List<PC_Prescription__c> prescription = new List<PC_Prescription__c>();
            if(prescriptionId != null){
                // FLS done above
                prescription = [SELECT PC_Product__c FROM PC_Prescription__c WHERE id = :prescriptionId];
            }

            Set<Id> engagementProgramId = new Set<Id>();
            List<Id> prescProdList  = new List<Id>();
            Set<Id> prescriptionProductId = new Set<Id>();
            for(PC_Order__c o : ord){
                engagementProgramId.add(o.PC_ProgramCase__r.PC_Engagement_Program__c);
                prescProdList.add(o.PC_Prescription__r.PC_Product__c);
            }

            if(prgcase.size() > 0 ){
                for(Case c : prgcase){
                    engagementProgramId.add(c.PC_Engagement_Program__c);
                }
            }

            if(prescription.size() > 0 ){
                prescProdList  = new List<Id>();
                for(PC_Prescription__c p : prescription){
                    prescProdList.add(p.PC_Product__c);
                }
            }

            prescriptionProductId.addAll(prescProdList);
            List<PC_Engagement_Program_Product__c> engProgramProduct  = new List<PC_Engagement_Program_Product__c>();
            if(!showAllProductCheck){
                List<String> engagementProgramFields = new List<String>();
                //engagementProgramFields.add(PC_Constants.getQualifiedAPIName('PC_Engagement_Program__c'));
                engagementProgramFields.add(PC_Constants.getQualifiedAPIName('PC_Product__c'));
                PC_Database.assertAccess(PC_Engagement_Program_Product__c.getSObjectType().getDescribe().name, PC_Database.Operation.Reading, engagementProgramFields);
                engProgramProduct = [SELECT PC_Engagement_Program__c, PC_Product__c FROM PC_Engagement_Program_Product__c
                                    WHERE PC_Engagement_Program__c in :engagementProgramId];
            }

            List<Id> tempProductIdList = new List<Id>();
            Set<Id> productId = new Set<Id>();
            for(PC_Engagement_Program_Product__c p : engProgramProduct){
                tempProductIdList.add(p.PC_Product__c);
            }
            productId.addAll(tempProductIdList);

            //List<Product2> prdList  = new List<Product2>();
            String fields = PC_Constants.EMPTY_STRING + String.join(fsFieldsToQuery, ', ');
            String query;
            if(showAllProductCheck){
                query = 'SELECT ' + fields + ' ' + 'FROM ' +' Product2' + ' ORDER BY Name LIMIT 1000';
            }else{
                query = 'SELECT ' + fields + ' ' + 'FROM ' +' Product2'+ ' WHERE Id IN :productId ORDER BY Name';
            }
            List<sObject> prdList = Database.query(query);

            String fields1 = PC_Constants.EMPTY_STRING + String.join(fsFieldsToQuery1, ', ');
            String query1 = 'SELECT ' + fields1 + ' ' + 'FROM ' +' PC_OrderItem__c'+ ' WHERE PC_Order__c = :recordId';
            List<sObject> orditmList = Database.query(query1);

            //List<Product2> prdList  = new List<Product2>();
            String fields2 = PC_Constants.EMPTY_STRING + String.join(fsFieldsToQuery, ', ');
            String query2 = 'SELECT ' + fields + ' ' + 'FROM ' +' Product2'+ ' WHERE Id IN :prescriptionProductId';
            List<sObject> prescPrdList = Database.query(query2);

            r.selectionColumns  = cListProduct;
            r.displayColumns    = cListOrderItem;
            r.productList       = (List<Product2>) prdList;
            r.orderItemList     = (List<PC_OrderItem__c>) orditmList;
            r.prescProductList  = (List<Product2>) prescPrdList;
        }catch(Exception ex){
            PC_Utility.logAndThrowException(ex);
        }
        return r;
    }
    
    public inherited sharing class column{
        @Auraenabled
        public String  label {get; set;}
        @Auraenabled
        public String  fieldName {get; set;}
        @Auraenabled
        public String  type {get; set;}
        @Auraenabled
        public Boolean  isEditable {get; set;}

        public column(){
        }
    }
    
    public inherited sharing class resultSet{
        @Auraenabled
        public List<column>  selectionColumns {get; set;}
        @Auraenabled
        public List<column>  displayColumns {get; set;}
        @Auraenabled
        public List<Product2>  productList {get; set;}
        @Auraenabled
        public List<PC_OrderItem__c>  orderItemList {get; set;}
        @Auraenabled
        public List<Product2>  prescProductList {get; set;}

        public resultSet(){
        }
    }

    public inherited sharing class resultSetFields{
        @Auraenabled
        public List<column>  fieldList {get; set;}
        @Auraenabled
        public List<Map<String,String>>  shipToValues {get; set;}
        @Auraenabled
        public Map<String,String>  associationMap {get; set;}
        @Auraenabled
        public String  existingProgramCaseValue {get; set;}
        @Auraenabled
        public String  existingShipToValue {get; set;}
        @Auraenabled
        public String  errorMessage {get; set;}

        public resultSetFields(){
        }
    }
}