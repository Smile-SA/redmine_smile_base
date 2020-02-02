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
            :debug,                   #  1/  new method
            :debug=,                  #  2/  new method
            :set_debug,               #  3/  new method

            :has_column_or_default?,  # 10/  new method
            :joins_additionnal,       # 11/  new method
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


          ##################
          # 2/ Class methods
          enhancements_class_methods = [
            :query_available_inline_columns_options_hook,          # 13/ EXTENDED PLUGIN  RM 4.0.0 OK  BAR
            :query_selected_inline_columns_options_hook,           # 14/ EXTENDED PLUGIN  RM 4.0.0 OK  BAR
          ]

          base.singleton_class.prepend ClassMethods

          last_postfix = '< (SM::MO::QueryOverride::Tools::CMeths)'

          smile_class_methods = base.methods.select{|m|
              base.method(m).owner == ClassMethods
            }

          missing_class_methods = enhancements_class_methods.select{|m|
            !smile_class_methods.include?(m)
          }

          if missing_class_methods.any?
            trace_first_prefix = "#{base.name} MISS                     methods  "
          else
            trace_first_prefix = "#{base.name}                          methods  "
          end

          SmileTools::trace_by_line(
            (
              missing_class_methods.any? ?
              missing_class_methods :
              smile_class_methods
            ),
            trace_first_prefix,
            trace_prefix,
            last_postfix
          )

          if missing_class_methods.any?
            raise trace_first_prefix + missing_class_methods.join(', ') + '  ' + last_postfix
          end
        end # def self.prepended


        # 1/ new method
        def debug
          return @debug if defined?(@debug)

          @debug = options[:debug_enabled]
        end

        # 2/ new method
        def debug=(arg)
          options[:debug_enabled] = (arg.present? ? arg : nil)
          @debug = options[:debug_enabled]
        end

        # 3/ new method
        def set_debug(debug_value)
          @debug = debug_value
        end

        # 10/ new method
        # Smile specific #329468 Query : missing preloads if only default columns
        # Smile comment : return a boolean
        def has_column_or_default?(column_name)
          if has_default_columns?
            return default_columns_names.include?(column_name)
          else
            return ( has_column?(column_name) ? true : false)
          end
        end

        # 11/ new method, RM 4.0.0 OK
        # Smile comment : method to extend to add additionnal joins
        def joins_additionnal(order_options)
          []
        end

        module ClassMethods
          # 14/ New method, RM 4.0.3 OK
          # Smile specific #245965 Rapport : critères, indication type champ personnalisé
          def query_available_inline_columns_options_hook(query, column)
            [nil, nil]
          end

          # 15/ New method, RM 4.0.0 OK
          # Smile specific #245965 Rapport : critères, indication type champ personnalisé
          def query_selected_inline_columns_options_hook(query, column)
            nil
          end
        end # module ClassMethods
      end # module Tools
    end # module QueryOverride
  end # module Models
end # module Smile
