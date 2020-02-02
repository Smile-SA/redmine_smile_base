redmine_smile_base
==================

Redmine plugin that adds Common Tools needed by Smile Redmine plugins

# What it brings

## app/views

### New hooks/redmine_smile_base

* view_projects_show_sidebar_bottom_conversion_in_days

  Add an input field to convert hours in days, to **enable in plugin settings**

* New settings/redmine_smile_base

  The plugin settings page, that shows overrides

### 🔑 **REWRITTEN** queries/_columns.html.erb

* New hook **view_queries_colums_after_columns_selected**
* Column List box : style min-width 295px

### 🔑 **REWRITTEN** issues/_attributes.html.erb

* Assignee list : added author

  **principals_options_for_select** : added param author

## config/locales

  New label : **label_hours_by_day** needed by hours by day conversion

## lib

### lib/helpers

* **smile_helpers_application.rb**

  * New helper method, **param_hours_by_day_to_instance_var** used in other plugins
  * New hook method **format_object_hook**, to be able to add overrides in plugins
  * 🔑 REWRITTEN method **principals_options_for_select**

    Added author param, to add Issue author in assignee list

* **smile_helpers_queries.rb**

  New method **column_value_hook** to introduce behaviour that can be **overriden** in **column_value**

  New method **csv_value_hook** to introduce behaviour that can be **overriden** in **csv_value**

  New method **filters_options_for_select_hook** to introduce behaviour that can be **overriden** in other plugins

  New Groups setup for **redmine_xtended_queries** plugin

  REWRITTEN methods that also add a new **options** parameter :

  * 🔑 REWRITTEN method **column_content**
  * 🔑 REWRITTEN method **column_value**
  * 🔑 REWRITTEN method **csv_content**
  * 🔑 REWRITTEN method **csv_value**

* **smile_helpers_timelog.rb**

  * 🔑 REWRITTEN method **user_collection_for_select_options**, added author, debug params

    To add Issue author in assignee list
    Param to pass in other plugins, **no view Rewritten for that** in this plugin

### lib/models

* **smile_models_issue.rb** module **Tools**

  Brings new methods to load Issue association an sub association :

  * New method **load_assoc**
  * New method **load_sub_assoc_of_assoc**

* **smile_models_query.rb** module **Tools**

  Brings new methods :

  * New method **debug**, **debug=**, **set_debug**
  * New method **has_column_or_default?**

    Adds a debug flag in the query

  * New method **joins_additionnal**

    To extend to add additionnal joins depending on query order and filters

  * New hook **Class** method **query_available_inline_columns_options_hook**
  * New hook **Class** method **query_selected_inline_columns_options_hook**

* **smile_models_time_entry.rb** module **AssignableUsers**

  Rewrites **assignable_users** to optimize it

* **smile_models_project.rb** module **NewScopes**

  + Project scope **having_parent**

* **smile_models_issue_query.rb** module **Tools**

  * New method **available_filters_hook** :

    Adds a hook to overide in client plugins

### lib/not_reloaded

* **smile_tools.rb**

  Methods to trace **overrides made by plugins**, overrides listed in plugin settings :

  * New method **trace_by_line**
  * New method **trace_override**
  * New method **regex_path_in_plugin**

  New method to debug a scope : **debug_scope**

### lib/redmine_smile_base

* **hooks.rb**

  The hook **view_projects_show_sidebar_bottom** used to display the convert hours in days input

  Input field used in **another Smile plugin**

### lib/smile_redmine_i18n.rb

  New methods :

* New method **l_time**
* New method **round_decimals**

  Rounds the decimals and hides zero decimals

* New method **format_date_by_directives**
* New method **format_date_time**

  Like format_date

* New method **format_duration**

  For example : **1.573s**

* 🔑 REWRITTEN method **l_hours**

  Manage **negative** hours

* 🔑 REWRITTEN method **format_hours**

  Allows **hours to day** conversion, and removes un-necessary 0 in decimals

  New **class** methods :

* New method **format_duration**

### lib/smile_redmine_export_pdf.rb

* 🔑 REWRITTEN method **fetch_row_values**

* New hook method **fetch_row_values_hook**

  * Allows **Array** values
  * Manages **with_children** option enabled by another Smile plugin

# Changelog

* **V1.0.8** New **query.joins_additionnal**

  To extend to add additionnal joins depending on query order and filters

* **V1.0.7** + New hooks : **available_filters_hook**, **query_{available/selected}_inline_columns_options_hook**
* **V1.0.6** + Project scope **having_parent**
* **V1.0.5** TimeEntry.assignable_user optimized
* **V1.0.4** new feature : Issue assignee / Time entry user : add author in list

  **roles_settable_hook** moved to **redmine_admin_enhancements** plugin

* **V1.0.3** new hooks : fetch_row_values_hook, filters_options_for_select_hook, format_object_hook


Enjoy !
