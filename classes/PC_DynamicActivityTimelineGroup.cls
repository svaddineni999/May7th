/*************************************************************************************
Source - https://github.com/vipultaylor/sf-activity-timeline
Class Name          : PC_DynamicActivityTimelineGroup
Description         : Wrapper class for PC_DynamicActivityTimelineController.
CreatedBy           : Deloitte
Created Date        : 1 March 2021
Modification Log    :
*****************************************************************************************************
Developer                   Date                   Description
********************************************************************************************
Kanteti Kishore            1 March 2021           Initial version[PC-7427]
*****************************************************************************************/

public with sharing class PC_DynamicActivityTimelineGroup {
   @AuraEnabled
    public String name {get;set;}

    @AuraEnabled
    public List<PC_DynamicActivityTimelineModel> items {get;set;}

    public PC_DynamicActivityTimelineGroup(String name, List<PC_DynamicActivityTimelineModel> items){
        this.name = name;
        this.items = items;
    }

    public PC_DynamicActivityTimelineGroup(Long dateAsLong, List<PC_DynamicActivityTimelineModel> items){
        this.name = DateTime.valueOf(dateAsLong).format('MMM') + ' • ' + DateTime.valueOf(dateAsLong).year();
        this.items = items;
    }
}