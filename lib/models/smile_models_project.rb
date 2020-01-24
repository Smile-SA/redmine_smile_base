# Smile - add methods to the Project model
#

# 1/ module NewScopes
# * #156114 Projects admin, show issues count
#   2018-11

#require 'active_support/concern' #Rails 3

module Smile
  module Models
    module ProjectOverride
      #************
      # 6/ NewScopes
      module NewScopes
        # extend ActiveSupport::Concern

        def self.prepended(base)
          trace_prefix       = "#{' ' * (base.name.length + 25)}  --->  "
          last_postfix       = '< (SM::MO::ProjectOverride::NewScopes::CMeths)'

          ###########
          # 1) Scopes
          # Smile specific #156114 Projects admin, show issues count
          SmileTools.trace_override "#{base.name}                          scope  having_parent " + last_postfix,
            :redmine_smile_base

          base.instance_eval do
            scope :having_parent, lambda { |parent_name, including_itself=false|
              parent = Project.find_by_name(parent_name)
              if parent
                operator_equal = (including_itself ? '=' : '')
                where("lft >#{operator_equal} ?", parent.lft).where("rgt <#{operator_equal} ?", parent.rgt)
              else
                none
              end
            }
          end
        end # def self.prepended
      end # module NewScopes
    end # module ProjectOverride
  end # module Models
end # module Smile
