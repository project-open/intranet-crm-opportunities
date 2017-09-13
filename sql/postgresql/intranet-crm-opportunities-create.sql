-- /packages/intranet-crm-opportunities/sql/postgresql/intranet-crm-opportunities-create.sql
--
-- Copyright (c) 2003-now ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author klaus.hofeditz@project-open.com

-----------------------------------------------------------
-- Opportunity

SELECT im_category_new(102, 'CRM Opportunity', 'Intranet Project Type');
SELECT im_category_new(103, 'CRM Campaign', 'Intranet Project Type');
update im_categories set enabled_p = 'f' where category_id in (102, 103);

update im_categories 
set category_description = 'Allows assignment of opportunities to marketing campaigns. Disable if CRM module is not used.' 
where category_type = 'Intranet Project Type' and category = 'CRM Campaign';



-- Disable "Opportunity & Campaign" so that they do not appear in the list of project types
-- update im_categories set enabled_p = 'f' where category_id = '102';
-- update im_categories set enabled_p = 'f' where category_id = '103';

-----------------------------------------------------------
-- Categories
-----------------------------------------------------------

-- 84000-84009 - Intranet Opportunity Priority
SELECT im_category_new(84000, '1 - Highest Priority', 'Intranet Opportunity Priority');
SELECT im_category_new(84001, '2 - Very High Priority', 'Intranet Opportunity Priority');
SELECT im_category_new(84002, '3 - High Priority', 'Intranet Opportunity Priority');
SELECT im_category_new(84003, '4 - Medium High Priority', 'Intranet Opportunity Priority');
SELECT im_category_new(84004, '5 - Average Priority', 'Intranet Opportunity Priority');
SELECT im_category_new(84005, '6 - Medium Low Priority', 'Intranet Opportunity Priority');
SELECT im_category_new(84006, '7 - Low Priority', 'Intranet Opportunity Priority');
SELECT im_category_new(84007, '8 - Very Low Priority', 'Intranet Opportunity Priority');
SELECT im_category_new(84008, '9 - Lowest Priority', 'Intranet Opportunity Priority');

-- 84010-84020 - Intranet Opportunity Sales Stage
SELECT im_category_new(84010, 'Prospecting', 'Intranet Opportunity Sales Stage');
SELECT im_category_new(84011, 'Qualification', 'Intranet Opportunity Sales Stage');
SELECT im_category_new(84012, 'Needs Analysis', 'Intranet Opportunity Sales Stage');
SELECT im_category_new(84013, 'Value Proposition', 'Intranet Opportunity Sales Stage');
SELECT im_category_new(84014, 'Id. Decision Makers', 'Intranet Opportunity Sales Stage');
SELECT im_category_new(84015, 'Perception Analysis', 'Intranet Opportunity Sales Stage');
SELECT im_category_new(84016, 'Proposal/Price Quote', 'Intranet Opportunity Sales Stage');
SELECT im_category_new(84017, 'Negotiation/Review', 'Intranet Opportunity Sales Stage');
SELECT im_category_new(84018, 'Closed', 'Intranet Opportunity Sales Stage');
SELECT im_category_new(84019, 'Closed Won', 'Intranet Opportunity Sales Stage');
SELECT im_category_new(84020, 'Closed Lost', 'Intranet Opportunity Sales Stage');

SELECT im_category_hierarchy_new (84019, 84018);
SELECT im_category_hierarchy_new (84020, 84018);

-----------------------------------------------------------
-- Component Plugins
--
-- Opportunity Base Data on Opportunity Home 

SELECT im_component_plugin__new (
	null,						-- plugin_id
	'im_component_plugin',				-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'Opportunity Base Data',			-- plugin_name - shown in menu
	'intranet-crm-opportunities',			-- package_name
	'left',						-- location
	'/intranet-crm-opportunities/view',		-- page_url
	null,						-- view_name
	10,						-- sort_order
	'im_opportunity_base_data_component -opportunity_id $opportunity_id',	-- component_tcl
	'lang::message::lookup "" "intranet-crm-opportunities.OpportunityBaseData" "Opportunity Base Data"'
);

SELECT acs_permission__grant_permission(
	(select plugin_id from im_component_plugins where plugin_name = 'Opportunity Base Data' and package_name = 'intranet-crm-opportunities'), 
	(select group_id from groups where group_name = 'Employees'),
	'read'
);

-- Opportunity Forum 
SELECT im_component_plugin__new (
        null,                           		-- plugin_id
        'im_component_plugin',          		-- object_type
        now(),                          		-- creation_date
        null,                           		-- creation_user
        null,                           		-- creation_ip
        null,                           		-- context_id
        'Opportunity Contact History',  		-- plugin_name - shown in menu
        'intranet-crm-opportunities',           	-- package_name
        'right',                         		-- location
        '/intranet-crm-opportunities/view',     	-- page_url
        null,                           		-- view_name
        10,                             		-- sort_order
        'im_forum_component -user_id $user_id -forum_object_id $opportunity_id -current_page_url $current_url -return_url $return_url -forum_type "project" -export_var_list [list project_id forum_start_idx forum_order_by forum_how_many forum_view_name] -view_name [im_opt_val forum_view_name] -forum_order_by [im_opt_val forum_order_by] -start_idx [im_opt_val forum_start_idx] -restrict_to_mine_p "f" -restrict_to_new_topics 0 -write_icons 1',    -- component_tcl
        'lang::message::lookup "" "intranet-crm-opportunities.OpportunityBaseData" "Opportunity Contact History"'
);

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'Opportunity Contact History' and package_name = 'intranet-crm-opportunities'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);

-- Members
SELECT  im_component_plugin__new (
        null,                           		-- plugin_id
        'im_component_plugin',                   		-- object_type
        now(),                          		-- creation_date
        null,                           		-- creation_user
        null,                           		-- creation_ip
        null,                           		-- context_id
        'Opportunity Members',              		-- plugin_name
        'intranet-crm-opportunities',           	-- package_name
        'right',                        		-- location
        '/intranet-crm-opportunities/view',     	-- page_url
        null,                           		-- view_name
        20,                             		-- sort_order
        'im_table_with_title "[lang::message::lookup "" intranet-crm-opportunities.OpportunityMembers "Members"]" [im_group_member_component $opportunity_id $current_user_id $user_admin_p $return_url "" "" 1 ]'   		-- component_tcl
);

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'Opportunity Members' and package_name = 'intranet-crm-opportunities'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);

-- Timesheet
select im_component_plugin__new (
        null,                                   	-- plugin_id
        'im_component_plugin',                  	-- object_type
        now(),                                  	-- creation_date
        null,                                   	-- creation_user
        null,                                   	-- creattion_ip
        null,                                   	-- context_id

        'Opportunity Timesheet Component',      	-- plugin_name
        'intranet-crm-opportunities',			-- package_name
        'right',                                	-- location
        '/intranet-crm-opportunities/view',             -- page_url
        null,                                   	-- view_name
        50,                                     	-- sort_order
        'im_timesheet_project_component $user_id $opportunity_id',
        'lang::message::lookup "" intranet-timesheet2.Timesheet "Timesheet"'
);
update im_component_plugins
set title_tcl = 'lang::message::lookup "" intranet-timesheet2.Timesheet "Timesheet"'
where plugin_name = 'Opportunity Timesheet Component';

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'Opportunity Timesheet Component' and package_name = 'intranet-crm-opportunities'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);



-------------------------------------------------------------------------------
-- Sales Pipeline by Number and Volume
--

SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Sales Pipeline by Number',		-- plugin_name
	'intranet-crm-opportunities',		-- package_name
	'right',				-- location
	'/intranet-crm-opportunities/index',	-- page_url
	null,					-- view_name
	100,					-- sort_order
        'im_dashboard_histogram_sql -diagram_width 300 -sql "
                select  im_lang_lookup_category(''[ad_conn locale]'', p.opportunity_sales_stage_id) as project_status,
                        count(*) as cnt,
                        (select sort_order from im_categories where category_id = p.opportunity_sales_stage_id) as sort_order
                from    im_projects p
                where   p.parent_id is null
                        and p.project_status_id not in (select * from im_sub_categories(84018))
                        and project_type_id = 102
                group by opportunity_sales_stage_id
                order by sort_order, p.opportunity_sales_stage_id
        "',
	'lang::message::lookup "" intranet-crm-opportunities.Sales_Pipeline_by_Number "Sales Pipeline by Number"'
);


SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Sales Pipeline by Volume',		-- plugin_name
	'intranet-crm-opportunities',		-- package_name
	'right',				-- location
	'/intranet-crm-opportunities/index',	-- page_url
	null,					-- view_name
	200,					-- sort_order
	'im_dashboard_histogram_sql -diagram_width 300 -sql "
		select  im_lang_lookup_category(''[ad_conn locale]'', p.opportunity_sales_stage_id) as project_status,
			round(sum(coalesce(presales_probability,0) * coalesce(presales_value,project_budget,0)) / 100.0 / 1000.0) as value,
			(select sort_order from im_categories where category_id = p.opportunity_sales_stage_id) as sort_order
		from	im_projects p
		where   p.parent_id is null
			and p.project_status_id not in (select * from im_sub_categories(84018))
			and project_type_id = 102
		group by opportunity_sales_stage_id
		order by
			sort_order,
			p.opportunity_sales_stage_id
	"',
	'lang::message::lookup "" intranet-crm-opportunities.Sales_Pipeline_by_Volume "Sales Pipeline by Volume"'
);


SELECT im_component_plugin__new (
	null,					-- plugin_id
	'im_component_plugin',			-- object_type
	now(),					-- creation_date
	null,					-- creation_user
	null,					-- creation_ip
	null,					-- context_id
	'Top 10 Opportunities',			-- plugin_name - shown in menu
	'intranet-crm-opportunities',		-- package_name
	'right',				-- location
	'/intranet-crm-opportunities/index',	-- page_url
	null,					-- view_name
	100,					-- sort_order
	'im_ad_hoc_query -format html -package_key intranet-crm-opportunities "
		select
			''<a href=/intranet/companies/view?company_id='' || cust.company_id || ''>'' || cust.company_name || ''</a>'' as company,
			''<a href=/intranet/projects/view?project_id='' || p.project_id || ''>'' || p.project_name || ''</a>'' as opportunity,
			p.presales_value,
			p.presales_probability,
			p.presales_value * p.presales_probability as weighted_value
		from	im_projects p,
			im_companies cust
		where	p.parent_id is null and
			p.project_type_id = 102 and
			p.company_id = cust.company_id
		order by weighted_value DESC
		limit 10
"',   -- component_tcl
	'lang::message::lookup "" intranet-crm-opportunities.Top_10_Opportunities "Top 10 Opportunities"'
);



SELECT im_component_plugin__new (
	null,						-- plugin_id
	'im_component_plugin',				-- object_type
	now(),						-- creation_date
	null,						-- creation_user
	null,						-- creation_ip
	null,						-- context_id
	'Sales Pipeline - Volume vs. Probability',	-- plugin_name
	'intranet-crm-opportunities',			-- package_name
	'left',						-- location
	'/intranet-crm-opportunities/index',		-- page_url
	null,						-- view_name
	200,						-- sort_order
	'im_opportunity_pipeline -diagram_width 600 -diagram_height 600',
	'lang::message::lookup "" intranet-crm-opportunities.Sales_Pipeline_Volume_vs_Probability "Sales Pipeline - Volume vs. Probability"'
);

SELECT acs_permission__grant_permission(
        (select plugin_id from im_component_plugins where plugin_name = 'Sales Pipeline - Volume vs. Probability' and package_name = 'intranet-crm-opportunities'),
        (select group_id from groups where group_name = 'Employees'),
        'read'
);




-- Dont hide this component like the other ones below,
-- it should appear by default on the "summary" page

-----------------------------------------------------------
-- Menu for CRM
--
-- Create a menu item and set some default permissions
-- for various groups who whould be able to see the menu.

create or replace function inline_0 ()
returns integer as $BODY$
declare
	-- Menu IDs
	v_menu			integer;
	v_main_menu		integer;
	v_crm_menu		integer;

	-- Groups
	v_employees		integer;
	v_accounting		integer;
	v_senman		integer;
	v_companies		integer;
	v_freelancers		integer;
	v_proman		integer;
	v_admins		integer;
	v_reg_users		integer;
BEGIN
	-- Get some group IDs
	select group_id into v_admins from groups where group_name = 'P/O Admins';
	select group_id into v_senman from groups where group_name = 'Senior Managers';
	select group_id into v_proman from groups where group_name = 'Project Managers';
	select group_id into v_employees from groups where group_name = 'Employees';
	select group_id into v_reg_users from groups where group_name = 'Registered Users';

	-- Determine the main menu. "Label" is used to
	-- identify menus.
	select menu_id into v_main_menu	from im_menus where label='main';

	-- Create the menu.
	v_crm_menu := im_menu__new (
		null,				-- p_menu_id
		'im_menu',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		'intranet-crm-opportunities',	-- package_name
		'crm',				-- label
		'CRM',				-- name
		'/intranet-crm-opportunities/',	-- url
		9850,				-- sort_order
		v_main_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);
	PERFORM acs_permission__grant_permission(v_crm_menu, v_admins, 'read');
	PERFORM acs_permission__grant_permission(v_crm_menu, v_senman, 'read');
	PERFORM acs_permission__grant_permission(v_crm_menu, v_proman, 'read');
	PERFORM acs_permission__grant_permission(v_crm_menu, v_employees, 'read');

	-- Create Opportunities
	v_menu := im_menu__new (
		null,				-- p_menu_id
		'im_menu',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		'intranet-crm-opportunities',	-- package_name
		'crm_home',			-- label
		'CRM Home',			-- name
		'/intranet-crm-opportunities/',	-- url
		10,				-- sort_order
		v_crm_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);
	PERFORM acs_permission__grant_permission(v_menu, v_admins, 'read');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, 'read');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, 'read');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, 'read');

	-- Create Opportunities
	v_menu := im_menu__new (
		null,				-- p_menu_id
		'im_menu',			-- object_type
		now(),				-- creation_date
		null,				-- creation_user
		null,				-- creation_ip
		null,				-- context_id
		'intranet-crm-opportunities',	-- package_name
		'crm_opportunities',		-- label
		'Opportunities List',		-- name
		'/intranet-crm-opportunities/opportunities',	-- url
		20,				-- sort_order
		v_crm_menu,			-- parent_menu_id
		null				-- p_visible_tcl
	);
	PERFORM acs_permission__grant_permission(v_menu, v_admins, 'read');
	PERFORM acs_permission__grant_permission(v_menu, v_senman, 'read');
	PERFORM acs_permission__grant_permission(v_menu, v_proman, 'read');
	PERFORM acs_permission__grant_permission(v_menu, v_employees, 'read');

	-- Rename menu created by intranet-contacts 
	update im_menus set 
		name = 'Contacts',
		parent_menu_id = v_crm_menu
	where package_name = 'intranet-contacts' and name='CRM';

	return 0;
end; $BODY$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- 

-- reserved for intranet-crm-opportunities: 980-989
-----------------------------------------------------------
-- OpportunityListPage Main View
-----------------------------------------------------------

delete from im_view_columns where view_id = 980;
delete from im_views where view_id = 980;

insert into im_views (view_id, view_name, visible_for, view_type_id)
values (980, 'opportunity_list', 'view_opportunities', 1400);

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(98000,980,10, 'Prio','"[im_category_from_id $opportunity_priority_id]"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(98010,980,20, 'Nr','"<a href=/intranet-crm-opportunities/view?opportunity_id=$project_id>$project_nr</a>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(98020,980,30,'Name','"<a href=/intranet-crm-opportunities/view?opportunity_id=$project_id>$project_name</A>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(98030,980,40,'Company','"<a href=/intranet/companies/view?company_id=$company_id>$company_name</A>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(98040,980,50,'Contact','"<a href=/intranet/users/view?user_id=$company_contact_id>$contact_name</a>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(98050,980,60,'Sales Stage','[im_category_from_id $opportunity_sales_stage_id]');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(98060,980,70,'Presales Value','"$presales_value_pretty $presales_value_currency"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(98070,980,80,'Probability','$presales_probability %');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(98080,980,90,'Weighted Value','"$opportunity_weighted_value $presales_value_currency"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(98090,980,100,'Owner','"<a href=/intranet/users/view?user_id=$user_id>$opportunity_owner</a>"');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(98100,980,110,'Campaign','"<a href=/intranet/users/view?user_id=$user_id>$campaign_name</a>"');

-- insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
-- (98100,980,110,'Close Date','$confirm_date');

insert into im_view_columns (column_id, view_id, sort_order, column_name, column_render_tcl) values
(98110,980,110,'Create Project','"<a href=/intranet-crm-opportunities/create-project-from-opportunity?opportunity_id=$opportunity_id>Create</a>"');


-----------------------------------------------------------
-- DynField Widgets
--

-- opportunity_sales_stage
SELECT im_dynfield_widget__new (
        null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
        'opportunity_sales_stage', 'Opportunity Sales Stage', 'Opportunity Sales Stage',
        10007, 'integer', 'im_category_tree', 'integer',
        '{custom {category_type "Intranet Opportunity Sales Stage"}}'
);

-- opportunity_priority
SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'opportunity_priority', 'Opportunity Priority', 'Opportunity Priority',
	10007, 'integer', 'im_category_tree', 'integer',
	'{custom {category_type "Intranet Opportunity Priority"}}'
);

-- opportunity_campaign
SELECT im_dynfield_widget__new (
	null, 'im_dynfield_widget', now(), 0, '0.0.0.0', null,
	'opportunity_campaign', 'Opportunity Campaign', 'Opportunity Campaign',
	10007, 'integer', 'generic_sql', 'integer',
	'{custom {sql {select project_id, project_name from im_projects where project_type_id = 103 and project_status_id in (76) order by project_name }}}'

);

-----------------------------------------------------------
-- DynFields
--


-- Enable presales_value
create or replace function inline_0 ()
returns integer as $BODY$
declare
        v_dynfield_attribute_id           integer;
begin

        SELECT attribute_id into v_dynfield_attribute_id
	FROM   im_dynfield_attributes where acs_attribute_id in (
		select	attribute_id from acs_attributes where attribute_name = 'presales_value' and object_type = 'im_project'
	       );

	-- Delete dynfield map for "CRM Opportunity"
	delete from im_dynfield_type_attribute_map
	where	attribute_id = v_dynfield_attribute_id and
		object_type_id = 102;

	insert into im_dynfield_type_attribute_map (
		attribute_id, object_type_id, display_mode
	) values (
		v_dynfield_attribute_id, 102, 'edit'
	);

        return 0;
end;$BODY$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- Enable presales_probability
create or replace function inline_0 ()
returns integer as $BODY$
declare
        v_dynfield_attribute_id           integer;
begin

        SELECT attribute_id into v_dynfield_attribute_id
	FROM   im_dynfield_attributes where acs_attribute_id in (
		select	attribute_id from acs_attributes where attribute_name = 'presales_probability' and object_type = 'im_project'
	       );

	-- Delete dynfield map for "CRM Opportunity"
	delete from im_dynfield_type_attribute_map
	where	attribute_id = v_dynfield_attribute_id and
		object_type_id = 102;

	insert into im_dynfield_type_attribute_map (
		attribute_id, object_type_id, display_mode
	) values (
		v_dynfield_attribute_id, 102, 'edit'
	);

        return 0;
end;$BODY$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();




-- presales_value_currency
create or replace function inline_0 ()
returns integer as $BODY$
declare
        v_dynfield_attribute_id           integer;
begin
        SELECT im_dynfield_attribute_new (
	        'im_project', 'presales_value_currency', 'Presales Value Currency', 'currencies', 'string', 'f', 10, 'f', 'im_projects'
        ) into v_dynfield_attribute_id ;

        RAISE NOTICE 'intranet-crm-opportunities-create.sql: Created Dynfield ''Presales Value Currency'' -  v_dynfield_attribute_id: %',v_dynfield_attribute_id;

        begin
                alter table im_projects add column presales_value_currency varchar;
        exception when others then
                raise notice 'intranet-crm-opportunities-create.sql: Could not create column ''presales_value_currency'', it might exist already ';
        end;

        -- Show Dynfield only for sub type 'opportunity'
        update im_dynfield_type_attribute_map set display_mode = 'none' where attribute_id = v_dynfield_attribute_id and object_type_id <> 102;


        return 1;

end;$BODY$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();



-- opportunity_priority
create or replace function inline_0 ()
returns integer as $BODY$
declare
        v_dynfield_attribute_id           integer;
begin

        SELECT im_dynfield_attribute_new (
        'im_project', 'opportunity_priority_id', 'Priority', 'opportunity_priority', 'integer', 'f', 20, 'f', 'im_projects'
        ) into v_dynfield_attribute_id ;

        RAISE NOTICE 'intranet-crm-opportunities-create.sql: Created Dynfield ''Priority'' -  v_dynfield_attribute_id: %',v_dynfield_attribute_id;

        begin
                alter table im_projects add column opportunity_priority_id integer;
        exception when others then
                raise notice 'intranet-crm-opportunities-create.sql: Could not create column ''opportunity_priority_id'', it might exist already ';
        end;

        -- Show only Dynfield only for sub type 'opportunity'
        update im_dynfield_type_attribute_map set display_mode = 'none' where attribute_id = v_dynfield_attribute_id and object_type_id <> 102;

        return 1;

end;$BODY$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- opportunity_sales_stage_id
create or replace function inline_0 ()
returns integer as $BODY$
declare
        v_dynfield_attribute_id           integer;
begin

	SELECT im_dynfield_attribute_new (
        'im_project', 'opportunity_sales_stage_id', 'Sales Stage', 'opportunity_sales_stage', 'integer', 't', 30, 'f', 'im_projects'
        ) into v_dynfield_attribute_id ;

        RAISE NOTICE 'intranet-crm-opportunities-create.sql: Created Dynfield ''Sales Stage'' -  v_dynfield_attribute_id: %',v_dynfield_attribute_id;

        begin
                alter table im_projects add column opportunity_sales_stage_id integer;
        exception when others then
                raise notice 'intranet-crm-opportunities-create.sql: Could not create column ''opportunity_sales_stage_id'', it might exist already ';
        end;

        -- Show only Dynfield only for sub type 'opportunity'
        update im_dynfield_type_attribute_map set display_mode = 'none' where attribute_id = v_dynfield_attribute_id and object_type_id <> 102;

        return 1;

end;$BODY$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- opportunity_campaign_id
create or replace function inline_0 ()
returns integer as $BODY$
declare
        v_dynfield_attribute_id           integer;
begin

	SELECT im_dynfield_attribute_new (
               'im_project', 'opportunity_campaign_id', 'Opportunity Campaign', 'opportunity_campaign', 'integer', 'f', 40, 'f', 'im_projects'
	) into v_dynfield_attribute_id;

        RAISE NOTICE 'intranet-crm-opportunities-create.sql: Created Dynfield ''Opportunity Campaign'' -  v_dynfield_attribute_id: %',v_dynfield_attribute_id;

        begin
                alter table im_projects add column opportunity_campaign_id integer;
        exception when others then
                raise notice 'intranet-crm-opportunities-create.sql: Could not create column ''opportunity_campaign_id'', it might exist already ';
        end;

	-- Show only Dynfield only for sub type 'opportunity' 
	update im_dynfield_type_attribute_map set display_mode = 'none' where attribute_id = v_dynfield_attribute_id and object_type_id <> 102;

        return 1;

end;$BODY$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();

