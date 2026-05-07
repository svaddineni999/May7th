/*********************************************************************************
Class Name      : PC_GoogleMapServiceV2
Description     : Process accounts and set geolocation
Created By      : Roxana Ivan
Created Date    : 31-May-15
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Roxana Ivan               31-May-16              Initial Version
*********************************************************************************/

public with sharing class PC_GoogleMapServiceV2 {

    /*********************************************************************************
    Method Name    : updateGeoLocations
    Description    : Make a call to batch class with a size of 9
    Return Type    : void
    Parameter      : 1. IdSet : set of ids for which geolocation values to be inserted
    *********************************************************************************/
    public static void updateGeoLocations(Set<Id> IdSet){
        List<Id> Ids = new List<Id> (IdSet);
        if (Ids == null || Ids.size() == 0)
            return;

        if (Ids.size() < 9) {
            getGeolocationsFuture(Ids);
        }
        else {
            Database.executebatch(new PC_Batch_GeolocationCalloutV2(Ids), 30);
            return;
        }
    }

    /*********************************************************************************
    Method Name    : getGeolocationsFuture
    Description    : Make a call directly to the method if the number of records are less than 9
    Return Type    : void
    Parameter      : 1. Ids : list of ids for which geolocation values to be inserted
    *********************************************************************************/
    @future (callout=true)
    public static void getGeolocationsFuture(List<Id> Ids) {
        PC_Batch_GeolocationCalloutV2 caller = new PC_Batch_GeolocationCalloutV2(Ids);
        caller.makeCallouts(Ids);
    }
}