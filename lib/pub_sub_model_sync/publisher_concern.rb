# frozen_string_literal: true

module PubSubModelSync
  module PublisherConcern
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Before initializing sync service (callbacks: after create/update/destroy)
    def ps_skip_callback?(_action)
      false
    end

    # before preparing data to sync
    def ps_skip_sync?(_action)
      false
    end

    # before delivering data
    def ps_before_sync(_action, _data); end

    # after delivering data
    def ps_after_sync(_action, _data); end

    # To perform sync on demand
    def ps_perform_sync(action = :create)
      service = self.class.ps_publisher_service
      service.publish_model(self, action, self.class.ps_publisher_info(action))
    end

    module ClassMethods
      # Permit to publish crud actions (:create, :update, :destroy)
      # @param settings (Hash): { actions: nil, as_klass: nil, id: nil }
      def ps_publish(attrs, settings = {})
        actions = settings.delete(:actions) || %i[create update destroy]
        actions.each do |action|
          info = settings.merge(klass: name, action: action, attrs: attrs)
          PubSubModelSync::Config.publishers << info
          ps_register_callback(action.to_sym, info)
        end
      end

      # Publisher info for specific action
      def ps_publisher_info(action = :create)
        PubSubModelSync::Config.publishers.select do |listener|
          listener[:klass] == name && listener[:action] == action
        end.last
      end

      # On demand class level publisher
      def ps_class_publish(data, action:, as_klass: nil)
        as_klass = (as_klass || name).to_s
        ps_publisher_service.publish_data(as_klass, data, action.to_sym)
      end

      def ps_publisher_service
        PubSubModelSync::Publisher.new
      end

      private

      def ps_register_callback(action, info)
        after_commit(on: action) do |model|
          unless model.ps_skip_callback?(action)
            service = model.class.ps_publisher_service
            service.publish_model(model, action.to_sym, info)
          end
        end
      end
    end
  end
end
