/**
 * Created by vkashikar on 11/17/2020.
 */

@IsTest
public with sharing class PC_Test_OrderItemService {
    public static final string getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/orderItem/';
    @isTest static void testOrderItemService() {
        User adminUser;
        adminUser = PC_Test_Setup.createUser(PC_Test_Setup.SYS_ADMIN_PROFILE, 'user@test100.com', 'test');
        PC_Database.ins(adminUser);
        System.runAs(adminUser){
            Test.startTest();

            List<Account> manufacturers = PC_Test_Setup.createAccounts('Manu',1,PC_Constants.MANUFACTURER_RECORD_TYPE);
            PC_Database.ins(manufacturers);

            Product2 product = new Product2();
            product.PC_NDC__c = 'test';
            product.Name = 'test';
            product.PC_Manufacturer__c = manufacturers[0].id;
            PC_Database.ins(product);

            PC_Order__c order = new PC_Order__c();
            PC_Database.ins(order);

            RestRequest re = new  RestRequest();
            RestResponse rp = new  RestResponse();
            RestContext.request = re;
            RestContext.response = rp;

            Map<String, Object> orderItemMap = new Map<String, Object>();
            orderItemMap.put('status', 'Draft');
            orderItemMap.put('type','Informational Kits');
            orderItemMap.put('order',order.Id);
            orderItemMap.put('product',product.Id);

            String requestJSONString = JSON.serialize(orderItemMap);

            re.requestBody = Blob.valueOf(requestJSONString);
            re.requestURI = getURL_part;
            re.httpMethod = 'POST';
            PC_OrderItemService.doPost();
            system.debug(rp.statusCode);
            system.debug(rp.responseBody);

            if(rp.statusCode == 200)
            {
                System.assert(true);

                // Test the PUT service. Here, we will remove the 'order' key and insert the 'id' key
                String postResponseBody = rp.responseBody.toString();
                system.debug(postResponseBody);
                Map<String, Object> postResponseMap = (Map<String, Object>) JSON.deserializeUntyped(postResponseBody);
                String orderItemId = (String) postResponseMap.get('orderItem');
                orderItemMap.remove('order');
                orderItemMap.put('id', orderItemId);

                String putRequestJSONString = JSON.serialize(orderItemMap);
                system.debug(putRequestJSONString);
                RestRequest putRequest = new  RestRequest();
                RestResponse putResponse = new  RestResponse();
                RestContext.request = putRequest;
                RestContext.response = putResponse;
                putRequest.requestBody = Blob.valueOf(putRequestJSONString);
                putRequest.requestURI = getURL_part;
                putRequest.httpMethod = 'PUT';
                PC_OrderItemService.doPut();
                if(putResponse.statusCode == 200) {
                    system.debug(putResponse.responseBody.toString());
                    System.assert(true);
                }
                else {
                    system.debug(putResponse.responseBody.toString());
                    System.assert(false);
                }


                //Test GET service - I
                RestRequest getRequest = new  RestRequest();
                RestResponse getResponse = new  RestResponse();
                RestContext.request = getRequest;
                RestContext.response = getResponse;
                getRequest.requestURI = getURL_part + orderItemId;
                PC_OrderItemService.doGet();
                if(getResponse.statusCode == 200) {
                    system.assert(true);
                }
                else {
                    system.assert(false);
                }

                //Test GET service - II
                RestRequest getRequest2 = new  RestRequest();
                RestResponse getResponse2 = new  RestResponse();
                RestContext.request = getRequest2;
                RestContext.response = getResponse2;
                getRequest2.requestURI = getURL_part;
                getRequest2.addParameter('orderNumber', order.Name);
                getRequest2.addParameter('productId', product.Id);

                system.debug('requestURI=' + getRequest2.requestURI);
                PC_OrderItemService.doGet();
                if(getResponse2.statusCode == 200) {
                    system.assert(true);
                }
                else {
                    system.assert(false);
                }

                //Test GET service - III - No parameters will be passed here and we expect a failure.
                RestRequest getRequest3 = new  RestRequest();
                RestResponse getResponse3 = new  RestResponse();
                RestContext.request = getRequest3;
                RestContext.response = getResponse3;
                getRequest3.requestURI = getURL_part;
                try {
                    PC_OrderItemService.doGet();
                }
                catch(Exception ex) {
                    system.assert(true);
                }
            }
            else
            {
                System.assert(false);
            }
            Test.stopTest();
        }
    }
}