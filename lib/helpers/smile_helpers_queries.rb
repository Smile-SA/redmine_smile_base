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
            :column_content,                              #  1/ REWRITTEN   RM 4.0.0 OK
            :column_value,                                #  2/ REWRITTEN   RM 4.0.0 OK
            :csv_content,                                 #  3/ REWRITTEN   RM 4.0.0 OK
            :csv_value,                                   #  4/ REWRITTEN   RM 4.0.0 OK
            :filters_options_for_select,                  #  5/ REWRITTEN   RM 4.0.0 OK
            :query_available_inline_columns_options,      #  6/ REWRITTEN   RM 4.0.0 OK
            :query_selected_inline_columns_options,       #  7/ REWRITTEN   RM 4.0.0 OK
            :sort_options_by_label_and_order!,            #  8/ new method  RM 4.0.3 OK

            :column_value_hook,                           #  11/ new method RM 4.0.0 OK
            :csv_value_hook,                              #  12/ new method RM 4.0.0 OK
            :filters_options_for_select_hook,             #  13/ new method RM 4.0.0 OK
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
                format_object(value, true)
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

            # 5/ REWRITTEN, RM 4.0.3 OK
            # Smile specific #245550 Requêtes personnalisées : filtres : indicateur du type du groupe
            # Smile specific : hook added
            def filters_options_for_select(query)
              ungrouped = []
              grouped = {}
              query.available_filters.map do |field, field_options|
                ###############
                # Smile specfic : hook
                group = filters_options_for_select_hook(query, field, field_options)

                ################
                # Smile specific : unless
                unless group
                  # Smile comment : NATIVE code
                  if field_options[:type] == :relation
                    group = :label_relations
                  elsif field_options[:type] == :tree
                    group = query.is_a?(IssueQuery) ? :label_relations : nil
                  elsif field =~ /^cf_\d+\./
                    group = (field_options[:through] || field_options[:field]).try(:name)
                  elsif field =~ /^(.+)\./
                    # association filters
                    group = "field_#{$1}".to_sym
                  elsif %w(member_of_group assigned_to_role).include?(field)
                    group = :field_assigned_to
                  elsif field_options[:type] == :date_past || field_options[:type] == :date
                    group = :label_date
                  end
                end
                if group
                  (grouped[group] ||= []) << [field_options[:name], field]
                else
                  ungrouped << [field_options[:name], field]
                end
              end
              # Don't group dates if there's only one (eg. time entries filters)
              if grouped[:label_date].try(:size) == 1
                ungrouped << grouped.delete(:label_date).first
              end
              s = options_for_select([[]] + ungrouped)
              if grouped.present?
                localized_grouped = grouped.map {|k,v| [k.is_a?(Symbol) ? l(k) : k.to_s, v]}
                ################
                # Smile specific : sort groups by alphabetical order
                localized_grouped.sort_by! {|g| g.first}
                s << grouped_options_for_select(localized_grouped)
              end
              s
            end

            # 6/ REWRITTEN, RM 4.0.0 OK  BAR + INDIC
            # Smile specific #245965 Rapport : critères, indication type champ personnalisé
            # Smile comment : hook introduced here because this plugin is the one that is
            # loaded the first (before redmine_smile_* and redmine_xtended_queries)
            def query_available_inline_columns_options(query)
              available_inline_columns = (query.available_inline_columns - query.columns).reject(&:frozen?).collect {|column|
                  #######################
                  # Smile specific #245965 Rapport : critères, indication type champ personnalisé
                  # Smile specific : New hook
                  column_order = nil
                  column_label = column.caption

                  column_order_hook, column_label_hook = Query.column_label_and_order_hook(query, column)

                  if column_order_hook
                    column_order = column_order_hook
                    column_label = column_label_hook
                  end
                  # END -- Smile specific #245965 Rapport : critères, indication type champ personnalisé
                  #######################

                  ################
                  # Smile specific #245965 Rapport : critères, indication type champ personnalisé
                  # Smile specific : column.caption -> column_label
                  # Smile specific : added third value in array for order
                  [column_label, column.name, column_order]
                }

              ################
              # Smile specific #245965 Rapport : critères, indication type champ personnalisé
              # Smile specific : sort with criteria order
              sort_options_by_label_and_order!(available_inline_columns)

              ################
              # Smile specific #245965 Rapport : critères, indication type champ personnalisé
              # Smile specific : remove last element used to sort => will remain [column_label, column.name]
              available_inline_columns = available_inline_columns.collect{|k| [k[0], k[1]]}
            end

            # 7/ REWRITTEN, RM 4.0.0 OK  SMILE
            # Smile specific #245965 Rapport : critères, indication type champ personnalisé
            def query_selected_inline_columns_options(query)
              # Smile comment : do NOT sort !
              (query.inline_columns & query.available_inline_columns).reject(&:frozen?).collect {|column|
                  ################
                  # Smile specific #245965 Rapport : critères, indication type champ personnalisé
                  column_label = column.caption
                  # Smile specific : New hook
                  column_label_from_hook = Query.column_label_hook(query, column)

                  if column_label_from_hook
                    column_label = column_label_from_hook
                  end
                  # END -- Smile specific #245965 Rapport : critères, indication type champ personnalisé
                  #######################

                  ################
                  # Smile specific #245965 Rapport : critères, indication type champ personnalisé
                  # Smile specific : column.caption -> column_label
                  [column_label, column.name]
                }
            end

            # 8/ new method, RM 4.0.0 OK
            # Smile specific #245965 Rapport : critères, indication type champ personnalisé
            # Smile specific : options = [[label, name, order]]
            def sort_options_by_label_and_order!(options)
              # Smile specific : sort with label and order
              options.sort!{|x, y|
                option_order_x = x[2]
                option_order_y = y[2]

                if option_order_x && option_order_y
                  # [,, orderx], [,, ordery]
                  if option_order_x == option_order_y
                    # [labelx,, orderx], [labelx,, orderx]
                    x[0] <=> y[0]
                  else
                    # [labelx,, orderx], [labely,, ordery]
                    option_order_x <=> option_order_y
                  end
                elsif option_order_x
                  # [labelx,, orderx], [nil,, ordery] => at the end
                  1
                elsif option_order_y
                  # [nil,, orderx], [labely,, ordery] => at the begining
                  -1
                else
                  # [labelx,, orderx], [labelx,, orderx] normal order, not sorted
                  0
                  # x[0] <=> y[0]
                end
              }
              # END -- Smile specific #245965 Rapport : critères, indication type champ personnalisé
              #######################
            end


            # 11/ new method, RM 4.0.0 OK
            # Smile specific : method to override in other plugin to have specific behaviour
            def column_value_hook(column, item, value, options={})
              nil
            end

            # 12/ new method, RM 4.0.0 OK
            # Smile specific : method to override in other plugin to have specific behaviour
            def csv_value_hook(column, object, value, options={})
              nil
            end

            # 13/ New method, RM 4.0.3 OK
            # Smile specific : new hook
            def filters_options_for_select_hook(query, field, field_options)
              group = nil

              ################
              # Smile specific : TREE
              if field_options[:type] == :tree
                # Smile specific : tree filters group for TimeEntryQuery
                query_with_tree_group = query.is_a?(IssueQuery)
                query_with_tree_group ||= query.is_a?(TimeEntryQuery)
                # Smile specific : label_relations -> label_subtask_plural
                group = query_with_tree_group ? :label_subtask_plural : nil
                # END -- Smile specific : tree filters group for HistoryQuery
                #######################

              ################
              # Smile specific : C.F.
              # Smile specific #245550 Requêtes personnalisées : filtres : indicateur du type du groupe
              elsif field =~ /^cf_\d+/
                group = :label_custom_field

              ################
              # Smile specific : C.F.
              # Smile specific : custom_field_?_value
              elsif field =~ /^custom_field_\d+_value/
                group = :label_custom_field

              ################
              # Smile specific : CALENDAR
              # Smile specific : +duration, week, month, year
              elsif field_options[:type] == :date_past || field_options[:type] == :date || ['duration', 'week', 'month', 'year'].include?(field)
                group = :label_date

              ################
              # Smile specific : TREE
              # Smile specific : added root_id, children_count, parent_id, issue_id, level_in_tree
              elsif %w(subproject_id parent_project_id root_id children_count parent_id issue_id level_in_tree id issue).include?(field)
                group = :label_subtask_plural
              end

              group
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
