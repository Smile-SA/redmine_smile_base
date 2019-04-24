# Smile - queries_helper enhancement

# module Smile::Helpers::QueriesOverride
# - 1/ module ::Hooks

module Smile
  module Helpers
    module QueriesOverride
      #*********
      # 1/ Hooks
      module Hooks
        def self.prepended(base)
          query_columns_and_bar_instance_methods = [
            # module_eval
            :column_content,                         #  1/ REWRITTEN   RM 4.0.0 OK
            :column_value,                           #  2/ REWRITTEN   RM 4.0.0 OK
            :csv_content,                            #  3/ REWRITTEN   RM 4.0.0 OK
            :csv_value,                              #  4/ REWRITTEN   RM 4.0.0 OK

            :column_value_hook,                      #  10/ new method RM 4.0.0 OK
            :csv_value_hook,                         #  11/ new method RM 4.0.0 OK
          ]


          # Methods dynamically added to QueriesHelper, source replaced by module_eval
          # Because we can't use normal methods override
          # => no access to super
          # 2012-01-18 no way to include a module in a module (like InstanceMethods)
          # QueryController
          #  -> has a dynamic module (accessible QueryController.with master_helper_module)
          #     -> includes all Controller helpers :
          #        including QueriesHelper
          #          -> includes modules included in the helpers
          #          -> Pb. 1 : includes the sub modules in the dynamic module => duplication !
          #             - methods already present in QueriesHelper -- OK
          #             - Pb. 2 : new methods in the modules included -- NON-OK
          base.module_eval do # <<READER, __FILE__, (__LINE__ + 1) #does not work
            # 1/ REWRITTEN, RM 4.0.0 OK
            # Smile specific : separator ', ' -> '<br/>'
            # Smile specific : new param : options
            #
            # To display a column value in the issues tables
            # Smile specific #134828 New issues list columns (Array, IssueRelations, Watchers)
            # Smile specific #222040 Liste des entrées de temps : dé-sérialisation colonne Demande et filtres
            # Smile specific #238910 Liste des demandes : conversion jours comme dans le rapport
            def column_content(column, item, options={})
              # Smile comment : call to value_object instead of value to avoid cast_value for QueryCustomField columns

              #-----------------------------
              # Smile specific : debug trace
              debug         = options.has_key?( :debug )         ? options[:debug]         : false
              logger.debug " =>prof shq   column_content  [#{column.name}] #{item.class.name} id:#{item.id} column.value_object" if debug == '3'
              # END -- Smile specific : debug trace
              #------------------------------------

              value = column.value_object(item)

              #---------------
              # Smile specific : debug trace
              logger.debug " =>prof shq   column_content value found" if debug == '3'

              # Smile specific : is_a?(Array) -> respond_to? each
              if value.respond_to?(:each)
                ################
                # Smile specific Evolution #134828 New issues list columns (Array, IssueRelations, Watchers)
                # Smile specific : column_value added options param
                values = value.collect {|v| column_value(column, item, v, options)}.compact
                # Smile specific : ', ' -> '<br/>'
                safe_join(values, '<br/>'.html_safe)
              else
                ################
                # Smile specific #238910 Liste des demandes : conversion jours comme dans le rapport
                # Smile specific : column_value added options param
                column_value(column, item, value, options)
              end
            end

            # 2/ OVERRIDEN totally rewritten, RM 4.0.0 OK
            # Smile specific : new options array
            # Smile specific : hook call inserted
            # Smile comment : to display a COLUMN VALUE in the tables
            def column_value(column, item, value, options={})
              #####################################################
              # Smile specific #994 Budget and Remaining management
              debug         = options.has_key?(:debug)         ? options[:debug]         : false

              # Smile specific : method to override to get specific behaviour
              hook_result = column_value_hook(column, item, value, options)

              unless hook_result.nil?
                return hook_result
              end

              logger.debug " =>prof shq     column_value              #{item.class.name}##{item.id}  [#{column.name}]" if debug == '2' || debug == '3'
              # END -- Smile specific 994 Budget and Remaining management
              ###########################################################

              # UPSTREAM CODE
              case column.name
              when :id
                link_to value, issue_path(item)
              when :subject
                link_to value, issue_path(item)
              when :parent
                value ? (value.visible? ? link_to_issue(value, :subject => false) : "##{value.id}") : ''
              when :description
                item.description? ? content_tag('div', textilizable(item, :description), :class => "wiki") : ''
              when :last_notes
                item.last_notes.present? ? content_tag('div', textilizable(item, :last_notes), :class => "wiki") : ''
              when :done_ratio
                progress_bar(value)
              when :relations
                content_tag('span',
                  value.to_s(item) {|other| link_to_issue(other, :subject => false, :tracker => false)}.html_safe,
                  :class => value.css_classes_for(item))
              when :hours, :estimated_hours
                format_hours(value)
              when :spent_hours
                link_to_if(value > 0, format_hours(value), project_time_entries_path(item.project, :issue_id => "#{item.id}"))
              when :total_spent_hours
                link_to_if(value > 0, format_hours(value), project_time_entries_path(item.project, :issue_id => "~#{item.id}"))
              when :attachments
                # Smile specific : test on is array,
                # because in column_content is_a?(Array) -> respond_to? each
                if value.is_a?(Array)
                  value.to_a.map {|a| format_object(a)}.join(" ").html_safe
                else
                  format_object(value).html_safe
                end
              else
                format_object(value, true, options)
              end
            end # def column_value

            # 3/ REWRITTEN, RM 4.0.0 OK
            # Smile specific : new options array
            def csv_content(column, item, options={})
              value = column.value_object(item)
              if value.is_a?(Array)
                # Smile specific : params added, options
                value.collect {|v| csv_value(column, item, v, options)}.compact.join(', ')
              else
                # Smile specific : params added, options
                csv_value(column, item, value, options)
              end
            end

            # 4/ REWRITTEN, RM 4.0.0 OK
            # Smile specific : new options array
            # Smile specific : hook call inserted
            def csv_value(column, object, value, options={})
              #####################################################
              # Smile specific #994 Budget and Remaining management
              debug         = options.has_key?(:debug)         ? options[:debug]         : false

              # Smile specific : method to override to get specific behaviour
              hook_result = csv_value_hook(column, object, value, options)

              unless hook_result.nil?
                return hook_result
              end

              logger.debug " =>prof shq     csv_value             #{object.class.name}##{object.id} #{column.name}" if debug == '2'
              # END -- Smile specific 994 Budget and Remaining management
              ###########################################################

              # UPSTREAM CODE
              case column.name
              when :attachments
                value.to_a.map {|a| a.filename}.join("\n")
              else
                format_object(value, false) do |value|
                  case value.class.name
                  when 'Float'
                    sprintf("%.2f", value).gsub('.', l(:general_csv_decimal_separator))
                  when 'IssueRelation'
                    value.to_s(object)
                  when 'Issue'
                    if object.is_a?(TimeEntry)
                      "#{value.tracker} ##{value.id}: #{value.subject}"
                    else
                      value.id
                    end
                  else
                    value
                  end
                end
              end
            end

            # 10/ new method, RM 4.0.0 OK
            # Smile specific : method to override in other plugin to have specific behaviour
            def column_value_hook(column, item, value, options={})
              nil
            end

            # 11/ new method, RM 4.0.0 OK
            # Smile specific : method to override in other plugin to have specific behaviour
            def csv_value_hook(column, object, value, options={})
              nil
            end
          end # base.module_eval do


          trace_prefix       = "#{' ' * (base.name.length + 19)}  --->  "
          last_postfix       = '< (SM::HO::QueriesOverride::Hooks)'

          smile_instance_methods = (base.instance_methods + base.protected_instance_methods).select{|m|
              query_columns_and_bar_instance_methods.include?(m) &&
                base.instance_method(m).source_location.first =~ SmileTools.regex_path_in_plugin('lib/helpers/smile_helpers_queries', :redmine_smile_base)
            }

          missing_instance_methods = query_columns_and_bar_instance_methods.select{|m|
            !smile_instance_methods.include?(m)
          }

          if missing_instance_methods.any?
            trace_first_prefix = "#{base.name} MISS    instance_methods  "
          else
            trace_first_prefix = "#{base.name}         instance_methods  "
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
    end # module QueriesOverride
  end # module Helpers
end # module Smile
