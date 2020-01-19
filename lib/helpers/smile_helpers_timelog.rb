# Smile - timelog_helper enhancement
#
# - 1/ module ::AssignToAuthor
#      #120773 Assigner à << moi >> et à << auteur >>

module Smile
  module Helpers
    module TimelogOverride
      #******************
      # 1/ AssignToAuthor
      module AssignToAuthor
        def self.prepended(base)
          assign_to_me_and_author_instance_methods = [
            :user_collection_for_select_options,       # 1/ REWRITTEN,  RM 4.0.0 OK
          ]

          # Smile comment : module_eval mandatory with helpers, but no more access to rewritten methods
          # Smile comment : => use of alias method to access to ancestor version
          base.module_eval do
            # 1/ REWRITTEN, RM 4.0.0 OK
            # Smile specific #120773 Assigner à << moi >> et à << auteur >>
            # New parameters added :
            # * author
            # * debug
            def user_collection_for_select_options(time_entry, author=nil, debug=nil)
              collection = time_entry.assignable_users(debug)
              principals_options_for_select(collection, time_entry.user_id, author)
            end
          end # base.module_eval do

          trace_prefix       = "#{' ' * (base.name.length + 19)}  --->  "
          last_postfix       = '< (SM::HO::TimelogOverride::AssignToAuthor)'

          smile_instance_methods = base.instance_methods.select{|m|
              assign_to_me_and_author_instance_methods.include?(m) &&
                base.instance_method(m).source_location.first =~ SmileTools.regex_path_in_plugin('lib/helpers/smile_helpers_timelog', :redmine_smile_base)
            }

          missing_instance_methods = assign_to_me_and_author_instance_methods.select{|m|
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
        end # def self.extended
      end # module AssignToAuthor
    end # module TimelogOverride
  end # module Helpers
end # module Smile
