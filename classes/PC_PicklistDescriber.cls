/****************************************************************************************************************************************************
--------------------------------------------------------------------------------------------------------------
Developer          Log#         Date                   Description
--------------------------------------------------------------------------------------------------------------
Deloitte         		  	 Aug 30, 2016           Initial Version
Vijay Kashikar         		 May 29, 2018           [PC-4666] Added logic to return picklist values along with their API names
Vijay Kashikar               Apr 16, 2019          [PC-4723] Picklist values with HTML entities are now supported.
Vijay Kashikar               Nov 21, 2019          [PC-5751] Removed debug statements and commented-out code
Haritha Reddy                21-Jan-2021           [PC-7102] Force Reviewer scan issue fix. Updated Sharing declaration.
****************************************************************************************************************************************************/

/*
Copyright (c) 2012 tgerm.com
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
	Class which client code needs to interact with. Call any of the overloaded describe method,
	make sure you are passing all the params in the method signature  
	@author Abhinav 
*/
public with sharing class PC_PicklistDescriber {
	static final Pattern OPTION_PATTERN = Pattern.compile('<option.+?>(.+?)</option>'); 
    //static final Pattern OPTION_PATTERN_VALUE = Pattern.compile('<option value="(.+?)".+?</option>'); 
    static final Pattern OPTION_PATTERN_VALUE = Pattern.compile('<option value="(.*?)">(.*?)</option>');
	//Pattern for matching dependent pick list values
	static final Pattern DEPENDENT_PICKLIST_PATTERN_VALUE = Pattern.compile('pl.vals_(.*?)=(.*?);');

    public static Map<String, String> describeAsMap(String sobjectType, Id recordTypeId, String dependentFieldName) {
		return parseOptionsAsMap(
                new Map<String, String>	{
                        'sobjectType' => sobjectType,
                        'recordTypeId' => recordTypeId,
                        'dependentFieldName'=> dependentFieldName
                }
        );
	}

	/*********************************************************************************
    Method Name    : describeAsMap
    Author         : Vivek Kumar Mishra
    Description    : Overloaded method to fetch dependent picklist values based on
                     Record Type
    Return Type    : Map<String, String>
    Parameter      : String sobjectType, Id recordTypeId, String dependentFieldName,
                     String controllingFieldName
    *********************************************************************************/
	public static Map<String, String> describeAsMap(String sobjectType, Id recordTypeId, String dependentFieldName, String controllingFieldName) {
		return parseOptionsAsMap(
				new Map<String, String>	{
						'sobjectType' => sobjectType,
						'recordTypeId' => recordTypeId,
						'dependentFieldName'=> dependentFieldName,
						'controllingFieldName'=> controllingFieldName
				}
		);
	}
	
	static Map<String, String> parseOptionsAsMap(Map<String, String> params) {
		Pagereference pr = Page.PC_PicklistDesc;
		Matcher mchr = null;
		pr.getParameters().put('core.apexpages.devmode.url', '1');
		
		for (String key : params.keySet()) {
			pr.getParameters().put(key, params.get(key));	
		}
		String xmlContent = pr.getContent().toString();
		xmlContent = xmlContent.unescapeXml();
		xmlContent = xmlContent.unescapeUnicode();

		if(isControllingFieldIncluded(params)){
			//Selected pattern in dependent pick list scenario
			mchr= DEPENDENT_PICKLIST_PATTERN_VALUE.matcher(xmlContent);
		} else{
			mchr= OPTION_PATTERN_VALUE.matcher(xmlContent);
		}
        Map<String, String> options = new Map<String, String>();
		Map<String, String> options1 = new Map<String, String>();
        String name;
		String value;
		while(mchr.find()) {
			value = mchr.group(1);
			if(isControllingFieldIncluded(params)){
				String tempStr = mchr.group(2).substring(1, mchr.group(2).length()-1);
				tempStr = tempStr.replace('\'','');
                List<String> recordTypeList = tempStr.split(',');
				for(Integer i=0; i < recordTypeList.size() - 1; i++) {
					// size of recordTypeList will always be zero or even number.
					if(Math.mod(i,2) == 0) {
						options1.put(recordTypeList[i], recordTypeList[i+1]);
					}
				}
				return options1;
			} else {
				name = mchr.group(2);
			}
            
            if(value.indexOf('"', 0) != -1) {
            	value = value.substring(0, value.indexOf('"', 0));
            }
            options.put(value, name);
		}
            
		return options;
	}

	/*********************************************************************************
    Method Name    : isControllingFieldIncluded
    Author         : Vivek Kumar Mishra
    Description    : Method to check whether controlling field parameter is included
                     in the parameter map
    Return Type    : Boolean
    Parameter      : Map<String, String> params
    *********************************************************************************/
    static Boolean isControllingFieldIncluded(Map<String, String> params) {
        if (params.containsKey('controllingFieldName')) {
            return true;
        }
        return false;
    }
}