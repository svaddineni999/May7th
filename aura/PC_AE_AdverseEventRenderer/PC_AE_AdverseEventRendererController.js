/**
 * Created by shisbansal on 12/3/2018.
 */
({
    doInit: function(component, event, helper){
        helper.getAdverseEventData(component, event, helper);
    },
    onOutcomeChange:function(component, event, helper){
        helper.onOutcomeChange(component, event, helper);
    }
})