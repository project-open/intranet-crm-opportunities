SELECT acs_log__debug('/packages/intranet-crm-opportunities/sql/postgresql/upgrade/upgrade-5.0.4.0.0-5.0.4.0.1.sql','');

update im_component_plugins
set enabled_p = 'f'
where plugin_name = 'Opportunity Pipeline';
