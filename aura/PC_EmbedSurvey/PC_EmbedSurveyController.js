/**
 * Created by havalakki on 6/11/2021.
 */
({
    doInit: function(component,event,helper){
        helper.setNamespace(component);
        helper.clearErrors(component);
        helper.getRecordIdAndEngagementProgValues(component,event,helper);
        helper.launchSurvey(component,event,helper);
    },
})