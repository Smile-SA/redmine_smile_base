# Smile - add methods to the Redmine::I18n module
#
# 1/ module Enhancements
# - #50583 Affichage des heures entières
# - #994 Budget / Remaining management


module Smile
  module RedmineOverride
    module I18nOverride
      #****************
      # 1/ Enhancements
      module Enhancements
        def self.prepended(base)
          # We must use a module eval, because module included in included modules
          # TODO jebat get explanation
          base.module_eval do
            # 1/ new method, RM 2.6.10 OK
            # Smile specific #50583 Affichage des heures entières
            # Label for hours / days, optionally truncated
            def l_time(time_value, hours_by_day=nil, convert_in_days=false, nbsp=false)
              is_in_days = (hours_by_day && hours_by_day != 0)

              # Value is nil
              unless time_value
                label_no = l(:label_no)
                if is_in_days
                  return l( :label_f_day, :value => label_no )
                else
                  return l( :label_f_hour, :value => label_no )
                end
              end

              # Convert in days ? time_value is a float
              time_value /= hours_by_day if is_in_days && convert_in_days && (time_value != 0)

              is_plural_value = time_value && ( (time_value <= -2.0) || (time_value >= 2.0) )

              if is_in_days
                rounded_decimals = 5
              else
                rounded_decimals = 2
              end

              time_value_i = time_value.round
              time_value_f_r = time_value.round(rounded_decimals)

              if time_value_i == time_value_f_r
                time_value = time_value_i.to_s
              else
                time_value = ("%.#{rounded_decimals}f" % time_value)
                time_value.gsub!(/[0]*$/, '') # Remove ending zeros
              end

              if is_in_days
                time_html = l( ( is_plural_value ? :label_f_day_plural : :label_f_day), :value => time_value )
              else
                time_html = l( ( is_plural_value ? :label_f_hour_plural : :label_f_hour), :value => time_value )
              end

              # Smile specific to avoid time to be separated from label
              time_html.gsub!(' ', '&nbsp;').html_safe if nbsp

              time_html
            end

            # 2/ new method, RM 2.6.10 OK
            # Smile specific #50583 Affichage des heures entières
            # Smile specific : do not display decimals if zero
            # Smile specific : For estimated_hours, budget_hours, spent_hours, remaining_hours, billable_hours, gain_hours, deviation_hours
            def round_decimals(time_value, hours_by_day=nil, convert_in_days=false)
              return '' if time_value.nil?

              is_in_days = (hours_by_day && hours_by_day != 0)

              # Convert in days ? time_value is a float
              time_value /= hours_by_day if is_in_days && convert_in_days && (time_value != 0)

              if is_in_days
                rounded_decimals = 5
              else
                rounded_decimals = 2
              end

              time_value_i = time_value.round
              time_value_f_r = time_value.round(rounded_decimals)

              if time_value_i == time_value_f_r
                # 4.00001 -> 4
                time_value_i.to_s
              else
                time_value = ("%.#{rounded_decimals}f" % time_value)
                # 2.25000 -> 2.25
                time_value.gsub!(/[0]*$/, '') # Remove ending zeros

                time_value
              end
            end

            # 3/ new method, RM 2.6.10 OK
            # Smile specific : format_date enhanced, new param format=nil
            def format_date_by_directives(date, format)
              return nil unless date
              options = {}

              # Smile specific #50583 Affichage des heures entières
              options[:format] = format

              options[:locale] = User.current.language unless User.current.language.blank?
              ::I18n.l(date.to_date, options)
            end

            # 4/ new_method, RM 2.6.10 OK
            # Smile specific : format_time enhanced, new params time_fmt=nil, date_fmt=nil
            def format_date_time(time, time_fmt=nil, date_fmt=nil)
              return nil unless time
              options = {}

              #####################################################
              # Smile specific #50583 Affichage des heures entières
              if time_fmt.present?
                options[:format] = time_fmt
              else
                options[:format] = (Setting.time_format.blank? ? :time : Setting.time_format)
              end
              # END -- Smile specific #50583 Affichage des heures entières
              ############################################################

              options[:locale] = User.current.language unless User.current.language.blank?
              time = time.to_time if time.is_a?(String)
              zone = User.current.time_zone
              local = zone ? time.in_time_zone(zone) : (time.utc? ? time.localtime : time)

              # Smile specific #50583 Affichage des heures entières
              # Smile specific : format_date_by_directives
              "#{format_date_by_directives(local, date_fmt)} "  + ::I18n.l(local, options)
            end

            # 5/ new method, RM 2.6.10 OK
            def format_duration(time_seconds, show_millis=false, color_if_greater_than=false)
              Redmine::I18n.format_duration(time_seconds, show_millis, color_if_greater_than)
            end

            # 6/ REWRITTEN, RM 4.0.0 OK
            # Smile specific #49896 Imputation négatives
            def l_hours(hours)
              hours = hours.to_f

              # Smile specific #49896 Imputation négatives : hours > -2.0
              l(((hours > -2.0 && hours < 2.0) ? :label_f_hour : :label_f_hour_plural), :value => format_hours(hours))
            end

            # 7/ REWRITTEN (super not accessible), RM 4.0.0 OK
            # Smile specific #50583 Affichage des heures entières
            # Smile specific #50583 Display decimals hours only if fractional
            # Smile specific : +param hours_by_day
            def format_hours(hours, hours_by_day=nil)
              return "" if hours.blank?

              if Setting.timespan_format == 'minutes'
                h = hours.floor
                m = ((hours - h) * 60).round
                "%d:%02d" % [ h, m ]
              else
                #################################################################
                # Smile specific #50583 Display decimals hours only if fractional
                # Smile specific #50583 Affichage des heures entières
                # Upstream behaviour : "%.2f" % hours.to_f
                round_decimals(hours, hours_by_day)
                # END -- Smile specific #50583 Display decimals hours only if fractional
                ########################################################################
              end
            end

            class << self
              # 10/ new method, RM 2.6.10 OK
              def format_duration(time_seconds, show_millis=false, color_if_greater_than=nil)
                remaining_seconds = time_seconds.to_i

                color_enabled = false
                if (
                  color_if_greater_than &&
                  color_if_greater_than.is_a?(Integer) &&
                  remaining_seconds > color_if_greater_than
                )
                  color_enabled = true
                end

                if show_millis
                  milli_seconds = (time_seconds * 1000).to_i
                  milli_seconds -= remaining_seconds * 1000
                end

                a_day_in_seconds = 3600 * 24

                #find the days
                days = remaining_seconds / a_day_in_seconds
                remaining_seconds -= days * a_day_in_seconds

                #find the hours
                hours = remaining_seconds / 3600
                remaining_seconds -= hours * 3600

                #find the minutes
                minutes = remaining_seconds / 60
                remaining_seconds -= minutes * 60

                with_millis        = show_millis && (milli_seconds != 0.0)
                with_hours         = hours > 0
                with_hours_minutes = minutes > 0 || with_hours
                with_time          = remaining_seconds > 0 || with_hours_minutes
                with_days          = days > 0

                duration_formated = ''
                if with_millis || with_time || ! with_days
                  # Display time (with millis) if present or if no days
                  if with_millis
                    duration_formated = format("%03d", milli_seconds)
                    duration_formated = '.' + duration_formated if with_time || ! with_days
                  end

                  # Prefix with 0 ?
                  if with_hours_minutes || with_days
                    duration_formated = format("%02d", remaining_seconds) + duration_formated
                  else
                    duration_formated = remaining_seconds.to_s + duration_formated
                  end

                  duration_formated = format("%02d", minutes) + ':' + duration_formated if with_hours_minutes || with_days

                  duration_formated = format("%02d", hours) + ':' + duration_formated if with_hours || with_days

                  # Separator with days
                  duration_formated = ' ' + duration_formated if with_days
                else
                  duration_formated = ''
                end

                if with_days
                  duration_formated = days.to_s +
                    # '<b>D</b>' depends of the language
                    "<b>#{::I18n.t(:label_day_plural).first.upcase}</b>".html_safe +
                    duration_formated
                end

                if color_enabled
                  duration_formated = "\033[1;31;47m#{duration_formated}\033[0m"
                end

                duration_formated
              end
            end # class << self
          end # base.module_eval


          #-----------------
          # Instance methods
          enhancements_instance_methods = [
            :l_time,                    # 1/ new method
            :round_decimals,            # 2/ new method
            :format_date_by_directives, # 3/ new method
            :format_date_time,          # 4/ new method
            :format_duration,           # 5/ new method
            :l_hours,                   # 6/ REWRITTEN   RM V4.0.0 OK
            :format_hours,              # 7/ REWRITTEN   RM V4.0.0 OK
          ]

          module_name = 'SM::RedmineOverride::I18nOverride::Enhancements'
          trace_prefix       = "#{' ' * (base.name.length - 5)}                          --->  "
          last_postfix       = "< (#{module_name})"

          smile_instance_methods = base.instance_methods.select{|m|
              enhancements_instance_methods.include?(m) &&
                base.instance_method(m).source_location.first =~ SmileTools.regex_path_in_plugin('lib/smile_redmine_i18n', :redmine_smile_base)
            }

          missing_instance_methods = enhancements_instance_methods.select{|m|
            !smile_instance_methods.include?(m)
          }

          if missing_instance_methods.any?
            trace_first_prefix = "Redmine::I18n MISS    instance_methods  "
          else
            trace_first_prefix = "Redmine::I18n         instance_methods  "
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


          #--------------
          # Class methods
          enhancements_class_methods = [
            :format_duration, # 10/ new method
          ]

          smile_class_methods = enhancements_class_methods.select{|m|
              base.methods.include?(m) || base.private_methods.include?(m)
            }

          trace_first_prefix = "Redmine::I18n                  methods  "
          trace_prefix       = "#{' ' * (base.name.length - 5)}                           --->  "
          last_postfix       = "< (#{module_name})"

          SmileTools::trace_by_line(
            smile_class_methods,
            trace_first_prefix,
            trace_prefix,
            last_postfix,
            :redmine_smile_base
          )
        end # def self.prepended
      end # module Enhancements
    end # module I18nOverride
  end # module RedmineOverride
end # module Smile
