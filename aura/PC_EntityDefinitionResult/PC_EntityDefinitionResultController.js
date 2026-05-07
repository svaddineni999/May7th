/**
 * Created by tusarora on 3/11/2020.
 */
({
    selectRecord : function(component, event, helper){
        // get the selected record from list
         helper.setNamespace(component);
         var getSelectRecord = component.get("v.objRecord");
         // call the event
         var appEventName = 'e.' + component.get("v.namespace") + ':PC_SelectedEntityDefinitionEvent';
         //var appEventName = 'e.' + 'c:PC_SelectedEntityDefinitionEvent';
         console.log('appEventName::::'+appEventName);
         var appEvent = $A.get(appEventName);
         console.log('appEvent::::'+appEvent);
         //var appEvent = component.getEvent("oSelectedRecordEvent");
        // set the Selected sObject Record to the event attribute.
         appEvent.setParams({"recordByEvent" : getSelectRecord });
         console.log('appEventbeforeFire::::');
        // fire the event

         appEvent.fire();
         console.log('appEventAfterFire::::');
    }
})