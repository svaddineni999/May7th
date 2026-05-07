@isTest
global class ACLS_Test_SMSSendHttpCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');  
        System.debug('request.getEndpoint() VG'+request.getEndpoint());
        if(request.getEndpoint().contains('/token')){
           	response.setBody('{"access_token":"eyJraWQiOiI2NzYzZjQzMy03N2RlLTQwMjQtODBiZi1hODkyZTBiMzdjZGIiLCJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJBalB2c01LSGV6djIwOFNZR0JYeWhseWFaR21kTU14TyIsInZlciI6MSwiY2xpZW50SWQiOiJBalB2c01LSGV6djIwOFNZR0JYeWhseWFaR21kTU14TyIsInJvbGVzIjpbIklWUl9TTVMiXSwiaXNzIjoiaHR0cHM6XC9cL2FwaS5wcm9kLnVzLmZpdmU5Lm5ldCIsInR5cGUiOiJBY2Nlc3NUb2tlbiIsImV4cCI6MTY4MTkwNDU3NywiaWF0IjoxNjgxOTAwOTc3LCJvcmdJZCI6IjEzNjQyNyIsImRvbWFpbklkIjoiMTM2NDI3IiwianRpIjoiMzFkMzgwNDgtMjFhOC00MmNhLThhYzktODQ4OTllMjIyNjgxIn0.oULeFyynMddPvK4tk9tNrsNCQ3O_4CgIasOTc8BZaq9BVdVq4OWBQ5qSv-MTwFVGoL8PCzWnaqSwKEqI3aqQ-c2Wf9nXbdr1ghE12kprbV6fQ37q-n2YAqy-pcAgjyrRQLIpt_v15sRs5679ixeZOnZOPM3Mmo-msazFgUXzUsJvM-gRIEH-fqSJrKQrrCX6VnxHvv4WupPYvHnwoLHOtETLoyl_WXEq5nm-DO9ndx3py0ZRsYM4k-SJEZf8yUf10eosXkfxcvlyg64ln54VYeyAptB59rLKy2okEgvZuRz_fJYVEaSLJzISPHXBZI5BYmB4TwhRxJgpuWX6d0aGcg"}');
            response.setStatusCode(200);
        }else if(request.getEndpoint().contains('/smsoptinlist')){
            response.setStatusCode(204);
        }else if(request.getEndpoint().contains('https://api.prod.us.five9.net/send-sms-svc/v1/domains/136427/send-sms-tasks/')){
            System.debug('request.getEndpoint() VG1'+request.getEndpoint());
            response.setBody('{"createdOn": "2023-04-18T14:12:38.202Z", "createdBy": "136427", "lastModifiedOn": "2023-04-18T14:13:38.694Z", "lastModifiedBy": "136427", "campaignName": "CC_US_SMS_OB",  "dispositionName": null, "message": "Welcome to RareAssistRx! We have received your RareAssistRx enrollment form for salafaxine. Reply HELP for help, STOP to cancel.",  "scheduledTime": null, "attributes": {}, "name": "a1bDT000001lYFpYAM","sendSmsTaskId": "018793a3-7216-ebcb-9cce-e246cb0ae8e6",  "status": "FAILED",    "taskProgress": [ { "count": 1, "status": "DELIVERED" } ]}');
            response.setStatusCode(200);
        }else if(request.getEndpoint().contains('send-sms-tasks')){
            response.setBody('{"sendSmsTaskId": "018793a3-7216-ebcb-9cce-e246cb0ae8e6","uri": "/send-sms-svc/v1/domains/136427/send-sms-tasks/018793a3-7216-ebcb-9cce-e246cb0ae8e6"}');
            response.setStatusCode(200);
        }  
        
        return response; 
    }    
}