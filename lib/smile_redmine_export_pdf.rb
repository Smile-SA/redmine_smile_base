# Smile - add methods to the Redmine::Export::PDF class
#
# 1/ module PDFOverride
# - #134828 (Array, IssueRelations, Watchers)
#   watchers (Array)
#
# - #256456 Sauvegarder la case à cocher "Include sub-tasks time"
#   fetch_row_values :
#   - value with children
#   - manage Array case (but NOT custom_field)

module Smile
  module RedmineOverride
    module ExportOverride
      module PDFOverride
        module IssuesPdfHelperOverride
          #*******************
          # 1/ ExtendedQueries
          module ExtendedQueries
            def self.prepended(base)
              extended_queries_instance_methods = [
                :fetch_row_values,      # 1/ REWRITTEN   TO TEST
                :fetch_row_values_hook, # 2/ new method  TO TEST
              ]

              # Methods dynamically added to the Helper module
              base.module_eval do
                # 1/ REWRITTEN, RM 4.0.0 OK
                # Smile specific : hook added
                # Smile specific #134828 (Array, IssueRelations, Watchers)
                # Smile specific #256456 Sauvegarder la case à cocher "Include sub-tasks time"
                #
                # fetch row values
                def fetch_row_values(issue, query, level)
                  query.inline_columns.collect do |column|
                    s = if column.is_a?(QueryCustomFieldColumn)
                      cv = issue.visible_custom_field_values.detect {|v| v.custom_field_id == column.custom_field.id}
                      show_value(cv, false)
                    else
                      value = issue.send(column.name)

                      ################
                      # Smile specific : new hook
                      value_hook = fetch_row_values_hook(issue, column, query, value)

                      if value_hook
                        value = value_hook
                      else
                        ################
                        # Smile specific #256456 Sauvegarder la case à cocher "Include sub-tasks time"
                        if query.respond_to?('with_children') && query.with_children
                          case column.name
                          when :estimated_hours
                            value = issue.total_estimated_hours
                          when :spent_hours
                            value = issue.total_spent_hours
                          end
                        end
                        # END -- Smile specific #256456 Sauvegarder la case à cocher "Include sub-tasks time"
                        #######################

                        ###############
                        # Smile comment : NATIVE code
                        case column.name
                        when :subject
                          value = "  " * level + value
                        when :attachments
                          value = value.to_a.map {|a| a.filename}.join("\n")
                        end
                        if value.is_a?(Date)
                          # Smile specific : +value =
                          value = format_date(value)
                        elsif value.is_a?(Time)
                          # Smile specific : +value =
                          value = format_time(value)
                        elsif value.is_a?(Float)
                          # Smile specific : +value =
                          value = sprintf("%.2f", value)
                        ################
                        # Smile specific #134828 (Array, IssueRelations, Watchers)
                        # Smile specific, manage Array case (but NOT custom_field)
                        elsif value.respond_to?(:each)
                          # Smile specific : +value =
                          value = value.each.collect{|v|
                            if v.is_a?(IssueRelation)
                              v.to_s(issue, false, false)
                            else
                              v.to_s
                            end
                          }.join(', ')
                          # END -- Smile specific, manage Array case (but NOT custom_field)
                        #######################
                        end
                      end

                      value
                    end
                    s.to_s
                  end
                end # def fetch_row_values(issue, query, level)

                # 2/ New method, RM 4.0.0 OK
                def fetch_row_values_hook(column, query, value)
                  # Not changing the value here : nothing here
                  nil
                end
              end


              base_name = 'RM::E:P::IssuesPdfHr'
              trace_prefix       = "#{' ' * (base_name.length + 12)}  --->  "
              last_postfix       = '< (SM::RedmineOverride::ExportOverride::PDFOverride::IssuesPdfHelperOverride::ExtendedQueries)'

              smile_instance_methods = (base.instance_methods + base.protected_instance_methods).select{|m|
                  extended_queries_instance_methods.include?(m) &&
                    base.instance_method(m).source_location.first =~ SmileTools.regex_path_in_plugin('lib/smile_redmine_export_pdf', :redmine_smile_base)
                }

              missing_instance_methods = extended_queries_instance_methods.select{|m|
                !smile_instance_methods.include?(m)
              }

              if missing_instance_methods.any?
                trace_first_prefix = "#{base_name} MISS  instance_methods  "
              else
                trace_first_prefix = "#{base_name}  instance_methods  "
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
          end # module ExtendedQueries
        end # module IssuesPdfHelperOverride
      end # module PDFOverride
    end # module ExportOverride
  end # module RedmineOverride
end # module Smile
