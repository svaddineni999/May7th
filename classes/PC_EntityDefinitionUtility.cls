/**
 * Created by tusarora on 3/6/2020.
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
----------------------------------------------------------------------------------
Haritha Reddy          21-Jan-2021                 [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/

public with sharing class PC_EntityDefinitionUtility {
    @AuraEnabled
    public static List<EntityDefinitionDetailWrapper> getEntityDefinitionList(String searchKeyword, Boolean isPlatformEventContext) {

        List<EntityDefinitionDetailWrapper> entityDefinitionWrapperList= new List<EntityDefinitionDetailWrapper>();
        List<EntityDefinition> entityDefinitionList = new List<EntityDefinition>();

        String Query;
        if(!isPlatformEventContext){
            searchKeyword ='\'%' + String.escapeSingleQuotes(searchKeyword.trim()) + '%\'';
            Query = 'SELECT Id, QualifiedApiName, NamespacePrefix, DeveloperName, Label, MasterLabel, PluralLabel, IsProcessEnabled FROM EntityDefinition where IsProcessEnabled = true AND Label Like '+ searchKeyword + 'Order by Label';
        } else {
            String platformEventIdentity = '__e';
            String platformEventKeyword = '';
            if(String.isBlank(searchKeyword)){
                platformEventKeyword = '\'%' + String.escapeSingleQuotes(platformEventIdentity.trim()) + '\'';
            }else{
                platformEventKeyword = '\'%' + String.escapeSingleQuotes(searchKeyword.trim()) + '%' + String.escapeSingleQuotes(platformEventIdentity.trim()) + '\'';
            }
            Query = 'SELECT Id, QualifiedApiName, NamespacePrefix, DeveloperName, MasterLabel, Label, PluralLabel, IsApexTriggerable, IsRetrieveable, IsProcessEnabled FROM EntityDefinition Where QualifiedApiName Like ' + platformEventKeyword + 'AND IsRetrieveable =false AND IsProcessEnabled = false AND isTriggerable = true' ;
        }
            //String Query = 'SELECT Id, QualifiedApiName, NamespacePrefix, DeveloperName, Label, MasterLabel, PluralLabel, IsProcessEnabled FROM EntityDefinition where IsProcessEnabled = true AND Label Like '+ searchKeyword + 'Order by Label';
        entityDefinitionList = Database.query(Query);

        for(EntityDefinition ed : entityDefinitionList){
            entityDefinitionWrapperList.add(new EntityDefinitionDetailWrapper(ed));
        }
        System.debug('entityDefinitionWrapperList::::'+entityDefinitionWrapperList);
        return entityDefinitionWrapperList;
    }
    public inherited sharing class EntityDefinitionDetailWrapper {

        @AuraEnabled
        public String QualifiedApiName { get; set; }
        @AuraEnabled
        public String NamespacePrefix { get; set; }
        @AuraEnabled
        public String DeveloperName { get; set; }
        @AuraEnabled
        public String Label { get; set; }
        @AuraEnabled
        public String MasterLabel { get; set; }
        @AuraEnabled
        public String PluralLabel { get; set; }
        @AuraEnabled
        public Boolean IsProcessEnabled { get; set; }

        public EntityDefinitionDetailWrapper(EntityDefinition  ed) {

            QualifiedApiName = ed.QualifiedApiName;
            NamespacePrefix = ed.NamespacePrefix;
            DeveloperName = ed.DeveloperName;
            Label = ed.Label;
            MasterLabel = ed.MasterLabel;
            IsProcessEnabled = ed.IsProcessEnabled;

        }

    }
}