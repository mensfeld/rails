# frozen_string_literal: true

module ActiveRecord
  class ReadonlyAttributeError < ActiveRecordError
  end

  module ReadonlyAttributes
    extend ActiveSupport::Concern

    included do
      class_attribute :_attr_readonly, instance_accessor: false, default: []
    end

    module ClassMethods
      # Attributes listed as readonly will be used to create a new record but update operations will
      # ignore these fields.
      #
      # You can assign a new value to a readonly attribute, but it will be ignored when the record is updated.
      #
      # ==== Examples
      #
      #   class Post < ActiveRecord::Base
      #     attr_readonly :title
      #   end
      #
      #   post = Post.create!(title: "Introducing Ruby on Rails!")
      #   post.update(title: "a different title") # change to title will be ignored
      def attr_readonly(*attributes)
        new_attributes = attributes.map(&:to_s).reject { |a| _attr_readonly.include?(a) }

        if ActiveRecord.raise_on_assign_to_attr_readonly
          new_attributes.each do |attribute|
            define_method("#{attribute}=") do |value|
              raise ReadonlyAttributeError.new(attribute) unless new_record?

              super(value)
            end
          end

          include(HasReadonlyAttributes)
        end

        self._attr_readonly = Set.new(new_attributes) + _attr_readonly
      end

      # Returns an array of all the attributes that have been specified as readonly.
      def readonly_attributes
        _attr_readonly
      end

      def readonly_attribute?(name) # :nodoc:
        _attr_readonly.include?(name)
      end
    end

    module HasReadonlyAttributes # :nodoc:
      def write_attribute(attr_name, value)
        if !new_record? && self.class.readonly_attribute?(attr_name.to_s)
          raise ReadonlyAttributeError.new(attr_name)
        end

        super
      end
    end
  end
end
