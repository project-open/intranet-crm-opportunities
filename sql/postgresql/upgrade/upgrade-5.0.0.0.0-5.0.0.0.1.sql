-- upgrade-5.0.0.0.0-5.0.0.0.1.sql
SELECT acs_log__debug('/packages/intranet-crm-opportunities/sql/postgresql/upgrade/upgrade-5.0.0.0.0-5.0.0.0.1.sql','');

-- Create Project makes no sense for closed opportunities 
update im_view_columns set column_render_tcl = '$project_link' where column_id = 98110; 
