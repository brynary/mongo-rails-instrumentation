require 'mongo/rails/instrumentation'

module Mongo::Rails::Instrumentation
  module ControllerRuntime
    extend ActiveSupport::Concern

    protected

    attr_internal :mongo_runtime
    attr_internal :mongo_calls

    def process_action(action, *args)
      LogSubscriber.reset_runtime
      super
    end

    def cleanup_view_runtime
      mongo_rt_before_render = LogSubscriber.reset_runtime
      runtime = super
      mongo_rt_after_render = LogSubscriber.reset_runtime
      self.mongo_calls = LogSubscriber.reset_count
      self.mongo_runtime = mongo_rt_before_render + mongo_rt_after_render
      runtime - mongo_rt_after_render
    end

    def append_info_to_payload(payload)
      super
      payload[:mongo_calls] = mongo_calls
      payload[:mongo_runtime] = mongo_runtime
    end

    module ClassMethods
      def log_process_action(payload)
        messages, mongo_runtime = super, payload[:mongo_runtime]
        messages << ("Mongo: %d/%.1fms" % [payload[:mongo_calls], mongo_runtime.to_f]) if mongo_runtime
        messages
      end
    end
  end
end
