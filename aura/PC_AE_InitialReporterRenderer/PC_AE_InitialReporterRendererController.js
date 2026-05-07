({
	doInit : function(component, event, helper)
    { 
        helper.getInitialReportData(component, event, helper);
        var aeId = component.get('v.aeId');
        if(aeId != 'undefined' && aeId != null){
            helper.loadDataFromAE(component, event, helper);
        }else{
            component.set("v.showRefreshIcon",false);
            }
	},
    onReporterTypeChange:function(component, event, helper){
        component.set("v.showReporterWarning" , false);
        component.set("v.morethanOneReporter" , false);
        component.set("v.notFoundReporter" , false);
        component.set("v.wrongHealthCareProfessionalOption",false);
        helper.onReporterTypeChange(component, event, helper);

    },

    onHealthCareProfessionalChange:function(component,event,helper){
     component.set("v.aeWrapper.occupation"," ");
     helper.resetReporterValues(component,event,helper);
     helper.setReporterTypeOptions(component,event,helper);

    },

    onRefreshClick:function(component, event, helper){

        component.set("v.showReporterWarning" , false);
        component.set("v.morethanOneReporter" , false);
        component.set("v.notFoundReporter" , false);
        component.set("v.wrongHealthCareProfessionalOption",false);
        helper.onRefreshClick(component,event, helper);
    }

})