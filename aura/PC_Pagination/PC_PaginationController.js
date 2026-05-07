({
    
    doInit : function(component, event, helper) {
        debugger;
        component.set("v.currentPagenumber", 1);
        
        
        
    },
    
    navigate: function(component, event, helper) {
        
        // this function call on click on the previous page button  
        var currentPagenumber = component.get("v.currentPagenumber") || 1;
        // get the previous button label  
        var direction = event.getSource().get("v.alternativeText");
        // get the select option (drop-down) values.  
        var recordToDisply = component.find("recordSize").get("v.value");
        // set the current page,(using ternary operator.)  
        currentPagenumber = direction === "Previous Page" ? (currentPagenumber - 1) : (currentPagenumber + 1);
        
        var myEvent = $A.get("e.c:PC_Pagination_AppEvent");
        
        
        myEvent.setParams({
            "sourceId" : component.get("v.sourceId"),
            "currentPagenumber": currentPagenumber,
            "totalNumberOfPages": recordToDisply,

        });
        myEvent.fire(); 
        
    },
    
    navigateFirstLast: function(component, event, helper) {
        
        // this function call on click on the previous page button  
        var totalNumberOfPages = component.get("v.totalNumberOfPages") || 1;
        // get the previous button label  
        var direction = event.getSource().get("v.alternativeText");
        // get the select option (drop-down) values.  
        var recordToDisply = component.find("recordSize").get("v.value");
        // set the current page,(using ternary operator.)  
        var  currentPagenumber = direction === "First Page" ? 1 : totalNumberOfPages  ;
        var myEvent = $A.get("e.c:PC_Pagination_AppEvent");
        
        
        myEvent.setParams({
            "sourceId" : component.get("v.sourceId"),
            "currentPagenumber": currentPagenumber,
            "totalNumberOfPages": recordToDisply,
            
            
        });
        myEvent.fire(); 
    },
    
    onSelectChange: function(component, event, helper) { 
        debugger;
        // this function call on the select option change,	 
        var currentPagenumber = 1
        var recordToDisply = component.find("recordSize").get("v.value");
        
        var myEvent = $A.get("e.c:PC_Pagination_AppEvent");
        
        
        myEvent.setParams({
            "sourceId" : component.get("v.sourceId"),
            "currentPagenumber": currentPagenumber,
            "totalNumberOfPages": recordToDisply,
            
            
        });
        myEvent.fire(); 
    },
})