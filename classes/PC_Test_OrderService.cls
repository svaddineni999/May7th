/**
 * Created by vkashikar on 11/13/2020.
 */

@IsTest
private class PC_Test_OrderService {
    public static final string getURL_part = '/services/apexrest/' + PC_Constants.OrgNamespace + '/1.0/order/';
    @isTest static void testOrderService() {
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

            Account patient = PC_Test_Setup.createAccount('test', PC_SYSTEM.recordTypeId('Account', PC_Constants.PATIENT_RECORD_TYPE));
            PC_Database.ins(patient);
            Case c = PC_Test_Setup.createProgram(patient);

            RestRequest re = new  RestRequest();
            RestResponse rp = new  RestResponse();

            RestContext.request = re;
            RestContext.response = rp;

            Map<String, Object> orderMap = new Map<String, Object>();
            orderMap.put('status', 'Draft');
            orderMap.put('programCase',c.Id);
            String submittedDate = '2012-04-23';
            String submittedDateTime = submittedDate + 'T01:25:43.511Z'; // JSON format as needed by the service
            //Datetime submittedDatetime = Datetime.now();
            orderMap.put('submittedDate', submittedDatetime);


            Map<String, String> orderItemMap = new Map<String, String>();
            orderItemMap.put('type','Drugs');
            orderItemMap.put('product', product.Id);
            List<Map<String, String>> orderItemsMap = new List<Map<String, String>>();
            orderItemsMap.add(orderItemMap);
            orderMap.put('orderItems',orderItemsMap);
            String requestJSONString = JSON.serialize(orderMap);

            //string requestJSONString = '{"status":"Draft","orderItems":[{"type":"Drugs"}]}';
            re.requestBody = Blob.valueOf(requestJSONString);
            re.requestURI = getURL_part;
            re.httpMethod = 'POST';
            PC_OrderService.doPost();
            system.debug(rp.statusCode);
            system.debug(rp.responseBody);

            if(rp.statusCode == 200)
            {
                System.assert(true);

                String responseBody = rp.responseBody.toString();
                system.debug(responseBody);
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                String orderId = (String) responseMap.get('order');
                orderMap.put('id', orderId);

                List<Object> orderItemIds = (List<Object>) responseMap.get('orderItems');
                orderItemMap.put('id', (String) orderItemIds[0]);

                requestJSONString = JSON.serialize(orderMap);
                system.debug(requestJSONString);
                re.requestBody = Blob.valueOf(requestJSONString);
                re.requestURI = getURL_part;
                re.httpMethod = 'PUT';
                PC_OrderService.doPut();
                if(rp.statusCode == 200) {
                    system.debug(rp.responseBody.toString());
                    System.assert(true);
                }
                else {
                    system.debug(rp.responseBody.toString());
                    System.assert(false);
                }




                ///////////
                //Test GET service - I
                RestRequest getRequest = new  RestRequest();
                RestResponse getResponse = new  RestResponse();
                RestContext.request = getRequest;
                RestContext.response = getResponse;
                getRequest.requestURI = getURL_part + orderId;
                PC_OrderService.doGet();
                String orderNumber = null;
                if(getResponse.statusCode == 200) {
                    system.assert(true);
                    Map<String, Object> getResponseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(getResponse.responseBody.toString());
                    orderNumber = (String) getResponseBodyMap.get('orderNumber');
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
                system.debug('orderNumber=' + orderNumber);
                getRequest2.addParameter('orderNumber', orderNumber);
                getRequest2.addParameter('programCase', c.Id);
                getRequest2.addParameter('submittedDate', submittedDate);

                system.debug('requestURI=' + getRequest2.requestURI);
                PC_OrderService.doGet();
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
                    PC_OrderService.doGet();
                }
                catch(Exception ex) {
                    system.assert(true);
                }


                ////////

            }
            else
            {
                System.assert(false);
            }
            Test.stopTest();
        }
    }
}