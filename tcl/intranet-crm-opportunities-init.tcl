ad_library {
    Initialization for intranet-crm-opportunities
    @author Klaus Hofeditz (klaus.hofeditz@project-open.com)
}


ad_proc -public -callback im_opportunity_create_project {
    {-opportunity_id:required}
} {
	@param opportunity_id 
} -
