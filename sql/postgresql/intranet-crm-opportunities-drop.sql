-- /packages/intranet-crm-opportunities/sql/postgresql/intranet-crm-opportunities-drop.sql
--
-- Copyright (c) 2003-now ]project-open[
--
-- All rights reserved. Please check
-- http://www.project-open.com/license/ for details.
--
-- @author klaus.hofeditz@project-open.com



-----------------------------------------------------------

-- Delete menus, portlets and views
select im_menu__del_module('intranet-crm-opportunities');
select im_component_plugin__del_module('intranet-crm-opportunities');

delete from im_view_columns where view_id = 980;
delete from im_views where view_id = 980;




-- Fix function
create or replace function im_dynfield_widget__delete (integer) returns integer as '
DECLARE
	p_widget_id		alias for $1;
BEGIN
	-- Erase the im_dynfield_widgets item associated with the id
	delete from im_dynfield_widgets
	where widget_id = p_widget_id;

	-- Erase all the permissions
	delete from acs_permissions
	where object_id = p_widget_id;

	PERFORM acs_object__delete(p_widget_id);
	return 0;
end;' language 'plpgsql';


-- Delete Dynfields - first from the metadata and then from the DB
create or replace function inline_0 ()
returns integer as $body$
declare
	v_count integer;
	v_attribute_id integer;
	v_dynfield_attribute_id integer;
	row record;
	v_sql varchar;
begin
	FOR row IN
		select	*
		from	user_tab_columns
		where	lower(column_name) in (
				'presales_value_currency', 'opportunity_priority_id', 
				'opportunity_sales_stage_id', 'opportunity_campaign_id'
			)
	LOOP
		select attribute_id into v_dynfield_attribute_id
		from im_dynfield_attributes where acs_attribute_id = (
			select attribute_id from acs_attributes where lower(attribute_name) = lower(row.column_name)
		);

		perform im_dynfield_attribute__del(v_dynfield_attribute_id);
		v_sql := 'alter table im_projects drop column ' || row.column_name;
		execute v_sql;
	END LOOP;

	FOR row IN
		select	*
		from	im_dynfield_widgets
		where	widget_name in ('opportunity_sales_stage', 'opportunity_priority', 'opportunity_campaign')
	LOOP
		perform im_dynfield_widget__delete(row.widget_id);
	END LOOP;
	return 0;
end;$body$ language 'plpgsql';
select inline_0 ();
drop function inline_0 ();


-- Delete Categories
delete from im_category_hierarchy where child_id in (
	select category_id from im_categories where category_type = 'Intranet Opportunity Priority'
);

delete from im_category_hierarchy where child_id in (
	select category_id from im_categories where category_type = 'Intranet Opportunity Sales Stage'
);

delete from im_categories where category_type = 'Intranet Opportunity Priority';
delete from im_categories where category_type = 'Intranet Opportunity Sales Stage';

