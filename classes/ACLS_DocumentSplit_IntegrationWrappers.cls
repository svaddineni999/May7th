/*********************************************************************************
 Class Name     : ACLS_DocumentSplit_IntegrationWrappers
Description     : Stores all the request wrappers and response wrappers needed to perform the document split
Created Date    : April 5, 2023
Modification Log:
----------------------------------------------------------------------------------
Developer                   Date                   Description
-----------------------------------------------------------------------------------
Ronak Bansal            April 5, 2023              Initial Version
*********************************************************************************/
public with sharing class ACLS_DocumentSplit_IntegrationWrappers {    

    /*********************************************************************************
    Class Name     : splitRequest
    Description    : Prepares the request wrapper
    *********************************************************************************/
    public class SplitRequest{
        public PageSpecificationList pageSpecificationList;
        public Boolean isOcrRequested;

        public SplitRequest(PageSpecificationList pageSpecList, Boolean isOcrRequested){
            pageSpecificationList = pageSpecList;
            isOcrRequested = isOcrRequested;
        }
    }

    /*********************************************************************************
    Class Name     : SplitResponse
    Description    : parse the response JSON
    *********************************************************************************/
    public class SplitResponse{
        public String contentDocumentId;
        public Boolean isSuccess;
    }

    /*********************************************************************************
    Class Name     : PageSpecificationList
    Description    : Prepares the list of wrapper nodes for page split
    *********************************************************************************/
    public class PageSpecificationList {
		public List<PageSpecifications> pageSpecifications;
        
        public PageSpecificationList(List<PageSpecifications> pageSpecificationsList){
            pageSpecifications = pageSpecificationsList;
        }
    }

    /*********************************************************************************
    Class Name     : PageSpecifications
    Description    : Prepares the individual wrapper node for page split
    *********************************************************************************/
    public class PageSpecifications {
        public Integer page;
        public Integer rotation;
        public Boolean addToTargetFile;
        
        public PageSpecifications(Integer pageNo, Integer rotationVal, Boolean addToTarget){
            page = pageNo;
            rotation = rotationVal;
            addToTargetFile = addToTarget;
        }
    }    
}