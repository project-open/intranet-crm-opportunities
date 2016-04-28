-- upgrade-5.0.0.0.1-5.0.0.0.2.sql
SELECT acs_log__debug('/packages/intranet-crm-opportunities/sql/postgresql/upgrade/upgrade-5.0.0.0.1-5.0.0.0.2.sql','');

-- Members
SELECT  im_component_plugin__new (
        null,                                           -- plugin_id
        'im_component_plugin',                          -- object_type
        now(),                                          -- creation_date
        null,                                           -- creation_user
        null,                                           -- creation_ip
        null,                                           -- context_id
        'Opportunities for User',                       -- plugin_name
        'intranet-crm-opportunities',                   -- package_name
        'right',                                        -- location
        '/intranet/users/view',             		-- page_url
        null,                                           -- view_name
        20,                                             -- sort_order
        'im_opportunity_user_component -user_id $user_id -number_opportunities_shown 5' -- component_tcl
);

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'Opportunities for User' and package_name = 'intranet-crm-opportunities'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);

-- Fix link in DynView (/intranet-crm-opportunities/opportunities)
update im_view_columns set column_render_tcl = '"<a href=/intranet/users/view?user_id=$project_lead_id>$opportunity_owner</a>"' where view_id = 980 and column_id = 98090; 

