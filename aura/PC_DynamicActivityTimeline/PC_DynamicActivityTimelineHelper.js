/**
 * Created by kkanteti on 3/11/2021.
 */
({
    getActivityTimelineGroups : function(component,event,helper){
        // retrieve server method
        var action = component.get("c.getActivityTimeline");

        // set method paramaters
        action.setParams({
            "recordId" : component.get("v.recordId"),
            "includeChildren": false    //use this only if account related activities are to be shown
        });

        // set call back instructions
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var timelineGroups = response.getReturnValue();
                var activeSections = [];
                timelineGroups.forEach(function(timelineGroup, index){
                    var sectionName = 'Section'+index;
                    activeSections.push(sectionName);
                    timelineGroup.sectionName = sectionName;
                });

                // assign server retrieved items to component variable
                component.set("v.timelineGroups", timelineGroups);
                component.set("v.activeSections", activeSections);
            }else if(state == 'ERROR'){
                var errors = response.getError();
                CH_PC_Util.showAllErrors(component.get("v.errorStatus"),errors);
            }
        });

        // queue action on the server
        $A.enqueueAction(action);
    }
})