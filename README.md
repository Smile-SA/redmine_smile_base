redmine_smile_base
==================

Redmine plugin that adds Common Tools needed by Smile Redmine pluginss

## How it works

* app/views
** hooks/redmine_smile_base/view_projects_show_sidebar_bottom_conversion_in_days
Add an input field to convert hours in days, to **enable in plugin settings**
** settings
The plugin settings page
* config/locales
new label : **label_hours_by_day** needed by hours by day conversion

* lib/helpers
** smile_helpers_application.rb
New method, **format_object_hook** to introduce behaviour that can be **overriden** in **format_object**
** smile_helpers_queries.rb
New method **column_value_hook** to introduce behaviour that can be **overriden** in **column_value**
New method **csv_value_hook** to introduce behaviour that can be **overriden** in **csv_value**
Overriden methods that also add a new **options** parameter :
*** column_content
*** column_value
*** csv_content
*** csv_value

* lib/models
** smile_models_issue.rb **Tool** module
Brings new methods to load Issue association an sub association :
*** **load_assoc**
*** **load_sub_assoc_of_assoc**
** smile_models_query.rb **Tool** module
Brings new methods :
*** **has_column_or_default?**
*** **debug**, **debug=**
Adds a debug flag in the query

* lib/not_reloaded/smile_tools.rb
Methods to traces **overrides made by Smile plugins**, overrides listed in plugin settings
** **trace_by_line**, **trace_override**, **regex_path_in_plugin**
Method to debug a scope : **debug_scope**

* lib/redmine_smile_base/hooks.rb
The hook **view_projects_show_sidebar_bottom** used to display the convert hours in days input

* lib/smile_redmine_i18n.rb
New methods :
** **l_time**
** **round_decimals**
** **format_date_by_directives**
** **format_date_time**
** **format_duration**
** **l_hours**
Manage negative hours
** **format_hours**
Allows hours to day conversion, and removes un-necessary 0 in decimals

New class methods :
** **format_duration**


Enjoy !
