-- upgrade-5.0.0.0.0-5.0.0.0.1.sql
SELECT acs_log__debug('/packages/intranet-crm-opportunities/sql/postgresql/upgrade/upgrade-5.0.0.0.0-5.0.0.0.1.sql','');

-- Create new parent category 
SELECT im_category_new(84009, 'Open', 'Intranet Opportunity Sales Stage');
SELECT im_category_hierarchy_new (84010, 84009);
SELECT im_category_hierarchy_new (84011, 84009);
SELECT im_category_hierarchy_new (84012, 84009);
SELECT im_category_hierarchy_new (84013, 84009);
SELECT im_category_hierarchy_new (84014, 84009);
SELECT im_category_hierarchy_new (84015, 84009);
SELECT im_category_hierarchy_new (84016, 84009);
SELECT im_category_hierarchy_new (84017, 84009);

-- Create Project makes no sense for closed opportunities 
update im_view_columns set column_render_tcl = '$project_link' where column_id = 98110; 
