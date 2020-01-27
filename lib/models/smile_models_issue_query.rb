# Smile - add methods to the IssueQuery model

# ###############
# 1/ module Tools

#require 'active_support/concern' #Rails 3

module Smile
  module Models
    module IssueQueryOverride
      ##########
      # 1/ Tools
      module Tools
        # extend ActiveSupport::Concern

        def self.prepended(base)
          #####################
          # 1) Instance methods
          tools_instance_methods = [
            :available_filters_hook,                          # 1/  New method  RM V4.0.0 OK
          ]

          trace_prefix = "#{' ' * (base.name.length + 22)}  --->  "
          last_postfix = '< (SM::MO::IssueQueryOverride::Tools)'

          smile_instance_methods = base.instance_methods.select{|m|
              base.instance_method(m).owner == self
            }

          smile_instance_methods += base.private_instance_methods.select{|m|
              base.instance_method(m).owner == self
            }

          missing_instance_methods = tools_instance_methods.select{|m|
            !smile_instance_methods.include?(m)
          }

          if missing_instance_methods.any?
            trace_first_prefix = "#{base.name} MISS       instance_methods  "
          else
            trace_first_prefix = "#{base.name}            instance_methods  "
          end

          SmileTools::trace_by_line(
            (
              missing_instance_methods.any? ?
              missing_instance_methods :
              smile_instance_methods
            ),
            trace_first_prefix,
            trace_prefix,
            last_postfix
          )

          if missing_instance_methods.any?
            raise trace_first_prefix + missing_instance_methods.join(', ') + '  ' + last_postfix
          end
     end

        # 1/ EXTENDED, RM 4.0.0 OK
        # Smile specific : new hook
        def available_filters_hook
          nil
        end
      end # module Tools
   end # module IssueQueryOverride
  end # module Models
end # module Smile
