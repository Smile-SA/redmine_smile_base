# encoding: UTF-8

# Smile - adds methods to the Issue model
#
# 1/ module Tools

#require 'active_support/concern' #Rails 3

module Smile
  module Models
    module IssueOverride
      #*********
      # 1/ Tools

      module Tools
        # extend ActiveSupport::Concern

        def self.prepended(base)
          ##################
          # 3/ Class methods
          tools_class_methods = [
            :load_assoc,                                           # 1/ new method
            :load_sub_assoc_of_assoc,                              # 2/ new method
          ]

          base.singleton_class.prepend ClassMethods

          trace_prefix    = "#{' ' * (base.name.length + 27)}  --->  "
          last_postfix    = '< (SM::MO::IssueOverride::Tools::CMeths)'

          smile_class_methods = base.methods.select{|m|
              base.method(m).owner == ClassMethods
            }

          missing_class_methods = tools_class_methods.select{|m|
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
            last_postfix,
            :redmine_smile_base
          )

          if missing_class_methods.any?
            raise trace_first_prefix + missing_class_methods.join(', ') + '  ' + last_postfix
          end
        end # def self.prepended


        module ClassMethods
         # 1/ new method, RM 2.6.1 OK
          # Preloads a model association
          def load_assoc(
            model_objects,
            assoc_target_model,
            assoc_target_name,
            assoc_target_key,
            assoc_target_select_columns=nil,
            debug=nil
          )
            return unless model_objects && model_objects.any?

            if debug
              logger.debug " =>prof"
              logger.debug "\\=>prof     load_assoc  #{assoc_target_key}/#{assoc_target_model}"

              start = Time.now
            end

            #******************************************************************
            # 1) Find all association TARGET DISTINCT IDs for the model objects
            sql_assoc_target_ids = model_objects.collect{|model_object|
              # Association target id
              model_object.send(assoc_target_key)
            }.select{|a| a.present?}.uniq.join(', ')

            if sql_assoc_target_ids.blank?
              logger.debug "/=>prof     NO target id found" if debug

              return
            end
            logger.debug " =>prof       sql_assoc_target_ids=#{sql_assoc_target_ids}" if debug == '2'


            #***********************************************
            # 2) Load all DISTINCT association model objects
            unless assoc_target_select_columns
              assoc_target_table_name = assoc_target_model.table_name
              assoc_target_select_columns = "#{assoc_target_table_name}.id, #{assoc_target_table_name}.name"
            else
              logger.debug " =>prof       select=#{assoc_target_select_columns}" if debug == '2'
            end

            assoc_target_models = assoc_target_model.where(
                "#{assoc_target_model.table_name}.id IN (#{sql_assoc_target_ids})"

              ).select(
                # Select the columns to retrieve
                assoc_target_select_columns
              )

            logger.debug " =>prof       [#{assoc_target_models.size}] assoc_target_models" if debug

            #SmileTools.debug_scope(assoc_target_models, 'prof', 'load_assoc')


            #****************************************
            # 3) Sort association target models by id
            assoc_target_models_by_ids = {}
            assoc_target_models.each{|a|
              assoc_target_models_by_ids[a.id] = a
            }

            logger.debug " =>prof       assoc_target_models_by_ids=#{assoc_target_models_by_ids.keys.inspect}" if debug == '2'

            #*******************************************
            # 4) Inject association target model objects
            assoc_targets_loaded = 0
            model_objects.each{|model_object|
              model_object_association = model_object.send(:association, assoc_target_name)

              # Do not reload again
              next if model_object_association.loaded?

              assoc_target_id = model_object.send(assoc_target_key)
              # Load dynamically association target object
              model_object_association.target = assoc_target_models_by_ids[assoc_target_id]
              assoc_targets_loaded += 1
            }

            logger.debug "/=>prof     load_assoc [#{assoc_targets_loaded}] objects loaded -- #{Redmine::I18n.format_duration(Time.now - start, true)}" if debug
          end

          # 2/ new method, RM 2.6.1 OK
          # Preloads sub-association of a model association
          def load_sub_assoc_of_assoc(
            model_objects,
            assoc_target_model,
            sub_assoc_target_model,
            sub_assoc_target_name,
            sub_assoc_target_key,
            sub_assoc_target_select_columns=nil,
            debug=nil
          )
            return unless model_objects && model_objects.any?

            if debug
              logger.debug "==>prof"
              logger.debug "\\=>prof   load_sub_assoc_of_assoc  #{assoc_target_model}.#{sub_assoc_target_name}"

              start = Time.now
            end

            #************************************************
            # 1) Find all sub association TARGET DISTINCT IDs
            #    for the given model object association
            sql_sub_assoc_target_ids = model_objects.collect{|model_object|
              # Sub-association target id
              model_object_association = model_object.send(assoc_target_model)

              next if model_object_association.nil?

              model_object_association.send(sub_assoc_target_key)
            }.select{|a| a.present?}.uniq.join(', ')

            if sql_sub_assoc_target_ids.blank?
              logger.debug "/=>prof     #{assoc_target_model} #{sub_assoc_target_name} NO target found" if debug

              return
            end


            #***************************************************
            # 2) Load all DISTINCT sub association model objects
            unless sub_assoc_target_select_columns
              sub_assoc_target_table_name = sub_assoc_target_model.table_name
              sub_assoc_target_select_columns = "#{sub_assoc_target_table_name}.id, #{sub_assoc_target_table_name}.name"
            else
              logger.debug " =>prof     #{assoc_target_model}   select=#{sub_assoc_target_select_columns}" if debug == '2'
            end

            sub_assoc_target_models = sub_assoc_target_model.where(
                "#{sub_assoc_target_model.table_name}.id IN (#{sql_sub_assoc_target_ids})"

              ).select(
                # Select the columns to retrieve
                sub_assoc_target_select_columns
              )

            #SmileTools.debug_scope(sub_assoc_target_models, 'prof', 'load_sub_assoc_of_assoc') if debug == '2'


            #********************************************
            # 3) Sort sub association target models by id
            sub_assoc_target_models_by_ids = {}

            sub_assoc_target_models.each{|a|
              sub_assoc_target_models_by_ids[a.id] = a
            }

            logger.debug " =>prof     [#{sub_assoc_target_models.size}] sub_assoc_target_models" if debug == '2'


            #***********************************************
            # 4) Inject sub association target model objects
            sub_assoc_targets_loaded = 0
            model_objects.each{|model_object|
              model_object_association = model_object.send(assoc_target_model)

              next if model_object_association.nil?


              model_object_sub_association = model_object_association.send(:association, sub_assoc_target_name)

              next if model_object_sub_association.loaded?

              logger.debug " =>prof     model_object_sub_associations=[#{model_object_association.class.reflect_on_all_associations.collect{|a| a.name}.join(', ')}]" if (sub_assoc_targets_loaded == 0) && debug == '2'


              sub_assoc_target_id = model_object_association.send(sub_assoc_target_key)
              model_object_sub_association.target = sub_assoc_target_models_by_ids[sub_assoc_target_id]
              sub_assoc_targets_loaded += 1
            }

            logger.debug "/=>prof     [#{sub_assoc_targets_loaded}] objects loaded -- #{Redmine::I18n.format_duration(Time.now - start, true)}" if debug
          end
        end # module ClassMethods
      end # module Tools
    end # module IssueOverride
  end # module Models
end # module Smile
