# Smile - application_helper enhancement
# module Smile::Helpers::ApplicationOverride
#
# * 1/ module ::Hooks
#      * param_hours_by_day_to_instance_var

module Smile
  module Helpers
    module ApplicationOverride
      ##########
      # 1/ Hooks
      module Hooks
        def self.prepended(base)
          hooks_instance_methods = [
            # module_eval
            :param_hours_by_day_to_instance_var, #  1/  new method       V4.0.0 OK
          ]

          # Smile comment : module_eval mandatory with helpers, but no more access to rewritten methods
          # Smile comment : => use of alias method to access to ancestor version
          base.module_eval do
            # 1/ new method, RM 4.0.0 OK  SMILE
            def param_hours_by_day_to_instance_var
               return unless params[:hours_by_day].present?

               hours_by_day = params[:hours_by_day].to_f
               @hours_by_day = hours_by_day if hours_by_day != 0.0
            end
          end # base.module_eval do

          smile_instance_methods = base.instance_methods.select{|m|
              hooks_instance_methods.include?(m) &&
                base.instance_method(m).source_location.first =~ SmileTools.regex_path_in_plugin('lib/helpers/smile_helpers_application', :redmine_smile_base)
            }

          missing_instance_methods = hooks_instance_methods.select{|m|
            !smile_instance_methods.include?(m)
          }

          trace_prefix         = "#{' ' * (base.name.length + 15)}  --->  "
          module_name          = 'SM::HO::AppOverride::Hooks'
          last_postfix         = "< (#{module_name})"

          if missing_instance_methods.any?
            trace_first_prefix = "#{base.name} MIS instance_methods  "
          else
            trace_first_prefix = "#{base.name}     instance_methods  "
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
      end # module Hooks
    end # module ApplicationOverride
  end # module Helpers
end # module Smile
