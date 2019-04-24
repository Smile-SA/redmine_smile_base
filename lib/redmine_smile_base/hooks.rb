# This module name must be unique, if not the last Hooks class will be taken in account
module RedmineSmileBasePlugin
  class Hooks < Redmine::Hook::ViewListener
    # This just renders the partial in
    # app/views/hooks/my_plugin/_view_projects_show_sidebar_bottom.html.erb
    # The contents of the context hash is made available as local variables to the partial.
    #
    # Additional context fields
    #   :issue  => the issue this is edited
    #   :f      => the form object to create additional fields

    render_on :view_projects_show_sidebar_bottom,
              :partial => "hooks/redmine_smile_base/view_projects_show_sidebar_bottom_conversion_in_days"
  end
end
