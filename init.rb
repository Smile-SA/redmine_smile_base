# encoding: UTF-8

require 'redmine'

###################
# 1/ Initialisation
Rails.logger.info 'o=>'
Rails.logger.info 'o=>Starting Redmine Smile Base plugin for Redmine'
Rails.logger.info "o=>Application user : #{ENV['USER']}"


plugin_name = :redmine_smile_base
plugin_root = File.dirname(__FILE__)


# lib/not_reloaded
require plugin_root + '/lib/not_reloaded/smile_tools'


Redmine::Plugin.register plugin_name do
  ########################
  # 2/ Plugin informations
  name 'Redmine - Smile - Base'
  author 'Jérôme BATAILLE'
  author_url "mailto:Jerome BATAILLE <redmine-support@smile.fr>?subject=#{plugin_name}"
  description 'Adds Common Tools needed by Smile Redmine plugins'
  url "https://github.com/Smile-SA/#{plugin_name}"
  version '1.0.2'
  requires_redmine :version_or_higher => '2.3.2'

  #######################
  # 2.1/ Plugin home page
  settings :default => HashWithIndifferentAccess.new(
    ),
    :partial => "settings/#{plugin_name}"

end # Redmine::Plugin.register ...


#################################
# 3/ Plugin internal informations
# To keep after plugin register
this_plugin = Redmine::Plugin::find(plugin_name.to_s)
plugin_version = '?.?'
# Root relative to application root
plugin_rel_root = '.'
plugin_id = 0
if this_plugin
  plugin_version  = this_plugin.version
  plugin_id       = this_plugin.__id__
  plugin_rel_root = 'plugins/' + this_plugin.id.to_s
end


def prepend_in(dest, mixin_module)
  return if dest.include? mixin_module

  # Rails.logger.info "o=>#{dest}.prepend #{mixin_module}"
  dest.send(:prepend, mixin_module)
end


###############
# 4/ Dispatcher
if Rails::VERSION::MAJOR < 3
  require 'dispatcher'
  rails_dispatcher = Dispatcher
else
  rails_dispatcher = Rails.configuration
end

###############
# 5/ to_prepare
# Executed after Rails initialization
rails_dispatcher.to_prepare do
  Rails.logger.info "o=>"
  Rails.logger.info "o=>\\__ #{plugin_name} V#{plugin_version}"

  SmileTools.reset_override_count(plugin_name)

  SmileTools.trace_override "                                plugin  #{plugin_name} V#{plugin_version}",
    true,
    :redmine_smile_base


  #########################################
  # 5.1/ List of files required dynamically
  # Manage dependencies
  # To put here if we want recent source files reloaded
  # Outside of to_prepare, file changed => reloaded,
  # but with primary loaded source code
  required = [
    # lib/
    "/lib/#{plugin_name}/hooks",
    '/lib/smile_redmine_i18n',

    # lib/controllers

    # lib/helpers
    '/lib/helpers/smile_helpers_queries',
    '/lib/helpers/smile_helpers_application',

    # lib/models
    '/lib/models/smile_models_query',
    '/lib/models/smile_models_issue',
  ]

  if Rails.env == "development"
    ###########################
    # 5.2/ Dynamic requirements
    Rails.logger.debug "o=>require_dependency"
    required.each{ |d|
      # Reloaded each time modified
      Rails.logger.debug "o=>  #{plugin_rel_root + d}"
      require_dependency plugin_root + d
    }
    required = nil

    # Folders whose contents should be reloaded, NOT including sub-folders

    autoload_plugin_paths = ['/lib/controllers', '/lib/helpers', '/lib/models']

    Rails.logger.debug 'o=>'
    Rails.logger.debug "o=>autoload_paths / watchable_dirs +="
    autoload_plugin_paths.each{|p|
      new_path = plugin_root + p
      Rails.logger.debug "o=>  #{plugin_rel_root + p}"
      ActiveSupport::Dependencies.autoload_paths << new_path
      rails_dispatcher.watchable_dirs[new_path] = [:rb]
    }
  else
    ##########################
    # 5.3/ Static requirements
    Rails.logger.debug "o=>require"
    required.each{ |p|
      # Never reloaded
      Rails.logger.debug "o=>  #{plugin_rel_root + p}"
      require plugin_root + p
    }
  end
  # END -- Manage dependencies


  ##############
  # 6/ Overrides

  #***************************
  # **** 6.0/ Libs ****
  Rails.logger.info "o=>----- LIBS"

  prepend_in(Redmine::I18n, Smile::RedmineOverride::I18nOverride::Enhancements)

  # Sub-module still there if reloading
  # => Re-prepend each time
  ApplicationHelper.send(:prepend, Smile::Helpers::ApplicationOverride::Hooks)

  prepend_in(QueriesHelper, Smile::Helpers::QueriesOverride::Hooks)


  #***************************
  # **** 6.1/ Controllers ****
  #Rails.logger.info "o=>----- CONTROLLERS"


  #***********************
  # **** 6.2/ Helpers ****
  #Rails.logger.info "o=>----- HELPERS"

  #**********************
  # **** 6.3/ Models ****
  Rails.logger.info "o=>----- MODELS"

  prepend_in(Issue, Smile::Models::IssueOverride::Tools)

  prepend_in(Query, Smile::Models::QueryOverride::Tools)


  # keep traces if classes / modules are reloaded
  SmileTools.enable_traces(false, plugin_name)

  Rails.logger.info 'o=>/--'
end
