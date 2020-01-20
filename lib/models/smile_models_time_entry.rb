# Smile - add methods to the Time entry model

# 2/ module AssignableUsers
#    #788748: V4.0.0 : Demande, problème de performance sur l'affichage

#require 'active_support/concern' #Rails 3


module Smile
  module Models
    module TimeEntryOverride
      #*******************
      # 2/ AssignableUsers
      module AssignableUsers
        # extend ActiveSupport::Concern

        def self.prepended(base)
          assignable_users_instance_methods = [
            :assignable_users,  # 1/ REWRITTEN   V4.0.0 OK
          ]


          trace_prefix = "#{' ' * (base.name.length + 23)}  --->  "
          last_postfix = '< (SM::MO::TimeEntryOverride::AssignableUsers)'

          smile_instance_methods = base.instance_methods.select{|m|
              base.instance_method(m).owner == self
            }

          missing_instance_methods = assignable_users_instance_methods.select{|m|
            !smile_instance_methods.include?(m)
          }

          if missing_instance_methods.any?
            trace_first_prefix = "#{base.name} MISS        instance_methods  "
          else
            trace_first_prefix = "#{base.name}             instance_methods  "
          end

          SmileTools::trace_by_line(
            (
              missing_instance_methods.any? ?
              missing_instance_methods :
              smile_instance_methods
            ),
            trace_first_prefix,
            trace_prefix,
            last_postfix,
            :redmine_smile_base
          )

          if missing_instance_methods.any?
            raise trace_first_prefix + missing_instance_methods.join(', ') + '  ' + last_postfix
          end
        end # def self.prepended


        # 1/ REWRITTEN, RM 4.0.0 OK
        # Smile specific #788748: V4.0.0 : Demande, problème de performance sur l'affichage
        # New parameter added :
        # * debug
        def assignable_users(debug=nil)
          users = []
          if project
            #---------------
            # Smile specific : debug trace
            if debug
              start = Time.now
              logger.debug "\\=>prof     assignable_users"
            end

            ################
            # Smile specific #788748: V4.0.0 : Demande, problème de performance sur l'affichage
            # Smile comment : NATIVE code
            # users = project.members.active.preload(:user)
            users_ids = project.members.active.pluck(:user_id)
            #---------------
            # Smile specific : trace
            if debug
              logger.debug " =>prof       AFT users_ids -- #{format_duration(Time.now - start, true)}"
              start = Time.now
            end

            # Smile specific : added joins and where to load only project memberships
            # {:member_roles => :role}
            # Smile comment : NATIVE code
            # users = users.map(&:user).select{ |u| u.allowed_to?(:log_time, project) }
            users = User.where(
                :id => users_ids
              ).joins( # Smile specific
                :memberships
              ).includes( # Smile specific
                :memberships,
                {:memberships => :roles}
              ).where( # Smile specific
                {:members => { :project_id => project.id} }
                # Smile specific : allowed_to? + relay_roles_disabled, debug options
                # Smile specific : for relay role optional feature brought by another plugin
              ).select{ |u| u.allowed_to?(:log_time, project, {:relay_roles_disabled => true, :debug => debug}) }

            #---------------
            # Smile specific : trace
            if debug
              logger.debug "/=>prof     assignable_users AFT users -- #{format_duration(Time.now - start, true)}"
              start = Time.now
            end
          end
          users << User.current if User.current.logged? && !users.include?(User.current)
          users
        end
      end # module AssignableUsers
    end # module TimeEntryOverride
  end # module Models
end # module Smile
