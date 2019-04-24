# Smile - application_helper enhancement
# module Smile::Helpers::ApplicationOverride
#
# * 1/ module ::Hooks
#      * format_object
#      * format_object_hook

module Smile
  module Helpers
    module ApplicationOverride
      ##########
      # 1/ Hooks
      module Hooks
        def self.prepended(base)
          hooks_instance_methods = [
            # module_eval
            :format_object,             # 1/   OVERRIDEN rewritten V4.0.0 OK

            :format_object_hook,        # 20/  OVERRIDEN PLUGIN V4.0.0 OK SMILE
          ]

          # Smile comment : module_eval mandatory with helpers, but no more access to rewritten methods
          # Smile comment : => use of alias method to access to ancestor version
          base.module_eval do
            # 4/ REWRITTEN, RM 4.0.0 OK
            # * Options param added
            #
            #
            # Helper that formats object for html or text rendering
            def format_object(object, html=true, options={}, &block)
              # UPSTREAM code
              if block_given?
                object = yield object
              end

              #####################################################
              # Smile specific #994 Budget and Remaining management
              # Smile specific : insert the hook method call
              debug         = options.has_key?( :debug )        ? options[:debug]        : false
              links         = options.has_key?( :links )        ? options[:links]        : true
              no_stringify  = options.has_key?( :no_stringify ) ? options[:no_stringify] : false

              hook_result = format_object_hook(object, html, options)
              unless hook_result.nil?
                return hook_result
              end
              # END -- Smile specific #994 Budget and Remaining management
              ############################################################

              case object.class.name
              when 'Array'
                formatted_objects = object.map {|o| format_object(o, html)}
                html ? safe_join(formatted_objects, ', ') : formatted_objects.join(', ')
              when 'Time'
                format_time(object)
              when 'Date'
                format_date(object)
              when 'Fixnum'
                object.to_s
              when 'Float'
                sprintf "%.2f", object
              when 'User'
                html ? link_to_user(object) : object.to_s
              when 'Project'
                html ? link_to_project(object) : object.to_s
              when 'Version'
                html ? link_to_version(object) : object.to_s
              when 'TrueClass'
                l(:general_text_Yes)
              when 'FalseClass'
                l(:general_text_No)
              when 'Issue'
                object.visible? && html ? link_to_issue(object) : "##{object.id}"
              when 'Attachment'
                html ? link_to_attachment(object) : object.filename
              when 'CustomValue', 'CustomFieldValue'
                if object.custom_field
                  f = object.custom_field.format.formatted_custom_value(self, object, html)
                  if f.nil? || f.is_a?(String)
                    f
                  else
                    format_object(f, html, &block)
                  end
                else
                  object.value.to_s
                end
              else
                ######################################
                # Smile specific : no_stringify option
                if no_stringify
                  object
                else
                  html ? h(object) : object.to_s
                end
              end
            end

            # 20/  OVERRIDEN PLUGIN V4.0.0 OK SMILE
            def format_object_hook(object, html=true, options={})
              nil
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
