# Smile - add methods to the Query model
#
# 1/ module Tools

#require 'active_support/concern' #Rails 3

module Smile
  module Models
    module QueryOverride
      #*********
      # 1/ Tools
      module Tools
        # extend ActiveSupport::Concern

        def self.prepended(base)
          #####################
          # 1/ Instance methods
          tools_instance_methods = [
            :has_column_or_default?,  # 1/  new method
            :debug,                   # 2/  new method
            :debug=,                  # 3/  new method
          ]

          trace_prefix = "#{' ' * (base.name.length + 27)}  --->  "
          last_postfix = '< (SM::MO::QueryOverride::Tools)'


          smile_instance_methods = base.public_instance_methods.select{|m|
              base.instance_method(m).owner == self
            }
          smile_instance_methods += base.protected_instance_methods.select{|m|
              base.instance_method(m).owner == self
            }

          smile_instance_methods += base.private_instance_methods.select{|m|
              base.instance_method(m).owner == self
            }

          missing_instance_methods = tools_instance_methods.select{|m|
            !smile_instance_methods.include?(m)
          }

          if missing_instance_methods.any?
            trace_first_prefix = "#{base.name} MISS            instance_methods  "
          else
            trace_first_prefix = "#{base.name}                 instance_methods  "
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

        # 1/ new method
        # Smile specific #329468 Query : missing preloads if only default columns
        # Smile comment : return a boolean
        def has_column_or_default?(column_name)
          if has_default_columns?
            return default_columns_names.include?(column_name)
          else
            return ( has_column?(column_name) ? true : false)
          end
        end

        # 2/ new method
        def debug
          options[:debug_enabled]
        end

        # 3/ new method
        def debug=(arg)
          options[:debug_enabled] = (arg.present? ? arg : nil)
        end
      end # module Tools
    end # module QueryOverride
  end # module Models
end # module Smile
