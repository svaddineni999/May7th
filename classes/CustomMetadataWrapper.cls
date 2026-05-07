/**
* Created by Tushar Arora  on 16 OCT 2019.
*/
/*********************************************************************************
Class Name      : CustomMetadataWrapper
Description     : This Wrapper Class will be used for Custom Metadata Type
Created By      : Tushar Arora
Created Date    : 16 OCT 2019
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Tushar Arora                 16-OCT-19                  Initial Version [PC-5508]
Haritha Reddy             21-Jan-2021                 [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
*********************************************************************************/
public with sharing class CustomMetadataWrapper {

    public GroupWrapper groupDetail;

    public inherited sharing class GroupWrapper {
        public STRING objectAPIName;
        public STRING objectNamespace;
        public STRING fieldAPIName;
        public STRING fieldNamespace;
        public STRING fieldValue;
    }

}