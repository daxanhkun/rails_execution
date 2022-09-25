module RailsExecution
  module Services
    class Execution

      def self.call(task_id)
        self.new(::RailsExecution::Task.find(task_id)).call
      end

      def initialize(task)
        @task = task
      end

      def call
        return if bad_syntax?

        build_execution_file!
        load_execution_file!
        execute_class!
      end

      private

      attr_reader :task
      attr_reader :class_name

      def bad_syntax?
        !::RailsExecution::Services::SyntaxChecker.new(task.script).call
      end

      def build_execution_file!
        @class_name = "RailsExecutionID#{task.id}Time#{task.updated_at.to_i}Executor"
        ruby_code = <<~RUBY
          class #{class_name} < ::RailsExecution::Services::Executor
            def call
              #{task.script}
            end
          end
        RUBY

        @file = ::Tempfile.new(class_name)
        @file.binmode
        @file.write(ruby_code)
        @file.flush
        @file
      end

      def load_execution_file!
        load @file.path
      end

      def execute_class!
        class_name.constantize.new(task).call
      end

    end
  end
end
